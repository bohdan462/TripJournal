//
//  KeychainHelper.swift
//  TripJournal
//
//  Created by Bohdan Tkachenko on 9/13/24.
//

import Foundation
import Security
import Combine

@objc
protocol SecureStorage {
    func save(data: Data, forKey key: String) async throws
    func get(forKey key: String) async throws -> Data?
    @objc optional func getURLPath(forKey key: String) -> URL
    func delete(forKey key: String) async throws
}

actor KeychainHelper: SecureStorage {
    
    static let shared = KeychainHelper() // Singleton instance
    
    private let serviceName = "com.TripJournal.service" // Keychain service identifier
    
    private init() {}

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
