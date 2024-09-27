//
//  TripController.swift
//  TripJournal
//
//  Created by Bohdan Tkachenko on 9/20/24.
//

import Foundation
import SwiftData
import SwiftUI

//@MainActor
//class TripController: ObservableObject {
//    @Published var trips: [Trip] = []
//    @Published var isLoading: Bool = false
//    @Published var error: Error?
//    @Published var tripFormMode: TripForm.Mode?
//    
//    private let context: ModelContext
//    let journalManager: JournalManager
//    private let syncController: TJSyncController
//    private let networkMonitor: NetworkMonitor
//    
//    init(context: ModelContext, journalManager: JournalManager, syncController: TJSyncController, networkMonitor: NetworkMonitor) {
//        self.context = context
//        self.journalManager = journalManager
//        self.syncController = syncController
//        self.networkMonitor = networkMonitor
//        fetchTrips()
//    }
//    
//    // Fetch trips from local storage
//    func fetchTrips() {
//        let descriptor = FetchDescriptor<Trip>(sortBy: [SortDescriptor(\Trip.id, order: .forward)])
//        do {
//            trips = try context.fetch(descriptor)
//        } catch {
//            self.error = error
//            print("Error fetching trips: \(error)")
//        }
//    }
//    
//    // Create a new trip, handling offline scenarios
//    func createTrip(from request: TripCreate) {
//        let trip = Trip(
//            name: request.name,
//            startDate: request.startDate,
//            endDate: request.endDate,
//            isSynced: networkMonitor.isConnected // Set isSynced based on network status
//        )
//        context.insert(trip)
//        
//        do {
//            try context.save()
//            trips.append(trip)
//            
//            if networkMonitor.isConnected {
//                Task {
//                    await syncTrip(trip)
//                }
//            }
//        } catch {
//            self.error = error
//            print("Failed to save trip locally: \(error)")
//        }
//    }
//    
//    // Inside TripController
//    private func syncTrip(_ trip: Trip) async {
//        var retryCount = 0
//        let maxRetries = 3
//        var delay: Double = 1.0
//        
//        while retryCount < maxRetries {
//            do {
//                let tripId = try await syncController.syncCreateTripWithServer(trip: trip)
//                trip.tripId = tripId
//                trip.isSynced = true
//                try context.save()
//                
//                if let index = trips.firstIndex(where: { $0.id == trip.id }) {
//                    trips[index] = trip
//                }
//                return // Successful sync, exit the loop
//            } catch {
//                retryCount += 1
//                if retryCount >= maxRetries {
//                    self.error = error
//                    print("Failed to sync trip after \(maxRetries) attempts: \(error)")
//                } else {
//                    print("Retrying sync in \(delay) seconds...")
//                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
//                    delay *= 2 // Exponential backoff
//                }
//            }
//        }
//    }
//
//}
