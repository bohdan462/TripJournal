//
//  JournalService+Live.swift
//  TripJournal
//
//  Created by Bohdan Tkachenko on 9/13/24.
//

import Foundation
import Combine

class JournalServiceLive {
    
    
    
    
    var tokenExpired: Bool = false
    
    @Published private var token: Token? {
        didSet {
            if let token = token {
                try? KeychainHelper.shared.saveToken(token)
            } else {
                try? KeychainHelper.shared.deleteToken()
            }
        }
    }
    
    var isAuthenticated: AnyPublisher<Bool, Never> {
        $token
            .map { $0 != nil }
            .eraseToAnyPublisher()
    }
    
    /// Shared URLSession instance
    private let session: URLSession
    private let cacheManager = CacheManager()
    @Published private var networkMonitor = NetworkMonitor()
    
    // MARK: - Initialization
    init(session: URLSession = .shared) {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30.0
        configuration.timeoutIntervalForResource = 60.0
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        
        self.session = URLSession(configuration: configuration)
    }
    
    
}


