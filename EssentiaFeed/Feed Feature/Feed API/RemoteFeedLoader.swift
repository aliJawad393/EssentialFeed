//
//  RemoteFeedLoader.swift
//  EssentiaFeed
//
//  Created by Ali Jawad on 23/02/2023.
//

import Foundation

public final class RemoteFeedLoader: FeedLoader {
    private let client: HTTPClient
    private let url: URL
    
    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }
    
    public typealias Result = LoadFeedResult<Error >
 
    
    public init(url: URL, client: HTTPClient) {
        self.client = client
        self.url = url
    }
        
    public func load(completion: @escaping(Result)->Void) {
        client.get(from: url) {[weak self] response in
            guard self != nil else {return}
            
            switch response {
            case let .succes(data, response):
                completion(FeedItemsMapper.map(data, response))
            case .failure:
                completion(.failure(.connectivity))
            }
        }
    }

}
 
