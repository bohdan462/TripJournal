//
//  EventRemoteDataSourceImpl.swift
//  TripJournal
//
//  Created by Bohdan Tkachenko on 9/24/24.
//

import Foundation
import SwiftData

protocol EventLocalDataSource {
    func getEvents() async -> [Event]
    func getEvent(withId id: Event.ID) async -> Event?
    func saveEvents(_ events: [Event]) async
    func saveEvent(_ event: Event) async
    func updateEvent(_ event: Event) async
    func deleteEvent(withId id: Event.ID) async -> Event?
}

class EventLocalDataSourceImpl: EventLocalDataSource {
    
    private let context: ModelContext
    
    init(context: ModelContext) {
        self.context = context
    }
    
    func getEvents() async -> [Event] {
        let descriptor = FetchDescriptor<Event>(sortBy: [SortDescriptor(\Event.id, order: .forward)])
        do {
            let events = try context.fetch(descriptor)
            return events
            
        } catch {
            
            print("Error fetching local Events: \(error.localizedDescription)")
        }
        return []
    }
    
    func getEvent(withId id: Event.ID) async -> Event? {
        let descriptor = FetchDescriptor<Event>(predicate: #Predicate<Event> {$0.id == id },
                                                sortBy: [SortDescriptor(\Event.name, order: .forward)])
        do {
            if let fetchedEvent = try context.fetch(descriptor).first {
                return fetchedEvent
            }
        } catch {
            print("Error fetching local Event with error: \(error.localizedDescription)")
        }
        return nil
    }
    
    func saveEvents(_ events: [Event]) async {
        events.forEach {
            context.insert($0)
        }
        
        do {
            try context.save()
        } catch {
            print("Failed to save events locally: \(error.localizedDescription)")
        }
    }
    
    func saveEvent(_ event: Event) async {
        context.insert(event)
        
        do {
            try context.save()
        } catch {
            print("Failed to save event locally: \(error.localizedDescription)")
        }
    }
    
    func updateEvent(_ event: Event) async {
        // Fetch the existing event
        let eventId = event.id
        let descriptor = FetchDescriptor<Event>(predicate: #Predicate<Event> { eventInContext in
              eventInContext.id == eventId 
          })
        do {
            if let fetchedEvent = try context.fetch(descriptor).first {
                // Update properties
                fetchedEvent.name = event.name
                fetchedEvent.note = event.note
                fetchedEvent.date = event.date
                fetchedEvent.location = event.location
                fetchedEvent.transitionFromPrevious = event.transitionFromPrevious
                fetchedEvent.isSynced = event.isSynced
                fetchedEvent.isDeleted = event.isDeleted
                try context.save()
            } else {
                // Event not found, insert as new
                context.insert(event)
                try context.save()
            }
        } catch {
            print("Error updating local Event with error: \(error.localizedDescription)")
        }
    }
    
    
    func deleteEvent(withId id: Event.ID) async -> Event? {
        let descriptor = FetchDescriptor<Event>(predicate: #Predicate<Event> {$0.id == id })
        
        do {
            if let fetchedEvent = try context.fetch(descriptor).first {
                context.delete(fetchedEvent)
                return fetchedEvent
            }
            try context.save()
            
        } catch {
            print("Error fetching local Event with error: \(error.localizedDescription)")
        }
        return nil
    }
    
    
}
