//
//  EventRepositoryImpl.swift
//  TripJournal
//
//  Created by Bohdan Tkachenko on 9/24/24.
//

import Foundation

enum EventRepositoryError: Error {
    case parentTripNotAvailable
    case eventNotFound
    case parentTripNotSynced
    // Add other error cases as needed
}

protocol EventRepository {
    func createEvent(_ event: Event, fromTrip: Trip) async throws
    func getEvent(withId eventId: Event.ID) async throws -> Event?
    func updateEvent(_ event: Event, inTrip: Trip) async throws
    func deleteEvent(_ event: Event) async throws
}

class EventRepositoryImpl: EventRepository {
    
    // Dependencies
    private let remoteDataSource: EventRemoteDataSource
    private let localDataSource: EventLocalDataSource
    
    // Initializer
    init(remoteDataSource: EventRemoteDataSource,
         localDataSource: EventLocalDataSource,
         networkMonitor: NetworkMonitor = NetworkMonitor.shared) {
        self.remoteDataSource = remoteDataSource
        self.localDataSource = localDataSource
    }
    
    // MARK: - Create Event
    func createEvent(_ event: Event, fromTrip: Trip) async throws {
        // Save the event locally first
        await localDataSource.saveEvent(event)
        
        if NetworkMonitor.shared.isConnected {
            guard let tripId = event.tripID else {
                throw EventRepositoryError.parentTripNotSynced
            }
            
            // Prepare EventCreate request
            let request = EventCreate(
                tripId: tripId,
                name: event.name,
                date: event.date,
                note: event.note,
                location: event.location != nil ? LocationResponse(
                    latitude: event.location!.latitude,
                    longitude: event.location!.longitude,
                    address: event.location!.address
                ) : nil,
                transitionFromPrevious: event.transitionFromPrevious
            )
            
            // Create event on the server
            let createdEventResponse = try await remoteDataSource.createEvent(with: request)
            
            // Update local event with response data
            event.eventId = createdEventResponse.eventId
            event.isSynced = true
            await localDataSource.updateEvent(event)
        } else {
            // Mark event as needing synchronization
            event.isSynced = false
            await localDataSource.updateEvent(event)
        }
    }

    
    
    // MARK: - Get Event
    func getEvent(withId eventId: Event.ID) async throws -> Event? {
        // Fetch the event from the local data source
        if let localEvent = await localDataSource.getEvent(withId: eventId) {
            if NetworkMonitor.shared.isConnected, let remoteEventId = localEvent.eventId {
                // Fetch the event from the remote server
                if let remoteEvent = try await remoteDataSource.getEvent(withId: remoteEventId) {
                    
                    // Update local event properties, but keep the trip relationship
                    localEvent.name = remoteEvent.name
                    localEvent.date = remoteEvent.date
                    localEvent.note = remoteEvent.note
                    localEvent.location = remoteEvent.location
                    localEvent.transitionFromPrevious = remoteEvent.transitionFromPrevious
                    localEvent.isSynced = true
                    
                    await localDataSource.updateEvent(localEvent)
                }
            }
            return localEvent
        } else {
            return nil
        }
    }

    
    // MARK: - Update Event
    func updateEvent(_ event: Event, inTrip: Trip) async throws {
        // Update the event locally
        await localDataSource.updateEvent(event)
        
        if NetworkMonitor.shared.isConnected {
            if let remoteEventId = event.eventId {
                // Prepare EventUpdate request
                let request = EventUpdate(
                    name: event.name,
                    date: event.date,
                    note: event.note,
                    location: event.location != nil ? LocationResponse(
                        latitude: event.location!.latitude,
                        longitude: event.location!.longitude,
                        address: event.location!.address
                    ) : nil,
                    transitionFromPrevious: event.transitionFromPrevious
                )
                
                // Update event on the server
                let updatedEventResponse = try await remoteDataSource.updateEvent(withId: remoteEventId, and: request)
                
                // Update local event with response data
                event.name = updatedEventResponse.name
                event.date = updatedEventResponse.date
                event.note = updatedEventResponse.note
                event.location = updatedEventResponse.location != nil ? Location(
                    latitude: updatedEventResponse.location!.latitude,
                    longitude: updatedEventResponse.location!.longitude,
                    address: updatedEventResponse.location!.address
                ) : nil
                event.transitionFromPrevious = updatedEventResponse.transitionFromPrevious
                event.isSynced = true
                await localDataSource.updateEvent(event)
            } else {
                // Handle case where event doesn't have a remote ID
                // Possibly create the event on the server
            }
        } else {
            // Mark event as needing synchronization
            event.isSynced = false
            await localDataSource.updateEvent(event)
        }
    }

    
    
    // MARK: - Delete Event
    
    func deleteEvent(_ event: Event) async throws {
        // Delete the event locally
        await localDataSource.deleteEvent(withId: event.id)
        
        if NetworkMonitor.shared.isConnected {
            if let remoteEventId = event.eventId {
                // Delete event on the server
                try await remoteDataSource.deleteEvent(withId: remoteEventId)
            }
        } else {
            // Mark event as needing synchronization
            event.isDeleted = true
            event.isSynced = false
            await localDataSource.updateEvent(event)
        }
    }
}
