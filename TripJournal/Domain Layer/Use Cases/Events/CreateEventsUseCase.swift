//
//  CreateEventsUseCase.swift
//  TripJournal
//
//  Created by Bohdan Tkachenko on 9/25/24.
//

import Foundation

protocol CreateEventsUseCase {
    func execute(event: Event) async throws
}

class CreateEventsUseCaseImpl: CreateEventsUseCase {
    private let tripRepository: TripRepository
    private var eventRepository: EventRepository
    
    init(tripRepository: TripRepository, eventRepository: EventRepository) {
        self.tripRepository = tripRepository
        self.eventRepository = eventRepository
    }
    
    @MainActor
    func execute(event: Event) async throws {
        
        print("\nCreateEventsUseCase--------------------------\n")
        print("Event: \(event.name), date: \(event.date), note: \(event.note), lat: \(event.location?.latitude), long: \(event.location?.longitude), address: \(event.location?.address), tripID: \(event.tripID), tripName: \(event.trip?.name), eventIDremote:\(event.eventId), localID:\(event.id), synced: \(event.isSynced)")
        
        let newEvent = try await eventRepository.createEvent(event)
        guard let updatedTrip = newEvent.trip else {
            fatalError("New event must have a trip")
        }
        

        print("\nCreateEventsUseCase--------------NEW EVENT FROM SERVER-------\n")
        print("Event: \(newEvent.name), date: \(newEvent.date), note: \(newEvent.note), lat: \(newEvent.location?.latitude), long: \(newEvent.location?.longitude), address: \(newEvent.location?.address), tripID: \(newEvent.tripID), tripName: \(newEvent.trip?.name), eventIDremote:\(newEvent.eventId), localID:\(newEvent.id), synced: \(newEvent.isSynced)")

        updatedTrip.events.append(newEvent)
        try await tripRepository.updateTrip(updatedTrip)
    }

}
