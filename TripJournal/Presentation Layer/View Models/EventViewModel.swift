//
//  EventViewModel.swift
//  TripJournal
//
//  Created by Bohdan Tkachenko on 9/25/24.
//

import Foundation
import Combine

class EventViewModel: ObservableObject {
    // Published properties to update the UI
    @Published var event: Event?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // Dependencies
    private let createEventUseCase: CreateEventsUseCase
    private let getEventUseCase: GetEventsUseCase
    private let updateEventUseCase: UpdateEventsUseCase
    private let deleteEventUseCase: DeleteEventsUseCase
    
    // Initializer
    init(event: Event? = nil,
        createEventUseCase: CreateEventsUseCase,
        getEventUseCase: GetEventsUseCase,
        updateEventUseCase: UpdateEventsUseCase,
        deleteEventUseCase: DeleteEventsUseCase
    ) {
        self.createEventUseCase = createEventUseCase
        self.getEventUseCase = getEventUseCase
        self.updateEventUseCase = updateEventUseCase
        self.deleteEventUseCase = deleteEventUseCase
    }
    
//    @MainActor
//    func addEvent(_ event: Event, toTrip trip: Trip) async {
//        isLoading = true
//        do {
//            try await createEventUseCase.execute(event: event, trip: trip)
//            if let index = trips.firstIndex(where: { $0.id == trip.id }) {
//                trips[index].events.append(event)
//            }
//            isLoading = false
//        } catch {
//            errorMessage = error.localizedDescription
//            isLoading = false
//        }
//    }
//
//    @MainActor
//    func updateEvent(_ event: Event, inTrip trip: Trip) async {
//        isLoading = true
//        do {
//            try await updateEventUseCase.execute(event: event, inTrip: trip)
//            if let tripIndex = trips.firstIndex(where: { $0.id == trip.id }) {
//                if let eventIndex = trips[tripIndex].events.firstIndex(where: { $0.id == event.id }) {
//                    trips[tripIndex].events[eventIndex] = event
//                }
//            }
//            isLoading = false
//        } catch {
//            errorMessage = error.localizedDescription
//            isLoading = false
//        }
//    }
//
//    @MainActor
//    func deleteEvent(withId eventId: Event.ID, fromTrip trip: Trip) async {
//        isLoading = true
//        do {
//            try await deleteEventUseCase.execute(eventId: eventId, fromTrip: trip)
//            if let tripIndex = trips.firstIndex(where: { $0.id == trip.id }) {
//                trips[tripIndex].events.removeAll { $0.id == eventId }
//            }
//            isLoading = false
//        } catch {
//            errorMessage = error.localizedDescription
//            isLoading = false
//        }
//    }

    
    // Methods
    func createEvent(name: String, note: String?, date: Date, location: Location?, trip: Trip, transitionFromPrevious: String?) async {
        isLoading = true
        errorMessage = nil
        let newEvent = Event(
            name: name,
            note: note,
            date: date,
            location: location,
            trip: trip,
            tripID: (trip.tripId != nil) ? trip.tripId : nil,
            transitionFromPrevious: transitionFromPrevious,
            isSynced: false,
            isDeleted: false
        )
        
        do {
            try await createEventUseCase.execute(event: newEvent, trip: trip)
            self.event = newEvent
        } catch {
            errorMessage = "Failed to create event: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    func fetchEvent(eventId: Event.ID) async {
        isLoading = true
        errorMessage = nil
        do {
            if let fetchedEvent = try await getEventUseCase.execute(eventId: eventId) {
                self.event = fetchedEvent
            } else {
                errorMessage = "Event not found."
            }
        } catch {
            errorMessage = "Failed to fetch event: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    func updateEvent(trip: Trip) async {
        guard let event = self.event else {
            errorMessage = "No event to update."
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            try await updateEventUseCase.execute(event: event, inTrip: trip)
        } catch {
            errorMessage = "Failed to update event: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    func deleteEvent(trip: Trip) async {
        guard let event = self.event else {
            errorMessage = "No event to delete."
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            try await deleteEventUseCase.execute(eventId: event.id, fromTrip: trip)
            self.event = nil // Clear the event after deletion
        } catch {
            errorMessage = "Failed to delete event: \(error.localizedDescription)"
        }
        isLoading = false
    }
}
