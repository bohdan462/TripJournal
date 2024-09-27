//
//  GetEventsUseCase.swift
//  TripJournal
//
//  Created by Bohdan Tkachenko on 9/25/24.
//

import Foundation

protocol GetEventsUseCase {
    func execute(eventId: Event.ID) async throws -> Event?
}

class GetEventsUseCaseImpl: GetEventsUseCase {
    private let eventRepository: EventRepository
    
    init(eventRepository: EventRepository) {
        self.eventRepository = eventRepository
    }
    
    func execute(eventId: Event.ID) async throws -> Event? {
        return try await eventRepository.getEvent(withId: eventId)
    }
}
