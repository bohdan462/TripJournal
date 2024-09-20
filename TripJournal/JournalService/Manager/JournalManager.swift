//
//  TripModelView.swift
//  TripJournal
//
//  Created by Bohdan Tkachenko on 9/16/24.
//

import Foundation
import UIKit
import SwiftData
import SwiftUI


class JournalManager: ObservableObject {
    
    let journalFacade: JournalServiceFacade
    @Published var trips: [Trip] = []
    @Published var events: [Event] = []
    @Published var meadias: [Media] = []
    
    @Query var localTrips: [Trip]
    
    
    init(facade: JournalServiceFacade) {
        self.journalFacade = facade
        
    }
    
    
    func register(username: String, password: String) async {
        do {
            let token = try await journalFacade.register(username: username, password: password)
            //            await journalFacade.tokenManager.saveToken(token)
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    
    func logIn(username: String, password: String) async {
        
        do {
            let token = try await journalFacade.logIn(username: username, password: password)
            //            await journalFacade.tokenManager.saveToken(token)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func logOut() async {
        trips.removeAll()
        events.removeAll()
        meadias.removeAll()
        await journalFacade.logOut()
    }
    
    func fetchAllTripsFromContext() -> [Trip] {
        return journalFacade.allPersistedTrips
    }
    
    func fetchUnsyncedTripsContext() -> [Trip] {
        return journalFacade.unsyncedTrips
    }
    
    func fectchSyncedTripsContext() -> [Trip] {
        return journalFacade.syncedTrips
    }
    
    func createTrip(from request: TripCreate) async -> Trip {
        return await journalFacade.createTrip(from: request)
    }
 
    
    // Fetch trips and update the published property
    @MainActor
    func fetchTripsFromServer() async -> [Trip] {
        do {
            return try await journalFacade.getTripsFromServer()
            //            self.trips = fetchedTrips
        } catch {
            print("Failed to fetch and save trips: \(error)")
            return []
        }
    }
    
    func getTrip(withId tripId: Int) async -> Trip {
        try! await journalFacade.getTrip(withId: tripId)
    }
    
    func updateTrip(withId tripId: Int, and request: TripUpdate) async -> Trip {
        try! await journalFacade.updateTrip(withId: tripId, and: request)
    }
    
    func deleteTrip(withId tripId: Int) async {
        try! await journalFacade.deleteTrip(withId: tripId)
    }
    
    func createEvent(with request: EventCreate) async -> Event {
        try! await journalFacade.createEvent(with: request)
    }
    
    func updateEvent(withId eventId: Int, tripId: Int, and request: EventUpdate) async -> Event {
        try! await journalFacade.updateEvent(withId: eventId, tripId: tripId, and: request)
    }
    
    func deleteEvent(withId eventId: Int) async {
        try! await journalFacade.deleteEvent(withId: eventId)
    }
    
    func createMedia(with data: Data, eventId: Int) async -> Media {
        
        let base64String = data.base64EncodedString()
        
        let mediaRequest = MediaCreate(caption: " ", base64Data: base64String, eventID: eventId)
        
        return try! await journalFacade.createMedia(with: mediaRequest)
    }
    
    func deleteMedia(withId mediaId: Int) async {
        try! await journalFacade.deleteMedia(withId: mediaId)
    }
    
}
