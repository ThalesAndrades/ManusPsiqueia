import XCTest
@testable import ManusPsiqueia

class DiaryEntryTests: XCTestCase {

    func testDiaryEntryInitialization() {
        let entry = DiaryEntry(id: UUID(), userId: "user_123", title: "My First Entry", content: "Today was a good day.", date: Date())
        XCTAssertNotNil(entry)
        XCTAssertEqual(entry.userId, "user_123")
        XCTAssertEqual(entry.title, "My First Entry")
        XCTAssertEqual(entry.content, "Today was a good day.")
    }

    func testDiaryEntryEncodingDecoding() throws {
        let originalEntry = DiaryEntry(id: UUID(), userId: "user_123", title: "My First Entry", content: "Today was a good day.", date: Date())
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(originalEntry)
        
        let decoder = JSONDecoder()
        let decodedEntry = try decoder.decode(DiaryEntry.self, from: data)
        
        XCTAssertEqual(originalEntry.id, decodedEntry.id)
        XCTAssertEqual(originalEntry.userId, decodedEntry.userId)
        XCTAssertEqual(originalEntry.title, decodedEntry.title)
        XCTAssertEqual(originalEntry.content, decodedEntry.content)
    }
}


