//
//  EventRepositoryImpl.swift
//  TripJournal
//
//  Created by Bohdan Tkachenko on 9/24/24.
//

import Foundation

protocol EventRepository {
    func createEvent(_ event: Event) async throws -> Event
    func getEvent(withId eventId: Event.ID) async throws -> Event?
    func updateEvent(_ event: Event) async throws -> Event
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
    func createEvent(_ event: Event) async throws -> Event {
        guard event.trip != nil else { throw EventRepositoryError.parentTripNotAvailable}
        let passedEvent = event
        if NetworkMonitor.shared.isConnected {
            guard let tripId = event.tripID else {
                throw EventRepositoryError.parentTripNotSynced
            }
            
            do {
                // Prepare EventCreate request
                let request = EventCreate(
                    tripId: tripId,
                    name: passedEvent.name,
                    date: passedEvent.date,
                    note: passedEvent.note,
                    location: passedEvent.location != nil ? LocationResponse(
                        latitude: passedEvent.location!.latitude,
                        longitude: passedEvent.location!.longitude,
                        address: passedEvent.location!.address
                    ) : nil,
                    transitionFromPrevious: passedEvent.transitionFromPrevious
                )
                
                // Create event on the server
                let createdEventResponse = try await remoteDataSource.createEvent(with: request)
                
                
//                createdEventResponse.tripID = tripId
//                createdEventResponse.trip = event.trip
                guard let eventId = createdEventResponse.eventId else {
                    throw EventRepositoryError.serverSideIdNotFound
                }
                
                passedEvent.eventId = createdEventResponse.eventId
                
                if createdEventResponse.name != passedEvent.name {
                    passedEvent.name = createdEventResponse.name
                }
                
                if createdEventResponse.note != passedEvent.note {
                    passedEvent.note = createdEventResponse.note
                }
                
                if createdEventResponse.transitionFromPrevious != passedEvent.transitionFromPrevious {
                    passedEvent.note = createdEventResponse.transitionFromPrevious
                }
                
                if createdEventResponse.date != passedEvent.date {
                    passedEvent.date = createdEventResponse.date
                }
                
                if let location = createdEventResponse.location {
                    if passedEvent.location == nil {
                        let latitude = location.latitude
                        let longitude = location.longitude
                        let address = location.address
                        passedEvent.location?.latitude = latitude
                        passedEvent.location?.longitude = longitude
                        passedEvent.location?.address = address
                    }
                }
                
                
                if !createdEventResponse.medias.isEmpty {
                    createdEventResponse.medias.forEach {  passedEvent.medias.append($0)
                    }
                }
                passedEvent.isSynced = createdEventResponse.isSynced
                return passedEvent
            } catch {
                throw RemoteDataSourceError.networkError(error)
            }
        } else {
            return passedEvent
        }
    }
    
    
    
    // MARK: - Get Event
    func getEvent(withId eventId: Event.ID) async throws -> Event? {
        // Fetch the event from the local data source
        do {
            guard let localEvent = try await localDataSource.getEvent(withId: eventId) else { return nil }
                if NetworkMonitor.shared.isConnected, let remoteEventId = localEvent.eventId {
                    // Fetch the event from the remote server
                    if let remoteEvent = try await remoteDataSource.getEvent(withId: remoteEventId) {
                        return remoteEvent
                    }
                }
        } catch {
            throw DataSourceError.noData(error)
        }
        return nil
    }
    
    
    // MARK: - Update Event
    func updateEvent(_ event: Event) async throws -> Event {
        var passedEvent = event
        if NetworkMonitor.shared.isConnected {
            if let remoteEventId = passedEvent.eventId {
                
                let request = EventUpdate(
                    name: passedEvent.name,
                    date: passedEvent.date,
                    note: passedEvent.note,
                    location: passedEvent.location != nil ? LocationResponse(
                        latitude: passedEvent.location!.latitude,
                        longitude: passedEvent.location!.longitude,
                        address: passedEvent.location!.address
                    ) : nil,
                    transitionFromPrevious: passedEvent.transitionFromPrevious
                )
                
                let updatedEventResponse = try await remoteDataSource.updateEvent(withId: remoteEventId, and: request)
                if updatedEventResponse.name != passedEvent.name {
                    passedEvent.name = updatedEventResponse.name
                }
                if updatedEventResponse.date != passedEvent.date {
                    passedEvent.date = updatedEventResponse.date
                }
                if updatedEventResponse.note != passedEvent.note {
                    passedEvent.note = updatedEventResponse.note
                }
                
                if let location = updatedEventResponse.location {
                    if passedEvent.location == nil {
                        let latitude = location.latitude
                        let longitude = location.longitude
                        let address = location.address
                        passedEvent.location?.latitude = latitude
                        passedEvent.location?.longitude = longitude
                        passedEvent.location?.address = address
                    }
                }
                if updatedEventResponse.transitionFromPrevious != passedEvent.transitionFromPrevious {
                    passedEvent.transitionFromPrevious = updatedEventResponse.transitionFromPrevious
                }
                
                if !updatedEventResponse.medias.isEmpty {
                    let existingMediaURLs = passedEvent.medias.map { $0.url }
                  
                    updatedEventResponse.medias.forEach { media in
                        if !existingMediaURLs.contains(media.url) {
                            passedEvent.medias.append(media)
                        }
                    }
                    
                    updatedEventResponse.medias.forEach {  passedEvent.medias.append($0)
                    }
                }
                
                passedEvent.isSynced = true
            
            } else {
              return try await createEvent(passedEvent)
                
            }
        } else {
            
            passedEvent.isSynced = false
            
        }
        return passedEvent
        
    }
    
    
    
    // MARK: - Delete Event
    
    func deleteEvent(_ event: Event) async throws {
        if NetworkMonitor.shared.isConnected {
            
            if let remoteEventId = event.eventId {
                do {
                    try await remoteDataSource.deleteEvent(withId: remoteEventId)
                } catch {
                    throw RemoteDataSourceError.networkError(error)
                }
            }
        } else {
            event.isDeleted = true
            event.isSynced = false
        }
    }
    
    func deleteAllEvents(in trip: Trip) async throws {
        trip.events = []
    }
}
