import XCTest
@testable import ManusPsiqueia

class AuthenticationManagerTests: XCTestCase {

    var authenticationManager: AuthenticationManager!

    override func setUpWithError() throws {
        super.setUpWithError()
        authenticationManager = AuthenticationManager()
        // Clear any existing user data for clean tests
        UserDefaults.standard.removeObject(forKey: "currentUser")
        authenticationManager.isAuthenticated = false
        authenticationManager.currentUser = nil
    }

    override func tearDownWithError() throws {
        authenticationManager = nil
        UserDefaults.standard.removeObject(forKey: "currentUser")
        super.tearDownWithError()
    }

    func testInitialState() {
        XCTAssertFalse(authenticationManager.isAuthenticated)
        XCTAssertNil(authenticationManager.currentUser)
        XCTAssertNil(authenticationManager.authenticationError)
    }

    func testInitWithExistingUser() throws {
        // Simulate existing user data in UserDefaults
        let testUser = User(
            id: UUID(),
            email: "test@example.com",
            firstName: "Test",
            lastName: "User",
            userType: .patient
        )
        let userData = try JSONEncoder().encode(testUser)
        UserDefaults.standard.set(userData, forKey: "currentUser")
        
        // Create new manager to test initialization
        let newManager = AuthenticationManager()
        
        XCTAssertTrue(newManager.isAuthenticated)
        XCTAssertNotNil(newManager.currentUser)
        XCTAssertEqual(newManager.currentUser?.email, "test@example.com")
    }

    func testLogout() {
        // Simulate a logged-in state
        let testUser = User(
            id: UUID(),
            email: "test@example.com",
            firstName: "Test",
            lastName: "User",
            userType: .patient
        )
        authenticationManager.currentUser = testUser
        authenticationManager.isAuthenticated = true

        authenticationManager.logout()

        XCTAssertFalse(authenticationManager.isAuthenticated)
        XCTAssertNil(authenticationManager.currentUser)
        XCTAssertNil(UserDefaults.standard.data(forKey: "currentUser"))
    }

    func testUpdateProfile() throws {
        // Setup initial user
        let initialUser = User(
            id: UUID(),
            email: "initial@example.com",
            firstName: "Initial",
            lastName: "User",
            userType: .patient
        )
        authenticationManager.currentUser = initialUser
        authenticationManager.isAuthenticated = true
        
        // Update profile
        let updatedUser = User(
            id: initialUser.id,
            email: "updated@example.com",
            firstName: "Updated",
            lastName: "User",
            userType: .psychologist
        )
        authenticationManager.updateProfile(user: updatedUser)
        
        // Verify update
        XCTAssertEqual(authenticationManager.currentUser?.email, "updated@example.com")
        XCTAssertEqual(authenticationManager.currentUser?.firstName, "Updated")
        XCTAssertEqual(authenticationManager.currentUser?.userType, .psychologist)
        
        // Verify persistence
        let savedData = UserDefaults.standard.data(forKey: "currentUser")
        XCTAssertNotNil(savedData)
        let savedUser = try JSONDecoder().decode(User.self, from: savedData!)
        XCTAssertEqual(savedUser.email, "updated@example.com")
    }

    func testAuthenticationErrorHandling() {
        // Initially no error
        XCTAssertNil(authenticationManager.authenticationError)
        
        // Test that error state can be set (this would normally happen in login/register methods)
        authenticationManager.authenticationError = .invalidResponse
        XCTAssertNotNil(authenticationManager.authenticationError)
        XCTAssertEqual(authenticationManager.authenticationError, .invalidResponse)
    }

    func testLoginMethodExists() {
        // Test that login method exists and can be called without crashing
        // Note: This doesn't test the network call success/failure as that requires mocking
        authenticationManager.login(email: "test@example.com", password: "password")
        
        // Should not crash and method should exist
        XCTAssertTrue(true, "Login method executed without crashing")
    }

    func testRegisterMethodExists() {
        // Test that register method exists and can be called without crashing
        let testUser = User(
            id: UUID(),
            email: "test@example.com",
            firstName: "Test",
            lastName: "User",
            userType: .patient
        )
        authenticationManager.register(user: testUser, password: "password")
        
        // Should not crash and method should exist
        XCTAssertTrue(true, "Register method executed without crashing")
    }

    func testUserPersistence() throws {
        // Test that user data is properly persisted and restored
        let testUser = User(
            id: UUID(),
            email: "persistence@example.com",
            firstName: "Persistence",
            lastName: "User",
            userType: .psychologist
        )
        
        // Update profile to trigger persistence
        authenticationManager.updateProfile(user: testUser)
        
        // Verify data is saved
        let savedData = UserDefaults.standard.data(forKey: "currentUser")
        XCTAssertNotNil(savedData)
        
        // Verify data can be decoded correctly
        let decodedUser = try JSONDecoder().decode(User.self, from: savedData!)
        XCTAssertEqual(decodedUser.id, testUser.id)
        XCTAssertEqual(decodedUser.email, testUser.email)
        XCTAssertEqual(decodedUser.firstName, testUser.firstName)
        XCTAssertEqual(decodedUser.userType, testUser.userType)
    }
}