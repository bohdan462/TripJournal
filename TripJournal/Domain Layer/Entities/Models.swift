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

@Model
final class Event: Identifiable, Sendable, Hashable {
    @Attribute(.unique)
    let id: UUID
    var eventId: Int?
    var name: String
    var note: String?
    var date: Date
    var location: Location?
    @Relationship(deleteRule: .nullify)
    var trip: Trip? // Reference to the Trip model
    var tripID: Int? // Remote trip ID
    var medias: [Media]
    var transitionFromPrevious: String?
    var isSynced: Bool
    var isDeleted: Bool // For offline deletions

    init(
        id: UUID = UUID(),
        eventId: Int? = nil,
        name: String,
        note: String? = nil,
        date: Date,
        location: Location? = nil,
        trip: Trip?,
        tripID: Int?,
        medias: [Media] = [],
        transitionFromPrevious: String? = nil,
        isSynced: Bool = false,
        isDeleted: Bool = false
    ) {
        self.id = id
        self.eventId = eventId
        self.name = name
        self.note = note
        self.date = date
        self.location = location
        self.trip = trip
        self.tripID = tripID
        self.medias = medias
        self.transitionFromPrevious = transitionFromPrevious
        self.isSynced = isSynced
        self.isDeleted = isDeleted
    }
    
    convenience init(from response: EventResponse, trip: Trip?) {
        self.init(
            eventId: response.id,
            name: response.name,
            note: response.note,
            date: response.date,
            location: response.location != nil ? Location(latitude: response.location!.latitude, longitude: response.location!.longitude) : nil,
            trip: trip, // Set the trip relationship
            tripID: trip?.tripId,
            medias: [], // Will be populated later
            transitionFromPrevious: response.transitionFromPrevious,
            isSynced: true
        )
        
        // Map and append Media objects
        for mediaResponse in response.medias {
            let media = Media(from: mediaResponse)
            media.event = self
            self.medias.append(media)
        }
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
        var event: Event? // Reference to the Event model
        var isSynced: Bool
        var isDeleted: Bool // For offline deletions

        init(
            id: UUID = UUID(),
            mediaId: Int? = nil,
            caption: String? = nil,
            url: URL? = nil,
            event: Event?,
            isSynced: Bool = false,
            isDeleted: Bool = false
        ) {
            self.id = id
            self.mediaId = mediaId
            self.caption = caption
            self.url = url
            self.event = event
            self.isSynced = isSynced
            self.isDeleted = isDeleted
        }
    
    /// Convenience initializer to map from `MediaResponse`
    convenience init(from response: MediaResponse) {
        self.init(
            mediaId: response.id,
            caption: response.caption,
            url: URL(string: response.url),
            event: nil
        )
    }
}



