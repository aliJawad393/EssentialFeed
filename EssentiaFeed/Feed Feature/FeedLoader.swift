//
//  FeedLoader.swift
//  EssentiaFeed
//
//  Created by Ali Jawad on 18/02/2023.
//

import Foundation

enum LoadFeedResult {
    case success([FeedItem])
    case failure(Error)
}

protocol FeedLoader {
    func load(completion: @escaping (LoadFeedResult)->Void)
}
