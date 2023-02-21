//
//  RemoteFeedLoaderTests.swift
//  EssentiaFeedTests
//
//  Created by Ali Jawad on 21/02/2023.
//

import Foundation
import XCTest

class RemoteFeedLoader {}

class HTTPClient {
    var requestedURL: URL?
}

class RemoteFeedLoaderTests: XCTestCase {
    
    func test_init_doesnt() {
        let client = HTTPClient()
        let _ = RemoteFeedLoader()
        
        XCTAssertNil(client.requestedURL)
    }
}
 
