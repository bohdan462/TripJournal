import Foundation
import SwiftData
import SwiftUI
import os

//actor SyncManager {
//    private var isSyncing: Bool = false
//    
//    
//    func performSync(task: () async throws -> Void) async throws {
//        guard !isSyncing else {
//            print("Sync already in progress")
//            throw SyncError.alreadySyncing
//        }
//        isSyncing = true
//        defer { isSyncing = false }
//        try await task()
//    }
//    
//    enum SyncError: Error {
//        case alreadySyncing
//    }
//}
//
//enum SyncError: Error {
//    case invalidTripId
//}
//
//class TJSyncController: ObservableObject {
//    
//    private let context: ModelContext
//    private let journalManager: JournalManager
//    private let syncManager: SyncManager
//    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "TJSyncController")
//    
//    init(journalManager: JournalManager, syncManager: SyncManager = SyncManager()) {
//        print("Initializing TJSyncController")
//        self.context = journalManager.journalFacade.context
//        self.journalManager = journalManager
//        self.syncManager = syncManager
//        print("!Initialized! TJSyncController")
//    }
//    
//    // MARK: - Public Methods
//    
//    // Synchronize a single trip with the server
//    func syncCreateTripWithServer(trip: Trip) async throws -> Int {
//        let request = TripCreate(name: trip.name, startDate: trip.startDate, endDate: trip.endDate)
//        let tripResponse = await journalManager.createTrip(from: request)
//        
//        guard let tripId = tripResponse.tripId else {
//            throw SyncError.invalidTripId
//        }
//        
//        return tripId
//    }
//    
//    /// Synchronize trips with the server
//    func syncTrips() async throws {
//        try await syncManager.performSync { [weak self] in
//            guard let self = self else { return }
//            
//            // Fetch unsynced trips ordered by creation date (FIFO)
//            let unsyncedTrips = self.journalManager.fetchUnsyncedTripsContext().sorted(by: { $0.id.uuidString < $1.id.uuidString })
//            
//            for trip in unsyncedTrips {
//                do {
//                    // Send trip to the server
//                    let tripId = try await self.sendTripToServer(trip)
//                    
//                    // Update local trip with the server-assigned TripId and mark as synced
//                    trip.tripId = tripId
//                    trip.isSynced = true
//                    
//                    // Save the context after each successful sync
//                    try self.context.save()
//                    
//                    self.logger.info("Successfully synced trip: \(trip.name) with TripId: \(tripId)")
//                    
//                } catch {
//                    
//                    throw error // Propagate the error to handle it in the calling function
//                }
//            }
//            
//            self.logger.info("All unsynced trips have been synchronized.")
//        }
//    }
//    
//    // MARK: - Private Methods
//    
//    /// Sends a single trip to the server and returns the assigned TripId
//    @MainActor
//    private func sendTripToServer(_ trip: Trip) async throws -> Int {
//        // Prepare the trip creation request
//        let request = TripCreate(name: trip.name, startDate: trip.startDate, endDate: trip.endDate)
//        
//        // Send the trip to the server and receive the TripId
//        return await journalManager.createTrip(from: request).tripId!
//        
//    }
//}
