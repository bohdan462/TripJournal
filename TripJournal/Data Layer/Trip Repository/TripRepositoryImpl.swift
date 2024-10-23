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
    func updateTrip(_ trip: Trip) async throws
    func deleteTrip(withId tripId: Trip.ID) async throws -> Trip
    func deleteAll() async throws
}

enum TripRepositoryError: Error {
    case tripNotFound
    case tripAlreadyExists
    case tripUpdateFailed
    case tripDeleteFailed
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
    
    func getTrips() async throws -> [Trip] {
        
        let localTrips = try await localDataSource.getTrips()
        let remoteTrips = try await remoteDataSource.getTrips()
        
        print("\n LOCAL_TRIPS_FETCHED \n")
        localTrips.forEach({ trip in
            
            print("TRIP_ID: \(trip.tripId)")
            print("TRIP_NAME: \(trip.name)")
            print("TRIP_EVENTS_CONT: \(trip.events.count)")
            print("TRIP_isSYNCED: \(trip.isSynced)")
            trip.events.forEach {  event in
                print("TRIP_EVENT name: \(event.name)\nbelongs Trip: \(event.trip) \nLocation lat:\(event.location?.latitude)\nlong: \(event.location?.longitude)")
                print("Media files count: \(event.medias.count), media files: \(event.medias.debugDescription)\n")
                event.medias.forEach({ media in
                    print("MEDIA_URL: \(media.url), and ID: \(media.id)")
                })
            }
        })
        
        for remoteTrip in remoteTrips {
            if localTrips.contains(where: { $0.tripId == remoteTrip.tripId }) {
                continue
            } else {
                try await localDataSource.saveTrip(remoteTrip)
                print("FOUND REMOTE TRIP NOT IN LOCAL---> SAVED")
            }
        }
        
        print("\n COMBINED LOCAL and REMOTE TRIP \n")
        localTrips.forEach({ trip in
            
            print("TRIP_ID: \(trip.tripId)")
            print("TRIP_NAME: \(trip.name)")
            print("TRIP_EVENTS_CONT: \(trip.events.count)")
            print("TRIP_isSYNCED: \(trip.isSynced)")
            trip.events.forEach({  event in
                print("TRIP_EVENT name: \(event.name)\nbelongs Trip: \(event.trip) \nLocation lat:\(event.location?.latitude)\nlong: \(event.location?.longitude) \n\\n")
                
            })
            
            
        })
        
        //MARK: - Only local and all are synced
        if !localTrips.isEmpty && localTrips.filter({ !$0.isSynced }).isEmpty {
            print("\n NOT CONNECTING TO SERVER---USING LOCAL TRIPS ONLY\n")
            return localTrips
            
            //MARK: - if unsynced locally with no server side ID
        } else if !localTrips.isEmpty && !localTrips.filter({ !$0.isSynced && $0.tripId == nil}).isEmpty && NetworkMonitor.shared.isConnected {
            
            try await syncUnsyncedTrips(localTrips, isServerSideID: false)
            
            print("\n NO SERVER IDS ---> COMBINED LOCAL and REMOTE WITH SYNCED SERVER IDs \n")
            localTrips.forEach({ trip in
                
                print("TRIP_ID: \(trip.tripId)")
                print("TRIP_NAME: \(trip.name)")
                print("TRIP_EVENTS_CONT: \(trip.events.count)")
                print("TRIP_isSYNCED: \(trip.isSynced)")
                trip.events.forEach({  event in
                    print("TRIP_EVENT name: \(event.name)\nbelongs Trip: \(event.trip) \nLocation lat:\(event.location?.latitude)\nlong: \(event.location?.longitude) \n\\n")
                    
                })
                
                
            })
            return localTrips
            
            
            //MARK: - if unsynced locally with server side ID
        } else if !localTrips.isEmpty && !localTrips.filter({ !$0.isSynced && $0.tripId != nil }).isEmpty && NetworkMonitor.shared.isConnected {
            
            try await syncUnsyncedTrips(localTrips, isServerSideID: true)
            print("\n WITH SERVER_ID COMBINED LOCAL and REMOTE \n")
            localTrips.forEach({ trip in
                
                print("TRIP_ID: \(trip.tripId)")
                print("TRIP_NAME: \(trip.name)")
                print("TRIP_EVENTS_CONT: \(trip.events.count)")
                print("TRIP_isSYNCED: \(trip.isSynced)")
                trip.events.forEach({  event in
                    print("TRIP_EVENT name: \(event.name)\nbelongs Trip: \(event.trip) \nLocation lat:\(event.location?.latitude)\nlong: \(event.location?.longitude) \n\\n")
                    
                })
                
                
            })
            return localTrips
            
            //MARK: - no trips in local fetch from server
        } else if localTrips.isEmpty && NetworkMonitor.shared.isConnected {
            
            let tripResponses = try await remoteDataSource.getTrips()
            var trips: [Trip] = []
            for tripResponse in tripResponses {
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
                        trip: tripResponse,
                        tripID: tripResponse.tripId,
                        isSynced: true
                    )
                }
                
                tripResponse.events = events
                trips.append(tripResponse)
            }
            
