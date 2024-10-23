//
//  MediaRepositoryImpl.swift
//  TripJournal
//
//  Created by Bohdan Tkachenko on 9/24/24.
//

import Foundation
import SwiftData

protocol MediaRepository {
    func AddMedia(with data: Data, caption: String, event: Event) async throws -> Media
    func getMedia(withId id: Media.ID) async throws -> Media?
    func deleteMedia(_ media: Media) async throws
}

class MediaRepositoryImpl: MediaRepository {
    
    //Dependencies
    private let remoteDataSource: MediaRemoteDataSource
    private let localDataSource: MediaLocalDataSource
    
    init(remoteDataSource: MediaRemoteDataSource,
         localDataSource: MediaLocalDataSource,
         networkMonitor: NetworkMonitor = NetworkMonitor.shared) {
        self.remoteDataSource = remoteDataSource
        self.localDataSource = localDataSource
    }
    
    func AddMedia(with data: Data, caption: String, event: Event) async throws -> Media {
        if NetworkMonitor.shared.isConnected {
            guard let id = event.eventId else {
                throw MediaRepositoryError.parentEventNotAvailable }
            let request = MediaCreate(caption: caption, base64Data: data.base64EncodedString(), eventId: id)
            let media = try await remoteDataSource.createMedia(request)
            media.event = event
            print("\n-----MediaRepositoryImpl-----MEDIA_DATA_URL: \(media.url), MEDIA_CAPTION: \(media.caption), EVENT: \(media.event?.name)")
            let _ = await localDataSource.save(data: data, for: media)
            return media
        } else {
            let media = Media(caption: caption, event: event)
           let _ = await localDataSource.save(data: data, for: media)
            return media
        }
        
    }
    
    func getMedia(withId id: Media.ID) async throws -> Media? {
        if NetworkMonitor.shared.isConnected {
            guard let media = await localDataSource.get(id) else {
                throw MediaRepositoryError.mediaNotFound
            }
            return media.1
        } else {
            return nil
        }
    }
    
    func deleteMedia(_ media: Media) async throws {
        if NetworkMonitor.shared.isConnected {
            guard media.mediaId != nil else {
                let _ = await localDataSource.delete(media)
                return
            }
            let _ = try await remoteDataSource.deleteMedia(withId: media.mediaId!)
            await localDataSource.delete(media)
        }
    }
}
