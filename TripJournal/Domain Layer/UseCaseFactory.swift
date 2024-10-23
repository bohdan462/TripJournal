// UseCaseFactory.swift
// TripJournal
//
// Created by Bohdan Tkachenko on 9/25/24.
//

import Foundation

class UseCaseFactory {
    private let tripRepository: TripRepository
    private let eventRepository: EventRepository
    private let mediaRepository: MediaRepository
    
    init(
        tripRepository: TripRepository,
        eventRepository: EventRepository,
        mediaRepository: MediaRepository
    ) {
        self.tripRepository = tripRepository
        self.eventRepository = eventRepository
        self.mediaRepository = mediaRepository
    }
    
    // MARK: - Trip Use Cases
    
    func makeGetTripsUseCase() -> GetTripsUseCase {
        return GetTripsUseCaseImpl(tripRepository: tripRepository)
    }
    
    func makeGetTripUseCase() -> GetTripUseCase {
        return GetTripUseCaseImpl(tripRepository: tripRepository)
    }
    
    func makeCreateTripUseCase() -> CreateTripUseCase {
        return CreateTripUseCaseImpl(tripRepository: tripRepository)
    }
    
    func makeUpdateTripUseCase() -> UpdateTripUseCase {
        return UpdateTripUseCaseImpl(tripRepository: tripRepository)
    }
    
    func makeDeleteTripUseCase() -> DeleteTripUseCase {
        return DeleteTripUseCaseImpl(tripRepository: tripRepository,
                                     eventRepository: eventRepository,
                                     mediaRepository: mediaRepository)
    }
    
    // MARK: - Event Use Cases
    
    func makeCreateEventUseCase() -> CreateEventsUseCase {
        return CreateEventsUseCaseImpl(tripRepository: tripRepository,
                                       eventRepository: eventRepository)
    }
    
    func makeGetEventUseCase() -> GetEventsUseCase {
        return GetEventsUseCaseImpl(eventRepository: eventRepository)
    }
    
    func makeUpdateEventUseCase() -> UpdateEventsUseCase {
        return UpdateEventsUseCaseImpl(eventRepository: eventRepository)
    }
    
    func makeDeleteEventUseCase() -> DeleteEventsUseCase {
        return DeleteEventsUseCaseImpl(eventRepository: eventRepository)
    }
    
    // MARK: - Media Use Cases
    
    func makeCreateMediaUseCase() -> CreateMediaUseCase {
        return CreateMediaUseCase(mediaRepository: mediaRepository,
                                  eventRepository: eventRepository)
    }
    
    func makeDeleteMediaUseCase() -> DeleteMediaUseCase {
        return DeleteMediaUseCaseImpl(mediaRepository: mediaRepository,
                                      eventRepository: eventRepository)
    }
}
