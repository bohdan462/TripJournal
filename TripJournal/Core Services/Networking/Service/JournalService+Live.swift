//
//  JournalService+Live.swift
//  TripJournal
//
//  Created by Bohdan Tkachenko on 9/13/24.
//

//import Foundation
//import Combine
//import SwiftUI
//import SwiftData
//
//class JournalServiceLive {
//    
//    private let tokenManager: TokenManager
//    private let networkClient: NetworkClient
//    /**
//     Initializes a new instance of `JournalServiceLive`.
//
//     */
//    init(tokenManager: TokenManager, networkClient: NetworkClient) {
//        self.tokenManager = tokenManager
//        self.networkClient = networkClient
//        print("Initialized JournalServiceLive")
//    }
//    
//    // MARK: - Trip Methods
//    func createTrip(with request: TripCreate) async throws -> Trip {
//        guard let token = try await tokenManager.getToken() else {
//            throw NetworkError.invalidValue
//        }
//
//        // Prepare trip data for the request
//        let dateFormatter = ISO8601DateFormatter()
//        dateFormatter.formatOptions = [.withInternetDateTime]
//        
//        let tripData: [String: Any] = [
//            "name": request.name,
//            "start_date": dateFormatter.string(from: request.startDate),
//            "end_date": dateFormatter.string(from: request.endDate)
//        ]
//        
//        let jsonData = try JSONSerialization.data(withJSONObject: tripData)
//        
//        // Configure the request
//        let config = CustomRequestConfigurable(
//            headers: [
//                HTTPHeaders.authorization.rawValue: "Bearer \(token.accessToken)",
//                HTTPHeaders.accept.rawValue: MIMEType.JSON.rawValue,
//                HTTPHeaders.contentType.rawValue: MIMEType.JSON.rawValue
//            ],
//            body: jsonData
//        )
//        
//        // Send the request and return the created trip
//        let tripResponse = try await networkClient.request(
//            .trips,
//            responseType: TripResponse.self,
//            method: .POST,
//            config: config
//        )
//        
//        // Map TripResponse to Trip
//        let trip = Trip(from: tripResponse)
//            return trip
//    }
//
//    func getTrips() async throws -> [Trip] {
//        guard let token = try await tokenManager.getToken() else {
//            throw NetworkError.invalidValue
//        }
//
//        let config = CustomRequestConfigurable(
//            headers: [
//                HTTPHeaders.authorization.rawValue: "Bearer \(token.accessToken)",
//                HTTPHeaders.accept.rawValue: MIMEType.JSON.rawValue
//            ]
//        )
//        
//        // Send the request and return the trips
//        let tripsResponse = try await networkClient.request(
//            .trips,
//            responseType: [TripResponse].self,
//            method: .GET,
//            config: config
//        )
//        
//        let trips = tripsResponse.map {
//            Trip(from: $0)
//        }
//        
//        return trips
//    }
//
//    /**
//     Fetches a specific trip by its ID.
//
//     */
//    func getTrip(withId tripId: Int) async throws -> Trip {
//        guard let token = try await tokenManager.getToken() else {
//            throw NetworkError.invalidValue
//        }
//
//        // Configure the request
//        let config = CustomRequestConfigurable(
//            headers: [
//                HTTPHeaders.authorization.rawValue: "Bearer \(token.accessToken)"
//            ]
//        )
//
//        // Send the request and return the trip
//        let tripResponse = try await networkClient.request(
//            .handleTrips(tripId.description),
//            responseType: TripResponse.self,
//            method: .GET,
//            config: config
//        )
//        
//        let trip = Trip(from: tripResponse)
//        // Optionally, insert into model context if using SwiftData
//           // modelContext.insert(trip)
//           // try modelContext.save()
//        return trip
//    }
//
//    /**
//     Updates an existing trip with the provided details.
//
//     */
//    func updateTrip(withId tripId: Int, and request: TripUpdate) async throws -> Trip {
//        guard let token = try await tokenManager.getToken() else {
//            throw NetworkError.invalidValue
//        }
//
//        // Prepare updated trip data
//        let dateFormatter = ISO8601DateFormatter()
//        dateFormatter.formatOptions = [.withInternetDateTime]
//        
//        let tripData: [String: Any] = [
//            "name": request.name,
//            "start_date": dateFormatter.string(from: request.startDate),
//            "end_date": dateFormatter.string(from: request.endDate)
//        ]
//        
//        let jsonData = try JSONSerialization.data(withJSONObject: tripData)
//        
//        // Configure the request
//        let config = CustomRequestConfigurable(
//            headers: [
//                HTTPHeaders.authorization.rawValue: "Bearer \(token.accessToken)",
//                HTTPHeaders.accept.rawValue: MIMEType.JSON.rawValue,
//                HTTPHeaders.contentType.rawValue: MIMEType.JSON.rawValue
//            ],
//            body: jsonData
//        )
//        
//        // Send the request and return the updated trip
//        let tripResponse = try await networkClient.request(
//            .handleTrips(tripId.description),
//            responseType: TripResponse.self,
//            method: .PUT,
//            config: config
//        )
//        
//        let trip = Trip(from: tripResponse)
//        // Optionally, insert into model context if using SwiftData
//           // modelContext.insert(trip)
//           // try modelContext.save()
//        return trip
//    }
//
//    /**
//     Deletes a trip by its ID.
//
//     */
//    func deleteTrip(withId tripId: Int) async throws {
//        guard let token = try await tokenManager.getToken() else {
//            throw NetworkError.invalidValue
//        }
//
//        // Configure the request
//        let config = CustomRequestConfigurable(
//            headers: [
//                HTTPHeaders.authorization.rawValue: "Bearer \(token.accessToken)"
//            ]
//        )
//        
//        // Send the request to delete the trip
//        try await networkClient.request(
//            .handleTrips(tripId.description),
//            method: .DELETE,
//            config: config
//        )
//    }
//
//    // MARK: - Event Methods
//    
//    func createEvent(with request: EventCreate) async throws -> Event {
//        guard let token = try await tokenManager.getToken() else {
//            throw NetworkError.invalidValue
//        }
//            
//        // Prepare event data as a dictionary
//        let eventData: [String: Any] = [
//            "name": request.name,
//            "note": request.note ?? "",
//            "date": ISO8601DateFormatter().string(from: request.date),
//            "location": [
//                "latitude": request.location?.latitude ?? 0.0,
//                "longitude": request.location?.longitude ?? 0.0
//            ],
//            "trip_id": request.tripId,
//            "transitionFromPrevious": request.transitionFromPrevious ?? ""
//        ]
//        
//        // Serialize event data to JSON
//        let jsonData = try JSONSerialization.data(withJSONObject: eventData)
//
//        // Configure the request
//        let config = CustomRequestConfigurable(
//            headers: [
//                HTTPHeaders.authorization.rawValue: "Bearer \(token.accessToken)",
//                HTTPHeaders.accept.rawValue: MIMEType.JSON.rawValue,
//                HTTPHeaders.contentType.rawValue: MIMEType.JSON.rawValue
//            ],
//            body: jsonData
//        )
//
//        // Send the request and return the created event
//        let eventResponse = try await networkClient.request(
//            .events,
//            responseType: EventResponse.self,
//            method: .POST,
//            config: config
//        )
//        
//        let event = Event(from: eventResponse, trip: nil)
//        return event
//    }
//
//
//    func updateEvent(withId eventId: Int, tripId: Int, and request: EventUpdate) async throws -> Event {
//        guard let token = try await tokenManager.getToken() else {
//            throw NetworkError.invalidValue
//        }
//
//        // Prepare updated event data
//        let eventData: [String: Any] = [
//            "name": request.name,
//            "note": request.note,
//            "date": request.date,
//            "location": request.location,
//            "transitionFromPrevious": request.transitionFromPrevious
//        ]
//        
//        let jsonData = try JSONSerialization.data(withJSONObject: eventData)
//        
//        // Configure the request
//        let config = CustomRequestConfigurable(
//            headers: [
//                HTTPHeaders.authorization.rawValue: "Bearer \(token.accessToken)",
//                HTTPHeaders.accept.rawValue: MIMEType.JSON.rawValue,
//                HTTPHeaders.contentType.rawValue: MIMEType.JSON.rawValue
//            ],
//            body: jsonData
//        )
//        
//        // Send the request and return the updated event
//        let eventResponse = try await networkClient.request(
//            .handleEvents(eventId.description),
//            responseType: EventResponse.self,
//            method: .PUT,
//            config: config
//        )
//        
//        let event = Event(from: eventResponse, trip: nil)
//        return event
//    }
//
//    /**
//     Deletes an event by its ID.
//     */
//    func deleteEvent(withId eventId: Int) async throws {
//        guard let token = try await tokenManager.getToken() else {
//            throw NetworkError.invalidValue
//        }
//
//        // Configure the request
//        let config = CustomRequestConfigurable(
//            headers: [
//                HTTPHeaders.authorization.rawValue: "Bearer \(token.accessToken)"
//            ]
//        )
//        
//        // Send the request to delete the event
//        try await networkClient.request(
//            .handleEvents(eventId.description),
//            method: .DELETE,
//            config: config
//        )
//    }
//    
//    // MARK: - Media Methods
//    
//    /**
//     Creates media related to an event.
//
//     */
//    func createMedia(with request: MediaCreate) async throws -> Media {
//        guard let token = try await tokenManager.getToken() else {
//            throw NetworkError.invalidValue
//        }
//
//        // Prepare media data
//        let mediaData: [String: Any] = [
//            "caption": request.caption,
//            "event_id": request.eventID,
//            "base64Data": request.base64Data
//        ]
//        
//        let jsonData = try JSONSerialization.data(withJSONObject: mediaData)
//        
//        // Configure the request
//        let config = CustomRequestConfigurable(
//            headers: [
//                HTTPHeaders.authorization.rawValue: "Bearer \(token.accessToken)",
//                HTTPHeaders.accept.rawValue: MIMEType.JSON.rawValue,
//                HTTPHeaders.contentType.rawValue: MIMEType.JSON.rawValue
//            ],
//            body: jsonData
//        )
//
//        // Send the request and return the created media
//        let mediaResponse = try await networkClient.request(
//            .media,
//            responseType: MediaResponse.self,
//            method: .POST,
//            config: config
//        )
//        
//        let media = Media(from: mediaResponse)
//        return media
//    }
//    
//    /**
//     Deletes media by its ID.
//     */
//    func deleteMedia(withId mediaId: Int) async throws {
//        guard let token = try await tokenManager.getToken() else {
//            throw NetworkError.invalidValue
//        }
//
//        // Configure the request
//        let config = CustomRequestConfigurable(
//            headers: [
//                HTTPHeaders.authorization.rawValue: "Bearer \(token.accessToken)"
//            ]
//        )
//        
//        // Send the request to delete the media
//        try await networkClient.request(
//            .handleMedia(mediaId.description),
//            method: .DELETE,
//            config: config
//        )
//    }
//}
