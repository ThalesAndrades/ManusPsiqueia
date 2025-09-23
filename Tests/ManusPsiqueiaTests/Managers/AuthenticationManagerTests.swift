import XCTest
@testable import ManusPsiqueia

class AuthenticationManagerTests: XCTestCase {

    var authenticationManager: AuthenticationManager!
    var mockNetworkManager: MockNetworkManager!

    override func setUpWithError() throws {
        super.setUpWithError()
        mockNetworkManager = MockNetworkManager()
        authenticationManager = AuthenticationManager(networkManager: mockNetworkManager)
    }

    override func tearDownWithError() throws {
        authenticationManager = nil
        mockNetworkManager = nil
        super.tearDownWithError()
    }

    func testLogin_success() async throws {
        let expectation = self.expectation(description: "Login should succeed")
        let mockUser = User(id: "user_123", email: "test@example.com", userType: .patient)
        mockNetworkManager.mockResponseData = try JSONEncoder().encode(mockUser)
        mockNetworkManager.mockError = nil

        authenticationManager.login(email: "test@example.com", password: "password123") { result in
            switch result {
            case .success(let user):
                XCTAssertEqual(user.email, "test@example.com")
                XCTAssertTrue(self.authenticationManager.isAuthenticated)
                XCTAssertEqual(self.authenticationManager.currentUser?.id, "user_123")
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Login failed with error: \(error.localizedDescription)")
            }
        }
        await fulfillment(of: [expectation], timeout: 1.0)
    }

    func testLogin_failure() async throws {
        let expectation = self.expectation(description: "Login should fail")
        let mockError = NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "Invalid credentials"])
        mockNetworkManager.mockResponseData = nil
        mockNetworkManager.mockError = mockError

        authenticationManager.login(email: "wrong@example.com", password: "wrong") { result in
            switch result {
            case .success(_):
                XCTFail("Login should have failed")
            case .failure(let error):
                XCTAssertFalse(self.authenticationManager.isAuthenticated)
                XCTAssertNil(self.authenticationManager.currentUser)
                XCTAssertEqual((error as NSError).code, 401)
                expectation.fulfill()
            }
        }
        await fulfillment(of: [expectation], timeout: 1.0)
    }

    func testRegister_success() async throws {
        let expectation = self.expectation(description: "Registration should succeed")
        let mockUser = User(id: "user_456", email: "new@example.com", userType: .psychologist)
        mockNetworkManager.mockResponseData = try JSONEncoder().encode(mockUser)
        mockNetworkManager.mockError = nil

        authenticationManager.register(email: "new@example.com", password: "newpassword", userType: .psychologist) { result in
            switch result {
            case .success(let user):
                XCTAssertEqual(user.email, "new@example.com")
                XCTAssertTrue(self.authenticationManager.isAuthenticated)
                XCTAssertEqual(self.authenticationManager.currentUser?.id, "user_456")
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Registration failed with error: \(error.localizedDescription)")
            }
        }
        await fulfillment(of: [expectation], timeout: 1.0)
    }

    func testLogout() {
        // Simulate a logged-in state
        authenticationManager.currentUser = User(id: "user_123", email: "test@example.com", userType: .patient)
        authenticationManager.isAuthenticated = true

        authenticationManager.logout()

        XCTAssertFalse(authenticationManager.isAuthenticated)
        XCTAssertNil(authenticationManager.currentUser)
    }
}

// Mock NetworkManager for AuthenticationManagerTests
class MockNetworkManager: NetworkManager {
    var mockResponseData: Data?
    var mockError: Error?

    override func performRequest(url: URL, method: String = "GET", headers: [String: String]? = nil, body: Data? = nil, completion: @escaping (Result<Data, Error>) -> Void) {
        if let error = mockError {
            completion(.failure(error))
        } else if let data = mockResponseData {
            completion(.success(data))
        } else {
            completion(.failure(NSError(domain: "MockError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No mock data or error provided"])))
        }
    }
}


