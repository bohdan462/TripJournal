//
//  ServiceFactory.swift
//  TripJournal
//
//  Created by Bohdan Tkachenko on 9/20/24.
//

import Foundation
import SwiftData


class ServiceFactory {
    
    private var modelContext: ModelContext
    
    init(context: ModelContext) {
        self.modelContext = context
    }
    
    func makeJournalServiceFacade() -> JournalServiceFacade {
        return JournalServiceFacade(context: modelContext)
    }
    
    func makeJournalManager() -> JournalManager {
        return JournalManager(facade: makeJournalServiceFacade())
    }
}
