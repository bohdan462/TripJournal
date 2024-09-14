//
//  CacheService.swift
//  TripJournal
//
//  Created by Bohdan Tkachenko on 9/13/24.
//

import Foundation

// MARK: - CacheService
protocol CacheService {
    func getCachedData(for key: String) -> Data?
    func cacheData(_ data: Data, for key: String)
}

class CacheServiceManager: CacheService {
    
    private let cache = NSCache<NSString, NSData>()
    
    func getCachedData(for key: String) -> Data? {
        return cache.object(forKey: key as NSString) as Data?
    }
    
    func cacheData(_ data: Data, for key: String) {
        cache.setObject(data as NSData, forKey: key as NSString)
    }
    
    
}
