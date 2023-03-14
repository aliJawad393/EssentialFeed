//
//  URLSessionHTTPClientTest.swift
//  EssentiaFeedTests
//
//  Created by Ali Jawad on 13/03/2023.
//

import Foundation
import XCTest
import EssentiaFeed

protocol HTTPSession {
    func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> HTTPSessionDataTask
}

protocol HTTPSessionDataTask {
    func resume()
}

class URLSessionHttpClient {
    private let session: HTTPSession
    
    init(session: HTTPSession) {
        self.session = session
    }
    
    
    func get(from url: URL, completion: @escaping (HTTPClientResponse) -> Void) {
        session.dataTask(with: url) {_, _, error in
            if let error = error {
                completion(.failure(error))
            }
        }.resume()
    }
}

final class URLSessionHTTPClientTests: XCTestCase {
    
    func test_gerFromURL_resumesDataTaskWithURL() {
        let session = HTTPSessionSpy()
        let url = URL(string: "http://any-url.com")!
        let task = URLSessionDataTaskSpy()
        session.stub(url: url, task: task)
        let sut = URLSessionHttpClient(session: session)
        sut.get(from: url) {_ in}
        XCTAssertEqual(task.resumeCallCount, 1)
    }
    
    func test_getFromURL_failsOnRequestError() {
        let session = HTTPSessionSpy()
        let url = URL(string: "http://any-url.com")!
        let error = NSError(domain: "any erroe", code: 1)
        session.stub(url: url, error: error)
        let sut = URLSessionHttpClient(session: session)
        let exp = expectation(description: "wait for completion")
        sut.get(from: url) { result in
            switch result {
            case .failure(let receivedError as NSError):
                XCTAssertEqual(receivedError, error)
            default:
                XCTFail("Exptected failure with error \(error), got \(result) instead")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }
    
}

//MARK:  - Helpers
private class HTTPSessionSpy: HTTPSession {
    private var stubs = [URL: Stub]()
    
    private struct Stub {
        let task: HTTPSessionDataTask
        let error: NSError?
    }
    
    func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> HTTPSessionDataTask {
        guard let stub = stubs[url] else {
            fatalError("Couldn't find stub")
        }
        completionHandler(nil, nil, stub.error)
        return stub.task
    }
    
    func stub(url: URL, task: HTTPSessionDataTask = FakeURLSessionDataTask(), error: NSError? = nil) {
        stubs[url] = Stub(task: task, error: error)
    }
}

private class FakeURLSessionDataTask: HTTPSessionDataTask {
    func resume() {
        
    }
}
private class URLSessionDataTaskSpy: HTTPSessionDataTask {
    var resumeCallCount: Int = 0
    
    func resume() {
        resumeCallCount += 1
    }
}
