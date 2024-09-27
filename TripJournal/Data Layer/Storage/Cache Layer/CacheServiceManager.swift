//
//  CacheService.swift
//  TripJournal
//
//  Created by Bohdan Tkachenko on 9/13/24.
//

import Foundation

// MARK: - CacheService
protocol CacheService {
    func getCachedData<T: Codable>(for key: String) -> T?
    func cacheData<T: Codable>(_ data: T, for key: String, expiresIn: TimeInterval?)
    func clearCache(for key: String)
    func clearAllCache()
}

// A struct to hold cached objects along with their expiration date
private struct CachedObject<T: Codable>: Codable {
    let data: T
    let expirationDate: Date?
}

class CacheServiceManager: CacheService {
    
    private let cache = NSCache<NSString, NSData>()
    
    // Retrieve cached data if it exists and hasn't expired
    func getCachedData<T: Codable>(for key: String) -> T? {
        guard let cachedData = cache.object(forKey: key as NSString) as Data?,
              let cachedObject = try? JSONDecoder().decode(CachedObject<T>.self, from: cachedData) else {
            return nil
        }
        
        // Check if the cached object has expired
        if let expirationDate = cachedObject.expirationDate, expirationDate < Date() {
            // The cached data has expired
            cache.removeObject(forKey: key as NSString)
            return nil
        }
        
        return cachedObject.data
    }
    
    // Cache data with optional expiration time
    func cacheData<T: Codable>(_ data: T, for key: String, expiresIn: TimeInterval? = nil) {
        let expirationDate = expiresIn != nil ? Date().addingTimeInterval(expiresIn!) : nil
        
        let cachedObject = CachedObject(data: data, expirationDate: expirationDate)
        if let encodedData = try? JSONEncoder().encode(cachedObject) {
            cache.setObject(encodedData as NSData, forKey: key as NSString)
        }
    }
    
    // Clear cache for a specific key
    func clearCache(for key: String) {
        cache.removeObject(forKey: key as NSString)
    }
    
    //Clear all cache
    func clearAllCache() {
        cache.removeAllObjects()
    }
}
