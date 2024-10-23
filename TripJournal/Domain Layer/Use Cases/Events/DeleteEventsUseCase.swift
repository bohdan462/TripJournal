//
//  DeleteEventsUseCase.swift
//  TripJournal
//
//  Created by Bohdan Tkachenko on 9/25/24.
//

import Foundation

protocol DeleteEventsUseCase {
    func execute(_ event: Event) async throws
    
}

class DeleteEventsUseCaseImpl: DeleteEventsUseCase {
    private let eventRepository: EventRepository
    
    init( eventRepository: EventRepository) {
        self.eventRepository = eventRepository
    }
    
    func execute(_ event: Event) async throws {
        try await eventRepository.deleteEvent(event)
        
    }
}
