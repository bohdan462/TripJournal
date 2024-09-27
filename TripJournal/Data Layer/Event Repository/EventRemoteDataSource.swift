//
//  EventRemoteDataSource.swift
//  TripJournal
//
//  Created by Bohdan Tkachenko on 9/24/24.
//

import Foundation

protocol EventRemoteDataSource{
    
    func createEvent(with request: EventCreate) async throws -> Event
    func getEvent(withId id: Int) async throws -> Event?
    func updateEvent(withId eventId: Int, and request: EventUpdate) async throws -> Event
    func deleteEvent(withId eventId: Int) async throws
}

class EventRemoteDataSourceImpl: EventRemoteDataSource {

    // Dependencies
    private let networking: NetworkClient
    private let tokenManager: TokenManager
    
    // Initializer
    init(networking: NetworkClient, tokenManager: TokenManager) {
        self.networking = networking
        self.tokenManager = tokenManager
    }

    func createEvent(with request: EventCreate) async throws -> Event {
        guard let token = try await tokenManager.getToken() else {
            throw NetworkError.invalidValue
        }
        
        // Prepare event data as a dictionary
        let eventData: [String: Any] = [
            "name": request.name,
            "note": request.note ?? "",
            "date": ISO8601DateFormatter().string(from: request.date),
            "location": [
                "latitude": request.location?.latitude ?? 0.0,
                "longitude": request.location?.longitude ?? 0.0
            ],
            "trip_id": request.tripId,
            "transitionFromPrevious": request.transitionFromPrevious ?? ""
        ]
        
        // Serialize event data to JSON
        let jsonData = try JSONSerialization.data(withJSONObject: eventData)

        // Configure the request
        let config = CustomRequestConfigurable(
            headers: [
                HTTPHeaders.authorization.rawValue: "Bearer \(token.accessToken)",
                HTTPHeaders.accept.rawValue: MIMEType.JSON.rawValue,
                HTTPHeaders.contentType.rawValue: MIMEType.JSON.rawValue
            ],
            body: jsonData
        )

        // Send the request and return the created event
        let eventResponse = try await networking.request(
            .events,
            responseType: EventResponse.self,
            method: .POST,
            config: config
        )
        
        let event = Event(from: eventResponse, trip: nil)
        return event
    }

    func getEvent(withId id: Int) async throws -> Event? {
        guard let token = try await tokenManager.getToken() else {
            throw NetworkError.invalidValue
        }

        // Configure the request
        let config = CustomRequestConfigurable(
            headers: [
                HTTPHeaders.authorization.rawValue: "Bearer \(token.accessToken)"
            ]
        )

        // Send the request and return the trip
        let eventResponse = try await networking.request(
            .handleTrips(id.description),
            responseType: EventResponse.self,
            method: .GET,
            config: config
        )
        
        let event = Event(from: eventResponse, trip: nil)
        return event
    }
    
    /**
     Updates an event by its ID.

     */
    func updateEvent(withId eventId: Int, and request: EventUpdate) async throws -> Event {
        guard let token = try await tokenManager.getToken() else {
            throw NetworkError.invalidValue
        }

        // Prepare updated event data
        let eventData: [String: Any] = [
            "name": request.name,
            "date": request.date,
            "note": (request.note ?? ""),
            "location": request.location ?? nil,
            "transitionFromPrevious": request.transitionFromPrevious
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: eventData)
        
        // Configure the request
        let config = CustomRequestConfigurable(
            headers: [
                HTTPHeaders.authorization.rawValue: "Bearer \(token.accessToken)",
                HTTPHeaders.accept.rawValue: MIMEType.JSON.rawValue,
                HTTPHeaders.contentType.rawValue: MIMEType.JSON.rawValue
            ],
            body: jsonData
        )
        
        // Send the request and return the updated event
        let eventResponse = try await networking.request(
            .handleEvents(eventId.description),
            responseType: EventResponse.self,
            method: .PUT,
            config: config
        )
        
        let event = Event(from: eventResponse, trip: nil)
        return event
    }

    /**
     Deletes an event by its ID.
     */
    func deleteEvent(withId eventId: Int) async throws {
        guard let token = try await tokenManager.getToken() else {
            throw NetworkError.invalidValue
        }

        // Configure the request
        let config = CustomRequestConfigurable(
            headers: [
                HTTPHeaders.authorization.rawValue: "Bearer \(token.accessToken)"
            ]
        )
        
        // Send the request to delete the event
        try await networking.request(
            .handleEvents(eventId.description),
            method: .DELETE,
            config: config
        )
    }
}
