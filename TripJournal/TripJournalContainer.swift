//
//  TripJournalContainer.swift
//  TripJournal
//
//  Created by Bohdan Tkachenko on 9/19/24.
//

import Foundation
import SwiftData

enum ContainerError: LocalizedError {
    case tripExists
    case eventExists
    case deleteError(item: String)
    case addError(item: String)
    case editError(item: String)
    
    var errorDescription: String? {
        switch self {
        case .tripExists:
            return "Trip with this name already exists. Please choose a different name."
            
        case .eventExists:
            return "Event with this name already exists. Consider using a unique name."
            
        case .deleteError(let item):
            return "Failed to delete \(item)."
        case .addError(let item):
            return "Failed to add \(item)."
        case .editError(let item):
            return "Failed to edit \(item)."
        }
    }
}


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
