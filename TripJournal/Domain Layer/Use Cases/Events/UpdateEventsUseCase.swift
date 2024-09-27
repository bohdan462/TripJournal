//
//  UpdateEventsUseCase.swift
//  TripJournal
//
//  Created by Bohdan Tkachenko on 9/25/24.
//

import Foundation

protocol UpdateEventsUseCase {
    func execute(event: Event, inTrip: Trip) async throws
}

class UpdateEventsUseCaseImpl: UpdateEventsUseCase {
    
    private let tripRepository: TripRepository
    private let eventRepository: EventRepository

        init(tripRepository: TripRepository, eventRepository: EventRepository) {
            self.tripRepository = tripRepository
            self.eventRepository = eventRepository
        }
    
    func execute(event: Event, inTrip: Trip) async throws {
//        var updatedTrip = trip
        
//        if let index = updatedTrip.events.firstIndex(where: { $0.id == event.id }) {
//            updatedTrip.events[index] = event
//        }
        try await eventRepository.updateEvent(event, inTrip: inTrip)
        
//        try await tripRepository.updateTrip(trip, withId: trip.id)
       
    }
}
