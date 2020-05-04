//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Indy

/**
 An internal representation of a wallet
 */
internal struct Wallet {
    
    /**
     Wallet ID
     */
    public let id: String
    
    /**
     Wallet handle
     */
    public let handle: WalletHandle
}
