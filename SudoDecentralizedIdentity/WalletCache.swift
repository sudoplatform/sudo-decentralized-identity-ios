//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/**
 A cache of wallets that have been opened
 */
internal protocol WalletCache {
    
    /**
     Get a wallet from an ID
     
     - Parameter: Wallet ID
     
     - Returns: Wallet, may be nil
     */
    func get(walletId: String) -> Wallet?
    
    /**
     Store a wallet in the cache
     
     - Parameter: Wallet
     */
    func store(wallet: Wallet) -> Void
    
    /**
     Reset cache, clears out all wallets
     */
    func reset() -> Void
}

/**
 Implementation of WalletCache
 */
internal class WalletCacheImpl: WalletCache {
    
    /// In-memory cache
    private var cache: [String: Wallet] = [:]
    
    internal init() { }
    
    /// See protocol documentation
    func get(walletId: String) -> Wallet? {
        return self.cache[walletId]
    }
    
    /// See protocol documentation
    func store(wallet: Wallet) {
        self.cache[wallet.id] = wallet
    }
    
    /// See protocol documentation
    func reset() {
        self.cache = [:]
    }
    
}
