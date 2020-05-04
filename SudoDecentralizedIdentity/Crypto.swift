//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/**
 Encrypted message, as defined by Indy library
 */
public struct EncryptedMessage: Codable {
    let protected: String
    let iv: String
    let ciphertext: String
    let tag: String
}
