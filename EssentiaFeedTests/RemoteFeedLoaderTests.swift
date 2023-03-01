//
//  RemoteFeedLoaderTests.swift
//  EssentiaFeedTests
//
//  Created by Ali Jawad on 21/02/2023.
//

import Foundation
import XCTest
import EssentiaFeed

class RemoteFeedLoaderTests: XCTestCase {
    
    func test_init_doesNotRequestDataFromURL() {
        let (_, client) = makeSUT()
        
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }
    
    func test_load_requestsDataFromURL() {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        sut.load{_ in}
        
        XCTAssertEqual(client.requestedURLs, [url])
    }
    
    func test_loadTwice_requestsDataTwiceFromURL() {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        sut.load{_ in}
        sut.load{_ in}
        
        XCTAssertEqual(client.requestedURLs, [url, url])

    }
    
    func test_load_deliversErrorOnClientError() {
        let (sut, client) = makeSUT()
        var capturedError = [RemoteFeedLoader.Error]()
         sut.load {  capturedError.append($0)}
        
        let clientError = NSError(domain: "Test", code: 0)
        client.complete(with: clientError)
        XCTAssertEqual(capturedError, [.connectivity])
    }
    
    func test_load_deliversErrorOnNon200HTTPResponse() {
        let (sut, client) = makeSUT()
        let samples = [199, 201, 300, 500, 500].enumerated()
        samples.forEach { index, code in
            var capturedError = [RemoteFeedLoader.Error]()
             sut.load {  capturedError.append($0)}

            client.complete(withStatusCode: code, at: index)
            XCTAssertEqual(capturedError, [.invalidData])
        }
    }
    
    func test_load_deliversErrorOn200HTTPResponseWithInvalidJSON() {
        let (sut, client) = makeSUT()
            var capturedError = [RemoteFeedLoader.Error]()
             sut.load {  capturedError.append($0)}
        let data = Data("invlaid JSON".utf8)
        client.complete(withStatusCode: 200, data: data)
            XCTAssertEqual(capturedError, [.invalidData])
    }
    
    //MARK: - Helpers
    
    private class HTTPClientSpy: HTTPClient {
        var requestedURLs: [URL] {
            messages.map {$0.url}
        }
        var messages = [(url: URL, completion: (HTTPClientResponse) -> Void)]()
        func get(from url: URL, completion: @escaping(HTTPClientResponse) -> Void) {
            messages.append((url, completion))
        }
        
        func complete(with error: Error, at index: Int = 0) {
            messages[index].completion(.failure(error))
        }
        
        func complete(withStatusCode: Int, data: Data = Data(), at index: Int = 0) {
            let response = HTTPURLResponse(url: requestedURLs[index], statusCode: withStatusCode, httpVersion: nil, headerFields: nil)
            
            messages[index].completion(.succes(data, response!))
        }
    }
    
    private func makeSUT(url: URL = URL(string: "https://a-given-url.com")!) -> (RemoteFeedLoader, HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        return (sut, client)
    }
}
 
