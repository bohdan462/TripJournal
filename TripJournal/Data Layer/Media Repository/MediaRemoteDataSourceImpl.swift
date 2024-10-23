//
//  MediaRemoteDataSourceImpl.swift
//  TripJournal
//
//  Created by Bohdan Tkachenko on 10/20/24.
//

import Foundation
import SwiftUI

protocol MediaRemoteDataSource {
    func createMedia(_ request: MediaCreate) async throws -> Media
    func deleteMedia(withId id: Int) async throws
}

class MediaRemoteDataSourceImpl: MediaRemoteDataSource {
    
    private let networking: NetworkClient
    private let tokenManager: TokenManager
    
    init(networking: NetworkClient, tokenManager: TokenManager) {
        self.networking = networking
        self.tokenManager = tokenManager
    }
    
    func createMedia(_ request: MediaCreate) async throws -> Media {
        guard let token = try await tokenManager.getToken() else {
            throw NetworkError.invalidValue
        }
        
        let mediaData: [String: Any] =
        [
            "caption": request.caption,
            "base64_data": request.base64Data,
            "event_id": request.eventId
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: mediaData )
        
        let config = CustomRequestConfigurable(headers: [
            HTTPHeaders.authorization.rawValue: "Bearer \(token.accessToken)",
            HTTPHeaders.accept.rawValue: MIMEType.JSON.rawValue,
            HTTPHeaders.contentType.rawValue: MIMEType.JSON.rawValue
        ],
                                               body: jsonData
        )
        
        let mediaResponse = try await networking.request(
            .media,
            responseType: MediaResponse.self,
            method: .POST,
            config: config
        )
        
        
        let media = Media(from: mediaResponse, event: nil)
        return media
        
    }
    
    func deleteMedia(withId id: Int) async throws {
        guard let token = try await tokenManager.getToken() else {
            throw NetworkError.invalidValue
        }
        
        let config = CustomRequestConfigurable(headers: [
            HTTPHeaders.authorization.rawValue: "Bearer \(token.accessToken)"
        ])
        
        try await networking.request(
            .handleMedia(id.description),
            method: .DELETE,
            config: config)
    }
}

