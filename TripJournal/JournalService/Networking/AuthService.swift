import Foundation
import Combine

/**
 The `AuthService` protocol defines the basic authentication functionality that any authentication service must provide. It includes methods for registering, logging in, logging out, and a publisher for the authentication state.
 
 - `isAuthenticated`: A `Combine` publisher that informs whether the user is authenticated.
 - `register(username:password:)`: Registers a new user with the given credentials.
 - `logIn(username:password:)`: Logs in an existing user.
 - `logOut()`: Logs out the current user.
 */
protocol AuthService {
    var isAuthenticated: AnyPublisher<Bool, Never> { get }
    func register(username: String, password: String) async throws -> Token
    func logIn(username: String, password: String) async throws -> Token
    func logOut() async
}

/**
 The `TokenRefreshable` protocol provides functionality for refreshing the authentication token.
 */
protocol TokenRefreshable {
    func refreshToken() async throws -> Token
}

/**
 The `AuthServiceImpl` class provides the implementation of the `AuthService` and `TokenRefreshable` protocols. It handles user authentication (register, login, logout) and token management. The class works with the `TokenManager` to store and retrieve authentication tokens and uses `Combine` for state management and publishing changes to the authentication state.
 
 ## Key Features:
 - Register a new user.
 - Log in an existing user.
 - Log out the current user.
 - Refresh the authentication token when expired.
 
 ## Dependencies:
 - `TokenManager`: Manages the storage, retrieval, and expiration of authentication tokens.
 
 ## Properties:
 - `tokenManager`: Manages token operations like saving, retrieving, and deleting tokens.
 - `token`: Holds the currently authenticated user's token (if available).
 - `isAuthenticated`: A `Combine` publisher that emits authentication status changes.
 */
class AuthenticationService: AuthService, TokenRefreshable {
    
    private let tokenManager: TokenManager
    
    @Published private var token: Token? {
        didSet {
            Task {
                (token?.expirationDate != nil ) ? await tokenManager.saveToken(token!) : await tokenManager.deleteToken()
            }
        }
    }
    
    /// Publisher that emits whether the user is authenticated or not.
    var isAuthenticated: AnyPublisher<Bool, Never> {
        $token.map { $0 != nil }.eraseToAnyPublisher()
    }
    

    init(tokenManager: TokenManager) {
        self.tokenManager = tokenManager
        
        Task {
            self.token = try? await tokenManager.getToken()
        }
    }

    func register(username: String, password: String) async throws -> Token {
        let requestBody: [String: Any] = ["username": username, "password": password]
        let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
        print("about to register")
        // Set up request configuration
        let config = CustomRequestConfigurable(
            headers: [
                HTTPHeaders.accept.rawValue: MIMEType.JSON.rawValue,
                HTTPHeaders.contentType.rawValue: MIMEType.JSON.rawValue
            ],
            body: jsonData
        )
        
        // Send the request to the server
        var token: Token = try await NetworkClient.shared.request(
            .register,
            responseType: Token.self,
            method: .POST,
            config: config
        )
        
        // Save the token and credentials to secure storage
        await tokenManager.saveToken(token, username: username, password: password)
        token.expirationDate = Token.defaultDate()
        self.token = token
        return token
    }

    func logIn(username: String, password: String) async throws -> Token {
        let requestBody = "grant_type=&username=\(username)&password=\(password)"
        let data = requestBody.data(using: .utf8)
        
        // Set up request configuration
        let config = CustomRequestConfigurable(
            headers: [
                HTTPHeaders.accept.rawValue: MIMEType.JSON.rawValue,
                HTTPHeaders.contentType.rawValue: MIMEType.form.rawValue
            ],
            body: data
        )
        
        // Send the request to the server
        var token: Token = try await NetworkClient.shared.request(
            .login,
            responseType: Token.self,
            method: .POST,
            config: config
        )
        // Save the token and credentials to secure storage
        token.expirationDate = Token.defaultDate()
        await tokenManager.saveToken(token, username: username, password: password)
        self.token = token
        return token
    }

    func logOut() async {
        token = nil
        await tokenManager.deleteToken()
    }

    func refreshToken() async throws -> Token {
        // Retrieve the current token
        guard let _ = try? await tokenManager.getToken() else {
            throw NetworkError.unauthorized // Handle missing token
        }
        
        // Retrieve stored credentials (username, password) from secure storage
        guard let credentialsData = try? await tokenManager.storage.get(forKey: "userCredentials"),
              let credentialsDict = try JSONSerialization.jsonObject(with: credentialsData, options: []) as? [String: String],
              let username = credentialsDict["username"],
              let password = credentialsDict["password"] else {
            throw KeychainError.unableToRetrieveData
        }
        
        // Re-login using cached credentials to obtain a new token
        let token = try await logIn(username: username, password: password)
        return token
    }
}
