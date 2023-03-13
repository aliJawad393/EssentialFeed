//
//  URLSessionHTTPClientTest.swift
//  EssentiaFeedTests
//
//  Created by Ali Jawad on 13/03/2023.
//

import Foundation
import XCTest

class URLSessionHttpClient {
    private let session: URLSession
    
    init(session: URLSession) {
        self.session = session
    }
    
    
    func get(from url: URL) {
        session.dataTask(with: url) {_, _, _ in}.resume()
    }
}

final class URLSessionHTTPClientTests: XCTestCase {
    func test_gerFromUrl_createdDataTaskWithURL() {
        let session = URLSessionSpy()
        let url = URL(string: "http://any-url.com")!
        let sut = URLSessionHttpClient(session: session)
        sut.get(from: url)
        XCTAssertEqual(session.requestedUrls, [url])
    }
    
    func test_gerFromUrl_resumesDataTaskWithURL() {
        let session = URLSessionSpy()
        let url = URL(string: "http://any-url.com")!
        let task = URLSessionDataTaskSpy()
        session.stub(url: url, task: task)
        let sut = URLSessionHttpClient(session: session)
        sut.get(from: url)
        XCTAssertEqual(task.resumeCallCount, 1)
    }
    
}

//MARK:  - Helpers
private class URLSessionSpy: URLSession {
    var requestedUrls = [URL]()
    private var stubs = [URL: URLSessionDataTask]()
    override func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        requestedUrls.append(url)
        return stubs[url] ?? FakeURLSessionDataTask()
    }
    
    func stub(url: URL, task: URLSessionDataTask) {
        stubs[url] = task
    }
}

private class FakeURLSessionDataTask: URLSessionDataTask {
    override func resume() {
        
    }
}
private class URLSessionDataTaskSpy: URLSessionDataTask {
    var resumeCallCount: Int = 0
    
    override func resume() {
        resumeCallCount += 1
    }
}
