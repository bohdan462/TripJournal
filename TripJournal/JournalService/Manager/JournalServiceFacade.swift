import Foundation
import UIKit
import SwiftData
import SwiftUI

class JournalServiceFacade {
    
    let authService: AuthService
    let tokenManager: TokenManager
    private let journalServiceLive: JournalServiceLive
    private let cacheService: CacheService
    var context: ModelContext
   

    init(context: ModelContext) {
        self.cacheService = CacheServiceManager()
        self.tokenManager = TokenManager(storage: KeychainHelper.shared)
        self.authService = AuthenticationService(tokenManager: tokenManager)
        self.journalServiceLive = JournalServiceLive(tokenManager: tokenManager, networkClient: NetworkClient())
        self.context = context
    }

//     MARK: - Auth Methods
  
      // Register a new user
      func register(username: String, password: String) async throws -> Token {
          return try await authService.register(username: username, password: password)
      }
  
      // Log in an existing user
      func logIn(username: String, password: String) async throws -> Token {
          return try await authService.logIn(username: username, password: password)
      }
  
      // Log out the currently authenticated user
      func logOut() async {
          await authService.logOut()
  //        cacheService.clearAllCache()
      }
    
    //MARK: Local Trips
    
     var allPersistedTrips: [Trip] {
        let descriptor = FetchDescriptor<Trip>(sortBy: [SortDescriptor(\Trip.id, order: .forward)])
        
        do {
            let filteredTrips = try context.fetch(descriptor)
            return filteredTrips
        } catch {
            print("Error fetching trips: \(error)")
            return []
        }
    }
    
     var unsyncedTrips: [Trip] {
         let descriptor = FetchDescriptor<Trip>(predicate: #Predicate<Trip> {$0.isSynced == false || $0.tripId == nil },
                                               sortBy: [SortDescriptor(\Trip.name, order: .forward)])
        
        do {
            let filteredTrips = try context.fetch(descriptor)
            return filteredTrips
        } catch {
            return []
        }
    }
    
     var syncedTrips: [Trip] {
        let descriptor = FetchDescriptor<Trip>(predicate: #Predicate<Trip> {$0.isSynced == true },
                                               sortBy: [SortDescriptor(\Trip.name, order: .forward)])
        
        do {
            let filteredTrips = try context.fetch(descriptor)
            return filteredTrips
        } catch {
            return []
        }
    }
    
    
    //MARK: - Trip Methods
    func getTripsFromServer() async throws -> [Trip] {
        return try await journalServiceLive.getTrips()
    }
    
    @MainActor
    func createLocalTrip(from trip: Trip) {
        //Check if no copies in context exists
        context.insert(trip)
        
        try? context.save()
        
        
    }
        
    
    @MainActor
    func createTrip(from request: TripCreate) async -> Trip {
        do {
            let trip = Trip(name: request.name, startDate: request.startDate, endDate: request.endDate, isSynced: false)
            // Check if the device is online
            if NetworkMonitor.shared.isConnected {
                let trip = try await syncCreateTripWithServer(request: request)  // Create trip on server and sync locally
                return trip
            } else {
//                 Offline: Create the trip locally only
                
//                context.insert(trip)
//                try context.save()
                return trip
            }
        } catch {
            print("Failed to create trip: \(error)")
            return Trip(name: "", startDate: Date(), endDate: Date(), events: [])
        }
    }

    func syncCreateTripWithServer(request: TripCreate) async throws -> Trip {
        // Send the trip data to the server
        let trip = try await createTrip(with: request)
     
    // Save the trip locally with server's TripID
        
        return trip
    }
    
        //MARK: - CRUD
        
        // Create a new trip
        func createTrip(with request: TripCreate) async throws -> Trip {
            
                let trip = try await journalServiceLive.createTrip(with: request)
            
            print("Just created Trip: sync \(trip.isSynced), tripID: \(trip.tripId)")
            
//            context.insert(trip)
//            try context.save()
            return trip
        }
        
        
        // Retrieve a specific trip by ID
        func getTrip(withId tripId: Int) async throws -> Trip {
            
            
            let trip = try await journalServiceLive.getTrip(withId: tripId)
            
            return trip
        }
        
        // Update a trip
        func updateTrip(withId tripId: Int, and request: TripUpdate) async throws -> Trip {
            let updatedTrip = try await journalServiceLive.updateTrip(withId: tripId, and: request)
            
            return updatedTrip
        }
        
        // Delete a trip by ID
        func deleteTrip(withId tripId: Int) async throws {
            try await journalServiceLive.deleteTrip(withId: tripId)
            
            
        }
        
        // MARK: - Event Methods
        
        // Create a new event
        func createEvent(with request: EventCreate) async throws -> Event {
            let event = try await journalServiceLive.createEvent(with: request)
            
            return event
        }
        
        // Update an event
        func updateEvent(withId eventId: Int, tripId: Int, and request: EventUpdate) async throws -> Event {
            
            let updatedEvent = try await journalServiceLive.updateEvent(withId: eventId, tripId: tripId, and: request)
            
            return updatedEvent
        }
        
        // Delete an event by ID
        func deleteEvent(withId eventId: Int) async throws {
            try await journalServiceLive.deleteEvent(withId: eventId)
            
        }
        
        // MARK: - Media Methods
        
        // Create a new media item associated with an event
        func createMedia(with media: MediaCreate) async throws -> Media {
            
            let mediaRequest = MediaCreate(caption: media.caption, base64Data: media.base64Data, eventID: media.eventID)
            
            return try await journalServiceLive.createMedia(with: mediaRequest)
        }
        
        // Delete a media item by ID
        func deleteMedia(withId mediaId: Int) async throws {
            try await journalServiceLive.deleteMedia(withId: mediaId)
            
        }
        
    }
