//
//  URLSessionHTTPClientTest.swift
//  EssentiaFeedTests
//
//  Created by Ali Jawad on 13/03/2023.
//

import Foundation
import XCTest
import EssentiaFeed

class URLSessionHttpClient {
    private let session: URLSession
    
    init(session: URLSession = .shared) {
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
    
    func test_getFromURL_perfromsGETRequestWithURL() {
        URLProtocolStub.startInterceptingRequests()
        let url = URL(string: "http://any-url.com")!
        let exp = expectation(description: "Wait for request")
        URLProtocolStub.observeRequest { request in
            XCTAssertEqual(request.url, url)
            XCTAssertEqual(request.httpMethod, "GET")
            exp.fulfill()
        }
        URLSessionHttpClient().get(from: url) { _ in}
        wait(for: [exp], timeout: 1.0)
        URLProtocolStub.stopInterceptingRequests()
    }
 
    func test_getFromURL_failsOnRequestError() {
        URLProtocolStub.startInterceptingRequests()
        let url = URL(string: "http://any-url.com")!
        let error = NSError(domain: "any erroe", code: 1)
        URLProtocolStub.stub(url: url, data: nil, response: nil, error: error)
        let sut = URLSessionHttpClient()
        let exp = expectation(description: "wait for completion")
        sut.get(from: url) { result in
            switch result {
            case .failure(let receivedError as NSError):
                XCTAssertEqual(receivedError.domain, error.domain)
                XCTAssertEqual(receivedError.code, error.code)
               // XCTAssertEqual(receivedError, error)
            default:
                XCTFail("Exptected failure with error \(error), got \(result) instead")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
        URLProtocolStub.stopInterceptingRequests()
    }
    
}

//MARK:  - Helpers
private class URLProtocolStub: URLProtocol {
    private static var stub: Stub?
    private static var  requestObserver: ((URLRequest) -> Void)?
    private struct Stub {
        let data: Data?
        let response: URLResponse?
        let error: NSError?
    }
    
    static func stub(url: URL, data: Data?, response:  URLResponse? ,error: NSError? = nil) {
        stub = Stub(data: data, response: response, error: error)
    }
    
    static func startInterceptingRequests() {
        URLProtocol.registerClass(URLProtocolStub.self)
    }
    
    static func stopInterceptingRequests() {
        URLProtocol.unregisterClass(URLProtocolStub.self)
        stub = nil
        requestObserver = nil
    }
    
    static func observeRequest(observer: @escaping(URLRequest) -> Void) {
        requestObserver = observer
    }
    
    override class func canInit(with request: URLRequest) -> Bool {
        requestObserver?(request)
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        
        if let data = URLProtocolStub.stub?.data {
            client?.urlProtocol(self, didLoad: data)
        }
        
        if let response = URLProtocolStub.stub?.response {
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed  )
        }
        
        if let error = URLProtocolStub.stub?.error {
            client?.urlProtocol(self, didFailWithError: error)
        }
        
        client?.urlProtocolDidFinishLoading(self)
    }
    
    override func stopLoading() {} // if we don't implement it, will get a crash on run-time.
    
}
