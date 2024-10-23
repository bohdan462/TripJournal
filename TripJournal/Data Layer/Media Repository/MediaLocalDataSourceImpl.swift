//
//  MediaLocalDataSourceImpl.swift
//  TripJournal
//
//  Created by Bohdan Tkachenko on 10/20/24.
//
import Foundation
import SwiftData

protocol MediaLocalDataSource {
    func save(data: Data, for media: Media) async -> URL?
    func get(_ id: Media.ID) async -> (Data, Media)?
    func delete(_ media: Media) async
}

class MediaLocalDataSourceImpl: MediaLocalDataSource {
    
    
    private let context: ModelContext
    private let storage: SecureStorage
    
    init(context: ModelContext, storage: SecureStorage) {
        self.context = context
        self.storage = storage
    }
    
    func save(data: Data, for media: Media) async -> URL? {
        var media = media
        
        do {
            try await storage.save(data: data, forKey: media.id.uuidString)
            media.url = URL(string: media.id.uuidString)!
            context.insert(media)
          
            return media.url
        } catch {
            print("Failed to save media locally: \(error.localizedDescription)")
        }
        return nil
    }
    
    func get(_ id: Media.ID) async -> (Data, Media)? {
        let descriptor = FetchDescriptor<Media>(predicate: #Predicate<Media> { $0.id == id})

        do {
           let data = try await storage.get(forKey: id.uuidString)
            let media = try context.fetch(descriptor).first!
            return (data, media) as? (Data, Media)
        } catch {
            print("Failed to save media locally: \(error.localizedDescription)")
        }
        return nil
    }
    
    func delete(_ media: Media) async {
        guard let (_, media) = await self.get(media.id) else {
            return
        }
        do {
                context.delete(media)
                try await storage.delete(forKey: media.id.uuidString)
            
        } catch {
            print("Error fetching local media with error: \(error.localizedDescription)")
        }
    }
    
}

