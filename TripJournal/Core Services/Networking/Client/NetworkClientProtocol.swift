//
//  NetworkClientProtocol.swift
//  TripJournal
//
//  Created by Bohdan Tkachenko on 10/22/24.
//

import Foundation

protocol NetworkClientProtocol {

    func request<T: Decodable>(
        _ endpoint: TripRouter,
        responseType: T.Type,
        method: HTTPMethods,
        config: RequestConfigurable
    ) async throws -> T
}

extension NetworkClientProtocol {

    func request(
        _ endpoint: TripRouter,
        method: HTTPMethods,
        config: RequestConfigurable
    ) async throws {
        let request = buildRequest(for: endpoint, method: method, config: config)
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.badResponse
        }
    }

    func buildRequest(
        for endpoint: TripRouter,
        method: HTTPMethods,
        config: RequestConfigurable
    ) -> URLRequest {
        return config.createURLRequest(for: endpoint, method: method)
    }
    
    func sendRequest<T: Decodable>(
        _ request: URLRequest,
        responseType: T.Type,
        session: URLSession
    ) async throws -> T {
        print("NetworkClient -> sendRequest() called")
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.badResponse
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                return try decoder.decode(T.self, from: data)
            } catch {
                throw NetworkError.failedToDecodeResponse
            }
        case 401:
            throw NetworkError.unauthorized
        case 404:
            throw NetworkError.notFound
        default:
            throw NetworkError.badResponse
        }
    }
}


