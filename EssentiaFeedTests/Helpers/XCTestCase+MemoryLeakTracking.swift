//
//  XCTestCase+MemoryLeakTracking.swift
//  EssentiaFeedTests
//
//  Created by Ali Jawad on 19/03/2023.
//

import XCTest

extension XCTestCase {
    func trackMemoryLeaks(instance: AnyObject,  file: StaticString = #filePath, line: UInt = #line) {
        addTeardownBlock {[weak instance] in
            XCTAssertNil(instance, "Instance should have been nil. Potential memory leak", file: file, line: line)
        }

    }

}
