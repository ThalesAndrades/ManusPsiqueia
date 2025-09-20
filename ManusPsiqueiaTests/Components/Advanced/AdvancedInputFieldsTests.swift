import XCTest
import SwiftUI
@testable import ManusPsiqueia

class AdvancedInputFieldsTests: XCTestCase {

    func testAdvancedTextFieldInitialization() {
        @State var text: String = ""
        let textField = AdvancedTextField(placeholder: "Enter text", text: $text)
        XCTAssertNotNil(textField, "AdvancedTextField should be initializable")
    }
    
    func testAdvancedSecureFieldInitialization() {
        @State var text: String = ""
        let secureField = AdvancedSecureField(placeholder: "Enter password", text: $text)
        XCTAssertNotNil(secureField, "AdvancedSecureField should be initializable")
    }
}


