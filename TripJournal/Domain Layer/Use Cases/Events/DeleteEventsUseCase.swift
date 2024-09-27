//
//  DeleteEventsUseCase.swift
//  TripJournal
//
//  Created by Bohdan Tkachenko on 9/25/24.
//

import Foundation

protocol DeleteEventsUseCase {
    func execute(eventId: Event.ID, fromTrip trip: Trip) async throws
    
}

class DeleteEventsUseCaseImpl: DeleteEventsUseCase {
    private let tripRepository: TripRepository
    
    init(tripRepository: TripRepository) {
        self.tripRepository = tripRepository
    }
    
    func execute(eventId: Event.ID, fromTrip trip: Trip) async throws {
        var updatedTrip = trip
        updatedTrip.events.removeAll { $0.id == eventId }
        
        // Update the trip after removing the event
        try await tripRepository.updateTrip(updatedTrip, withId: updatedTrip.id)
    }
}
