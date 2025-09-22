import XCTest
@testable import ManusPsiqueia

class SubscriptionTests: XCTestCase {

    func testSubscriptionInitialization() {
        let subscription = Subscription(id: "sub_123", userId: "user_456", plan: "premium", startDate: Date(), endDate: Date().addingTimeInterval(3600*24*30), isActive: true)
        XCTAssertNotNil(subscription)
        XCTAssertEqual(subscription.id, "sub_123")
        XCTAssertEqual(subscription.userId, "user_456")
        XCTAssertEqual(subscription.plan, "premium")
        XCTAssertTrue(subscription.isActive)
    }

    func testSubscriptionIsActiveComputedProperty() {
        let activeSubscription = Subscription(id: "sub_123", userId: "user_456", plan: "premium", startDate: Date().addingTimeInterval(-3600), endDate: Date().addingTimeInterval(3600), isActive: true)
        XCTAssertTrue(activeSubscription.isActive)

        let inactiveSubscription = Subscription(id: "sub_123", userId: "user_456", plan: "premium", startDate: Date().addingTimeInterval(-3600*2), endDate: Date().addingTimeInterval(-3600), isActive: false)
        XCTAssertFalse(inactiveSubscription.isActive)
    }

    func testSubscriptionEncodingDecoding() throws {
        let originalSubscription = Subscription(id: "sub_123", userId: "user_456", plan: "premium", startDate: Date(), endDate: Date().addingTimeInterval(3600*24*30), isActive: true)
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(originalSubscription)
        
        let decoder = JSONDecoder()
        let decodedSubscription = try decoder.decode(Subscription.self, from: data)
        
        XCTAssertEqual(originalSubscription.id, decodedSubscription.id)
        XCTAssertEqual(originalSubscription.userId, decodedSubscription.userId)
        XCTAssertEqual(originalSubscription.plan, decodedSubscription.plan)
        XCTAssertEqual(originalSubscription.isActive, decodedSubscription.isActive)
    }
}


