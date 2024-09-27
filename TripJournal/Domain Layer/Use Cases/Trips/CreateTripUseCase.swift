//
//  CreateTripUseCase.swift
//  TripJournal
//
//  Created by Bohdan Tkachenko on 9/25/24.
//

import Foundation

protocol CreateTripUseCase {
    func execute(_ request: TripCreate) async throws -> Trip
}

class CreateTripUseCaseImpl: CreateTripUseCase {
    private let tripRepository: TripRepository

    init(tripRepository: TripRepository) {
        self.tripRepository = tripRepository
    }

    func execute(_ request: TripCreate) async throws -> Trip {
        return try await tripRepository.createTrip(request)
    }
}
