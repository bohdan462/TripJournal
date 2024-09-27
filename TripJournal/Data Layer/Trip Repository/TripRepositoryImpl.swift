//
//  TripRepositoryImpl.swift
//  TripJournal
//
//  Created by Bohdan Tkachenko on 9/24/24.
//

import Foundation

protocol TripRepository {
    func getTrips() async throws -> [Trip]
    func createTrip(_ request: TripCreate) async throws -> Trip
    func getTrip(withId tripId: Trip.ID) async throws -> Trip?
    func updateTrip(_ trip: Trip, withId id: Trip.ID) async throws -> Trip
    func deleteTrip(withId tripId: Trip.ID) async throws
    func deleteAll() async throws
}


class TripRepositoryImpl: TripRepository {

    // Dependencies
    private let remoteDataSource: TripRemoteDataSource
    private let localDataSource: TripLocalDataSource
    
    // Initializer
    init(remoteDataSource: TripRemoteDataSource,
         localDataSource: TripLocalDataSource) {
        self.remoteDataSource = remoteDataSource
        self.localDataSource = localDataSource
    }
    
    // Methods
    // In TripRepositoryImpl or wherever you fetch trips
    func getTrips() async throws -> [Trip] {
        // 1. Check if trips are already available locally
        let localTrips = await localDataSource.getTrips()
        
        // 2. If local trips are available, return them without fetching from the server
        if !localTrips.isEmpty && !localTrips.compactMap({!$0.isSynced}).isEmpty {
            return localTrips
        }
        
        // 3. If trips aren't available locally, check if we're online
        if NetworkMonitor.shared.isConnected {
            // Fetch trips from the server only if we are online and there are no local trips
            let tripResponses = try await remoteDataSource.getTrips()
            
            var trips: [Trip] = []
            
            // 4. Map and create the trips with events from the response
            for tripResponse in tripResponses {
                let trip = Trip(
                    tripId: tripResponse.tripId,
                    name: tripResponse.name,
                    startDate: tripResponse.startDate,
                    endDate: tripResponse.endDate,
                    isSynced: true
                )
                
                // Map events for each trip
                let events = tripResponse.events.map { eventResponse -> Event in
                    Event(
                        eventId: eventResponse.tripID,
                        name: eventResponse.name,
                        note: eventResponse.note,
                        date: eventResponse.date,
                        location: eventResponse.location != nil ? Location(
                            latitude: eventResponse.location!.latitude,
                            longitude: eventResponse.location!.longitude,
                            address: eventResponse.location?.address
                        ) : nil,
                        trip: trip,
                        tripID: tripResponse.tripId,
                        isSynced: true
                    )
                }
                
                // Assign events to the trip
                trip.events = events
                trips.append(trip)
            }
            
            // 5. Save trips and events to the local data source (SwiftData)
            await localDataSource.saveTrips(trips)
            
            return trips
        } else {
            // 6. Offline mode: If offline and no trips are found locally, return an empty array
            return localTrips
        }
    }


    
    func createTrip(_ request: TripCreate) async throws -> Trip {
        if NetworkMonitor.shared.isConnected {
            let trip = try await remoteDataSource.createTrip(request)
            await localDataSource.saveTrip(trip)
            return trip
        } else {
            // Handle offline case
            let trip = Trip(name: request.name,
                            startDate: request.startDate,
                            endDate: request.endDate,
                            isSynced: NetworkMonitor.shared.isConnected)
            await localDataSource.saveTrip(trip)
            return trip
        }
    }
    
    func getTrip(withId tripId: Trip.ID) async throws -> Trip? {
        
        if let localCopy = await localDataSource.getTrip(withId: tripId) {
            return localCopy
        }
        return nil
    }
    
    func updateTrip(_ trip: Trip, withId id: Trip.ID) async throws -> Trip {
        // Update the local copy with new data
        var localTrip = trip
        localTrip.isSynced = false // Mark as needing synchronization

        // Attempt to synchronize if connected
        if NetworkMonitor.shared.isConnected {
            if let remoteTripId = localTrip.tripId {
                // Update the trip on the remote server
                let request = TripUpdate(name: localTrip.name, startDate: localTrip.startDate, endDate: localTrip.endDate)
                let updatedTripResponse = try await remoteDataSource.updateTrip(withId: remoteTripId, and: request)

                // Update local copy with any changes from the server
                localTrip = updatedTripResponse
              
                await localDataSource.updateTrip(localTrip, withId: id)
            } else {
                // Trip does not have a remote ID, create it on the server
                let createRequest = TripCreate(name: localTrip.name, startDate: localTrip.startDate, endDate: localTrip.endDate)
                let createdTripResponse = try await remoteDataSource.createTrip(createRequest)

                // Update local copy with new tripId and set isSynced to true
                localTrip.tripId = createdTripResponse.tripId
                localTrip.isSynced = true
                await localDataSource.updateTrip(localTrip, withId: id)
            }
        } else {
            await localDataSource.updateTrip(localTrip, withId: id)
        }
        return localTrip
    }

    
    
    
    func deleteTrip(withId tripId: Trip.ID) async throws {
        
        guard let tripToDelete = await localDataSource.deleteTrip(withId: tripId) else {
            return
        }
        
        if NetworkMonitor.shared.isConnected {
            // Online: Delete the trip on the remote server if it has a remote ID
            if let remoteTripId = tripToDelete.tripId {
                try await remoteDataSource.deleteTrip(withId: remoteTripId)
            }
        } else {
            // Offline: Mark the trip as deleted locally and flag it for synchronization
            let localTrip = tripToDelete

            localTrip.isSynced = false  
            localTrip.name = ""
            localTrip.events = []// Mark as needing synchronization

            // Update the trip locally
            await localDataSource.updateTrip(localTrip, withId: tripToDelete.id)
        }
    }
    
    func deleteAll() async throws {
        let allRemoteTrips = try await remoteDataSource.getTrips()
        let _ = await localDataSource.getTrips()
        
        print("Trips count: \(allRemoteTrips.count) before deleting")
        for (index, trip) in allRemoteTrips.enumerated() {
            if trip.tripId == nil {
                print("Trying to delete remote Trip withoout ID")
            }
            try await remoteDataSource.deleteTrip(withId: trip.tripId!)
            print("DELETED: \(trip.name)")
        }
        await localDataSource.deleteAll()
        print("Successfully deleted all trips")
    }

}
