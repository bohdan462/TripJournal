import Foundation
import Combine

protocol AuthService {
    var isAuthenticated: AnyPublisher<Bool, Never> { get }
    func register(username: String, password: String) async throws -> Token
    func logIn(username: String, password: String) async throws -> Token
    func logOut() async
}

protocol TokenRefreshable {
    func refreshToken() async throws -> Token
}

class AuthServiceImpl: AuthService, TokenRefreshable {
    private let tokenManager: TokenManager
    @Published private var token: Token?

    var isAuthenticated: AnyPublisher<Bool, Never> {
        $token.map { $0 != nil }.eraseToAnyPublisher()
    }

    init(tokenManager: TokenManager) {
        self.tokenManager = tokenManager
        
        // Use a task to load the token asynchronously
        Task {
            self.token = try? await tokenManager.getToken()
        }
    }

    // MARK: - Register a New User
    func register(username: String, password: String) async throws -> Token {
        let requestBody: [String: Any] = ["username": username, "password": password]
        let jsonData = try JSONSerialization.data(withJSONObject: requestBody)

        // Use JSONRequest to build the request configuration
        let config = CustomRequestConfigurable(
            headers: [
                HTTPHeaders.accept.rawValue: MIMEType.JSON.rawValue,
                HTTPHeaders.contentType.rawValue: MIMEType.JSON.rawValue
            ],
            body: jsonData
        )

        // Make the network request using the revised NetworkClient
        let token: Token = try await NetworkClient.shared.request(
            .register,
            responseType: Token.self,
            method: .POST,
            config: config
        )

        // Save the token and credentials
        await tokenManager.saveToken(token, username: username, password: password)
        self.token = token
        return token
    }

    // MARK: - Log In an Existing User
    func logIn(username: String, password: String) async throws -> Token {
        let requestBody: [String: Any] = ["username": username, "password": password]
        let jsonData = try JSONSerialization.data(withJSONObject: requestBody)

        // Use JSONRequest to build the request configuration
        let config = CustomRequestConfigurable(
            headers: [
                HTTPHeaders.accept.rawValue: MIMEType.JSON.rawValue,
                HTTPHeaders.contentType.rawValue: MIMEType.JSON.rawValue
            ],
            body: jsonData
        )

        // Make the network request using the revised NetworkClient
        let token: Token = try await NetworkClient.shared.request(
            .login,
            responseType: Token.self,
            method: .POST,
            config: config
        )

        // Save the token and credentials
        await tokenManager.saveToken(token, username: username, password: password)
        self.token = token
        return token
    }

    // MARK: - Log Out the User
    func logOut() async {
        token = nil
        await tokenManager.deleteToken()
    }

    // MARK: - Token Refresh Implementation
    func refreshToken() async throws -> Token {
        guard let currentToken = try? await tokenManager.getToken() else {
            throw NetworkError.unauthorized // Handle missing token
        }

        // Simulate refreshing by re-login using stored credentials
        guard let credentialsData = try? await tokenManager.storage.get(forKey: "userCredentials"),
              let credentialsDict = try JSONSerialization.jsonObject(with: credentialsData, options: []) as? [String: String],
              let username = credentialsDict["username"],
              let password = credentialsDict["password"] else {
            throw KeychainError.unableToRetrieveData
        }

        // Re-login using cached credentials to get a new token
        let token = try await logIn(username: username, password: password)
        return token
    }
}
