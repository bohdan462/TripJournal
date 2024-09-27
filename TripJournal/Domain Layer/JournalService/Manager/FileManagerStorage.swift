//
//  FileManagerStorage.swift
//  TripJournal
//
//  Created by Bohdan Tkachenko on 9/17/24.
//

import Foundation

class FileManagerStorage: SecureStorage {
    
    private func getDocumentsDirectory() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private func getFileURL(forKey key: String) -> URL {
        return getDocumentsDirectory().appendingPathComponent("\(key).json")
    }
    
    func save(data: Data, forKey key: String) async throws {
        try await Task(priority: .utility) { [weak self] in
            guard let self = self else {
                print("self is nil, cannot save data")
                return
            }
            let fileURL = self.getFileURL(forKey: key)
            do {
                try data.write(to: fileURL)
                print("Saved data for key \(key) at path: \(fileURL)")
            } catch {
                print("Failed to save data for key \(key): \(error)")
                throw error
            }
        }.value
    }

    func get(forKey key: String) async throws -> Data? {
        return try await Task(priority: .utility){ [weak self] in
            guard let self = self else {
                print("self is nil, cannot retrieve data")
                return nil
            }
            let fileURL = self.getFileURL(forKey: key)
            guard FileManager.default.fileExists(atPath: fileURL.path) else {
                print("No file found for key \(key) at path: \(fileURL)")
                return nil
            }
            do {
                let data = try Data(contentsOf: fileURL)
                return data
            } catch {
                print("Failed to retrieve data for key \(key): \(error)")
                throw error
            }
        }.value
    }

    // Delete data from the file system
    func delete(forKey key: String) async throws {
        let fileURL = getFileURL(forKey: key)
        if FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                try FileManager.default.removeItem(at: fileURL)
                print("Deleted file for key \(key) at path: \(fileURL)")
            } catch {
                print("Failed to delete file for key \(key): \(error)")
                throw error
            }
        } else {
            print("File not found for key \(key)")
        }
    }
}

//class JournalUserDefaultManager {
//    private let userDefaults = UserDefaults.standard
//    private let tripsKey = "trips"
//
//    func saveTrips(_ trips: [Trip]) {
//        do {
//            let data = try JSONEncoder().encode(trips)
//            userDefaults.set(data, forKey: tripsKey)
//        } catch {
//            print("Failed to save trips to UserDefaults: \(error)")
//        }
//    }
//
//    func loadTrips() -> [Trip] {
//        guard let data = userDefaults.data(forKey: tripsKey) else {
//            return []
//        }
//        do {
//            return try JSONDecoder().decode([Trip].self, from: data)
//        } catch {
//            return []
//        }
//    }
//}

/**
 UserDefaultsStorage provides an alternative implementation of the SecureStorage protocol, using UserDefaults to store data. It offers the same interface for saving, retrieving, and deleting data asynchronously, but operates in the less secure UserDefaults storage instead of the Keychain.
 
 Methods:
 - `save(data:forKey:)`: Saves the provided data to UserDefaults.
 - `get(forKey:)`: Retrieves data from UserDefaults.
 - `delete(forKey:)`: Deletes data from UserDefaults.
 */
class UserDefaultsStorage: SecureStorage {
    private let defaults = UserDefaults.standard
    
    func save(data: Data, forKey key: String) async throws {
        defaults.set(data, forKey: key)
    }
    
    func get(forKey key: String) async throws -> Data? {
        return defaults.data(forKey: key)
    }
    
    func delete(forKey key: String) async throws {
        defaults.removeObject(forKey: key)
    }
}

