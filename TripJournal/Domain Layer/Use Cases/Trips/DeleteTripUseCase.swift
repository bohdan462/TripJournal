//
//  DeleteTripUseCase.swift
//  TripJournal
//
//  Created by Bohdan Tkachenko on 9/25/24.
//

import Foundation

protocol DeleteTripUseCase {
    func execute(_ tripId: Trip.ID) async throws
    func deleteAll() async throws
}

class DeleteTripUseCaseImpl: DeleteTripUseCase {
    private let tripRepository: TripRepository
    private let eventRepository: EventRepository
    private let mediaRepository: MediaRepository
    
    init(tripRepository: TripRepository, eventRepository: EventRepository, mediaRepository: MediaRepository) {
        self.tripRepository = tripRepository
        self.eventRepository = eventRepository
        self.mediaRepository = mediaRepository
    }
    
    func execute(_ tripId: Trip.ID) async throws {
        let tripToDelete = try await tripRepository.deleteTrip(withId: tripId)
        if !tripToDelete.events.isEmpty {
            tripToDelete.events.forEach { event in
                if !event.medias.isEmpty {
                    event.medias.forEach { media in
                       Task {
                           try await mediaRepository.deleteMedia(media)
                       }
                    }
                    Task {
                       try await eventRepository.deleteEvent(event)
                    }
                }
            }
        }
    }
    
    func deleteAll() async throws {
        try await tripRepository.deleteAll()
    }
}
