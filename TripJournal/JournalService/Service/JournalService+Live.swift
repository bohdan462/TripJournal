//
//  JournalService+Live.swift
//  TripJournal
//
//  Created by Bohdan Tkachenko on 9/13/24.
//

import Foundation
import Combine

/**
 `JournalServiceLive` is a concrete implementation of the `JournalService` protocol. This class handles all interactions with the backend related to trips, events, and media. It uses `TokenManager` to manage authentication tokens and `NetworkClient` to send HTTP requests.

 The class is responsible for making network requests to create, read, update, and delete (CRUD) trips, events, and media. It relies on the `TokenManager` to obtain a valid token and the `NetworkClient` to handle HTTP requests.

 - Dependencies:
    - `TokenManager`: Handles authentication tokens.
    - `NetworkClient`: Used for making network requests.
    - `AuthService`: Handles authentication state.

 - It exposes the authentication status using `isAuthenticated`, a `Combine` publisher that informs whether a user is logged in.

 ## Key Functions:
 - `createTrip()`: Sends a request to create a new trip.
 - `getTrips()`: Fetches all trips.
 - `getTrip(withId:)`: Fetches a specific trip by its ID.
 - `updateTrip(withId:and:)`: Updates an existing trip.
 - `deleteTrip(withId:)`: Deletes a trip.
 - `createEvent()`: Creates a new event for a trip.
 - `updateEvent(withId:and:)`: Updates an event.
 - `deleteEvent(withId:)`: Deletes an event.
 - `createMedia()`: Uploads media related to an event.
 - `deleteMedia(withId:)`: Deletes media.

 ## Initialization:
 - `tokenManager`: Manages tokens for authentication.
 - `networkClient`: Sends HTTP requests.
 - `authService`: Provides authentication-related services.
 */
class JournalServiceLive: JournalService {
    
    private let tokenManager: TokenManager
    private let networkClient: NetworkClient
    let authService: AuthService
    
    // Publisher that emits the authentication status (whether a user is logged in).
    var isAuthenticated: AnyPublisher<Bool, Never> {
        authService.isAuthenticated
    }
    
    /**
     Initializes a new instance of `JournalServiceLive`.

     - Parameters:
        - tokenManager: A `TokenManager` instance responsible for managing tokens.
        - networkClient: A `NetworkClient` instance used to perform HTTP requests.
        - auth: An `AuthService` instance to handle authentication.
     */
    init(tokenManager: TokenManager, networkClient: NetworkClient, auth: AuthService) {
        self.tokenManager = tokenManager
        self.networkClient = networkClient
        self.authService = auth
    }
    
    // MARK: - Trip Methods
    
    /**
     Creates a new trip with the given details.

     - Parameter request: A `TripCreate` object containing trip details.
     - Throws: `NetworkError.invalidValue` if token retrieval fails.
     - Returns: The created `Trip` object.
     */
    func createTrip(with request: TripCreate) async throws -> Trip {
        guard let token = try await tokenManager.getToken() else {
            throw NetworkError.invalidValue
        }

        // Prepare trip data for the request
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime]
        
        let tripData: [String: Any] = [
            "name": request.name,
            "start_date": dateFormatter.string(from: request.startDate),
            "end_date": dateFormatter.string(from: request.endDate)
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: tripData)
        
        // Configure the request
        let config = CustomRequestConfigurable(
            headers: [
                HTTPHeaders.authorization.rawValue: "Bearer \(token.accessToken)",
                HTTPHeaders.accept.rawValue: MIMEType.JSON.rawValue,
                HTTPHeaders.contentType.rawValue: MIMEType.JSON.rawValue
            ],
            body: jsonData
        )
        
