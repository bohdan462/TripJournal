//
//  KeychainHelper.swift
//  TripJournal
//
//  Created by Bohdan Tkachenko on 9/13/24.
//

import Foundation
import Security

// MARK: - TokenProvider
///handles token management
protocol TokenProvider {
    func saveToken(_ token: Token) async throws
    func getToken() async throws -> Token?
    func deleteToken() async throws
}

//protocol SecureStorage {
//    func save(data: Data, forKey key: String) async throws
//    func get(forKey key: String) async throws -> Data?
//    func delete(forKey key: String) async throws
//}

actor KeychainHelper: TokenProvider {
    
    static let shared = KeychainHelper()
    private let serviceName = "com.TripJournal.service"
    private let accountName = "authToken"
    
    private init() {}
    
    // MARK: - Save Token Asynchronously
    func saveToken(_ token: Token) async throws {
        let tokenData = try JSONEncoder().encode(token)
        let query: [String: Any] = keychainQuery()
        
        let attributes: [String: Any] = [
            kSecValueData as String: tokenData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]
        
        return try await withCheckedThrowingContinuation { continuation in
            // Try updating the existing token if it exists
            let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
            
            if status == errSecItemNotFound {
                // If the token doesn't exist, add it
                let status = SecItemAdd(query.merging(attributes) { (_, new) in new } as CFDictionary, nil)
                if status == errSecSuccess {
                    continuation.resume(returning: ())
                } else {
                    continuation.resume(throwing: KeychainError.unableToSaveToken)
                }
            } else if status == errSecSuccess {
                continuation.resume(returning: ())
            } else {
                continuation.resume(throwing: KeychainError.unableToSaveToken)
            }
        }
    }
    
    
    //TODO: - Get Token asynchronously
    func getToken() async throws -> Token? {
        let query: [String: Any] = keychainQuery(additionalAttributes: [kSecReturnData as String: kCFBooleanTrue!,
                                                                        kSecMatchLimit as String: kSecMatchLimitOne])
        
        let token: Token? = try await withCheckedThrowingContinuation { continuation in
            var dataTypeRef: AnyObject? = nil
            let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
            
            switch status {
            case errSecSuccess:
                guard let data = dataTypeRef as? Data else {
                    continuation.resume(throwing: KeychainError.unableToRetrieveToken)
                    return
                }
                do {
                    let token = try JSONDecoder().decode(Token.self, from: data)
                    continuation.resume(returning: token)
                } catch {
                    continuation.resume(throwing: error)
                }
            case errSecItemNotFound:
                continuation.resume(returning: nil)  // Token not found, return nil
            case errSecAuthFailed:
                continuation.resume(throwing: KeychainError.authenticationFailed)
            case errSecInteractionNotAllowed:
                continuation.resume(throwing: KeychainError.interactionNotAllowed)
            default:
                continuation.resume(throwing: KeychainError.unableToRetrieveToken)
            }
        }
        
        // Check for token expiration if expirationDate is available
        if let token = token, let expirationDate = token.expirationDate, expirationDate < Date() {
            try await deleteToken()  // Delete expired token
            return nil  // Return nil since the token is expired
        }
        
        return token  // Return the valid token
    }
    
    func deleteToken() async throws {
        let query: [String: Any] = keychainQuery()
        
        // Perform keychain operations asynchronously
        return try await withCheckedThrowingContinuation { continuation in
            let status = SecItemDelete(query as CFDictionary)
            
            if status == errSecSuccess {
                continuation.resume(returning: ())
            } else {
                continuation.resume(throwing: KeychainError.unableToDeleteToken)
            }
        }
    }
    
    private func keychainQuery(additionalAttributes: [String: Any] = [:]) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: accountName
        ]
        
        // Merge any additional attributes for specific operations
        query.merge(additionalAttributes) { (_, new) in new }
        
        return query
    }
    
    
    enum KeychainError: LocalizedError {
        case unableToSaveToken
        case unableToDeleteToken
        case unableToRetrieveToken
        case authenticationFailed
        case interactionNotAllowed
        
        var errorDescription: String? {
            switch self {
            case .unableToSaveToken:
                return "Failed to save the token to Keychain."
            case .unableToDeleteToken:
                return "Failed to delete the token from Keychain."
            case .unableToRetrieveToken:
                return "Failed to retrieve the token from Keychain."
            case .authenticationFailed:
                return "Authentication failed. Could not access the Keychain."
            case .interactionNotAllowed:
                return "Interaction with the Keychain is not allowed at this time."
            }
        }
    }
}
