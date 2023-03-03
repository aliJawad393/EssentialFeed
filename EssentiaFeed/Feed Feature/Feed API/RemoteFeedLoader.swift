//
//  RemoteFeedLoader.swift
//  EssentiaFeed
//
//  Created by Ali Jawad on 23/02/2023.
//

import Foundation

public final class RemoteFeedLoader {
    private let client: HTTPClient
    private let url: URL
    
    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }
    
    public enum Result: Equatable {
        case success([FeedItem])
        case failure(Error)
    }

    
    public init(url: URL, client: HTTPClient) {
        self.client = client
        self.url = url
    }
    
    public func load(completion: @escaping(Result)->Void) {
        client.get(from: url) {response in
            switch response {
            case let .succes(data, response):
                if let items = try? FeedItemsMapper.map(data, response) {
                    completion(.success(items))
                } else {
                    completion(.failure(.invalidData))
                }
            case .failure:
                completion(.failure(.connectivity))
            }
        }
    }
}
 
