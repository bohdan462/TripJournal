//
//  NetworkService.swift
//  TripJournal
//
//  Created by Bohdan Tkachenko on 9/13/24.
//

import Foundation

// MARK: - TripRouter
/// Defines API endpoints and related information like HTTP methods.
enum TripRouter {
    static let base = "http://localhost:8000/"
    
    case register
    case login
    case trips
    case handleTrips(String)
    case events
    case handleEvents(String)
    case media
    case handleMedia(String)
//    case refreshToken
    
    // MARK: - Endpoints
    private var path: String {
        switch self {
        case .register:
            return TripRouter.base + "register"
        case .login:
            return TripRouter.base + "token"
        case .trips:
            return TripRouter.base + "trips"
        case .handleTrips(let tripId):
            return TripRouter.base + "trips/\(tripId)"
        case .events:
            return TripRouter.base + "events"
        case .handleEvents(let eventId):
            return TripRouter.base + "events/\(eventId)"
        case .media:
            return TripRouter.base + "media"
        case .handleMedia(let mediaId):
            return TripRouter.base + "media/\(mediaId)"
//        case .refreshToken:
//            return TripRouter.base + "toke/refresh"
            
        }

    }
    
    var url: URL {
        return URL(string: path)!
    }
}
