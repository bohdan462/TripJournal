//
//  DeleteTripUseCase.swift
//  TripJournal
//
//  Created by Bohdan Tkachenko on 9/25/24.
//

import Foundation

protocol DeleteTripUseCase {
    func execute(_ tripId: Trip.ID) async throws
    func deleteAll() async throws
}

class DeleteTripUseCaseImpl: DeleteTripUseCase {
    private let tripRepository: TripRepository

    init(tripRepository: TripRepository) {
        self.tripRepository = tripRepository
    }

    func execute(_ tripId: Trip.ID) async throws {
        try await tripRepository.deleteTrip(withId: tripId)
    }
    
    func deleteAll() async throws {
        try await tripRepository.deleteAll()
    }
}
