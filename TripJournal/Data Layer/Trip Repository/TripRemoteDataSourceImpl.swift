//
//  TripRemoteDataSourceImpl.swift
//  TripJournal
//
//  Created by Bohdan Tkachenko on 9/24/24.
//

import Foundation

protocol TripRemoteDataSource {
    func getTrips() async throws -> [Trip]
    func createTrip(_ request: TripCreate) async throws -> Trip
    func getTrip(withId tripId: Int) async throws -> Trip
    func updateTrip(withId tripId: Int, and request: TripUpdate) async throws -> Trip
    func deleteTrip(withId tripId: Int) async throws
}


class TripRemoteDataSourceImpl: TripRemoteDataSource {
    
    // Dependencies
    private let networking: NetworkClient
    private let tokenManager: TokenManager

    // Initializer
    init(networking: NetworkClient, tokenManager: TokenManager) {
        self.networking = networking
        self.tokenManager = tokenManager
    }
//TODO: - Consider adding a timestamp check to avoid fetching remote trips every time the network is available. For example, only fetch trips if they haven't been synced in the last X minutes.
    // Methods
    func getTrips() async throws -> [Trip] {
        guard let token = try await tokenManager.getToken() else {
            throw NetworkError.invalidValue
        }
        let config = CustomRequestConfigurable(
            headers: [
                HTTPHeaders.authorization.rawValue: "Bearer \(token.accessToken)",
                HTTPHeaders.accept.rawValue: MIMEType.JSON.rawValue
            ]
        )
        
        // Send the request and return the trips
        let tripsResponse = try await networking.request(
            .trips,
            responseType: [TripResponse].self,
            method: .GET,
            config: config
        )
        
        let trips = tripsResponse.map {
            Trip(from: $0)
        }
        
        return trips
    }

    func createTrip(_ request: TripCreate) async throws -> Trip {
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
        let tripResponse = try await networking.request(
            .trips,
            responseType: TripResponse.self,
            method: .POST,
            config: config
        )
        
        // Map TripResponse to Trip
        let trip = Trip(from: tripResponse)
            return trip
    }
    
    func getTrip(withId tripId: Int) async throws -> Trip {
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
        let tripResponse = try await networking.request(
            .handleTrips(tripId.description),
            responseType: TripResponse.self,
            method: .GET,
            config: config
        )
        
        let trip = Trip(from: tripResponse)
        return trip
    }
    
    func updateTrip(withId tripId: Int, and request: TripUpdate) async throws -> Trip {
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
        let tripResponse = try await networking.request(
            .handleTrips(tripId.description),
            responseType: TripResponse.self,
            method: .PUT,
            config: config
        )
        
        let trip = Trip(from: tripResponse)
        return trip
    }
    
    func deleteTrip(withId tripId: Int) async throws {
        guard let token = try await tokenManager.getToken() else {
            throw NetworkError.invalidValue
        }

        let config = CustomRequestConfigurable(
            headers: [
                HTTPHeaders.authorization.rawValue: "Bearer \(token.accessToken)"
            ]
        )
        
        try await networking.request(
            .handleTrips(tripId.description),
            method: .DELETE,
            config: config
        )
    }
    
}
