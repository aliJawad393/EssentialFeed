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
    
    struct UnexpectedValuesRepresentation: Error {}
    
    func get(from url: URL, completion: @escaping (HTTPClientResponse) -> Void) {
        session.dataTask(with: url) {_, _, error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.failure(UnexpectedValuesRepresentation()))
            }
        }.resume()
    }
}

final class URLSessionHTTPClientTests: XCTestCase {
    
    override class func setUp() {
        super.setUp()
        URLProtocolStub.startInterceptingRequests()
    }
    
    override class func tearDown() {
        super.tearDown()
        URLProtocolStub.stopInterceptingRequests()
    }
    
    func test_getFromURL_perfromsGETRequestWithURL() {
        let url = anyURL()
        let exp = expectation(description: "Wait for request")
        URLProtocolStub.observeRequest { request in
            XCTAssertEqual(request.url, url)
            XCTAssertEqual(request.httpMethod, "GET")
            exp.fulfill()
        }
        makeSUT().get(from: url) { _ in}
        wait(for: [exp], timeout: 1.0)
    }
 
    func test_getFromURL_failsOnRequestError() {
         let error = NSError(domain: "any erroe", code: 1)
        URLProtocolStub.stub(data: nil, response: nil, error: error)
        let exp = expectation(description: "wait for completion")
        makeSUT().get(from: anyURL()) { result in
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
    }
    
    func test_getFromURL_failsOnAllNilValues() {
        URLProtocolStub.stub(data: nil, response: nil, error: nil)
        let exp = expectation(description: "Wait for completion")
        makeSUT().get(from: anyURL()) { result in
            switch result {
            case .failure:
                break
            default:
                XCTFail("Expected failure, got \(result) instead")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }
    
    
    //MARK:  - Helpers
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> URLSessionHttpClient {
        let SUT = URLSessionHttpClient()
        trackMemoryLeaks(instance: SUT, file: file, line: line )
        return SUT
    }
    
    private func anyURL() -> URL {
        URL(string: "http://any-url.com")!
    }
    
    private class URLProtocolStub: URLProtocol {
        private static var stub: Stub?
        private static var  requestObserver: ((URLRequest) -> Void)?
        private struct Stub {
            let data: Data?
            let response: URLResponse?
            let error: NSError?
        }
        
        static func stub(data: Data?, response:  URLResponse? ,error: NSError? = nil) {
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
    
}

