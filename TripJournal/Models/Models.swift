import Foundation
import MapKit
import SwiftData

/// Represents  a token that is returns when the user authenticates.
struct Token: Codable {
    let accessToken: String
    let tokenType: String
    var expirationDate: Date?
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case expirationDate
    }
    
    static func defaultDate() -> Date {
        let calendar = Calendar.current
        let currentDate = Date()
        return calendar.date(byAdding: .hour, value: 1, to: currentDate) ?? currentDate
    }
}

@Model
final class Trip: Identifiable, Sendable {
    @Attribute(.unique)
    let id: UUID
    var tripId: Int?
    var name: String
    var startDate: Date
    var endDate: Date
    @Relationship(deleteRule: .cascade)
    var events: [Event]
    var isSynced: Bool
    
    init(tripId: Int? = nil, name: String, startDate: Date, endDate: Date, events: [Event] = [], isSynced: Bool = false) {
        self.id = UUID()
        self.tripId = tripId
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
        self.events = events
        self.isSynced = isSynced
    }
    
    convenience init(from response: TripResponse) {
        self.init(
            tripId: response.id,
            name: response.name,
            startDate: response.startDate,
            endDate: response.endDate,
            isSynced: true
        )
    }
    
}

/// Represents an event in a trip.
@Model
final class Event: Identifiable, Sendable {
    @Attribute(.unique)
    let id: UUID
    var evetId: Int?
    var name: String
    var note: String?
    var date: Date
    var location: Location?
    @Relationship(deleteRule: .nullify, inverse: \Trip.events)
    var tripID: Int
    @Relationship(deleteRule: .cascade)
    var medias: [Media]
    var transitionFromPrevious: String?
    var isSynced: Bool
    
    init(id: UUID = UUID(), eventId: Int? = nil, name: String, note: String? = nil, date: Date, location: Location? = nil, tripID: Int, medias: [Media], transitionFromPrevious: String? = nil, isSynced: Bool = false) {
        self.id = id
        self.evetId = eventId
        self.name = name
        self.note = note
        self.date = date
        self.location = location
        self.tripID = tripID
        self.transitionFromPrevious = transitionFromPrevious
        self.isSynced = isSynced
        self.medias = medias
    }
    
    /// Convenience initializer to map from `EventResponse`
    convenience init(from response: EventResponse, tripID: Int) {
        // Initialize with an empty medias array
        self.init(
            eventId: response.id,
            name: response.name,
            note: response.note,
            date: response.date,
            location: response.location != nil ? Location(latitude: response.location!.latitude, longitude: response.location!.longitude) : nil,
            tripID: tripID,
            medias: [], // Provide an empty array
            transitionFromPrevious: response.transitionFromPrevious,
            isSynced: true
        )
        
        // Insert the Event into the modelContext
        
        // Map and append Media objects
        for mediaResponse in response.medias {
            let media = Media(from: mediaResponse)
            self.medias.append(media)
            // Ensure Media is inserted into the context
        }
        
        // Insert Location if it exists
    }
}

/// Represents a location.
///
///  add a method for reverse-geocoding the address (optional but useful for future features like event location display).
@Model
final class Location: Sendable {
    var latitude: Double
    var longitude: Double
    var address: String?
    
    var coordinate: CLLocationCoordinate2D {
        return .init(latitude: latitude, longitude: longitude)
    }
    
    init(latitude: Double, longitude: Double, address: String? = nil) {
        self.latitude = latitude
        self.longitude = longitude
        self.address = address
    }
}

/// Represents a media with a URL.
@Model
final class Media: Identifiable, Sendable {
    @Attribute(.unique)
    let id: UUID
    var mediaId: Int?
    var caption: String?
    var url: URL?
    
    init(id: UUID = UUID(), mediaId: Int? = nil, caption: String? = nil, url: URL? = nil) {
        self.id = id
        self.url = url
        self.caption = caption
    }
    
    /// Convenience initializer to map from `MediaResponse`
    convenience init(from response: MediaResponse) {
        self.init(
            mediaId: response.id,
            caption: response.caption,
            url: URL(string: response.url)
        )
    }
}



