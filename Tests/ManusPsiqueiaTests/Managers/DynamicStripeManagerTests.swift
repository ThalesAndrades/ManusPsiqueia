import XCTest
@testable import ManusPsiqueiaCore
@testable import ManusPsiqueiaUI
@testable import ManusPsiqueiaServices

class DynamicStripeManagerTests: XCTestCase {

    var dynamicStripeManager: DynamicStripeManager!
    var mockStripeManager: MockStripeManager!

    override func setUpWithError() throws {
        super.setUpWithError()
        mockStripeManager = MockStripeManager()
        dynamicStripeManager = DynamicStripeManager(stripeManager: mockStripeManager)
    }

    override func tearDownWithError() throws {
        dynamicStripeManager = nil
        mockStripeManager = nil
        super.tearDownWithError()
    }

    func testFetchDynamicPricing() async throws {
        let expectation = self.expectation(description: "Dynamic pricing fetched")

        // Mock the behavior of fetching dynamic pricing from a backend or local source
        // For this test, we will simulate a successful fetch.
        let mockDynamicPricing = DynamicPricing(basePrice: 89.90, currency: "BRL", factors: ["demand": 1.2, "region": 1.0])
        mockStripeManager.mockDynamicPricing = mockDynamicPricing

        dynamicStripeManager.fetchDynamicPricing { result in
            switch result {
            case .success(let pricing):
                XCTAssertEqual(pricing.basePrice, 89.90)
                XCTAssertEqual(pricing.currency, "BRL")
                XCTAssertEqual(pricing.factors["demand"], 1.2)
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Failed to fetch dynamic pricing with error: \(error.localizedDescription)")
            }
        }
        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testCalculateFinalPrice() {
        let dynamicPricing = DynamicPricing(basePrice: 89.90, currency: "BRL", factors: ["demand": 1.2, "region": 1.0])
        let finalPrice = dynamicStripeManager.calculateFinalPrice(basePrice: dynamicPricing.basePrice, factors: dynamicPricing.factors)
        XCTAssertEqual(finalPrice, 89.90 * 1.2)
    }

    func testCreatePaymentIntentWithDynamicPrice() async throws {
        let expectation = self.expectation(description: "Payment intent created with dynamic price")

        let mockDynamicPricing = DynamicPricing(basePrice: 89.90, currency: "BRL", factors: ["demand": 1.2, "region": 1.0])
        mockStripeManager.mockDynamicPricing = mockDynamicPricing
        mockStripeManager.mockPaymentIntentClientSecret = "pi_dynamic_123_secret"

        dynamicStripeManager.createPaymentIntent(userId: "user_123", plan: "premium") { result in
            switch result {
            case .success(let clientSecret):
                XCTAssertEqual(clientSecret, "pi_dynamic_123_secret")
                XCTAssertTrue(self.mockStripeManager.createPaymentIntentCalled)
                XCTAssertEqual(self.mockStripeManager.lastPaymentIntentAmount, 89.90 * 1.2)
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Failed to create payment intent with dynamic price: \(error.localizedDescription)")
            }
        }
        waitForExpectations(timeout: 1.0, handler: nil)
    }
}

// Re-using MockStripeManager from AutoUpgradeManagerTests, extending it for DynamicStripeManagerTests
extension MockStripeManager {
    var mockDynamicPricing: DynamicPricing? = nil
    var mockPaymentIntentClientSecret: String? = nil
    var createPaymentIntentCalled = false
    var lastPaymentIntentAmount: Double? = nil

    override func fetchDynamicPricing(completion: @escaping (Result<DynamicPricing, Error>) -> Void) {
        if let pricing = mockDynamicPricing {
            completion(.success(pricing))
        } else {
            completion(.failure(NSError(domain: "MockError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Dynamic pricing not set in mock"])))
        }
    }

    override func createPaymentIntent(userId: String, amount: Double, currency: String, completion: @escaping (Result<String, Error>) -> Void) {
        createPaymentIntentCalled = true
        lastPaymentIntentAmount = amount
        if let clientSecret = mockPaymentIntentClientSecret {
            completion(.success(clientSecret))
        } else {
            completion(.failure(NSError(domain: "MockError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Payment intent client secret not set in mock"])))
        }
    }
}


