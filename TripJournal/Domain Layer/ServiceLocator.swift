// ServiceLocator.swift
// TripJournal
//
// Created by Bohdan Tkachenko on 9/25/24.
//

import Foundation
import SwiftData

class ServiceLocator {
    
    // Global dependencies
    private let context: ModelContext
    
    // Services
    private lazy var networkClient: NetworkClient = {
        return NetworkClient()
    }()
    
    private lazy var tokenManager: TokenManager = {
        print("Initialized TokenManager")
        return TokenManager(storage: KeychainHelper.shared, tokenStorage: TokenStorage(), serviceLocator: self)
    }()
    
    private lazy var cacheService: CacheService = {
        print("Initialized CacheService")
        return CacheServiceManager()
    }()
    
    // Authentication Service
    private lazy var authService: AuthenticationService = {
        print("Initialized AuthenticationService")
        return AuthenticationService(tokenManager: tokenManager)
    }()
    
    // Authentication Manager
    func makeJournalAuthManager() -> JournalAuthManager {
        return JournalAuthManager(authService: authService)
    }
    
    // MARK: - Data Sources and Repositories
    
    // Trip Data Sources
    func getTripRemoteDataSource() -> TripRemoteDataSource {
        return TripRemoteDataSourceImpl(networking: networkClient, tokenManager: tokenManager)
    }
    
    func getTripLocalDataSource() -> TripLocalDataSource {
        return TripLocalDataSourceImpl(context: context)
    }
    
    // Trip Repository
    func getTripRepository() -> TripRepository {
        return TripRepositoryImpl(
            remoteDataSource: getTripRemoteDataSource(),
            localDataSource: getTripLocalDataSource()
        )
    }
    
    // Event Data Sources
    func getEventRemoteDataSource() -> EventRemoteDataSource {
        return EventRemoteDataSourceImpl(networking: networkClient, tokenManager: tokenManager)
    }
    
    func getEventLocalDataSource() -> EventLocalDataSource {
        return EventLocalDataSourceImpl(context: context)
    }
    
    // Event Repository
    private lazy var eventRepository: EventRepository = {
        return EventRepositoryImpl(remoteDataSource: getEventRemoteDataSource(), localDataSource: getEventLocalDataSource())
    }()
    
    // Media Data Sources
    func getMediaRemoteDataSource() -> MediaRemoteDataSource {
        return MediaRemoteDataSourceImpl(networking: networkClient, tokenManager: tokenManager)
    }
    
    func getMediaLocalDataSource() -> MediaLocalDataSource {
        return MediaLocalDataSourceImpl(context: context, storage: FileManagerStorage.shared)
    }
    
    // Media Repository
    private lazy var mediaRepository: MediaRepository = {
        return MediaRepositoryImpl(remoteDataSource: getMediaRemoteDataSource(), localDataSource: getMediaLocalDataSource())
    }()
    
    // Use Case Factory
    private lazy var useCaseFactory: UseCaseFactory = {
        UseCaseFactory(
            tripRepository: getTripRepository(),
            eventRepository: eventRepository,
            mediaRepository: mediaRepository
        )
    }()
    
    init(context: ModelContext) {
        self.context = context
    }
    
    // MARK: - Authentication and Network Services
    
    func getAuthService() -> AuthenticationService {
        return authService
    }
    
    func getNetworkMonitor() -> NetworkMonitor {
        return NetworkMonitor.shared
    }
    
    // MARK: - View Models
    
    @MainActor
    func getTripViewModel() -> TripViewModel {
        return TripViewModel(
            getTripsUseCase: useCaseFactory.makeGetTripsUseCase(),
            getTripUseCase: useCaseFactory.makeGetTripUseCase(),
            createTripUseCase: useCaseFactory.makeCreateTripUseCase(),
            updateTripUseCase: useCaseFactory.makeUpdateTripUseCase(),
            deleteTripUseCase: useCaseFactory.makeDeleteTripUseCase(),
            createEventUseCase: useCaseFactory.makeCreateEventUseCase(),
            updateEventUseCase: useCaseFactory.makeUpdateEventUseCase(),
            deleteEventUseCase: useCaseFactory.makeDeleteEventUseCase()
        )
    }
    
    @MainActor
    func getEventViewModel() -> EventViewModel {
        return EventViewModel(
            createEventUseCase: useCaseFactory.makeCreateEventUseCase(),
            getEventUseCase: useCaseFactory.makeGetEventUseCase(),
            updateEventUseCase: useCaseFactory.makeUpdateEventUseCase(),
            deleteEventUseCase: useCaseFactory.makeDeleteEventUseCase()
        )
    }
    
    @MainActor
    func getMediaViewModel() -> MediaViewModel {
        return MediaViewModel(
            createMediaUseCase: useCaseFactory.makeCreateMediaUseCase(),
            deleteMediaUseCase: useCaseFactory.makeDeleteMediaUseCase()
        )
    }
}
