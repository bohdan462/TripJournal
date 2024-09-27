//
//  TokenManager.swift
//  TripJournal
//
//  Created by Bohdan Tkachenko on 9/13/24.
//

import Foundation
import Combine

enum TokenError: Error {
    case noRefreshHandler
    case authenticationServiceDeallocated
}

enum TokenState {
    case idle
    case fetching
    case fetched(Token)
    case refreshing
    case expired
    case error(Error)
}

actor TokenStorage {
    private var cachedToken: Token?

    func getToken() -> Token? {
        return cachedToken
    }

    func saveToken(_ token: Token?) {
        self.cachedToken = token
    }

    func deleteToken() {
        self.cachedToken = nil
    }
}

class TokenManager: ObservableObject {

    // MARK: - Published State
    @Published private(set) var state: TokenState = .idle

    // MARK: - Dependencies
    private let storage: SecureStorage
    private let tokenActor: TokenStorage
    private let serviceLocator: ServiceLocator // Instead of direct AuthService

    // Time interval in seconds to treat token as expired before its actual expiration
    private let tokenExpirationThreshold: TimeInterval = 300 // 5 minutes

    // MARK: - Internal Caching & State
    private var isRefreshing = false
    private var refreshWaiters: [CheckedContinuation<Token?, Error>] = []

    // MARK: - Initialization
    init(storage: SecureStorage, tokenStorage: TokenStorage, serviceLocator: ServiceLocator) {
        self.storage = storage
        self.tokenActor = tokenStorage
        self.serviceLocator = serviceLocator // Using ServiceLocator for dependencies
        print("Initialized TokenManager")
    }

    // MARK: - Public Methods
    func getToken() async throws -> Token? {
        // If a cached token exists and is still valid, return it
        if let cachedToken = await tokenActor.getToken(), !isTokenExpired(cachedToken) {
            print("cached: \(cachedToken)")
            print("TokenManager:: Using cached token")
            return cachedToken
        }

        // Attempt to fetch the token from storage
        if let token = try await loadTokenFromStorage() {
            // Check if the token has expired
            if isTokenExpired(token) {
                print("Token has expired, trigger a refresh")
                return try await handleTokenRefresh(token: token)
            }

            // Save the valid token to cache
            await tokenActor.saveToken(token)
            
            print("TokenManager:: Loaded token from storage: \(token)")
            return token
        }
        
        print("TokenManager: No token found")
        return nil  // No token found
    }


    @MainActor
    func saveToken(_ token: Token, username: String? = nil, password: String? = nil) async {
        state = .fetching
        do {
            
            await tokenActor.saveToken(token)
            // Cache the token in memory
            try await saveTokenToStorage(token: token, username: username, password: password)
            state = .fetched(token)
        } catch {
            state = .error(error)
        }
    }

    @MainActor
    func deleteToken() async {
        state = .fetching
        do {
            await tokenActor.deleteToken() // Clear in-memory cache
            try await deleteTokenFromStorage()
            state = .idle
        } catch {
            state = .error(error)
        }
    }

    // MARK: - Private Helper Methods

    private func loadTokenFromStorage() async throws -> Token? {
        guard let tokenData = try await storage.get(forKey: "authToken") else { return nil }
        return try JSONDecoder().decode(Token.self, from: tokenData)
    }

    private func isTokenExpired(_ token: Token) -> Bool {
        guard let expirationDate = token.expirationDate else { return false }
        print("TokenManager: Checking if token expired")
        return expirationDate.timeIntervalSinceNow < tokenExpirationThreshold
    }

