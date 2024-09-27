//
//  TripLocalDataSource.swift
//  TripJournal
//
//  Created by Bohdan Tkachenko on 9/24/24.
//

import Foundation
import SwiftData

protocol TripLocalDataSource {
    func getTrips() async -> [Trip]
    func getTrip(withId id: Trip.ID) async -> Trip?
    func saveTrips(_ trips: [Trip]) async
    func saveTrip(_ trip: Trip) async
    func updateTrip(_ trip: Trip, withId id: Trip.ID) async
    func deleteTrip(withId id: Trip.ID) async -> Trip?
    func deleteAll() async
}


class TripLocalDataSourceImpl: TripLocalDataSource {
    
    private let context: ModelContext
    
    init(context: ModelContext) {
        self.context = context
    }
    
    // Methods
    func getTrips() async -> [Trip] {
        await MainActor.run {
            let descriptor = FetchDescriptor<Trip>(sortBy: [SortDescriptor(\Trip.id, order: .forward)])
            do {
                let trips = try context.fetch(descriptor)
                return trips
            } catch {
                print("Error fetching local Trips: \(error.localizedDescription)")
                return []
            }
        }
    }
    
    func getTrip(withId id: Trip.ID) async -> Trip? {
        
        let descriptor = FetchDescriptor<Trip>(predicate: #Predicate<Trip> {$0.id == id },
                                               sortBy: [SortDescriptor(\Trip.name, order: .forward)])
        do {
            if let fetchedTrip = try context.fetch(descriptor).first {
                return fetchedTrip
            }
        } catch {
            print("Error fetching local Trip with error: \(error.localizedDescription)")
        }
        return nil
    }
    
    func saveTrips(_ trips: [Trip]) async {
        trips.forEach {
            context.insert($0)
        }
        
        do {
            try context.save()
        } catch {
            print("Failed to save trips locally: \(error.localizedDescription)")
        }
        
    }
    
    func saveTrip(_ trip: Trip) async {
        context.insert(trip)
        
        do {
            try context.save()
        } catch {
            print("Failed to save trip locally: \(error.localizedDescription)")
        }
    }
    
    func updateTrip(_ trip: Trip, withId id: Trip.ID) async {
        let descriptor = FetchDescriptor<Trip>(predicate: #Predicate<Trip> { $0.id == id })
        do {
            if let fetchedTrip = try context.fetch(descriptor).first {
                var tripToUpdate = fetchedTrip
                tripToUpdate = trip
                try context.save()
                
            }
        } catch {
            print("Error fetching local Trip with error: \(error.localizedDescription)")
        }
        
    }
    
    func deleteTrip(withId id: Trip.ID) async -> Trip? {
        let descriptor = FetchDescriptor<Trip>(predicate: #Predicate<Trip> {$0.id == id })
        
        do {
            if let fetchedTrip = try context.fetch(descriptor).first {
                context.delete(fetchedTrip)
                return fetchedTrip
            }
            try context.save()
            
        } catch {
            print("Error fetching local Trip with error: \(error.localizedDescription)")
        }
        return nil
    }
    
    func deleteAll() async {
        let fetchDescriptor = FetchDescriptor<Trip>()
        
        do {
            let allTrips = try context.fetch(fetchDescriptor)
            
            for trip in allTrips {
                context.delete(trip)
            }
            
            try context.save()
            
            print("All data deleted successfully from local context.")
        } catch {
            print("Failed to delete all data: \(error.localizedDescription)")
        }
    }
    
    
}

