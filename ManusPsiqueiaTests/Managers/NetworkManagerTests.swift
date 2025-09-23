import XCTest
@testable import ManusPsiqueia

class NetworkManagerTests: XCTestCase {

    var networkManager: NetworkManager!
    var mockURLSession: MockURLSession!

    override func setUpWithError() throws {
        super.setUpWithError()
        mockURLSession = MockURLSession()
        networkManager = NetworkManager(session: mockURLSession)
    }

    override func tearDownWithError() throws {
        networkManager = nil
        mockURLSession = nil
        super.tearDownWithError()
    }

    func testPerformRequest_success() async throws {
        let expectation = self.expectation(description: "Request should succeed with data")
        let url = URL(string: "https://api.example.com/data")!
        let mockData = "{\"message\": \"Success\"}".data(using: .utf8)!
        let mockResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)

        mockURLSession.data = mockData
        mockURLSession.response = mockResponse
        mockURLSession.error = nil

        networkManager.performRequest(url: url) { result in
            switch result {
            case .success(let data):
                XCTAssertEqual(data, mockData)
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Request failed with error: \(error.localizedDescription)")
            }
        }
        await fulfillment(of: [expectation], timeout: 1.0)
    }

    func testPerformRequest_failure_invalidResponse() async throws {
        let expectation = self.expectation(description: "Request should fail with invalid response")
        let url = URL(string: "https://api.example.com/data")!
        let mockData = "{\"message\": \"Success\"}".data(using: .utf8)!
        let mockResponse = HTTPURLResponse(url: url, statusCode: 404, httpVersion: nil, headerFields: nil)

        mockURLSession.data = mockData
        mockURLSession.response = mockResponse
        mockURLSession.error = nil

        networkManager.performRequest(url: url) { result in
            switch result {
            case .success(_):
                XCTFail("Request should have failed")
            case .failure(let error):
                XCTAssertEqual(error as? NetworkError, NetworkError.invalidResponse)
                expectation.fulfill()
            }
        }
        await fulfillment(of: [expectation], timeout: 1.0)
    }

    func testPerformRequest_failure_networkError() async throws {
        let expectation = self.expectation(description: "Request should fail with network error")
        let url = URL(string: "https://api.example.com/data")!
        let mockError = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, userInfo: nil)

        mockURLSession.data = nil
        mockURLSession.response = nil
        mockURLSession.error = mockError

        networkManager.performRequest(url: url) { result in
            switch result {
            case .success(_):
                XCTFail("Request should have failed")
            case .failure(let error):
                XCTAssertEqual(error as? NetworkError, NetworkError.unknown(mockError))
                expectation.fulfill()
            }
        }
        await fulfillment(of: [expectation], timeout: 1.0)
    }
}

// Mock URLSession for testing NetworkManager
class MockURLSession: URLSessionProtocol {
    var data: Data?
    var response: URLResponse?
    var error: Error?

    func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        let task = MockURLSessionDataTask {
            completionHandler(self.data, self.response, self.error)
        }
        return task
    }
}

class MockURLSessionDataTask: URLSessionDataTask {
    private let closure: () -> Void

    init(closure: @escaping () -> Void) {
        self.closure = closure
    }

    override func resume() {
        closure()
    }
}

// Protocol to allow mocking URLSession
protocol URLSessionProtocol {
    func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask
}

extension URLSession: URLSessionProtocol {}


