//
//  RemoteFeedLoader.swift
//  EssentiaFeed
//
//  Created by Ali Jawad on 23/02/2023.
//

import Foundation

public enum HTTPClientResponse {
    case succes(Data, HTTPURLResponse)
    case failure(Error)
}

public protocol HTTPClient {
    func get(from url: URL, completion: @escaping(HTTPClientResponse) -> Void)
}

public final class RemoteFeedLoader {
    private let client: HTTPClient
    private let url: URL
    
    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }
    
    public init(url: URL, client: HTTPClient) {
        self.client = client
        self.url = url
    }
    
    public func load(completion: @escaping(Error)->Void) {
        client.get(from: url) {response in
            switch response {
            case .succes:
                completion(.invalidData)
            case .failure:
                completion(.connectivity)
            }
        }
    }
}
