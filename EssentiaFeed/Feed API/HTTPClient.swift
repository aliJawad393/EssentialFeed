//
//  HTTPClient.swift
//  EssentiaFeed
//
//  Created by Ali Jawad on 03/03/2023.
//

import Foundation

public enum HTTPClientResponse {
    case succes(Data, HTTPURLResponse)
    case failure(Error)
}

public protocol HTTPClient {
    func get(from url: URL, completion: @escaping(HTTPClientResponse) -> Void)
}
