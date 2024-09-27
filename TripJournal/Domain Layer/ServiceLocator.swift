//
//  ServiceLocator.swift
//  TripJournal
//
//  Created by Bohdan Tkachenko on 9/25/24.
//

import Foundation
import SwiftData

class ServiceLocator {
    
    // Global dependencies
    private let context: ModelContext
    
    private lazy var networkClient: NetworkClient = {
        return NetworkClient()
    }()
    
    private lazy var tokenManager: TokenManager = {
           print("Initialized TokenManager")
           return TokenManager(storage: KeychainHelper.shared, tokenStorage: TokenStorage(), serviceLocator: self)
       }()
    
//    private lazy var journalServiceFacade: JournalServiceFacade = {
//        print("Initialized JournalServiceFacade")
//        return JournalServiceFacade(serviceLocator: self, context: context)
//    }()
    
    private lazy var cacheService: CacheService = {
         print("Initialized CacheService")
         return CacheServiceManager()
     }()
    
    // Authentication Service
       private lazy var authService: AuthenticationService = {
           print("Initialized AuthenticationService")
           return AuthenticationService(tokenManager: tokenManager)
       }()
    
    // JournalServiceLive
//    private lazy var journalServiceLive: JournalServiceLive = {
//        print("Initialized JournalServiceLive")
//        return JournalServiceLive(tokenManager: tokenManager, networkClient: networkClient)
//    }()
    
    init(context: ModelContext) {
        self.context = context
    }
    
    // Provide the ModelContext for SwiftData
    func getModelContext() -> ModelContext {
        return context
    }
    
    // Provide the NetworkMonitor
    func getNetworkMonitor() -> NetworkMonitor {
        return NetworkMonitor.shared
    }
    
    func getTokenManager() -> TokenManager {
        return tokenManager // Return the cached instance
    }
    
    func getNetworkClient() -> NetworkClient {
        return networkClient // Return the cached instance
    }
    
    func getCacheService() -> CacheService {
        return cacheService
    }
    
    func getAuthService() -> AuthenticationService {
        return authService as! AuthenticationService
    }
    
//    func getJournalServiceLive() -> JournalServiceLive {
//        return journalServiceLive
//    }
    
    func makeJournalAuthManager() -> JournalAuthManager {
        return JournalAuthManager(authService: authService)
    }
    
//    func getJournalServiceFacade() -> JournalServiceFacade {
//        return journalServiceFacade // Return the cached instance
//    }
    
    // MARK: - Trip
    
    // Data Sources (Remote and Local)
    func getTripRemoteDataSource() -> TripRemoteDataSource {
        return TripRemoteDataSourceImpl(networking: networkClient, tokenManager: tokenManager)
    }
    
    func getTripLocalDataSource() -> TripLocalDataSource {
        return TripLocalDataSourceImpl(context: getModelContext())
    }
    
    // Repositories
    func getTripRepository() -> TripRepository {
        return TripRepositoryImpl(
            remoteDataSource: getTripRemoteDataSource(),
            localDataSource: getTripLocalDataSource()
        )
    }
    
    func getGetTripsUseCase() -> GetTripsUseCase {
        return GetTripsUseCaseImpl(tripRepository: getTripRepository())
    }
    
    func getGetTripUseCase() -> GetTripUseCase {
        return GetTripUseCaseImpl(tripRepository: getTripRepository())
    }
    
    func getCreateTripUseCase() -> CreateTripUseCase {
        return CreateTripUseCaseImpl(tripRepository: getTripRepository())
    }
    
    func getUpdateTripUseCase() -> UpdateTripUseCase {
        return UpdateTripUseCaseImpl(tripRepository: getTripRepository())
    }
    
    func getDeleteTripUseCase() -> DeleteTripUseCase {
        return DeleteTripUseCaseImpl(tripRepository: getTripRepository())
    }
    
    //MARK: - Provide the ViewModel with Use Cases
    func getTripViewModel() -> TripViewModel {
        return TripViewModel(
            getTripsUseCase: getGetTripsUseCase(),
            getTripUseCase: getGetTripUseCase(),
            createTripUseCase: getCreateTripUseCase(),
            updateTripUseCase: getUpdateTripUseCase(),
            deleteTripUseCase: getDeleteTripUseCase(),
            createEventUseCase: createEventUseCase,
            updateEventUseCase: updateEventUseCase,
            deleteEventUseCase: deleteEventUseCase
        )
    }
    // MARK: - Event
        private lazy var eventRepository: EventRepository = {
            return EventRepositoryImpl(
                remoteDataSource: eventRemoteDataSource,
                localDataSource: eventLocalDataSource
            )
        }()
        
        // MARK: - Data Sources
        private lazy var eventRemoteDataSource: EventRemoteDataSource = {
            return EventRemoteDataSourceImpl(
                networking: networkClient,
                tokenManager: tokenManager
            )
        }()
        
        private lazy var eventLocalDataSource: EventLocalDataSource = {
            return EventLocalDataSourceImpl(context: context)
        }()
        
        // MARK: - Use Cases
        private lazy var createEventUseCase: CreateEventsUseCase = {
            return CreateEventsUseCaseImpl(tripRepository: getTripRepository(), eventRepository: eventRepository)
        }()
        
        private lazy var getEventUseCase: GetEventsUseCase = {
            return GetEventsUseCaseImpl(eventRepository: eventRepository)
        }()
        
        private lazy var updateEventUseCase: UpdateEventsUseCase = {
            return UpdateEventsUseCaseImpl(tripRepository: getTripRepository(), eventRepository: eventRepository)
        }()
        
        private lazy var deleteEventUseCase: DeleteEventsUseCase = {
            return DeleteEventsUseCaseImpl(tripRepository: getTripRepository())
        }()
    
    //MARK: - View Model with Use Cases
   func getEventViewModel(event: Event? = nil) -> EventViewModel {
        return EventViewModel(
            event: event,
            createEventUseCase: createEventUseCase,
            getEventUseCase: getEventUseCase,
            updateEventUseCase: updateEventUseCase,
            deleteEventUseCase: deleteEventUseCase
        )
    }

}
