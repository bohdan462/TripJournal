import Foundation

/**
 The `JournalServiceFacade` class serves as a façade to encapsulate the interaction between the `JournalService` and the `CacheService`. It simplifies and abstracts operations related to trips, events, and media, while handling caching logic and network monitoring transparently. This class provides methods for creating, retrieving, updating, and deleting trips, events, and media, as well as managing user authentication.

 ## Key Features:
 - Provides a clean interface to interact with the `JournalServiceLive` and `CacheService`.
 - Handles caching of trip, event, and media data.
 - Monitors network connection to ensure proper data retrieval.
 - Manages user authentication by delegating it to the underlying `JournalServiceLive` implementation.
 
 ## Dependencies:
 - `JournalServiceLive`: Responsible for handling all live network operations.
 - `CacheService`: Manages caching of trips, events, and media for offline access.
 
 ## Methods:
 - **Trip Methods**: `createTrip`, `getTrips`, `getTrip`, `updateTrip`, `deleteTrip`
 - **Event Methods**: `createEvent`, `updateEvent`, `deleteEvent`
 - **Media Methods**: `createMedia`, `deleteMedia`
 - **Auth Methods**: `register`, `logIn`, `logOut`
 - **Utility Methods**: `clearCache`
 */
class JournalServiceFacade {
    
    private let journalService: JournalServiceLive
    private let cacheService: CacheService

    /**
     Initializes a new instance of the `JournalServiceFacade`.
     
     - Parameters:
        - journalService: An instance of `JournalServiceLive` responsible for network requests.
        - cacheService: An instance of `CacheService` responsible for managing cached data.
     */
    init(journalService: JournalServiceLive, cacheService: CacheService) {
        self.journalService = journalService
        self.cacheService = cacheService
    }

    // MARK: - Trip Methods

    /**
     Creates a new trip.
     
     - Parameter request: A `TripCreate` object containing the trip details.
     - Throws: An error if the trip creation fails.
     - Returns: A newly created `Trip` object.
     */
    func createTrip(with request: TripCreate) async throws -> Trip {
        let trip = try await journalService.createTrip(with: request)
        cacheService.cacheData(trip, for: trip.id.description, expiresIn: 3600) // Cache for 1 hour
        return trip
    }

    /**
     Retrieves all trips. If the device is offline, cached trips will be returned.
     
     - Throws: `NetworkError.noConnection` if the device is offline and no cached trips are available.
     - Returns: An array of `Trip` objects.
     */
    func getTrips() async throws -> [Trip] {
        // Check network status
        if !NetworkMonitor.shared.isConnected {
            // No network, return cached trips
            if let cachedTrips: [Trip] = cacheService.getCachedData(for: "allTrips") {
                return cachedTrips
            }
            throw NetworkError.noConnection
        }

        // Network is available, proceed with API call
        let trips = try await journalService.getTrips()
        cacheService.cacheData(trips, for: "allTrips", expiresIn: 3600) // Cache for 1 hour
        return trips
    }

    /**
     Retrieves a specific trip by its ID.
     
     - Parameter tripId: The ID of the trip to retrieve.
     - Throws: An error if the trip retrieval fails.
     - Returns: A `Trip` object.
     */
    func getTrip(withId tripId: Trip.ID) async throws -> Trip {
        if let cachedTrip: Trip = cacheService.getCachedData(for: tripId.description) {
            return cachedTrip
        }
        let trip = try await journalService.getTrip(withId: tripId)
        cacheService.cacheData(trip, for: trip.id.description, expiresIn: 3600) // Cache for 1 hour
        return trip
    }

    /**
     Updates an existing trip.
     
     - Parameters:
        - tripId: The ID of the trip to update.
        - request: A `TripUpdate` object containing the updated trip details.
     - Throws: An error if the trip update fails.
     - Returns: The updated `Trip` object.
     */
    func updateTrip(withId tripId: Trip.ID, and request: TripUpdate) async throws -> Trip {
        let updatedTrip = try await journalService.updateTrip(withId: tripId, and: request)
        cacheService.cacheData(updatedTrip, for: updatedTrip.id.description, expiresIn: 3600) // Cache for 1 hour
        return updatedTrip
    }

