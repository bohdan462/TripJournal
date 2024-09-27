//
//  GetTripUseCase.swift
//  TripJournal
//
//  Created by Bohdan Tkachenko on 9/25/24.
//

import Foundation

protocol GetTripUseCase {
    func execute(_ id: Trip.ID) async throws -> Trip
}

class GetTripUseCaseImpl: GetTripUseCase {
    private let tripRepository: TripRepository

    init(tripRepository: TripRepository) {
        self.tripRepository = tripRepository
    }

    func execute(_ id: Trip.ID) async throws -> Trip {
        return try await tripRepository.getTrip(withId: id)!
    }
}
