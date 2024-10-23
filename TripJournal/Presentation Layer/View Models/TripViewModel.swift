//
//  TripViewModel.swift
//  TripJournal
//
//  Created by Bohdan Tkachenko on 9/25/24.
//

import Foundation
import SwiftData

@MainActor
class TripViewModel: ObservableObject {
    // Published properties
    @Published var trips: [Trip] = []
    
    @Published var currentTrip: Trip?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var tripFormMode: TripForm.Mode?

    // Dependencies
    private let getTripsUseCase: GetTripsUseCase
    private let getTripUseCase: GetTripUseCase
    private let createTripUseCase: CreateTripUseCase
    private let updateTripUseCase: UpdateTripUseCase
    private let deleteTripUseCase: DeleteTripUseCase
    
//    private let createEventUseCase: CreateEventsUseCase
//    private let updateEventUseCase: UpdateEventsUseCase
//    private let deleteEventUseCase: DeleteEventsUseCase
    
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
//            self.createEventUseCase = createEventUseCase
//            self.updateEventUseCase = updateEventUseCase
//            self.deleteEventUseCase = deleteEventUseCase
            
        }
    
    // MARK: - Methods

    func loadTrips() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Fetch trips in a background thread
            let fetchedTrips = try await getTripsUseCase.execute()
         
            trips = fetchedTrips
            print("\n TRIP_VIEW_MODEL")
            trips.forEach({ trip in
                
                print("TRIP_ID: \(trip.tripId)")
                print("TRIP_NAME: \(trip.name)")
               print("TRIP_EVENTS_CONT: \(trip.events.count)")
                print("TRIP_isSYNCED: \(trip.isSynced)")
                print("TRIP_FIRST_EVENT_LOCATION :\(trip.events.first?.location) \n\n")
               
                
            })

        } catch {
            errorMessage = error.localizedDescription
          
        }
    }
    

    func createTrip(name: String, startDate: Date, endDate: Date) async {
        isLoading = true
        defer { isLoading = false }
        
        let tripCreate = TripCreate(name: name, startDate: startDate, endDate: endDate)
        Task {
            do {
                _ = try await createTripUseCase.execute(tripCreate)
                await loadTrips()
            } catch {
                await MainActor.run {
                    print("\(error.localizedDescription)")
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    func updateTrip(_ trip: Trip) async {
        isLoading = true
        defer { isLoading = false }
        
        Task {
            do {
                try await updateTripUseCase.execute(trip)
                await loadTrips()
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    
    

    func getTrip(by tripId: Trip.ID) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
          let fetchedTrip = try await getTripUseCase.execute(tripId)
                currentTrip = fetchedTrip
            print("Current Trip To Show Details About: \(currentTrip!.name)")
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    
    func deleteTrip(_ tripId: Trip.ID) {
        isLoading = true
        defer { isLoading = false }
        
        Task {
            do {
                try await deleteTripUseCase.execute(tripId)
                await loadTrips()
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func deleteAll() {
        isLoading = true
        defer { isLoading = false }
        
        Task {
            do {
                try await deleteTripUseCase.deleteAll()
                await loadTrips()
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
}
