//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/**
 Logger protocol
 */
public protocol Logger {
    func log(_ string: String)
}

/**
 Implementation of Logger protocol
 */
public class LoggerImpl: Logger {
    
    public init() { }
    
    /**
     Log a string
     
     - Parameter: String to log
     */
    public func log(_ string: String) {
        print(string)
    }
}
