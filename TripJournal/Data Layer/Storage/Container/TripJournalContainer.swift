//
//  TripJournalContainer.swift
//  TripJournal
//
//  Created by Bohdan Tkachenko on 9/19/24.
//

import Foundation
import SwiftData

class TripJournalContainer {
    
    @MainActor
    static func create() -> ModelContainer {
        let schema = Schema([Trip.self, Event.self, Location.self, Media.self])
        let configuration = ModelConfiguration("TripJournalStore", schema: schema)
        
        do {
            let container = try ModelContainer(for: schema, configurations: configuration)
            return container
        } catch {
            fatalError("Error creating Model Container: \(error)")
        }
        
    }
}