    @MainActor
    private func handleTokenRefresh(token: Token?) async throws -> Token? {
        // If a refresh is already happening, wait for it to complete
        if isRefreshing {
            return try await withCheckedThrowingContinuation { continuation in
                refreshWaiters.append(continuation)
            }
        }

        // Begin refreshing the token
        isRefreshing = true
        state = .refreshing

        do {
            if let newToken = try await refreshToken(token: token) {
                isRefreshing = false

                // Save and cache the refreshed token
                await tokenActor.saveToken(newToken)
                state = .fetched(newToken)

                // Resume all waiting requests with the new token
                for waiter in refreshWaiters {
                    waiter.resume(returning: newToken)
                }
                refreshWaiters.removeAll()

                return newToken
            } // Call the refresh method
           
        } catch {
            // Handle the failure and notify waiters
            isRefreshing = false
            state = .error(error)

            for waiter in refreshWaiters {
                waiter.resume(throwing: error)
            }
            refreshWaiters.removeAll()

            throw error
        }
        return nil
    }


    private func refreshToken(token: Token?) async throws -> Token? {
        guard let credentialsData = try await storage.get(forKey: "userCredentials"),
              let credentialsDict = try JSONSerialization.jsonObject(with: credentialsData, options: []) as? [String: String],
              let username = credentialsDict["username"],
              let password = credentialsDict["password"] else {
            throw KeychainError.unableToRetrieveData
        }

        // Retrieve `AuthService` from the `ServiceLocator`
        let authService = serviceLocator.getAuthService()
        
        let retryCount = 3
        let delay: TimeInterval = 1.0 // 1 second delay for exponential backoff
        
        var attempt = 0
        var lastError: Error?

        while attempt < retryCount {
            do {
                
                let newToken = try await authService.logIn(username: username, password: password)
                await saveToken(newToken, username: username, password: password)
                print("Got new token after refresh and saved it")
                return newToken
            } catch {
                lastError = error
                attempt += 1
                await Task.sleep(UInt64(delay * pow(2.0, Double(attempt)) * 1_000_000_000)) // Exponential backoff
            }
        }

        throw lastError ?? NetworkError.unauthorized
    }

    private func saveTokenToStorage(token: Token, username: String?, password: String?) async throws {
        let tokenData = try JSONEncoder().encode(token)
        try await storage.save(data: tokenData, forKey: "authToken")
        
        if let username = username, let password = password {
            let credentialsData = try JSONSerialization.data(withJSONObject: ["username": username, "password": password])
            try await storage.save(data: credentialsData, forKey: "userCredentials")
        }
    }

    private func deleteTokenFromStorage() async throws {
        try await storage.delete(forKey: "authToken")
        try await storage.delete(forKey: "userCredentials")
    }
}






