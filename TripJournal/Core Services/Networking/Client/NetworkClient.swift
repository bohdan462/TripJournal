import Foundation
import Combine

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
