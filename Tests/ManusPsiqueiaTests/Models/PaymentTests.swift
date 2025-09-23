import XCTest
@testable import ManusPsiqueiaCore
@testable import ManusPsiqueiaUI
@testable import ManusPsiqueiaServices

class PaymentTests: XCTestCase {

    func testPaymentInitialization() {
        let payment = Payment(id: "pay_123", userId: "user_456", amount: 89.90, currency: "BRL", date: Date(), status: .completed)
        XCTAssertNotNil(payment)
        XCTAssertEqual(payment.id, "pay_123")
        XCTAssertEqual(payment.userId, "user_456")
        XCTAssertEqual(payment.amount, 89.90)
        XCTAssertEqual(payment.currency, "BRL")
        XCTAssertEqual(payment.status, .completed)
    }

    func testPaymentStatusChange() {
        var payment = Payment(id: "pay_123", userId: "user_456", amount: 89.90, currency: "BRL", date: Date(), status: .pending)
        XCTAssertEqual(payment.status, .pending)
        payment.status = .completed
        XCTAssertEqual(payment.status, .completed)
    }

    func testPaymentEncodingDecoding() throws {
        let originalPayment = Payment(id: "pay_123", userId: "user_456", amount: 89.90, currency: "BRL", date: Date(), status: .completed)
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(originalPayment)
        
        let decoder = JSONDecoder()
        let decodedPayment = try decoder.decode(Payment.self, from: data)
        
        XCTAssertEqual(originalPayment.id, decodedPayment.id)
        XCTAssertEqual(originalPayment.userId, decodedPayment.userId)
        XCTAssertEqual(originalPayment.amount, decodedPayment.amount)
        XCTAssertEqual(originalPayment.currency, decodedPayment.currency)
        XCTAssertEqual(originalPayment.status, decodedPayment.status)
    }
}