//class TokenManager: TokenProvider {
// 
//    // MARK: - Published State
//    private(set) var state: TokenState = .idle
//
//    // MARK: - Dependencies
//    private let storage: SecureStorage
//   private let tokenActor: TokenStorageActor
////    private let authService: AuthService
//    
//    // Token refresh handler closure
//       var refreshTokenHandler: TokenRefreshHandler?
//    
//    // Time interval in seconds to treat token as expired before its actual expiration
//    private let tokenExpirationThreshold: TimeInterval = 300 // 5 minutes
//
//    // MARK: - Internal Caching & State
//    private var isRefreshing = false
//    private var refreshWaiters: [CheckedContinuation<Token?, Error>] = []
//
//    // MARK: - Initialization
//    init(storage: SecureStorage, tokenStorage: TokenStorageActor) {
//        self.storage = storage
//        self.tokenActor = tokenStorage
//        print("Initialized TokenManager")
//    }
//
//   // MARK: - Public Methods
//    func getToken() async throws -> Token? {
//        // If a cached token exists and is still valid, return it
//        if let cachedToken = await tokenActor.getToken(), !isTokenExpired(cachedToken) {
//            print("TokenManager:: Using cached token")
//            return cachedToken
//        }
//
//        // Attempt to fetch the token from storage
//        if let token = try await loadTokenFromStorage() {
//            if isTokenExpired(token) {
//                // Token has expired, trigger a refresh
//                return try await handleTokenRefresh(token: token)
//            }
//            
//            await tokenActor.saveToken(token)
//            
//            print("TokenManager:: Loaded token from storage")
//            
//            return token
//        }
//        print("TokenManager: No token found")
//        return nil  // No token found
//    }
//
//    @MainActor
//    func saveToken(_ token: Token, username: String? = nil, password: String? = nil) async {
//        state = .fetching
//        do {
//            await tokenActor.saveToken(token)
//            // Cache the token in memory
//            try await saveTokenToStorage(token: token, username: username, password: password)
//            state = .fetched(token)
//        } catch {
//            state = .error(error)
//        }
//    }
//
//    @MainActor
//    func deleteToken() async {
//        state = .fetching
//        do {
//            await tokenActor.deleteToken() // Clear in-memory cache
//            try await deleteTokenFromStorage()
//            state = .idle
//        } catch {
//            state = .error(error)
//        }
//    }
//
//    // MARK: - Private Helper Methods
//
//    private func loadTokenFromStorage() async throws -> Token? {
//        guard let tokenData = try await storage.get(forKey: "authToken") else { return nil }
//        return try JSONDecoder().decode(Token.self, from: tokenData)
//    }
//
//    private func isTokenExpired(_ token: Token) -> Bool {
//        guard let expirationDate = token.expirationDate else { return false }
//        print("TokenManager: Checking if token expired")
//        return expirationDate.timeIntervalSinceNow < tokenExpirationThreshold
//    }
//
//    @MainActor
//    private func handleTokenRefresh(token: Token?) async throws -> Token? {
//        if isRefreshing {
//            return try await withCheckedThrowingContinuation { continuation in
//                refreshWaiters.append(continuation)
//            }
//        }
//
//        isRefreshing = true
//        state = .refreshing
//
//        do {
//            let newToken = try await refreshToken(token: token)
//            isRefreshing = false
//
//            await tokenActor.saveToken(newToken)
//            state = newToken != nil ? .fetched(newToken!) : .expired
//
//            for waiter in refreshWaiters {
//                waiter.resume(returning: newToken)
//            }
//            refreshWaiters.removeAll()
//
//            return newToken
//        } catch {
//            isRefreshing = false
//            state = .error(error)
//
//            for waiter in refreshWaiters {
//                waiter.resume(throwing: error)
//            }
//            refreshWaiters.removeAll()
//
//            throw error
//        }
//    }
//
//    private func refreshToken(token: Token?) async throws -> Token? {
//        guard let credentialsData = try await storage.get(forKey: "userCredentials"),
//              let credentialsDict = try JSONSerialization.jsonObject(with: credentialsData, options: []) as? [String: String],
//              let username = credentialsDict["username"],
//              let password = credentialsDict["password"] else {
//            throw KeychainError.unableToRetrieveData
//        }
//        
//        let retryCount = 3
//        let delay: TimeInterval = 1.0 // 1 second delay for exponential backoff
//        
//        var attempt = 0
//        var lastError: Error?
//
//        while attempt < retryCount {
//            do {
//                guard let refreshTokenHandler = refreshTokenHandler else {
//                    throw TokenError.noRefreshHandler
//                }
//                let newToken = try await refreshTokenHandler()
//                await saveToken(newToken)
//                return newToken
//            } catch {
//                lastError = error
//                attempt += 1
//                await Task.sleep(UInt64(delay * pow(2.0, Double(attempt)) * 1_000_000_000)) // Exponential backoff
//            }
//        }
//
//        throw lastError ?? NetworkError.unauthorized
//    }
//    
//
//
//
//    private func saveTokenToStorage(token: Token, username: String?, password: String?) async throws {
//        let tokenData = try JSONEncoder().encode(token)
//        try await storage.save(data: tokenData, forKey: "authToken")
//        
//        if let username = username, let password = password {
//            let credentialsData = try JSONSerialization.data(withJSONObject: ["username": username, "password": password])
//            try await storage.save(data: credentialsData, forKey: "userCredentials")
//        }
//    }
//
//    private func deleteTokenFromStorage() async throws {
//        try await storage.delete(forKey: "authToken")
//        try await storage.delete(forKey: "userCredentials")
//    }
//}

