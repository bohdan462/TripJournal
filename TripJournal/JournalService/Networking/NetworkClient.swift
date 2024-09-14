import Foundation
import Combine

// MARK: - NetworkClientProtocol
/**
 A protocol that combines network request building, sending, and response handling into one cohesive interface.
 It defines the essential method to execute a network request and decode the response.

 ## Methods:
 - **request**: Executes a network request with the given parameters, builds the request, and decodes the response.
 - **sendRequest**: A helper method that sends the request and handles the response.
 - **buildRequest**: A method to construct the URLRequest based on the provided configuration.
 */
protocol NetworkClientProtocol {
    /**
     Executes a network request and decodes the response into the provided type.
     
     - Parameters:
        - endpoint: A `TripRouter` value representing the API endpoint to hit.
        - responseType: The type of the response that conforms to `Decodable`.
        - method: The HTTP method to use for the request (e.g., GET, POST).
        - config: A `RequestConfigurable` instance containing request headers, body, etc.
     - Throws: An error if the request fails or if the decoding of the response fails.
     - Returns: The decoded response of the specified type.
     */
    func request<T: Decodable>(
        _ endpoint: TripRouter,
        responseType: T.Type,
        method: HTTPMethods,
        config: RequestConfigurable
    ) async throws -> T
}

extension NetworkClientProtocol {

    /**
     Executes a network request without expecting a response body. Primarily used for DELETE or POST requests that don't return a body.
     
     - Parameters:
        - endpoint: A `TripRouter` value representing the API endpoint to hit.
        - method: The HTTP method to use for the request (e.g., GET, POST).
        - config: A `RequestConfigurable` instance containing request headers, body, etc.
     - Throws: An error if the request fails or if the status code is not in the expected range.
     */
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
    
    /**
     Constructs a URLRequest based on the provided endpoint, HTTP method, and request configuration.

     - Parameters:
        - endpoint: A `TripRouter` value representing the API endpoint to hit.
        - method: The HTTP method to use for the request (e.g., GET, POST).
        - config: A `RequestConfigurable` instance containing request headers, body, etc.
     - Returns: A `URLRequest` configured with the provided parameters.
     */
    func buildRequest(
        for endpoint: TripRouter,
        method: HTTPMethods,
        config: RequestConfigurable
    ) -> URLRequest {
        return config.createURLRequest(for: endpoint, method: method)
    }
    
