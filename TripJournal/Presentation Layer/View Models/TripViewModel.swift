//
//  TripViewModel.swift
//  TripJournal
//
//  Created by Bohdan Tkachenko on 9/25/24.
//

import Foundation

class TripViewModel: ObservableObject {
    // Published properties
    @Published var trips: [Trip] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var tripFormMode: TripForm.Mode?
    
    // Dependencies
    private let getTripsUseCase: GetTripsUseCase
    private let getTripUseCase: GetTripUseCase
    private let createTripUseCase: CreateTripUseCase
    private let updateTripUseCase: UpdateTripUseCase
    private let deleteTripUseCase: DeleteTripUseCase
    
    private let createEventUseCase: CreateEventsUseCase
    private let updateEventUseCase: UpdateEventsUseCase
    private let deleteEventUseCase: DeleteEventsUseCase
    
    // Initializer with Dependency Injection
    init(
        getTripsUseCase: GetTripsUseCase,
        getTripUseCase: GetTripUseCase,
        createTripUseCase: CreateTripUseCase,
        updateTripUseCase: UpdateTripUseCase,
        deleteTripUseCase: DeleteTripUseCase,
        createEventUseCase: CreateEventsUseCase,
        updateEventUseCase: UpdateEventsUseCase,
        deleteEventUseCase: DeleteEventsUseCase) {
            self.getTripsUseCase = getTripsUseCase
            self.getTripUseCase = getTripUseCase
            self.createTripUseCase = createTripUseCase
            self.updateTripUseCase = updateTripUseCase
            self.deleteTripUseCase = deleteTripUseCase
            self.createEventUseCase = createEventUseCase
            self.updateEventUseCase = updateEventUseCase
            self.deleteEventUseCase = deleteEventUseCase
            
        }
    
    // MARK: - Methods
    
    func trip(withId id: Trip.ID) -> Trip? {
        let trip = trips.first { $0.id == id }
        trip?.events // Access to trigger lazy loading
        return trip
    }
    
    @MainActor
    func loadTrips() async {
        isLoading = true
        do {
            // Fetch trips in a background thread
            let fetchedTrips = try await getTripsUseCase.execute()
            
            // Ensure UI updates happen on the main thread
            trips = fetchedTrips
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
    
    @MainActor
    func createTrip(name: String, startDate: Date, endDate: Date) async {
        isLoading = true
        let tripCreate = TripCreate(name: name, startDate: startDate, endDate: endDate)
        Task {
            do {
                let newTrip = try await createTripUseCase.execute(tripCreate)
                await MainActor.run {
                    self.trips.append(newTrip)
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    print("\(error.localizedDescription)")
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    @MainActor
    func updateTrip(_ trip: Trip) async {
        isLoading = true
        Task {
            do {
                let updatedTrip = try await updateTripUseCase.execute(trip)
                print("Updated Trip: \(updatedTrip)")
                await MainActor.run {
                    if let index = self.trips.firstIndex(where: { $0.id == updatedTrip.id }) {
                        self.trips[index] = updatedTrip
                    }
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    
    
    @MainActor
    func getTrip(by tripId: Trip.ID) async -> Trip? {
        isLoading = true
        
        do {
            // Fetch the trip in the background thread
            let fetchedTrip = try await getTripUseCase.execute(tripId)
            
            // Ensure that any UI updates (like modifying trips) happen on the main thread
            if let index = trips.firstIndex(where: { $0.id == fetchedTrip.id }) {
                trips[index] = fetchedTrip
            } else {
                trips.append(fetchedTrip)
            }
            isLoading = false
            return fetchedTrip
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return nil
        }
    }
    
    
    func deleteTrip(_ tripId: Trip.ID) {
        isLoading = true
        Task {
            do {
                try await deleteTripUseCase.execute(tripId)
                await MainActor.run {
                    self.trips.removeAll { $0.id == tripId }
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    func deleteAll() {
        isLoading = true
        Task {
            do {
                try await deleteTripUseCase.deleteAll()
                await MainActor.run {
                    self.trips.removeAll()
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
}

extension TripViewModel {
    
    func addEvent(_ event: Event, fromTrip: Trip) async {
        // Mark isLoading as true on the main thread
        await MainActor.run {
            isLoading = true
        }
        
        do {
            // Execute the use case asynchronously (this can happen off the main thread)
            try await createEventUseCase.execute(event: event, trip: fromTrip)
            
            // Update the trips array on the main thread
            await MainActor.run {
                if let tripIndex = trips.firstIndex(where: { $0.id == fromTrip.id }) {
                    trips[tripIndex].events.append(event)
                    Task {
                        await self.updateTrip(trips[tripIndex]) // Call updateTrip to sync
                    }
                    
                }
                isLoading = false
            }
        } catch {
            // Handle errors on the main thread
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
    
    func updateEvent(_ event: Event, inTrip: Trip) async {
        // Mark isLoading as true on the main thread
        await MainActor.run {
            isLoading = true
        }
        
        // Check if the trip exists in the array
        if let tripIndex = trips.firstIndex(where: { $0.id == inTrip.id }) {
            // Perform the event update
            await MainActor.run {
                if let eventIndex = trips[tripIndex].events.firstIndex(where: { $0.id == event.id }) {
                    
                    //TODO: - this probably should be updated with server respose Event object, not the passes object
                    trips[tripIndex].events[eventIndex] = event
                }
            }
            //            // Optionally, persist the changes to the server or local storage
                        await updateTrip(trips[tripIndex])
            
            do {
                try await updateEventUseCase.execute(event: event, inTrip: trips[tripIndex])
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
        
        // Ensure that isLoading is turned off on the main thread
        await MainActor.run {
            isLoading = false
        }
    }
    
    func deleteEvent(withId eventId: Event.ID, fromTrip trip: Trip) async {
        // Mark isLoading as true on the main thread
        await MainActor.run {
            isLoading = true
        }
        
        do {
            // Execute the delete event use case asynchronously
            try await deleteEventUseCase.execute(eventId: eventId, fromTrip: trip)
            
            // Update the trips array on the main thread
            await MainActor.run {
                if let tripIndex = trips.firstIndex(where: { $0.id == trip.id }) {
                    trips[tripIndex].events.removeAll { $0.id == eventId }
                }
                isLoading = false
            }
        } catch {
            // Handle errors on the main thread
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
}

