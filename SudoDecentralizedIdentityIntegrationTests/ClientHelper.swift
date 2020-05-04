//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
import SudoDecentralizedIdentity

class ClientHelper {
    
    let client: SudoDecentralizedIdentityClient
    let WAIT_TIMEOUT = 20.0
    
    init(_ client: SudoDecentralizedIdentityClient? = nil) {
        self.client = client ?? DefaultSudoDecentralizedIdentityClient()
    }
    
    @discardableResult func setupWallet(walletId: String, expectation: XCTestExpectation) -> Bool {
        var success = false
        self.client.setupWallet(walletId: walletId) { result in
            defer { expectation.fulfill() }
            switch result {
            case .success(let sSuccess):
                success = sSuccess
            case .failure(let error):
                assertionFailure("Error occurred: \(error)")
            }
            
        }
        return success
    }
    
    func createDid(walletId: String, label: String, ledger: Ledger? = nil) -> Did? {
        let semaphore = SudoTestingSemaphore(self.WAIT_TIMEOUT)
        
        var did: Did?
        self.client.createDid(walletId: walletId, label: label, ledger: ledger) { result in
            defer { semaphore.signal() }
            switch result {
            case .success(let rDid):
                did = rDid
            case .failure(let error):
                assertionFailure("Error occurred: \(error)")
            }
            
        }
        
        semaphore.wait()
        
        return did
    }
    
    func invitation(walletId: String, myDid: String, serviceEndpoint: String, label: String) -> Invitation? {
        let semaphore = SudoTestingSemaphore(self.WAIT_TIMEOUT)
        
        var invitation: Invitation?
        self.client.invitation(walletId: walletId, myDid: myDid, serviceEndpoint: serviceEndpoint, label: label) { result in
            defer { semaphore.signal() }
            switch result {
            case .success(let rInvitation):
                invitation = rInvitation
            case .failure(let error):
                assertionFailure("Error occurred: \(error)")
            }
            
        }
        
        semaphore.wait()
        
        return invitation
    }
    
    func keyForDid(walletId: String, did: String) -> String? {
        let semaphore = SudoTestingSemaphore(self.WAIT_TIMEOUT)
        
        var key: String?
        self.client.keyForDid(walletId: walletId, did: did) { result in
            defer { semaphore.signal() }
            switch result {
            case .success(let rKey):
                key = rKey
            case .failure(let error):
                assertionFailure("Error occurred: \(error)")
            }
            
        }
        
        semaphore.wait()
        
        return key
    }
}

struct SudoTestingSemaphore {
    let semaphore: DispatchSemaphore
    let timeout: TimeInterval
    
    init(_ timeout: TimeInterval) {
        self.semaphore = DispatchSemaphore(value: 0)
        self.timeout = timeout
    }
    
    func signal() {
        self.semaphore.signal()
    }
    
    func wait() {
        let result = semaphore.wait(timeout: .now() + self.timeout)
        switch result {
        case .success:
            break
        case .timedOut:
            assertionFailure("Semaphore wait timed out")
        }
    }
}
