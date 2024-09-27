//
//  CreateEventsUseCase.swift
//  TripJournal
//
//  Created by Bohdan Tkachenko on 9/25/24.
//

import Foundation

protocol CreateEventsUseCase {
    func execute(event: Event, trip: Trip) async throws
}

class CreateEventsUseCaseImpl: CreateEventsUseCase {
    private let tripRepository: TripRepository
    private var eventRepository: EventRepository
    
    init(tripRepository: TripRepository, eventRepository: EventRepository) {
        self.tripRepository = tripRepository
        self.eventRepository = eventRepository
    }
    
 @MainActor
    func execute(event: Event, trip: Trip) async throws {
        let updatedTrip = trip
        
        try await eventRepository.createEvent(event, fromTrip: trip)
        
        if let updatedEvent = try await eventRepository.getEvent(withId: event.id) {
            await MainActor.run {
                updatedTrip.events.append(updatedEvent)
                // Notify the tripRepository to save the updated trip
            }
            
            try await tripRepository.updateTrip(updatedTrip, withId: updatedTrip.id)
            
        } else {
            print("Cannot create event")
        }
    }

}
