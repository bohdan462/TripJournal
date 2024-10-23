//
//  ErrorManager.swift
//  TripJournal
//
//  Created by Bohdan Tkachenko on 10/22/24.
//

import Foundation


enum ContainerError: LocalizedError {
    case tripExists
    case eventExists
    case deleteError(item: String)
    case addError(item: String)
    case editError(item: String)
    
    var errorDescription: String? {
        switch self {
        case .tripExists:
            return "Trip with this name already exists. Please choose a different name."
            
        case .eventExists:
            return "Event with this name already exists. Consider using a unique name."
            
        case .deleteError(let item):
            return "Failed to delete \(item)."
        case .addError(let item):
            return "Failed to add \(item)."
        case .editError(let item):
            return "Failed to edit \(item)."
        }
    }
}


enum NetworkError: Error {
    case badUrl
    case badResponse
    case failedToDecodeResponse
    case invalidValue
    case unauthorized
    case notFound
    case noConnection
}

enum SessionError: Error {
    case expired
}

extension SessionError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .expired:
            return "Your session has expired. Please log in again."
        }
    }
}

enum AuthError: Error {
    case noCredentials
}

enum TokenError: Error {
    case noRefreshHandler
    case authenticationServiceDeallocated
}


enum KeychainError: LocalizedError {
    case unableToSaveData
    case unableToDeleteData
    case unableToRetrieveData
    case unableToDecodeData
    case unableToUpdateData
    case authenticationFailed
    case interactionNotAllowed
    
    var errorDescription: String? {
        switch self {
        case .unableToSaveData:
            return "Failed to save data to Keychain."
        case .unableToDeleteData:
            return "Failed to delete data from Keychain."
        case .unableToRetrieveData:
            return "Failed to retrieve data from Keychain."
        case .authenticationFailed:
            return "Authentication failed. Could not access the Keychain."
        case .interactionNotAllowed:
            return "Interaction with the Keychain is not allowed at this time."
        case .unableToDecodeData:
            return "Failed to decode data to Keychain."
        case .unableToUpdateData:
            return "Failed to update data to Keychain."
        }
    }
}

enum DeleteMediaError: Error {
    case eventNotFound
}


enum EventRepositoryError: Error {
    case parentTripNotAvailable
    case eventNotFound
    case parentTripNotSynced
    case serverSideIdNotFound
    
}

enum MediaRepositoryError: Error {
    case parentEventNotAvailable
    case mediaNotFound
    case parentEventNotSynced
    
}

enum DataSourceError: Error {
    case noData(Error)
    case decodingFailed(Error)
    case networkError(Error)
    case failedToProcessData(Error)
    case localStorageError(LocalDataSourceError)
    case unknown(Error)
    case appLogicError
    
    var localizedDescription: String {
        switch self {
        case .noData(let error):
            return "No data: \(error.localizedDescription)"
        case .decodingFailed(let error):
            return "Failed to decode data: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .failedToProcessData(let error):
            return "Failed to process data: \(error.localizedDescription)"
        case .localStorageError(let error):
            return "Local storage error: \(error.localizedDescription)"
        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        case .appLogicError:
            return "App logic error"
        }
    }
}

enum LocalDataSourceError: Error {
    case fetchFailed(Error)
    case saveFailed(Error)
    case updateFailed(Error)
    case deleteFailed(Error)
    
    
    var localizedDescription: String {
        switch self {
        case .fetchFailed(let error):
            return "Failed to fetch data: \(error.localizedDescription)"
        case .saveFailed(let error):
            return "Failed to save data: \(error.localizedDescription)"
        case .updateFailed(let error):
            return "Failed to update data: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Failed to delete data: \(error.localizedDescription)"
        }
    }
}

enum RemoteDataSourceError: Error {
    case invalidToken
    case networkError(Error)
    case decodingError(Error)
    case objectActionError(Error)
    
    
    // Provide a description for each error case if needed
    var localizedDescription: String {
        switch self {
        case .invalidToken:
            return "Invalid token. Please log in again."
        case .networkError(let error):
            return "Network error occurred: \(error.localizedDescription)"
            
        case .decodingError(let error):
            return "Failed to decode data: \(error.localizedDescription)"
            
        case .objectActionError(let error):
            return "Failed to perform object action: \(error.localizedDescription)"
        }
    }
}



class ErrorManager {
    
}