    /**
     Deletes a trip by its ID.
     
     - Parameter tripId: The ID of the trip to delete.
     - Throws: An error if the trip deletion fails.
     */
    func deleteTrip(withId tripId: Trip.ID) async throws {
        try await journalService.deleteTrip(withId: tripId)
        cacheService.clearCache(for: tripId.description) // Remove trip from cache
    }

    // MARK: - Event Methods

    /**
     Creates a new event.
     
     - Parameter request: An `EventCreate` object containing the event details.
     - Throws: An error if the event creation fails.
     - Returns: A newly created `Event` object.
     */
    func createEvent(with request: EventCreate) async throws -> Event {
        let event = try await journalService.createEvent(with: request)
        cacheService.cacheData(event, for: event.id.description, expiresIn: 3600) // Cache for 1 hour
        return event
    }

    /**
     Updates an existing event.
     
     - Parameters:
        - eventId: The ID of the event to update.
        - request: An `EventUpdate` object containing the updated event details.
     - Throws: An error if the event update fails.
     - Returns: The updated `Event` object.
     */
    func updateEvent(withId eventId: Event.ID, and request: EventUpdate) async throws -> Event {
        let updatedEvent = try await journalService.updateEvent(withId: eventId, and: request)
        cacheService.cacheData(updatedEvent, for: updatedEvent.id.description, expiresIn: 3600) // Cache for 1 hour
        return updatedEvent
    }

    /**
     Deletes an event by its ID.
     
     - Parameter eventId: The ID of the event to delete.
     - Throws: An error if the event deletion fails.
     */
    func deleteEvent(withId eventId: Event.ID) async throws {
        try await journalService.deleteEvent(withId: eventId)
        cacheService.clearCache(for: eventId.description) // Remove event from cache
    }

    // MARK: - Media Methods

    /**
     Creates a new media item associated with an event.
     
     - Parameter request: A `MediaCreate` object containing the media details.
     - Throws: An error if the media creation fails.
     - Returns: A newly created `Media` object.
     */
    func createMedia(with request: MediaCreate) async throws -> Media {
        let media = try await journalService.createMedia(with: request)
        cacheService.cacheData(media, for: media.id.description, expiresIn: 3600) // Cache for 1 hour
        return media
    }

    /**
     Deletes a media item by its ID.
     
     - Parameter mediaId: The ID of the media item to delete.
     - Throws: An error if the media deletion fails.
     */
    func deleteMedia(withId mediaId: Media.ID) async throws {
        try await journalService.deleteMedia(withId: mediaId)
        cacheService.clearCache(for: mediaId.description) // Remove media from cache
    }

    // MARK: - Auth Methods

    /**
     Registers a new user.
     
     - Parameters:
        - username: The new user's username.
        - password: The new user's password.
     - Throws: An error if the registration fails.
     - Returns: A `Token` representing the authenticated user's token.
     */
    func register(username: String, password: String) async throws -> Token {
        return try await journalService.authService.register(username: username, password: password)
    }

    /**
     Logs in an existing user.
     
     - Parameters:
        - username: The user's username.
        - password: The user's password.
     - Throws: An error if the login fails.
     - Returns: A `Token` representing the authenticated user's token.
     */
    func logIn(username: String, password: String) async throws -> Token {
        return try await journalService.authService.logIn(username: username, password: password)
    }

    /**
     Logs out the currently authenticated user and clears the cache.
     */
    func logOut() async {
        await journalService.authService.logOut()
        cacheService.clearAllCache() // Clear all cached data on logout
    }

    // MARK: - Utility Methods

    /**
     Clears all cached data.
     */
    func clearCache() {
        cacheService.clearAllCache()
    }
}
