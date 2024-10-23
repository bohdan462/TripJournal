//
//  CreateMeadiaUseCase.swift
//  TripJournal
//
//  Created by Bohdan Tkachenko on 10/20/24.
//
import Foundation

protocol CreateMediaRepository {
    func execute(with data: Data, caption: String, event: Event) async throws
}

class CreateMediaUseCase: CreateMediaRepository {
   
    private var mediaRepository: MediaRepository
    private var eventRepository: EventRepository
    
    init(mediaRepository: MediaRepository, eventRepository: EventRepository) {
        self.mediaRepository = mediaRepository
        self.eventRepository = eventRepository
    }
    
    @MainActor
    func execute(with data: Data, caption: String, event: Event) async throws {
        let event = event
        do {
            
            print("\n-----CREATE MEDIA USE CASE-----MEDIA_EVENT_DATA: \(data.description), MEDIA_EVENT_CAPTION: \(caption), EVENT: \(event.name)")
           let media = try await mediaRepository.AddMedia(with: data, caption: caption, event: event)
            print("\n-----CREATE MEDIA USE CASE-----MEDIA_DATA_URL: \(media.url), MEDIA_CAPTION: \(media.caption), EVENT: \(media.event?.name)")
            event.medias.append(media)
            try await eventRepository.updateEvent(event)
        } catch {
            fatalError("Could not add media: \(error)")
        }
    }
    
    
}
