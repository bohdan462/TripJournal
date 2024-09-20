//
//  TokenManager.swift
//  TripJournal
//
//  Created by Bohdan Tkachenko on 9/13/24.
//

import Foundation
import Combine

/**
 TokenState is an enum representing the various states of the token management lifecycle.

 - idle: No token-related operation is in progress.
 - fetching: A token is being fetched.
 - fetched: A token has been successfully fetched.
 - refreshing: A token refresh is in progress.
 - expired: The token has expired and cannot be used.
 - error: An error occurred during token operations, carrying the error details.
 */
enum TokenState {
    case idle
    case fetching
    case fetched(Token)
    case refreshing
    case expired
    case error(Error)
}

/**
 TokenManager is an actor responsible for managing access tokens, handling their expiration, refresh, and storage.

 It interacts with a `SecureStorage` (such as Keychain) for saving and retrieving tokens, and ensures token validity by refreshing it if necessary. The state of the token (e.g., fetching, expired) is published to any observers.

 - Uses Combine's `@Published` to provide real-time updates on token state.
 - Utilizes in-memory caching for tokens to avoid redundant storage access.
 - Refreshes tokens when they are close to expiration (configurable by `tokenExpirationThreshold`).

 Properties:
 - `state`: The current state of the token, published for observers.
 - `storage`: An implementation of `SecureStorage` for saving and retrieving tokens securely.
 - `tokenExpirationThreshold`: Time interval before the actual expiration when the token is considered expired (default is 5 minutes).

 Methods:
 - `getToken()`: Retrieves a valid token, refreshing it if it has expired.
 - `fetchToken()`: Fetches the token and updates the internal state accordingly.
 - `saveToken(_:username:password:)`: Saves a new token and optionally the associated credentials.
 - `deleteToken()`: Deletes the stored token and clears the in-memory cache.

 Private Methods:
 - `loadTokenFromStorage()`: Loads a token from secure storage.
 - `isTokenExpired(_:)`: Checks whether the token has expired or is close to expiration.
 - `handleTokenRefresh(token:)`: Refreshes the token, using stored credentials if available.
 - `refreshToken(token:)`: Handles the actual process of re-authenticating with stored credentials to fetch a new token.
 - `saveTokenToStorage(token:username:password:)`: Saves the token and optionally user credentials to secure storage.
 - `deleteTokenFromStorage()`: Deletes the token and credentials from secure storage.
 */
class TokenManager: ObservableObject {

    // MARK: - Published State
    @Published private(set) var state: TokenState = .idle

    // MARK: - Dependencies
    let storage: SecureStorage
    
    // Time interval in seconds to treat token as expired before its actual expiration
    private let tokenExpirationThreshold: TimeInterval = 300 // 5 minutes

    // MARK: - Internal Caching & State
    private var isRefreshing = false
    private var refreshWaiters: [CheckedContinuation<Token?, Error>] = []
    private var cachedToken: Token?  // In-memory cached token

    // MARK: - Initialization
    /**
     Initializes the TokenManager with a provided SecureStorage implementation.
     
     - Parameter storage: A SecureStorage implementation for handling token and credential persistence.
     */
    init(storage: SecureStorage) {
        self.storage = storage
    }

    // MARK: - Public Methods

    /**
     Asynchronously fetches a valid token. If the cached token is expired, it attempts to refresh it.

     - Throws: An error if token retrieval or refresh fails.
     - Returns: A valid Token if one exists and is not expired.
     */
    func getToken() async throws -> Token? {
        print("Token:\(cachedToken?.accessToken)")
        // If a cached token exists and is still valid, return it
        if let cachedToken = cachedToken, !isTokenExpired(cachedToken) {
            print("Using cached token")
            return cachedToken
        }

        // Attempt to fetch the token from storage
        if let token = try await loadTokenFromStorage() {
            if isTokenExpired(token) {
                // Token has expired, trigger a refresh
                return try await handleTokenRefresh(token: token)
            }
            cachedToken = token  // Cache the valid token
            print("Loaded token from storage")
            return token
        }
        print("No token found")
        return nil  // No token found
    }