    /**
     Sends the constructed request and decodes the response into the provided type.

     - Parameters:
        - request: The constructed `URLRequest` to send.
        - responseType: The type of the response that conforms to `Decodable`.
        - session: A `NetworkSession` instance to handle the request.
     - Throws: An error if the request fails or if the decoding of the response fails.
     - Returns: The decoded response of the specified type.
     */
    func sendRequest<T: Decodable>(
        _ request: URLRequest,
        responseType: T.Type,
        session: NetworkSession
    ) async throws -> T {
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.badResponse
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601 // Ensure consistent date decoding
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
/**
 A protocol that defines a configurable request structure. It allows creating a `URLRequest` with custom headers and body and supports adding additional headers.

 ## Methods:
 - **createURLRequest**: Creates and configures a `URLRequest` for the specified endpoint and HTTP method.
 - **withAdditionalHeaders**: Returns a new `RequestConfigurable` with additional headers.
 */
protocol RequestConfigurable {
    var headers: [String: String] { get }
    var body: Data? { get }

    /**
     Creates a `URLRequest` based on the specified endpoint and HTTP method.

     - Parameters:
        - endpoint: A `TripRouter` value representing the API endpoint.
        - method: The HTTP method to use for the request (e.g., GET, POST).
     - Returns: A configured `URLRequest`.
     */
    func createURLRequest(for endpoint: TripRouter, method: HTTPMethods) -> URLRequest

    /**
     Adds additional headers to the current configuration.

     - Parameters:
        - additionalHeaders: A dictionary of additional headers to include.
     - Returns: A new `RequestConfigurable` instance with the combined headers.
     */
    func withAdditionalHeaders(_ additionalHeaders: [String: String]) -> RequestConfigurable
}

extension RequestConfigurable {
    
    /**
     Adds additional headers to the current configuration and returns a new `RequestConfigurable` object.

     - Parameters:
        - additionalHeaders: A dictionary of headers to add.
     - Returns: A modified `RequestConfigurable` object with additional headers.
     */
    func withAdditionalHeaders(_ additionalHeaders: [String: String]) -> RequestConfigurable {
        var modifiedHeaders = headers
        additionalHeaders.forEach { modifiedHeaders[$0] = $1 }
        return CustomRequestConfigurable(headers: modifiedHeaders, body: body)
    }
    
    /**
     Constructs a `URLRequest` using the provided endpoint and HTTP method.

     - Parameters:
        - endpoint: A `TripRouter` value representing the API endpoint.
        - method: The HTTP method to use for the request (e.g., GET, POST).
     - Returns: A `URLRequest` object configured with headers and body.
     */
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
/**
 A concrete implementation of `RequestConfigurable`. It holds request headers and an optional body, allowing for the construction of requests.

 ## Properties:
 - **headers**: A dictionary of request headers.
 - **body**: Optional data representing the request body.
 */
struct CustomRequestConfigurable: RequestConfigurable {
    var headers: [String: String]
    var body: Data?

    /**
     Initializes a `CustomRequestConfigurable` object with specified headers and an optional body.
     
     - Parameters:
        - headers: A dictionary of request headers.
        - body: Optional data representing the request body.
     */
    init(headers: [String: String], body: Data? = nil) {
        self.headers = headers
        self.body = body
    }
}

// MARK: - NetworkClient
/**
 A concrete implementation of `NetworkClientProtocol` that uses `URLSession` to execute network requests. It manages the network session, constructs requests, and handles responses.

 ## Key Features:
 - Implements the `NetworkClientProtocol` to manage network requests.
 - Uses a shared instance for simple access.
 - Can be injected with any session conforming to `NetworkSession` for easy testing and flexibility.

 ## Methods:
 - **request**: Executes a network request and decodes the response into the specified type.
 */
class NetworkClient: NetworkClientProtocol {
    
    static let shared = NetworkClient()
    private let session: NetworkSession
    
    /**
     Initializes the `NetworkClient` with a custom session. The default session is `URLSession.shared`.
     
     - Parameter session: A custom `NetworkSession` to handle network requests. Defaults to `URLSession.shared`.
     */
    init(session: NetworkSession = URLSession.shared) {
        self.session = session
    }
    
    /**
     Executes a network request and decodes the response into the provided type.

     - Parameters:
        - endpoint: A `TripRouter` value representing the API endpoint to hit.
        - responseType: The type of the response that conforms to `Decodable`.
        - method: The HTTP method to use for the request (e.g., GET, POST).
        - config: A `RequestConfigurable` instance containing request headers, body, etc.
     - Throws: An error if the request fails or if the decoding of the response fails.
     - Returns: The decoded response of the specified type.
     */
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
/**
 Extends `URLSession` to conform to the `NetworkSession` protocol, making it easier to inject into `NetworkClient` for flexibility and testing.

 ## Methods:
 - **data(for:)**: Executes the request and returns the response data.
 */
extension URLSession: NetworkSession {
    /**
     Executes the network request and returns the response data and metadata.
     
     - Parameter request: The `URLRequest` to execute.
     - Throws: An error if the request fails.
     - Returns: A tuple containing the response data and the URL response.
     */
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        return try await self.data(for: request)
    }
}

// MARK: - NetworkSession Protocol for Dependency Injection
/**
 A protocol to abstract the network session, making it easy to inject custom network handling classes or mock implementations for testing.

 ## Methods:
 - **data(for:)**: Executes the network request and returns the response data.
 */
protocol NetworkSession {
    /**
     Executes the network request and returns the response data and metadata.
     
     - Parameter request: The `URLRequest` to execute.
     - Throws: An error if the request fails.
     - Returns: A tuple containing the response data and the URL response.
     */
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}
