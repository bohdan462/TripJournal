//
//  TripLocalDataSource.swift
//  TripJournal
//
//  Created by Bohdan Tkachenko on 9/24/24.
//

import Foundation
import SwiftData

protocol TripLocalDataSource {
    func getTrips() async throws-> [Trip]
    func getTrip(withId id: Trip.ID) async throws-> Trip?
    func saveTrips(_ trips: [Trip]) async throws
    func saveTrip(_ trip: Trip) async throws
    func updateTrip(_ trip: Trip) async throws
    func deleteTrip(withId id: Trip.ID) async throws -> Trip?
    func deleteAll() async throws
}


class TripLocalDataSourceImpl: TripLocalDataSource {
    
    private let context: ModelContext
    
    init(context: ModelContext) {
        self.context = context
    }
    
    // Methods
    @MainActor
    func getTrips() async throws -> [Trip] {
            let descriptor = FetchDescriptor<Trip>(sortBy: [SortDescriptor(\Trip.id, order: .forward)])
            do {
                let trips = try context.fetch(descriptor)
                return trips
            } catch {
                throw LocalDataSourceError.fetchFailed(error)
            }
    }
    
    @MainActor
    func getTrip(withId id: Trip.ID) async throws -> Trip? {
        let descriptor = FetchDescriptor<Trip>(predicate: #Predicate<Trip> {$0.id == id })
        do {
            if let fetchedTrip = try context.fetch(descriptor).first {
                return fetchedTrip
            }
        } catch {
            throw LocalDataSourceError.fetchFailed(error)
        }
        return nil
    }
    
    @MainActor
    func saveTrips(_ trips: [Trip]) async throws {
        let incomingIDs = trips.map { $0.id }
        let descriptor = FetchDescriptor<Trip>(predicate: #Predicate<Trip> { incomingIDs.contains($0.id) })

        do {
            let fetchedTrips = try context.fetch(descriptor)
            let existingIDs = Set(fetchedTrips.map { $0.id })
            
            trips.forEach { trip in
                        if !existingIDs.contains(trip.id) {
                            context.insert(trip)
                        }
                    }
            
            try context.save()
        } catch {
            throw LocalDataSourceError.saveFailed(error)
        }
        
    }
    
    @MainActor
    func saveTrip(_ trip: Trip) async throws {
        let passedTripId = trip.id
        let descriptor = FetchDescriptor<Trip>(predicate: #Predicate<Trip> { $0.id == passedTripId })

        do {
            
            if try context.fetch(descriptor).first != nil {
                try await updateTrip(trip)
            } else {
                context.insert(trip)
            }
            try context.save()
        } catch {
            throw LocalDataSourceError.saveFailed(error)
        }
    }
    
    @MainActor
    func updateTrip(_ trip: Trip) async throws {
        let passedTripId = trip.id
        let descriptor = FetchDescriptor<Trip>(predicate: #Predicate<Trip> { $0.id == passedTripId })
        do {
            if let fetchedTrip = try context.fetch(descriptor).first {
                if (fetchedTrip.tripId == nil && trip.tripId != nil) {
                    fetchedTrip.tripId = trip.tripId
                }
                
                if fetchedTrip.name != trip.name {
                    fetchedTrip.name = trip.name
                    fetchedTrip.isSynced = false
                }
                
                if fetchedTrip.startDate != trip.startDate {
                    fetchedTrip.startDate = trip.startDate
                    fetchedTrip.isSynced = false
                }
                if fetchedTrip.endDate != trip.endDate {
                    fetchedTrip.endDate = trip.endDate
                    fetchedTrip.isSynced = false
                }
                
                fetchedTrip.events.removeAll { event in
                    !trip.events.contains { $0.id == event.id}
                }
                
            
                trip.events.forEach { event in
                    if let index = fetchedTrip.events.firstIndex(where: { $0.id == event.id }) {
                        // Update existing event in-place
                        var existingEvent = fetchedTrip.events[index]
                        existingEvent.name = event.name
                        existingEvent.note = event.note
                        existingEvent.date = event.date
                        existingEvent.location = event.location
                        existingEvent.trip = fetchedTrip
                        existingEvent.transitionFromPrevious = event.transitionFromPrevious
                        fetchedTrip.events[index] = existingEvent
                    } else {
                       
                        let newEvent = event
                        newEvent.trip = fetchedTrip
                        fetchedTrip.events.append(newEvent)
                    }
                }

                try context.save()
            }
        } catch {
            throw LocalDataSourceError.updateFailed(error)
        }
    }
    
    @MainActor
    func deleteTrip(withId id: Trip.ID) async throws -> Trip? {
        let descriptor = FetchDescriptor<Trip>(predicate: #Predicate<Trip> {$0.id == id })
        
        do {
            if let fetchedTrip = try context.fetch(descriptor).first {
                context.delete(fetchedTrip)
               try context.save()
                return fetchedTrip
            }
        } catch {
            throw LocalDataSourceError.deleteFailed(error)
        }
        return nil
    }
    
    func deleteAll() async throws {
        let fetchDescriptor = FetchDescriptor<Trip>()
        
        do {
            let allTrips = try context.fetch(fetchDescriptor)
            
            for trip in allTrips {
                context.delete(trip)
            }
            
            try context.save()
            
            print("All data deleted successfully from local context.")
        } catch {
            throw LocalDataSourceError.deleteFailed(error)
        }
    }
}

