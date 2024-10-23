//
//  DeleteMediaUseCase.swift
//  TripJournal
//
//  Created by Bohdan Tkachenko on 10/21/24.
//

import Foundation
import SwiftData

protocol DeleteMediaUseCase {
    func execute(media: Media) async throws
}

class DeleteMediaUseCaseImpl: DeleteMediaUseCase {
    
    private var mediaRepository: MediaRepository
    private var eventRepository: EventRepository
    
    init(mediaRepository: MediaRepository, eventRepository: EventRepository) {
        self.mediaRepository = mediaRepository
        self.eventRepository = eventRepository
    }
    
    func execute(media: Media) async throws {
        guard let event = media.event else {
            throw DeleteMediaError.eventNotFound
        }
        try await mediaRepository.deleteMedia(media)
        try await eventRepository.updateEvent(event)
    }
}
