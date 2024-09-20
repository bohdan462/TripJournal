import Foundation

import Foundation

class JournalLocalService<T: Identifiable & Codable> {
    
    private let securedLocalStorage: SecureStorage
    private var storage: [T] = []
    
    init(securedLocalStorage: SecureStorage = FileManagerStorage()) {
        self.securedLocalStorage = securedLocalStorage
        Task { await loadFromFileManagerIfNeeded() } // Load on initialization
    }
    
    // MARK: - Create an entity
    func create(entity: T) async throws {
        // Ensure data is loaded before appending
        await loadFromFileManagerIfNeeded()
        storage.append(entity)
        try await saveToFileManager()
    }
    
    // MARK: - Read All Entities
    func readAll() async -> [T] {
        await loadFromFileManagerIfNeeded()
        return storage
    }

    // MARK: - Read by ID
    func read(byId id: T.ID) async -> T? {
        await loadFromFileManagerIfNeeded()
        return storage.first { $0.id == id }
    }
    
    // MARK: - Update an entity
    func update(entity: T) async throws {
        await loadFromFileManagerIfNeeded()
        if let index = storage.firstIndex(where: { $0.id == entity.id }) {
            storage[index] = entity
            try await saveToFileManager()
        }
    }
    
    // MARK: - Delete by ID
    func delete(byId id: T.ID) async throws {
        await loadFromFileManagerIfNeeded()
        storage.removeAll { $0.id == id }
        try await saveToFileManager()
    }
    
    // MARK: - Delete All
    func deleteAll() async throws {
        storage.removeAll()
        try await securedLocalStorage.delete(forKey: "\(T.self)")
    }
    
    // MARK: - Save to FileManager
    private func saveToFileManager() async throws {
        let data = try JSONEncoder().encode(storage)
        try await securedLocalStorage.save(data: data, forKey: "\(T.self)")
    }

    // MARK: - Load from FileManager, only when necessary
    private func loadFromFileManagerIfNeeded() async {
        if storage.isEmpty {
            if let data = try? await securedLocalStorage.get(forKey: "\(T.self)"),
               let decodedData = try? JSONDecoder().decode([T].self, from: data) {
                storage = decodedData
            }
        }
    }
}
