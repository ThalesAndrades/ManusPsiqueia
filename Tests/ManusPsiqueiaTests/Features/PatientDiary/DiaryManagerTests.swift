import XCTest
@testable import ManusPsiqueia

class DiaryManagerTests: XCTestCase {

    var diaryManager: DiaryManager!
    var mockUserDefaults: MockUserDefaults!

    override func setUpWithError() throws {
        super.setUpWithError()
        mockUserDefaults = MockUserDefaults()
        diaryManager = DiaryManager(userDefaults: mockUserDefaults)
    }

    override func tearDownWithError() throws {
        diaryManager = nil
        mockUserDefaults = nil
        super.tearDownWithError()
    }

    func testAddEntry() {
        let initialCount = diaryManager.entries.count
        diaryManager.addEntry(title: "Test Title", content: "Test Content")
        XCTAssertEqual(diaryManager.entries.count, initialCount + 1)
        XCTAssertEqual(diaryManager.entries.last?.title, "Test Title")
    }

    func testDeleteEntry() {
        diaryManager.addEntry(title: "Test Title", content: "Test Content")
        let entryToDelete = diaryManager.entries.first!
        let initialCount = diaryManager.entries.count
        diaryManager.deleteEntry(entryToDelete)
        XCTAssertEqual(diaryManager.entries.count, initialCount - 1)
        XCTAssertFalse(diaryManager.entries.contains(where: { $0.id == entryToDelete.id }))
    }

    func testUpdateEntry() {
        diaryManager.addEntry(title: "Original Title", content: "Original Content")
        var entryToUpdate = diaryManager.entries.first!
        entryToUpdate.title = "Updated Title"
        entryToUpdate.content = "Updated Content"
        diaryManager.updateEntry(entryToUpdate)
        
        let updatedEntry = diaryManager.entries.first(where: { $0.id == entryToUpdate.id })
        XCTAssertEqual(updatedEntry?.title, "Updated Title")
        XCTAssertEqual(updatedEntry?.content, "Updated Content")
    }

    func testLoadAndSaveEntries() {
        diaryManager.addEntry(title: "Entry 1", content: "Content 1")
        diaryManager.addEntry(title: "Entry 2", content: "Content 2")
        
        // Simulate saving and then loading from new manager instance
        let newDiaryManager = DiaryManager(userDefaults: mockUserDefaults)
        XCTAssertEqual(newDiaryManager.entries.count, 2)
        XCTAssertEqual(newDiaryManager.entries.first?.title, "Entry 1")
    }
}

class MockUserDefaults: UserDefaults {
    var data = [String: Any]()

    override func set(_ value: Any?, forKey defaultName: String) {
        data[defaultName] = value
    }

    override func object(forKey defaultName: String) -> Any? {
        return data[defaultName]
    }
}


