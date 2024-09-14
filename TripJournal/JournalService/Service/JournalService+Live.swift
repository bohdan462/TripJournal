//
//  JournalService+Live.swift
//  TripJournal
//
//  Created by Bohdan Tkachenko on 9/13/24.
//

import Foundation
import Combine

class JournalServiceLive: JournalService {
    func register(username: String, password: String) async throws -> Token {
        <#code#>
    }
    
    func logIn(username: String, password: String) async throws -> Token {
        <#code#>
    }
    
    func logOut() {
        <#code#>
    }
    
    
    private let tokenManager: TokenManager
    private let networkClient: NetworkClient

    init(tokenManager: TokenManager, networkClient: NetworkClient) {
        self.tokenManager = tokenManager
        self.networkClient = networkClient
    }

    var isAuthenticated: AnyPublisher<Bool, Never> {
        tokenManager.$state
            .map { state in
                if case .fetched = state { return true }
                return false
            }
            .eraseToAnyPublisher()
    }


    func createTrip(with request: TripCreate) async throws -> Trip {
    }

    func getTrips() async throws -> [Trip] {
        <#code#>
    }
    
    func getTrip(withId tripId: Trip.ID) async throws -> Trip {
        <#code#>
    }
    
    func updateTrip(withId tripId: Trip.ID, and request: TripUpdate) async throws -> Trip {
        <#code#>
    }
    
    func deleteTrip(withId tripId: Trip.ID) async throws {
        <#code#>
    }
    
    func createEvent(with request: EventCreate) async throws -> Event {
        <#code#>
    }
    
    func updateEvent(withId eventId: Event.ID, and request: EventUpdate) async throws -> Event {
        <#code#>
    }
    
    func deleteEvent(withId eventId: Event.ID) async throws {
        <#code#>
    }
    
    func createMedia(with request: MediaCreate) async throws -> Media {
        <#code#>
    }
    
    func deleteMedia(withId mediaId: Media.ID) async throws {
        <#code#>
    }
}


