import Foundation
import Combine

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
        
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }

        if let body = body {
            request.httpBody = body
        }
        
        return request
    }
}

struct CustomRequestConfigurable: RequestConfigurable {
    var headers: [String: String]
    var body: Data?

    init(headers: [String: String], body: Data? = nil) {
        self.headers = headers
        self.body = body
    }
}

class NetworkClient: NetworkClientProtocol {
    
    static let shared = NetworkClient()
    private let session: URLSession

    init(session: URLSession = URLSession.shared) {
        self.session = session
    }

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