            try await localDataSource.saveTrips(trips)
            
            print("\n LOCAL _EMPTY ---> REMOTE_FETCHED_and_SAVED_LOCAL or EMPTY")
            trips.forEach({ trip in
                
                print("TRIP_ID: \(trip.tripId)")
                print("TRIP_NAME: \(trip.name)")
                print("TRIP_EVENTS_CONT: \(trip.events.count)")
                print("TRIP_isSYNCED: \(trip.isSynced)")
                trip.events.forEach({  event in
                    print("TRIP_EVENT name: \(event.name)\nbelongs Trip: \(event.trip) \nLocation lat:\(event.location?.latitude)\nlong: \(event.location?.longitude) \n\\n")
                    
                })
                
            })
            
            return trips
        } else {
            print("\n NO NETWORK RETURN LOCAL or EMPTY")
            localTrips.forEach({ trip in
                
                print("TRIP_ID: \(trip.tripId)")
                print("TRIP_NAME: \(trip.name)")
                print("TRIP_EVENTS_CONT: \(trip.events.count)")
                print("TRIP_isSYNCED: \(trip.isSynced)")
                trip.events.forEach({  event in
                    print("TRIP_EVENT name: \(event.name)\nbelongs Trip: \(event.trip) \nLocation lat:\(event.location?.latitude)\nlong: \(event.location?.longitude) \n\\n")
                    
                })
            })
            
            return localTrips
        }
    }
    
    private func syncUnsyncedTrips(_ trips: [Trip], isServerSideID: Bool) async throws {
        
        let unsyncedTrips = trips.filter { !$0.isSynced && (isServerSideID ? $0.tripId != nil : $0.tripId == nil) }
        
        for unsyncedTrip in unsyncedTrips {
            //Checks if server assigned ID
            do {
                if isServerSideID {
                    // Update trip remotely
                    
                    let tripUpdate = TripUpdate(name: unsyncedTrip.name, startDate: unsyncedTrip.startDate, endDate: unsyncedTrip.endDate)
                    let updatedTrip = try await remoteDataSource.updateTrip(withId: unsyncedTrip.tripId!, and: tripUpdate)
                    unsyncedTrip.isSynced = true
                    try await localDataSource.saveTrip(unsyncedTrip)
                    
                } else {
                    // Create trip remotely
                    
                    let tripCreate = TripCreate(name: unsyncedTrip.name, startDate: unsyncedTrip.startDate, endDate: unsyncedTrip.endDate)
                    let createdTrip = try await remoteDataSource.createTrip(tripCreate)
                    unsyncedTrip.tripId = createdTrip.tripId
                    unsyncedTrip.isSynced = true
                    try await localDataSource.saveTrip(unsyncedTrip)
                    
                }
            }  catch {
                throw DataSourceError.failedToProcessData(error)
            }
        }
    }
    
    func createTrip(_ request: TripCreate) async throws -> Trip {
        if NetworkMonitor.shared.isConnected {
            do {
                let trip = try await remoteDataSource.createTrip(request)
                try await localDataSource.saveTrip(trip)
                return trip
            } catch {
                throw RemoteDataSourceError.networkError(error)
            }
        } else {
            // Handle offline case
            do {
                let trip = Trip(name: request.name,
                                startDate: request.startDate.toDate(),
                                endDate: request.endDate.toDate(),
                                isSynced: NetworkMonitor.shared.isConnected)
                try await localDataSource.saveTrip(trip)
                return trip
            } catch {
                throw DataSourceError.failedToProcessData(error)
            }
        }
    }
    
    func getTrip(withId tripId: Trip.ID) async throws -> Trip? {
        do {
            if let localCopy = try await localDataSource.getTrip(withId: tripId) {
                return localCopy
            }
        } catch {
            throw DataSourceError.failedToProcessData(error)
        }
        return nil
    }
    
    func updateTrip(_ trip: Trip) async throws {
        
        print("\n --TRIP_REPOSITIRY---UPDATING_TRIP")
        print("\n TRIP_NAME: \(trip.name), START_DATE: \(trip.startDate), END_DATE:\(trip.endDate), LOCAL_ID: \(trip.id), REMOTE_ID: \(trip.tripId), EVENTS_COUNT: \(trip.events.count)\n")
        trip.events.forEach({  event in
            print("TRIP_EVENT_NAME: \(event.name)\nbelongs Trip: \(event.trip) \nLocation lat:\(event.location?.latitude)\nlong: \(event.location?.longitude) \n\\n")
            
        })
        
        var updatedTrip = trip
        if NetworkMonitor.shared.isConnected {
            if let remoteTripId = trip.tripId {
                do {
                    let request = TripUpdate(name: trip.name, startDate: trip.startDate, endDate: trip.endDate)
                    let updatedTripResponse = try await remoteDataSource.updateTrip(withId: remoteTripId, and: request)
                    
                    
                    
                    updatedTrip.name = updatedTripResponse.name
                    updatedTrip.startDate = updatedTripResponse.startDate
                    updatedTrip.endDate = updatedTripResponse.endDate
                    updatedTrip.tripId = updatedTripResponse.tripId
                    
                    try await localDataSource.updateTrip(updatedTrip)
                    print("\n --TRIP_REPOSITIRY---UPDATED_TRIP")
                    print("\n TRIP_NAME: \(updatedTrip.name), START_DATE: \(updatedTrip.startDate), END_DATE:\(updatedTrip.endDate), LOCAL_ID: \(updatedTrip.id), REMOTE_ID: \(updatedTrip.tripId), EVENTS_COUNT: \(updatedTrip.events.count)\n")
                    updatedTrip.events.forEach({  event in
                        print("TRIP_EVENT_NAME: \(event.name)\nbelongs Trip: \(event.trip) \nLocation lat:\(event.location?.latitude)\nlong: \(event.location?.longitude) \n\\n")
                        
                    })
                } catch {
                    throw DataSourceError.localStorageError(.saveFailed(error))
                }
            } else {
                do {
                    
                    
                    let createRequest = TripCreate(name: trip.name, startDate: trip.startDate, endDate: trip.endDate)
                    let createdTripResponse = try await remoteDataSource.createTrip(createRequest)
                    updatedTrip.tripId = createdTripResponse.tripId
//                    try await localDataSource.updateTrip(createdTripResponse)
                    try await updateTrip(updatedTrip)
                } catch {
                    throw DataSourceError.localStorageError(.updateFailed(error))
                }
            }
        } else {
            trip.isSynced = false
            do {
                try await localDataSource.updateTrip(trip)
            } catch {
                throw DataSourceError.localStorageError(.updateFailed(error))
            }
        }
    }
    
    
    
    
    func deleteTrip(withId tripId: Trip.ID) async throws -> Trip {
        
        if NetworkMonitor.shared.isConnected {
            guard let deletedTrip = try await localDataSource.deleteTrip(withId: tripId) else {
                throw TripRepositoryError.tripNotFound
            }
            do {
                if let remoteTripId = deletedTrip.tripId {
                    try await remoteDataSource.deleteTrip(withId: remoteTripId)
                }
                return deletedTrip
            } catch {
                throw RemoteDataSourceError.objectActionError(error)
            }
        } else {
            
            if let localTrip = try await localDataSource.getTrip(withId: tripId) {
                localTrip.isSynced = false
                localTrip.name = ""
                try await localDataSource.updateTrip(localTrip)
                return localTrip
                
            } else {
                throw TripRepositoryError.tripNotFound
            }
        }
    }
    
    
    //MARK: - Testing
    
    func deleteAll() async throws {
        let allRemoteTrips = try await remoteDataSource.getTrips()
        
        print("Trips count: \(allRemoteTrips.count) before deleting")
        for (index, trip) in allRemoteTrips.enumerated() {
            if trip.tripId == nil {
                print("Trying to delete remote Trip withoout ID")
            }
            
            try await remoteDataSource.deleteTrip(withId: trip.tripId!)
            print("DELETED: \(trip.name)")
        }
        try await localDataSource.deleteAll()
        print("Successfully deleted all trips")
    }
    
}
