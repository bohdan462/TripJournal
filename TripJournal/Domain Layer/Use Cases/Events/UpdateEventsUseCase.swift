//
//  UpdateEventsUseCase.swift
//  TripJournal
//
//  Created by Bohdan Tkachenko on 9/25/24.
//

import Foundation

protocol UpdateEventsUseCase {
    func execute(event: Event) async throws
}

class UpdateEventsUseCaseImpl: UpdateEventsUseCase {
    
    private let eventRepository: EventRepository

        init( eventRepository: EventRepository) {
            self.eventRepository = eventRepository
        }
    
    func execute(event: Event) async throws {
        try await eventRepository.updateEvent(event)
    }
}
