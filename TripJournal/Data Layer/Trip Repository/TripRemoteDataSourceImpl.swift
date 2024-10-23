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
    
    func getTrips() async throws -> [Trip] {
        let config = try await fetchConfig(additionalHeaders:
                                            [HTTPHeaders.accept.rawValue: MIMEType.JSON.rawValue])
        do {
            let tripsResponse = try await networking.request(
                .trips,
                responseType: [TripResponse].self,
                method: .GET,
                config: config
            )
            
            let trips = tripsResponse.map { Trip(from: $0) }
            return trips
        } catch {
            throw RemoteDataSourceError.networkError(error)
        }
    }
    
    func createTrip(_ request: TripCreate) async throws -> Trip {
        let config = try await fetchConfig(withBody:
                                            try tripData(from: request),
                                           additionalHeaders:
                                            [HTTPHeaders.accept.rawValue: MIMEType.JSON.rawValue,
                                             HTTPHeaders.contentType.rawValue: MIMEType.JSON.rawValue])

        do {
            let tripResponse = try await networking.request(
                .trips,
                responseType: TripResponse.self,
                method: .POST,
                config: config
            )
            
            let trip = Trip(from: tripResponse)
            return trip
        } catch {
            throw RemoteDataSourceError.networkError(error)
        }
    }
    
    func getTrip(withId tripId: Int) async throws -> Trip {
        let config = try await fetchConfig()
        
        do {
            let tripResponse = try await networking.request(
                .handleTrips(tripId.description),
                responseType: TripResponse.self,
                method: .GET,
                config: config
            )
            
            let trip = Trip(from: tripResponse)
            return trip
        } catch {
            throw RemoteDataSourceError.networkError(error)
        }
    }
    
    func updateTrip(withId tripId: Int, and request: TripUpdate) async throws -> Trip {
        let config = try await fetchConfig(withBody:
                                            try tripData(from: request),
                                           additionalHeaders:
                                            [HTTPHeaders.accept.rawValue: MIMEType.JSON.rawValue,
                                             HTTPHeaders.contentType.rawValue: MIMEType.JSON.rawValue])
        
        
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
        let config = try await fetchConfig()
        
        do {
            try await networking.request(
                .handleTrips(tripId.description),
                method: .DELETE,
                config: config
            )
        } catch {
            throw RemoteDataSourceError.networkError(error)
        }
    }
    
    // MARK: - Helper Methods
    private func fetchConfig(
        withBody body: Data? = nil,
        additionalHeaders: [String: String]? = nil
    ) async throws -> RequestConfigurable {
        guard let token = try await tokenManager.getToken() else {
            throw RemoteDataSourceError.invalidToken
        }

        let baseHeaders: [String: String] = [
            HTTPHeaders.authorization.rawValue: "Bearer \(token.accessToken)"
        ]

        var config: RequestConfigurable = CustomRequestConfigurable(headers: baseHeaders, body: body)

        if let extraHeaders = additionalHeaders {
            config = config.withAdditionalHeaders(extraHeaders)
        }
        
        return config
    }
    
    
    private func tripData(from request: TripCreate) throws -> Data {
        let tripData: [String: Any] = [
            "name": request.name,
            "start_date": request.startDate,
            "end_date": request.endDate
        ]
        do {
            let data = try JSONSerialization.data(withJSONObject: tripData)
            return data
        } catch {
            throw RemoteDataSourceError.decodingError(error)
        }
    }
    
    private func tripData(from request: TripUpdate) throws -> Data {
        let tripData: [String: Any] = [
            "name": request.name,
            "start_date": request.startDate,
            "end_date": request.endDate
        ]
        do {
            let data = try JSONSerialization.data(withJSONObject: tripData)
            return data
        } catch {
            throw RemoteDataSourceError.decodingError(error)
        }
        
    }
}
