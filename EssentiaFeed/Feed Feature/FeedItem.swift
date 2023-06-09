//
//  FeedItem.swift
//  EssentiaFeed
//
//  Created by Ali Jawad on 18/02/2023.
//

import Foundation

public struct FeedItem: Equatable {
    public init(id: UUID,
                description: String?,
                location: String?,
                imageURL: URL) {
        self.id = id
        self.description = description
        self.location = location
        self.imageURL = imageURL
    }
    
    public let id: UUID
    public let description: String?
    public let location: String?
    public let imageURL: URL
}

