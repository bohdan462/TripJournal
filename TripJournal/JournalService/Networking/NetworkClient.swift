//
//  NetworkClient.swift
//  TripJournal
//
//  Created by Bohdan Tkachenko on 9/13/24.
//

import Foundation

// MARK: - HTTPClient
/// focuses purely on making network requests.
protocol HTTPClient {
    func sendRequest<T: Decodable>(_ request: URLRequest, responseType: T.Type) async throws -> T
}
// MARK: - NetworkService
protocol NetworkService {
    func request<T: Decodable>(_ endpoint: TripRouter, responseType: T.Type, method: HTTPMethods, body: Data?, token: String?) async throws -> T
    func requestWithBody<T: Decodable, U: Encodable>(_ endpoint: TripRouter, body: U, responseType: T.Type, method: HTTPMethods, token: String?) async throws -> T
}

// MARK: - RequestBuilder
///is responsible for building requests.
protocol RequestBuilder {
    func buildRequest(for endpoint: TripRouter, method: HTTPMethods, token: String?, body: Data?) -> URLRequest
}

// MARK: - ResponseHandler
protocol ResponseHandler {
    func handleResponse<T: Decodable>(_ data: Data, response: URLResponse, type: T.Type) throws -> T
}

class NetworkClient: HTTPClient, NetworkService, RequestBuilder, ResponseHandler {
    
    static let shared = NetworkClient()
    
    // MARK: - HTTPClient Conformance
    func sendRequest<T>(_ request: URLRequest, responseType: T.Type) async throws -> T where T : Decodable {
        let (data, response) = try await URLSession.shared.data(for: request)
        return try handleResponse(data, response: response, type: responseType)
    }
    
    // MARK: - NetworkService Conformance
    
    ///.GET
    func request<T>(_ endpoint: TripRouter, responseType: T.Type, method: HTTPMethods, body: Data? = nil, token: String?) async throws -> T where T : Decodable {
        let request = buildRequest(for: endpoint, method: method, token: token, body: body)
        return try await sendRequest(request, responseType: responseType)
    }
    
    ///.POST
    func requestWithBody<T, U>(_ endpoint: TripRouter, body: U, responseType: T.Type, method: HTTPMethods, token: String? = nil) async throws -> T where T : Decodable, U : Encodable {
        let bodyData = try JSONEncoder().encode(body)
        let request = buildRequest(for: endpoint, method: method, token: token, body: bodyData)
        return try await sendRequest(request, responseType: responseType)
    }
    
    // MARK: - RequestBuilder Conformance
    func buildRequest(for endpoint: TripRouter, method: HTTPMethods, token: String?, body: Data?) -> URLRequest {
        
        var request = URLRequest(url: endpoint.url)
        request.httpMethod = method.rawValue
        request.httpBody = body
        request.addValue(MIMEType.JSON.rawValue, forHTTPHeaderField: HTTPHeaders.contentType.rawValue)
        
        if let token = token {
            request.addValue("Bearer \(token)", forHTTPHeaderField:HTTPHeaders.authorization.rawValue)
        }
        
        return request
    }
    
    // MARK: - ResponseHandler
    func handleResponse<T>(_ data: Data, response: URLResponse, type: T.Type) throws -> T where T : Decodable {
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 || httpResponse.statusCode == 204 else {
            throw NetworkError.badResponse
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            do {
                return try JSONDecoder().decode(T.self, from: data)
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
