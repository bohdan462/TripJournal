import Foundation
import MapKit

struct TripCreate: Codable {
    let name: String
    let startDate: String
    let endDate: String
    
    enum CodingKeys: String, CodingKey {
        case name
        case startDate = "start_date"
        case endDate = "end_date"
    }
    
    init(name: String, startDate: Date, endDate: Date) {
        self.name = name
        self.startDate = startDate.toString()
        self.endDate = endDate.toString()
    }
}

struct TripUpdate: Codable {
    let name: String
    let startDate: String
    let endDate: String
    
    enum CodingKeys: String, CodingKey {
        case name
        case startDate = "start_date"
        case endDate = "end_date"
    }
    
    init(name: String, startDate: Date, endDate: Date) {
        self.name = name
        self.startDate = startDate.toString()
        self.endDate = endDate.toString()
    }
}

struct TripResponse: Codable {
    let tripId: Int
    let name: String
    let startDate: String
    let endDate: String
    let events: [EventResponse]
    
    enum CodingKeys: String, CodingKey {
        case tripId = "id"
        case name
        case startDate = "start_date"
        case endDate = "end_date"
        case events
    }
    
    init(tripId: Int, name: String, startDate: Date, endDate: Date, events: [EventResponse]) {
        self.tripId = tripId
        self.name = name
        self.startDate = startDate.toString()
        self.endDate = endDate.toString()
        self.events = events
    }
}

struct EventCreate: Codable {
    let tripId: Int
    let name: String
    let date: String
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
    
    init(tripId: Int, name: String, date: Date, note: String?, location: LocationResponse?, transitionFromPrevious: String?) {
        self.tripId = tripId
        self.name = name
        self.date = date.toString()
        self.note = note
        self.location = location
        self.transitionFromPrevious = transitionFromPrevious
    }

}

struct EventUpdate: Codable {
    let name: String
    let date: String
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
    
    init(name: String, date: Date, note: String?, location: LocationResponse?, transitionFromPrevious: String?) {
        self.name = name
        self.date = date.toString()
        self.note = note
        self.location = location
        self.transitionFromPrevious = transitionFromPrevious
    }
}

struct EventResponse: Codable {
    let eventId: Int
    let name: String
    let date: String
    let note: String?
    let location: LocationResponse?
    let transitionFromPrevious: String?
    let medias: [MediaResponse]
    
    enum CodingKeys: String, CodingKey {
        case eventId = "id"
        case name
        case date
        case note
        case location
        case transitionFromPrevious = "transition_from_previous"
        case medias
    }
    
    init(eventId: Int, name: String, date: Date, note: String?, location: LocationResponse?, transitionFromPrevious: String?, medias: [MediaResponse]) {
        self.eventId = eventId
        self.name = name
        self.date = date.toString()
        self.note = note
        self.location = location
        self.transitionFromPrevious = transitionFromPrevious
        self.medias = medias
    }
}

struct MediaCreate: Codable {
    let caption: String
    let base64Data: String
    let eventId: Int
    
    enum CodingKeys: String, CodingKey {
        case caption
        case base64Data = "base64_data"
        case eventId = "event_id"
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
