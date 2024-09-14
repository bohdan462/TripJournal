import Foundation
import Combine

// MARK: - NetworkClientProtocol
/// Combines network request building, sending, and response handling into one cohesive protocol.
protocol NetworkClientProtocol {
    func request<T: Decodable>(
        _ endpoint: TripRouter,
        responseType: T.Type,
        method: HTTPMethods,
        config: RequestConfigurable
    ) async throws -> T
}

extension NetworkClientProtocol {
    // Provides a default implementation for building requests based on RequestConfigurable
    func buildRequest(
        for endpoint: TripRouter,
        method: HTTPMethods,
        config: RequestConfigurable
    ) -> URLRequest {
        return config.createURLRequest(for: endpoint, method: method)
    }
    
    // Provides a default implementation for sending requests and handling responses
    func sendRequest<T: Decodable>(
        _ request: URLRequest,
        responseType: T.Type,
        session: NetworkSession
    ) async throws -> T {
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 || httpResponse.statusCode == 204 else {
            throw NetworkError.badResponse
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601 // Consistent date strategy
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

// MARK: - RequestConfigurable Protocol
protocol RequestConfigurable {
    var headers: [String: String] { get }
    var body: Data? { get }

    func createURLRequest(for endpoint: TripRouter, method: HTTPMethods) -> URLRequest
    func withAdditionalHeaders(_ additionalHeaders: [String: String]) -> RequestConfigurable
}

extension RequestConfigurable {
    func withAdditionalHeaders(_ additionalHeaders: [String: String]) -> RequestConfigurable {
        var modifiedHeaders = headers
        additionalHeaders.forEach { modifiedHeaders[$0] = $1 }
        return CustomRequestConfigurable(headers: modifiedHeaders, body: body)
    }
    
    func createURLRequest(for endpoint: TripRouter, method: HTTPMethods) -> URLRequest {
        var request = URLRequest(url: endpoint.url)
        request.httpMethod = method.rawValue
        
        // Apply headers
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        
        // Apply body if available
        if let body = body {
            request.httpBody = body
        }
        
        return request
    }
}

// MARK: - CustomRequestConfigurable
struct CustomRequestConfigurable: RequestConfigurable {
    var headers: [String: String]
    var body: Data?
    
    init(headers: [String: String], body: Data? = nil) {
        self.headers = headers
        self.body = body
    }
}

// MARK: - NetworkClient
class NetworkClient: NetworkClientProtocol {
    
    static let shared = NetworkClient()
    private let session: NetworkSession
    
    init(session: NetworkSession = URLSession.shared) {
        self.session = session
    }
    
    // Conforms to NetworkClientProtocol
    func request<T: Decodable>(
        _ endpoint: TripRouter,
        responseType: T.Type,
        method: HTTPMethods,
        config: RequestConfigurable
    ) async throws -> T {
        let request = buildRequest(for: endpoint, method: method, config: config)
        return try await sendRequest(request, responseType: responseType, session: session)
    }
}

// MARK: - URLSession Extension to Conform to NetworkSession Protocol
extension URLSession: NetworkSession {
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        return try await self.data(for: request)
    }
}

// MARK: - NetworkSession Protocol for Dependency Injection
protocol NetworkSession {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}
