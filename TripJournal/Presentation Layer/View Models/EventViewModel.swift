//
//  EventViewModel.swift
//  TripJournal
//
//  Created by Bohdan Tkachenko on 9/25/24.
//

import Foundation
import Combine
import SwiftUI

@MainActor
class EventViewModel: ObservableObject {

    @Published var event: Event?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var isSaving: Bool = false
    @Published var isDeleting: Bool = false
    @Published var isDeleted: Bool = false
    @Published var isUpdated: Bool = false
    @Published var isCreated: Bool = false
    
    // Dependencies
    private let createEventUseCase: CreateEventsUseCase
    private let getEventUseCase: GetEventsUseCase
    private let updateEventUseCase: UpdateEventsUseCase
    private let deleteEventUseCase: DeleteEventsUseCase
    
    // Initializer
    init(event: Event? = nil,
         createEventUseCase: CreateEventsUseCase,
         getEventUseCase: GetEventsUseCase,
         updateEventUseCase: UpdateEventsUseCase,
         deleteEventUseCase: DeleteEventsUseCase
    ) {
        self.event = event
        self.createEventUseCase = createEventUseCase
        self.getEventUseCase = getEventUseCase
        self.updateEventUseCase = updateEventUseCase
        self.deleteEventUseCase = deleteEventUseCase
  
    
    }
    
    func fetchEvent(_ event: Event) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            if let event = try await getEventUseCase.execute(eventId: event.id) {
                self.event = event
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    func addEvent(_ event: Event) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await createEventUseCase.execute(event: event)
            
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    func updateEvent(_ event: Event) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await updateEventUseCase.execute(event: event)
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
               
            }
        }
    }
    
    
    func deleteEvent(_ event: Event) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await deleteEventUseCase.execute(event)
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }
    }
}
