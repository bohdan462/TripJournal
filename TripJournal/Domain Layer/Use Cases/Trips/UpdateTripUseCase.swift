//
//  UpdateTripUseCase.swift
//  TripJournal
//
//  Created by Bohdan Tkachenko on 9/25/24.
//

import Foundation

protocol UpdateTripUseCase {
    func execute(_ trip: Trip) async throws
}

class UpdateTripUseCaseImpl: UpdateTripUseCase {
    private let tripRepository: TripRepository

    init(tripRepository: TripRepository) {
        self.tripRepository = tripRepository
    }

    func execute(_ trip: Trip) async throws {
        return try await tripRepository.updateTrip(trip)
    }
}