    /**
     Fetches a token and updates the internal state accordingly. This method will attempt to load or refresh a token and publish the result via the `state` property.
     */
    @MainActor
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

    /**
     Saves a token to storage and updates the in-memory cache. Optionally, the associated credentials (username, password) can also be stored.
     
     - Parameters:
        - token: The token to be saved.
        - username: Optional username to be saved with the token.
        - password: Optional password to be saved with the token.
     */
    @MainActor
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

    /**
     Deletes the token and associated credentials from storage and clears the in-memory cache.
     */
    @MainActor
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

    /**
     Loads the token from storage.

     - Throws: An error if unable to retrieve the token from storage.
     - Returns: A Token if it exists, or nil if no token is found.
     */
    private func loadTokenFromStorage() async throws -> Token? {
        guard let tokenData = try await storage.get(forKey: "authToken") else { return nil }
        return try JSONDecoder().decode(Token.self, from: tokenData)
    }

    /**
     Checks if the token is expired or will expire soon, based on the `tokenExpirationThreshold`.

     - Parameter token: The token to be checked.
     - Returns: A Boolean indicating whether the token is considered expired.
     */
    private func isTokenExpired(_ token: Token) -> Bool {
        guard let expirationDate = token.expirationDate else { return false }
        print("Checking if expired")
        return expirationDate.timeIntervalSinceNow < tokenExpirationThreshold
    }

    /**
     Handles the token refresh process. If a refresh is already in progress, it waits for the ongoing refresh to complete.

     - Parameter token: The token to be refreshed.
     - Throws: An error if refreshing the token fails.
     - Returns: A new valid Token if the refresh is successful, or nil if not.
     */
    @MainActor
    private func handleTokenRefresh(token: Token?) async throws -> Token? {
        if isRefreshing {
            return try await withCheckedThrowingContinuation { continuation in
                refreshWaiters.append(continuation)
            }
        }

        isRefreshing = true
        state = .refreshing

        do {
            let newToken = try await refreshToken(token: token)
            isRefreshing = false

            cachedToken = newToken
            state = newToken != nil ? .fetched(newToken!) : .expired

            for waiter in refreshWaiters {
                waiter.resume(returning: newToken)
            }
            refreshWaiters.removeAll()

            return newToken
        } catch {
            isRefreshing = false
            state = .error(error)

            for waiter in refreshWaiters {
                waiter.resume(throwing: error)
            }
            refreshWaiters.removeAll()

            throw error
        }
    }

    /**
     Performs the actual token refresh operation using stored credentials. If refreshing fails, retries up to 3 times with exponential backoff.

     - Parameter token: The current token (optional) being refreshed.
     - Throws: An error if refreshing fails after all retries.
     - Returns: A new valid Token or nil if unable to refresh.
     */
    private func refreshToken(token: Token?) async throws -> Token? {
        guard let credentialsData = try await storage.get(forKey: "userCredentials"),
              let credentialsDict = try JSONSerialization.jsonObject(with: credentialsData, options: []) as? [String: String],
              let username = credentialsDict["username"],
              let password = credentialsDict["password"] else {
            throw KeychainError.unableToRetrieveData
        }
        
        let authService = AuthenticationService(tokenManager: self)
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

        throw lastError ?? NetworkError.unauthorized
    }

    /**
     Saves the token and optionally user credentials to secure storage.

     - Parameters:
        - token: The token to be saved.
        - username: The username to be saved (optional).
        - password: The password to be saved (optional).
     - Throws: An error if saving to storage fails.
     */
    private func saveTokenToStorage(token: Token, username: String?, password: String?) async throws {
        let tokenData = try JSONEncoder().encode(token)
        try await storage.save(data: tokenData, forKey: "authToken")
        
        if let username = username, let password = password {
            let credentialsData = try JSONSerialization.data(withJSONObject: ["username": username, "password": password])
            try await storage.save(data: credentialsData, forKey: "userCredentials")
        }
    }

    /**
     Deletes the token and credentials from storage.

     - Throws: An error if deleting from storage fails.
     */
    private func deleteTokenFromStorage() async throws {
        try await storage.delete(forKey: "authToken")
        try await storage.delete(forKey: "userCredentials")
    }
}