        // Send the request and return the created trip
        return try await networkClient.request(
            .trips,
            responseType: Trip.self,
            method: .POST,
            config: config
        )
    }
    
    /**
     Fetches a list of all trips.
     
     - Throws: `NetworkError.invalidValue` if token retrieval fails.
     - Returns: An array of `Trip` objects.
     */
    func getTrips() async throws -> [Trip] {
        guard let token = try await tokenManager.getToken() else {
            throw NetworkError.invalidValue
        }
        
        // Configure the request
        let config = CustomRequestConfigurable(
            headers: [
                HTTPHeaders.authorization.rawValue: "Bearer \(token.accessToken)",
                HTTPHeaders.accept.rawValue: MIMEType.JSON.rawValue
            ]
        )
        
        // Send the request and return the trips
        return try await networkClient.request(
            .trips,
            responseType: [Trip].self,
            method: .GET,
            config: config
        )
    }

    /**
     Fetches a specific trip by its ID.
     
     - Parameter tripId: The ID of the trip to be fetched.
     - Throws: `NetworkError.invalidValue` if token retrieval fails.
     - Returns: The `Trip` object.
     */
    func getTrip(withId tripId: Trip.ID) async throws -> Trip {
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
        return try await networkClient.request(
            .handleTrips(tripId.description),
            responseType: Trip.self,
            method: .GET,
            config: config
        )
    }

    /**
     Updates an existing trip with the provided details.
     
     - Parameters:
        - tripId: The ID of the trip to update.
        - request: The `TripUpdate` object containing updated details.
     - Throws: `NetworkError.invalidValue` if token retrieval fails.
     - Returns: The updated `Trip` object.
     */
    func updateTrip(withId tripId: Trip.ID, and request: TripUpdate) async throws -> Trip {
        guard let token = try await tokenManager.getToken() else {
            throw NetworkError.invalidValue
        }

        // Prepare updated trip data
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime]
        
        let tripData: [String: Any] = [
            "name": request.name,
            "start_date": dateFormatter.string(from: request.startDate),
            "end_date": dateFormatter.string(from: request.endDate)
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: tripData)
        
        // Configure the request
        let config = CustomRequestConfigurable(
            headers: [
                HTTPHeaders.authorization.rawValue: "Bearer \(token.accessToken)",
                HTTPHeaders.accept.rawValue: MIMEType.JSON.rawValue,
                HTTPHeaders.contentType.rawValue: MIMEType.JSON.rawValue
            ],
            body: jsonData
        )
        
        // Send the request and return the updated trip
        return try await networkClient.request(
            .handleTrips(tripId.description),
            responseType: Trip.self,
            method: .PUT,
            config: config
        )
    }

    /**
     Deletes a trip by its ID.
     
     - Parameter tripId: The ID of the trip to be deleted.
     - Throws: `NetworkError.invalidValue` if token retrieval fails.
     */
    func deleteTrip(withId tripId: Trip.ID) async throws {
        guard let token = try await tokenManager.getToken() else {
            throw NetworkError.invalidValue
        }

        // Configure the request
        let config = CustomRequestConfigurable(
            headers: [
                HTTPHeaders.authorization.rawValue: "Bearer \(token.accessToken)"
            ]
        )
        
        // Send the request to delete the trip
        try await networkClient.request(
            .handleTrips(tripId.description),
            method: .DELETE,
            config: config
        )
    }

    // MARK: - Event Methods
    
    /**
     Creates a new event for a specific trip.
     
     - Parameter request: An `EventCreate` object containing event details.
     - Throws: `NetworkError.invalidValue` if token retrieval fails.
     - Returns: The created `Event` object.
     */
    func createEvent(with request: EventCreate) async throws -> Event {
        guard let token = try await tokenManager.getToken() else {
            throw NetworkError.invalidValue
        }

        // Prepare event data
        let eventData: [String: Any] = [
            "tripId": request.tripId,
            "name": request.name,
            "note": request.note,
            "date": request.date,
            "location": request.location,
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

        // Send the request and return the created event
        return try await networkClient.request(
            .events,
            responseType: Event.self,
            method: .POST,
            config: config
        )
    }
    
    /**
     Updates an event by its ID.
     
     - Parameters:
        - eventId: The ID of the event to update.
        - request: An `EventUpdate` object containing updated event details.
     - Throws: `NetworkError.invalidValue` if token retrieval fails.
     - Returns: The updated `Event` object.
     */
    func updateEvent(withId eventId: Event.ID, and request: EventUpdate) async throws -> Event {
        guard let token = try await tokenManager.getToken() else {
            throw NetworkError.invalidValue
        }

        // Prepare updated event data
        let eventData: [String: Any] = [
            "name": request.name,
            "note": request.note,
            "date": request.date,
            "location": request.location,
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
        return try await networkClient.request(
            .handleEvents(eventId.description),
            responseType: Event.self,
            method: .PUT,
            config: config
        )
    }

    /**
     Deletes an event by its ID.
     
     - Parameter eventId: The ID of the event to be deleted.
     - Throws: `NetworkError.invalidValue` if token retrieval fails.
     */
    func deleteEvent(withId eventId: Event.ID) async throws {
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
        try await networkClient.request(
            .handleEvents(eventId.description),
            method: .DELETE,
            config: config
        )
    }
    
    // MARK: - Media Methods
    
    /**
     Creates media related to an event.
     
     - Parameter request: A `MediaCreate` object containing media details.
     - Throws: `NetworkError.invalidValue` if token retrieval fails.
     - Returns: The created `Media` object.
     */
    func createMedia(with request: MediaCreate) async throws -> Media {
        guard let token = try await tokenManager.getToken() else {
            throw NetworkError.invalidValue
        }

        // Prepare media data
        let mediaData: [String: Any] = [
            "eventId": request.eventId,
            "base64Data": request.base64Data
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: mediaData)
        
        // Configure the request
        let config = CustomRequestConfigurable(
            headers: [
                HTTPHeaders.authorization.rawValue: "Bearer \(token.accessToken)",
                HTTPHeaders.accept.rawValue: MIMEType.JSON.rawValue,
                HTTPHeaders.contentType.rawValue: MIMEType.JSON.rawValue
            ],
            body: jsonData
        )

        // Send the request and return the created media
        return try await networkClient.request(
            .media,
            responseType: Media.self,
            method: .POST,
            config: config
        )
    }
    
    /**
     Deletes media by its ID.
     
     - Parameter mediaId: The ID of the media to be deleted.
     - Throws: `NetworkError.invalidValue` if token retrieval fails.
     */
    func deleteMedia(withId mediaId: Media.ID) async throws {
        guard let token = try await tokenManager.getToken() else {
            throw NetworkError.invalidValue
        }

        // Configure the request
        let config = CustomRequestConfigurable(
            headers: [
                HTTPHeaders.authorization.rawValue: "Bearer \(token.accessToken)"
            ]
        )
        
        // Send the request to delete the media
        try await networkClient.request(
            .handleMedia(mediaId.description),
            method: .DELETE,
            config: config
        )
    }
}
