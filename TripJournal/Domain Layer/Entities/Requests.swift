import Foundation
import MapKit

struct TripCreate: Codable {
    let name: String
    let startDate: Date
    let endDate: Date
    
    enum CodingKeys: String, CodingKey {
        case name
        case startDate = "start_date"
        case endDate = "end_date"
    }
}

struct TripUpdate: Codable {
    let name: String
    let startDate: Date
    let endDate: Date
    
    enum CodingKeys: String, CodingKey {
        case name
        case startDate = "start_date"
        case endDate = "end_date"
    }
}

struct TripResponse: Codable {
    let id: Int
    let name: String
    let startDate: Date
    let endDate: Date
    let events: [EventResponse]
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case startDate = "start_date"
        case endDate = "end_date"
        case events
    }
}

struct EventCreate: Codable {
    let tripId: Int
    let name: String
    let date: Date
    let note: String?
    let location: LocationResponse?
    let transitionFromPrevious: String?
    
    enum CodingKeys: String, CodingKey {
        case tripId = "trip_id"
        case name
        case note
        case date
        case location
        case transitionFromPrevious = "transition_from_previous"
    }
    
    
}

struct EventUpdate: Codable {
    let name: String
    let date: Date
    let note: String?
    let location: LocationResponse?
    let transitionFromPrevious: String?
    
    enum CodingKeys: String, CodingKey {
        case name
        case date
        case note
        case location
        case transitionFromPrevious = "transition_from_previous"
    }
}

struct EventResponse: Codable {
    let id: Int
    let name: String
    let date: Date
    let note: String?
    let location: LocationResponse?
    let transitionFromPrevious: String?
    let medias: [MediaResponse]
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case date
        case note
        case location
        case transitionFromPrevious = "transition_from_previous"
        case medias
    }
}

struct MediaCreate: Codable {
    let caption: String
    let base64Data: String
    let eventID: Int
    
    enum CodingKeys: String, CodingKey {
        case caption
        case base64Data = "base64_data"
        case eventID = "event_id"
    }
}

/// A response object received after creating a media.
struct MediaResponse: Codable {
    let id: Int
    let caption: String
    let url: String
}

struct LocationResponse: Codable {
    var latitude: Double
    var longitude: Double
    var address: String?
}
