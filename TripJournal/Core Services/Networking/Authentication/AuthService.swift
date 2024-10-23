import Foundation
import Combine

enum AuthRequestBodyType: String {
    case username
    case password
}

protocol AuthService {
    var isAuthenticated: AnyPublisher<Bool, Never> { get }
    func register(username: String, password: String) async throws -> Token
    func logIn(username: String, password: String) async throws -> Token
    func logOut() async
}

// MARK: - AuthenticationService Implementation
class AuthenticationService: AuthService, ObservableObject {
    
    enum AuthRequestBodyType: String {
        case username
        case password
    }
    
    // Dependencies
    private let tokenManager: TokenManager
    
    // Internal publisher for authentication state
    @Published private var token: Token? {
        didSet {
            Task {
                if let token = token {
                    await tokenManager.saveToken(token)
                } else {
                    await tokenManager.deleteToken()
                }
            }
        }
    }
    
    // MARK: - isAuthenticated Publisher
    /// Publisher that emits whether the user is authenticated or not.
    var isAuthenticated: AnyPublisher<Bool, Never> {
        $token.map { $0 != nil }.eraseToAnyPublisher()
    }
    
    // MARK: - Initialization
    init(tokenManager: TokenManager) {
        self.tokenManager = tokenManager
        Task {
            // Fetch token from storage during initialization
           await loadToken()
//            self.token = try? await tokenManager.getToken()
        }
        print("Initialized AuthenticationService")
    }
    
    @MainActor
        private func loadToken() async {
            if token == nil {
                self.token = try? await tokenManager.getToken()
            }
        }
    
    // MARK: - Register
    func register(username: String, password: String) async throws -> Token {
        let requestBody: [String: Any] = [AuthRequestBodyType.username.rawValue: username,
                                          AuthRequestBodyType.password.rawValue: password]
        let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
        
        print("About to register")
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
        token.expirationDate = Token.defaultDate()
        // Save the token and credentials to secure storage
        await tokenManager.saveToken(token, username: username, password: password)
        DispatchQueue.main.async {
            self.token = token
        }
        return token
    }
    
    // MARK: - Log In
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
        token.expirationDate = Token.defaultDate()
        
        // Save the token and credentials to secure storage
        await tokenManager.saveToken(token, username: username, password: password)
        DispatchQueue.main.async {
            self.token = token
        }
        return token
    }
    
    // MARK: - Log Out
    func logOut() async {
        DispatchQueue.main.async {
            self.token = nil
        }
        await tokenManager.deleteToken()
    }
}
