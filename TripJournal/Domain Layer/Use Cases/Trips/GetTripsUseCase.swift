//
//  GetTripsUseCase.swift
//  TripJournal
//
//  Created by Bohdan Tkachenko on 9/24/24.
//

import Foundation

protocol GetTripsUseCase {
    func execute() async throws -> [Trip]
}

class GetTripsUseCaseImpl: GetTripsUseCase {
    private let tripRepository: TripRepository

    init(tripRepository: TripRepository) {
        self.tripRepository = tripRepository
    }

    func execute() async throws -> [Trip] {
        return try await tripRepository.getTrips()
    }
}
