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
        expect(sut, toCompleteWith: failure(.connectivity), when: {
            let clientError = NSError(domain: "Test", code: 0)
            client.complete(with: clientError)
        })
    }
    
    func test_load_deliversErrorOnNon200HTTPResponse() {
        let (sut, client) = makeSUT()
        let samples = [199, 201, 300, 500, 500].enumerated()
        samples.forEach { index, code in
            expect(sut, toCompleteWith: failure(.invalidData), when: {
                let data = makeItemsJSON([])
                client.complete(withStatusCode: code, data: data, at: index)
            })
        }
    }
    
    func test_load_deliversErrorOn200HTTPResponseWithInvalidJSON() {
        let (sut, client) = makeSUT()
        expect(sut, toCompleteWith: failure(.invalidData), when: {
            let data = Data("invlaid JSON".utf8)
             client.complete(withStatusCode: 200, data: data)
        })
    }
    
    func test_load_delivetsNoFeedItemsOn200HTTPResponseWithEmptyJSONList() {
        let (sut, client) = makeSUT()
        expect(sut, toCompleteWith: .success([]), when: {
            let emptyJSONList = makeItemsJSON([])
            client.complete(withStatusCode: 200, data: emptyJSONList)
        })
    }
    
    func test_load_deliversItemsOnHTTP200WithJSONItems() {
        let (sut, client) = makeSUT()
        let item1 = makeFeedItem(id: UUID(), imageURL: URL(string: "https://www.a-url.com")!)
                 
        let item2 = makeFeedItem(id: UUID(), description: "Feed item description", location: "a location", imageURL: URL(string: "http://www.another-url.com")!)
        
        let items = [item1.model, item2.model]
        
        expect(sut, toCompleteWith: .success(items), when: {
            let data = makeItemsJSON([item1.json, item2.json])
            client.complete(withStatusCode: 200, data: data )
        })
    }
    
    func test_load_doesNotDeliverResultAfterSUTInstanceIsDeallocated() {
        let client = HTTPClientSpy()
        var sut: RemoteFeedLoader? = RemoteFeedLoader(url: URL(string: "http://any-url.com")!, client: client)
        
        var capturedResult = [RemoteFeedLoader.Result]()
        sut?.load {  capturedResult.append($0)}
        sut = nil
        client.complete(withStatusCode: 200, data: makeItemsJSON([]))
    
        
        XCTAssertTrue(capturedResult.isEmpty )
    }
    
    //MARK: - Helpers
    
    private func makeFeedItem(id: UUID,
                              description: String? = nil,
                              location: String? = nil,
                              imageURL: URL) -> (model: FeedItem, json: [String: Any]) {
        let item = FeedItem(id: id, description: description, location: location, imageURL: imageURL)
        let json = [
            "id": id.uuidString,
            "description": description,
            "location": location,
            "image": imageURL.absoluteString
        ].reduce(into: [String: Any]()) {(acc, e) in
            if let value = e.value {acc[e.key] = value}
        }
        
        
        return (item, json)
    }
    
    private func makeItemsJSON(_ items: [[String: Any]]) -> Data {
        let json = ["items": items]
        return try! JSONSerialization.data(withJSONObject: json)
    }
    
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
        
        func complete(withStatusCode: Int, data: Data, at index: Int = 0) {
            let response = HTTPURLResponse(url: requestedURLs[index], statusCode: withStatusCode, httpVersion: nil, headerFields: nil)
            
            messages[index].completion(.succes(data, response!))
        }
    }
    
    private func failure(_ error: RemoteFeedLoader.Error) -> RemoteFeedLoader.Result {
        .failure(error)
    }
    
    private func expect(_ sut: RemoteFeedLoader, toCompleteWith expectedResult: RemoteFeedLoader.Result, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
        let exp = expectation(description:  "Wait for load completion")
         sut.load {receivedResult in
             switch (receivedResult, expectedResult) {
             case (.success(let receivedItems), .success(let expectedItems)):
                 XCTAssertEqual(receivedItems, expectedItems, file: file, line: line)
                 
             case (.failure(let receivedError as RemoteFeedLoader.Error), .failure(let expectedError as RemoteFeedLoader.Error)):
                 XCTAssertEqual(receivedError, expectedError)
                 
             default:
                 XCTFail("Expected result \(expectedResult) got \(receivedResult) instead", file: file, line  : line)
                 
             }
             exp.fulfill()

         }
        action()
        wait(for: [exp], timeout: 1.0)

    }
    
    private func makeSUT(url: URL = URL(string: "https://a-given-url.com")!, file: StaticString = #filePath, line: UInt = #line) -> (RemoteFeedLoader, HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        trackMemoryLeaks(instance: sut, file: file, line: line)
        trackMemoryLeaks(instance: client, file: file, line: line)
        return (sut, client)
    }
    
    private func trackMemoryLeaks(instance: AnyObject,  file: StaticString = #filePath, line: UInt = #line) {
        addTeardownBlock {[weak instance] in
            XCTAssertNil(instance, "Instance should have been nil. Potential memory leak", file: file, line: line)
        }

    }
}
 
