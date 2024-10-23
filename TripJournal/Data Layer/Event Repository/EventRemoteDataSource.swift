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
        let config = try await fetchConfig(withBody:
                                        eventData(from: request),
                                        additionalHeaders: [
                                        HTTPHeaders.accept.rawValue: MIMEType.JSON.rawValue,
                                        HTTPHeaders.contentType.rawValue: MIMEType.JSON.rawValue
                                        ])
        do {
            let eventResponse = try await networking.request(
                .events,
                responseType: EventResponse.self,
                method: .POST,
                config: config
            )
            
            let event = Event(from: eventResponse, trip: nil)
            return event
        } catch {
            throw RemoteDataSourceError.networkError(error)
        }
    }

    func getEvent(withId id: Int) async throws -> Event? {
        let config = try await fetchConfig()
        do {
            let eventResponse = try await networking.request(
                .handleEvents(id.description),
                responseType: EventResponse.self,
                method: .GET,
                config: config
            )
            
            let event = Event(from: eventResponse, trip: nil)
            return event
        } catch {
            throw RemoteDataSourceError.networkError(error)
        }
    }

    func updateEvent(withId eventId: Int, and request: EventUpdate) async throws -> Event {
        let config = try await fetchConfig(withBody: eventData(from: request), additionalHeaders: [HTTPHeaders.accept.rawValue: MIMEType.JSON.rawValue,  HTTPHeaders.contentType.rawValue: MIMEType.JSON.rawValue])
        do {
            // Send the request and return the updated event
            let eventResponse = try await networking.request(
                .handleEvents(eventId.description),
                responseType: EventResponse.self,
                method: .PUT,
                config: config
            )
            
            let event = Event(from: eventResponse, trip: nil)
            return event
        } catch {
            throw RemoteDataSourceError.networkError(error)
        }
    }

    func deleteEvent(withId eventId: Int) async throws {
        let config = try await fetchConfig()
        do {
            try await networking.request(
                .handleEvents(eventId.description),
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
    
    private func eventData(from request: EventCreate) throws -> Data {
        
        let eventData: [String: Any] = [
            "name": request.name,
            "note": request.note ?? "",
            "date": request.date,
            "location": [
                "latitude": request.location?.latitude ?? 0,
                "longitude": request.location?.longitude ?? 0
            ],
            "trip_id": request.tripId,
            "transitionFromPrevious": request.transitionFromPrevious ?? ""
        ]
        
        do {
            let data = try JSONSerialization.data(withJSONObject: eventData)
            return data
        } catch {
            throw RemoteDataSourceError.decodingError(error)
        }
    }
    
    private func eventData(from request: EventUpdate) throws -> Data {
        
        let eventData: [String: Any] = [
            "name": request.name,
            "date": request.date,
            "note": (request.note ?? ""),
            "location": [
                "latitude": request.location?.latitude ?? 0,
                "longitude": request.location?.longitude ?? 0
            ],
            "transitionFromPrevious": request.transitionFromPrevious ?? ""
        ]
        
        do {
            let data = try JSONSerialization.data(withJSONObject: eventData)
            return data
        } catch {
            throw RemoteDataSourceError.decodingError(error)
        }
    }
}
