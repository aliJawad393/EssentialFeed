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
        session.dataTask(with: url) {_, _, _ in}
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
}

//MARK:  - Helpers
private class URLSessionSpy: URLSession {
    var requestedUrls = [URL]()
    override func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        requestedUrls.append(url)
        return FakeURLSessionDataTask()
    }
}

private class FakeURLSessionDataTask: URLSessionDataTask {}
