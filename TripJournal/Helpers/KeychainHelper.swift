//
//  KeychainHelper.swift
//  TripJournal
//
//  Created by Bohdan Tkachenko on 9/13/24.
//

import Foundation
import Security
import Combine

/**
 KeychainError defines possible errors that can occur when interacting with the Keychain, such as failures in saving, deleting, retrieving, or updating data.
 
 - unableToSaveData: Indicates failure to save data to the Keychain.
 - unableToDeleteData: Indicates failure to delete data from the Keychain.
 - unableToRetrieveData: Indicates failure to retrieve data from the Keychain.
 - unableToDecodeData: Indicates failure to decode data retrieved from the Keychain.
 - unableToUpdateData: Indicates failure to update existing data in the Keychain.
 - authenticationFailed: Indicates failure in accessing the Keychain due to authentication issues.
 - interactionNotAllowed: Indicates failure to access the Keychain due to current system restrictions or user policies.
 */
enum KeychainError: LocalizedError {
    case unableToSaveData
    case unableToDeleteData
    case unableToRetrieveData
    case unableToDecodeData
    case unableToUpdateData
    case authenticationFailed
    case interactionNotAllowed
    
    var errorDescription: String? {
        switch self {
        case .unableToSaveData:
            return "Failed to save data to Keychain."
        case .unableToDeleteData:
            return "Failed to delete data from Keychain."
        case .unableToRetrieveData:
            return "Failed to retrieve data from Keychain."
        case .authenticationFailed:
            return "Authentication failed. Could not access the Keychain."
        case .interactionNotAllowed:
            return "Interaction with the Keychain is not allowed at this time."
        case .unableToDecodeData:
            return "Failed to decode data to Keychain."
        case .unableToUpdateData:
            return "Failed to update data to Keychain."
        }
    }
}

/**
 SecureStorage is a protocol that defines methods for saving, retrieving, and deleting data securely. It allows for the abstraction of the actual storage mechanism (e.g., Keychain, UserDefaults).
 
 Methods:
 - `save(data:forKey:)`: Saves the provided data securely.
 - `get(forKey:)`: Retrieves data securely using the provided key.
 - `delete(forKey:)`: Deletes data securely for the provided key.
 */
protocol SecureStorage {
    func save(data: Data, forKey key: String) async throws
    func get(forKey key: String) async throws -> Data?
    func delete(forKey key: String) async throws
}

/**
 KeychainHelper is an actor that implements the SecureStorage protocol for securely saving, retrieving, and deleting data in the iOS/macOS Keychain. It uses the Keychain Services API to perform operations asynchronously.
 
 - Singleton Instance: `KeychainHelper.shared` is the shared instance of this class.
 
 Methods:
 - `save(data:forKey:)`: Saves the provided data to the Keychain with a specified key.
 - `get(forKey:)`: Retrieves data from the Keychain using the provided key.
 - `delete(forKey:)`: Deletes data from the Keychain for the provided key.
 */
actor KeychainHelper: SecureStorage {
    
    static let shared = KeychainHelper() // Singleton instance
    
    private let serviceName = "com.TripJournal.service" // Keychain service identifier
    
    private init() {}
    
    /**
     Saves data to the Keychain for the given key.
     
     - Parameters:
        - data: The data to be saved.
        - key: The key under which the data will be stored.
     
     - Throws: KeychainError if unable to save data.
     */
    func save(data: Data, forKey key: String) async throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]
        
        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]
        
        return try await withCheckedThrowingContinuation { continuation in
            let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
            
            if status == errSecItemNotFound {
                let addStatus = SecItemAdd(query.merging(attributes) { (_, new) in new } as CFDictionary, nil)
                if addStatus == errSecSuccess {
                    continuation.resume(returning: ())
                } else {
                    continuation.resume(throwing: KeychainError.unableToSaveData)
                }
            } else if status == errSecSuccess {
                continuation.resume(returning: ())
            } else {
                continuation.resume(throwing: KeychainError.unableToUpdateData)
            }
        }
    }
    
    /**
     Retrieves data from the Keychain for the given key.
     
     - Parameter key: The key associated with the data to be retrieved.
     - Returns: The data retrieved from the Keychain or nil if no data is found.
     - Throws: KeychainError if unable to retrieve data.
     */
    func get(forKey key: String) async throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        return try await withCheckedThrowingContinuation { continuation in
            var dataTypeRef: AnyObject? = nil
            let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
            if status == errSecSuccess, let data = dataTypeRef as? Data {
                continuation.resume(returning: data)
            } else if status == errSecItemNotFound {
                continuation.resume(returning: nil)
            } else {
                continuation.resume(throwing: KeychainError.unableToRetrieveData)
            }
        }
    }
    
    /**
     Deletes data from the Keychain for the given key.
     
     - Parameter key: The key associated with the data to be deleted.
     - Throws: KeychainError if unable to delete data.
     */
    func delete(forKey key: String) async throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]
        
        return try await withCheckedThrowingContinuation { continuation in
            let status = SecItemDelete(query as CFDictionary)
            if status == errSecSuccess {
                continuation.resume(returning: ())
            } else {
                continuation.resume(throwing: KeychainError.unableToDeleteData)
            }
        }
    }
}
