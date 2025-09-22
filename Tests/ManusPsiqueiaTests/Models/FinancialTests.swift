import XCTest
@testable import ManusPsiqueia

class FinancialTests: XCTestCase {

    func testFinancialInitialization() {
        let financial = Financial(id: "fin_123", userId: "user_456", balance: 1000.00, currency: "BRL", lastUpdate: Date())
        XCTAssertNotNil(financial)
        XCTAssertEqual(financial.id, "fin_123")
        XCTAssertEqual(financial.userId, "user_456")
        XCTAssertEqual(financial.balance, 1000.00)
        XCTAssertEqual(financial.currency, "BRL")
    }

    func testFinancialBalanceUpdate() {
        var financial = Financial(id: "fin_123", userId: "user_456", balance: 1000.00, currency: "BRL", lastUpdate: Date())
        financial.balance += 500.00
        XCTAssertEqual(financial.balance, 1500.00)
    }

    func testFinancialEncodingDecoding() throws {
        let originalFinancial = Financial(id: "fin_123", userId: "user_456", balance: 1000.00, currency: "BRL", lastUpdate: Date())
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(originalFinancial)
        
        let decoder = JSONDecoder()
        let decodedFinancial = try decoder.decode(Financial.self, from: data)
        
        XCTAssertEqual(originalFinancial.id, decodedFinancial.id)
        XCTAssertEqual(originalFinancial.userId, decodedFinancial.userId)
        XCTAssertEqual(originalFinancial.balance, decodedFinancial.balance)
        XCTAssertEqual(originalFinancial.currency, decodedFinancial.currency)
    }
}


