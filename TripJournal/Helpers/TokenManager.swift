import Foundation
import Combine

enum TokenState {
    case idle
    case fetching
    case fetched(Token)
    case refreshing  // New state for when refresh is in progress
    case expired
    case error(Error)
}

actor TokenManager: ObservableObject {

    @Published private(set) var state: TokenState = .idle
    let storage: SecureStorage
    private let tokenExpirationThreshold: TimeInterval = 300 // 5 minutes (300 seconds)
    
    private var isRefreshing = false
    private var refreshWaiters: [CheckedContinuation<Token?, Error>] = [] // To queue pending requests during refresh
    private var cachedToken: Token?  // In-memory cached token
    
    init(storage: SecureStorage) {
        self.storage = storage
    }
    
    // Public method to get a token and handle its expiration
    func getToken() async throws -> Token? {
        // If a cached token exists and is still valid, return it
        if let cachedToken = cachedToken, !isTokenExpired(cachedToken) {
            return cachedToken
        }

        // Attempt to fetch the token from storage
        if let token = try await loadTokenFromStorage() {
            if isTokenExpired(token) {
                // Token has expired, trigger a refresh
                return try await handleTokenRefresh(token: token)
            }
            cachedToken = token  // Cache the valid token
            return token
        }
        return nil  // No token found
    }

    // Public method to fetch the token and update state
    func fetchToken() async {
        state = .fetching
        do {
            if let token = try await getToken() {
                state = .fetched(token)
            } else {
                state = .idle  // No token found
            }
        } catch {
            state = .error(error)
        }
    }

    // Save token to storage and cache
    func saveToken(_ token: Token, username: String? = nil, password: String? = nil) async {
        state = .fetching
        do {
            cachedToken = token  // Cache the token in memory
            try await saveTokenToStorage(token: token, username: username, password: password)
            state = .fetched(token)
        } catch {
            state = .error(error)
        }
    }

    // Delete token and credentials from storage
    func deleteToken() async {
        state = .fetching
        do {
            cachedToken = nil  // Clear in-memory cache
            try await deleteTokenFromStorage()
            state = .idle
        } catch {
            state = .error(error)
        }
    }

    // MARK: - Private Helper Methods

    // Load token from storage
    private func loadTokenFromStorage() async throws -> Token? {
        guard let tokenData = try await storage.get(forKey: "authToken") else { return nil }
        return try JSONDecoder().decode(Token.self, from: tokenData)
    }

    // Check if the token is expired or about to expire
    private func isTokenExpired(_ token: Token) -> Bool {
        guard let expirationDate = token.expirationDate else { return false }
        return expirationDate.timeIntervalSinceNow < tokenExpirationThreshold  // Expire a few minutes early
    }

    // Handle token refresh
    private func handleTokenRefresh(token: Token?) async throws -> Token? {
        if isRefreshing {
            // If a refresh is already in progress, wait for it to complete
            return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Token?, Error>) in
                refreshWaiters.append(continuation) // Add this request to the waiting queue
            }
        }

        isRefreshing = true
        state = .refreshing  // Set state to refreshing

        do {
            let newToken = try await refreshToken(token: token)
            isRefreshing = false

            if let validToken = newToken {
                cachedToken = validToken
                state = .fetched(validToken)  // Update the state with the valid token
            } else {
                state = .expired  // No token found, set state to expired
            }

            // Resolve all waiting continuations with the new token (even if nil)
            for waiter in refreshWaiters {
                waiter.resume(returning: newToken)  // Can return nil if no token is fetched
            }
            refreshWaiters.removeAll()

            return newToken
        } catch {
            isRefreshing = false
            state = .error(error)  // Update the state with the error

            // Propagate error to waiting continuations
            for waiter in refreshWaiters {
                waiter.resume(throwing: error)
            }
            refreshWaiters.removeAll()

            throw error
        }
    }

    // Refresh the token using credentials from storage
    private func refreshToken(token: Token?) async throws -> Token? {
        print("Token expired. Refreshing token...")
        
        guard let credentialsData = try await storage.get(forKey: "userCredentials"),
              let credentialsDict = try JSONSerialization.jsonObject(with: credentialsData, options: []) as? [String: String],
              let username = credentialsDict["username"],
              let password = credentialsDict["password"] else {
            throw KeychainError.unableToRetrieveData
        }
        
        let authService = AuthServiceImpl(tokenManager: self)
        let retryCount = 3
        let delay: TimeInterval = 1.0 // 1 second delay for exponential backoff
        
        var attempt = 0
        var lastError: Error?

        while attempt < retryCount {
            do {
                let newToken = try await authService.logIn(username: username, password: password)
                await saveToken(newToken, username: username, password: password)
                return newToken
            } catch {
                lastError = error
                attempt += 1
                await Task.sleep(UInt64(delay * pow(2.0, Double(attempt)) * 1_000_000_000)) // Exponential backoff
            }
        }

        // If all retries fail, throw the last error
        throw lastError ?? NetworkError.unauthorized
    }

    // Save token and optionally credentials to storage
    private func saveTokenToStorage(token: Token, username: String?, password: String?) async throws {
        let tokenData = try JSONEncoder().encode(token)
        try await storage.save(data: tokenData, forKey: "authToken")
        
        if let username = username, let password = password {
            let credentialsData = try JSONSerialization.data(withJSONObject: ["username": username, "password": password])
            try await storage.save(data: credentialsData, forKey: "userCredentials")
        }
    }

    // Delete token and credentials from storage
    private func deleteTokenFromStorage() async throws {
        try await storage.delete(forKey: "authToken")
        try await storage.delete(forKey: "userCredentials")
    }
}
