//
//  EventRemoteDataSourceImpl.swift
//  TripJournal
//
//  Created by Bohdan Tkachenko on 9/24/24.
//

import Foundation
import SwiftData

protocol EventLocalDataSource {
    func getEvents() async throws-> [Event]
    func getEvent(withId id: Event.ID) async throws -> Event?
//    func saveEvents(_ events: [Event]) async throws
//    func saveEvent(_ event: Event) async throws
//    func updateEvent(_ event: Event) async throws -> Event
//    func deleteEvent(withId id: Event.ID) async throws -> Event?
}

class EventLocalDataSourceImpl: EventLocalDataSource {
    
    private let context: ModelContext
    
    init(context: ModelContext) {
        self.context = context
    }
    @MainActor
    func getEvents() async throws -> [Event] {
        let descriptor = FetchDescriptor<Event>(sortBy: [SortDescriptor(\Event.id, order: .forward)])
        do {
            let events = try context.fetch(descriptor)
            return events
        } catch {
            throw LocalDataSourceError.fetchFailed(error)
        }
    }
    
    @MainActor
    func getEvent(withId id: Event.ID) async throws -> Event? {
        let descriptor = FetchDescriptor<Event>(predicate: #Predicate<Event> {$0.id == id })
        do {
            if let fetchedEvent = try context.fetch(descriptor).first {
                return fetchedEvent
            }
        } catch {
            throw LocalDataSourceError.fetchFailed(error)
        }
        return nil
    }
    
//    @MainActor
//    func saveEvents(_ events: [Event]) async throws {
//        events.forEach {
//            context.insert($0)
//        }
//        let incomingIDs = events.map { $0.id }
//        let descriptor = FetchDescriptor<Event>(predicate: #Predicate<Event> { incomingIDs.contains($0.id) })
//        
//        do {
//            let fetchedEvents = try context.fetch(descriptor)
//            let existingIDs = Set(fetchedEvents.map { $0.id })
//            
//            events.forEach { event in
//                if !existingIDs.contains(event.id) {
//                    context.insert(event)
//                }
//            }
//            try context.save()
//        } catch {
//            throw LocalDataSourceError.saveFailed(error)
//        }
//    }
    
//    @MainActor
//    func saveEvent(_ event: Event) async throws {
//        let passedEventId = event.id
//        let descriptor = FetchDescriptor<Event>(predicate: #Predicate<Event> { $0.id == passedEventId })
//        guard let tripID = event.tripID else { throw DataSourceError.appLogicError }
//        do {
//            try context.save()
//        } catch {
//            print("Failed to save event locally: \(error.localizedDescription)")
//        }
//    }
    
//    @MainActor
//    func updateEvent(_ event: Event) async throws {
//        // Fetch the existing event
//        let eventId = event.id
//        let descriptor = FetchDescriptor<Event>(predicate: #Predicate<Event> { eventInContext in
//              eventInContext.id == eventId 
//          })
//        do {
//            if let fetchedEvent = try context.fetch(descriptor).first {
//                // Update properties
//                fetchedEvent.name = event.name
//                fetchedEvent.note = event.note
//                fetchedEvent.date = event.date
//                fetchedEvent.location = event.location
//                fetchedEvent.transitionFromPrevious = event.transitionFromPrevious
//                fetchedEvent.isSynced = event.isSynced
//                fetchedEvent.isDeleted = event.isDeleted
//                try context.save()
//            } else {
//                // Event not found, insert as new
//                context.insert(event)
//                try context.save()
//            }
//        } catch {
//            print("Error updating local Event with error: \(error.localizedDescription)")
//        }
 //   }
//
//    @MainActor
//    func deleteEvent(withId id: Event.ID) async throws -> Event? {
//        let descriptor = FetchDescriptor<Event>(predicate: #Predicate<Event> {$0.id == id })
//        
//        do {
//            if let fetchedEvent = try context.fetch(descriptor).first {
//                context.delete(fetchedEvent)
//                return fetchedEvent
//            }
//            try context.save()
//            
//        } catch {
//            print("Error fetching local Event with error: \(error.localizedDescription)")
//        }
//        return nil
//    }
    
    
}
