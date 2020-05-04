//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Indy

/**
 Crypto service error
 */
public enum CryptoServiceError: Error {
    case invalidJson
    case failedToEncodeVerkeys
    case noDataAfterPack
    case general(Error)
    case indy(Error)
    case unknown
}

/**
 Crypto service protocol
 */
internal protocol CryptoService {
    
    /**
     Encrypt message using keys, anon
     
     - Parameter: Wallet
     - Parameter: Message data to encrypt
     - Parameter: Verkey
     - Parameter: Completion handler that handles encrypted data or `CryptoServiceError`
     */
    func encryptMessage(wallet: Wallet, message: Data, verkey: String, completion: @escaping (Result<Data, CryptoServiceError>) -> Void)
    
    /**
     Encrypt message using keys, use for pairwise
     
     - Parameter: Wallet
     - Parameter: Message data to encrypt
     - Parameter: Receiver verkeys
     - Parameter: Sender verkey
     - Parameter: Completion handler that handles encrypted data or `CryptoServiceError`
     */
    func encryptMessage(wallet: Wallet, message: Data, receiverVerkeys: [String], senderVerkey: String, completion: @escaping (Result<Data, CryptoServiceError>) -> Void)
    
    /**
     Decrypt encrypted message, anon
     
     - Parameter: Wallet
     - Parameter: Encrypted message data
     - Parameter: Verkey
     - Parameter: Completion handler that handles decrypted data or `CryptoServiceError`
     */
    func decryptMessage(wallet: Wallet, message: Data, verkey: String, completion: @escaping (Result<Data, CryptoServiceError>) -> Void)
    
    /**
     Decrypt encrypted message, use for pairwise
     
     - Parameter: Wallet
     - Parameter: Encrypted message data
     - Parameter: Their DID (must exist in wallet)
     - Parameter: Completion handler that handles decrypted data or `CryptoServiceError`
     */
    func decryptMessage(wallet: Wallet, message: Data, theirDid: String, completion: @escaping (Result<Data, CryptoServiceError>) -> Void)
    
}

/**
 Crypto service implementation
 */
internal class CryptoServiceImpl: CryptoService {
    
    /// Logger
    private let logger: Logger
    
    internal init(logger: Logger = LoggerImpl()) {
        self.logger = logger
    }
    
    /// See protocol documentation
    internal func encryptMessage(wallet: Wallet, message: Data, verkey: String, completion: @escaping (Result<Data, CryptoServiceError>) -> Void) {
            
            IndyCrypto.anonCrypt(message, theirKey: verkey) { error, data in
                if let error = error {
                    let indyCode = self.toIndyCode(error: error)
                    switch indyCode {
                    // Successful code or did already exists
                    case .Success:
                        guard let data = data else {
                            completion(.failure(.noDataAfterPack))
                            return
                        }
                        completion(.success(data))
                        return
                    // All other indy errors just propagate
                    default:
                        completion(.failure(.indy(error)))
                        return
                    }
                }
                
            }
    
    }
    
    /// See protocol documentation
    internal func encryptMessage(wallet: Wallet, message: Data, receiverVerkeys: [String], senderVerkey: String, completion: @escaping (Result<Data, CryptoServiceError>) -> Void) {
        
        do {
            let receivers = try JSONEncoder().encode(receiverVerkeys)
            let receiverStr = String(data: receivers, encoding: .utf8)
            
            IndyCrypto.packMessage(message, receivers: receiverStr, sender: senderVerkey, walletHandle: wallet.handle) { error, data in
                if let error = error {
                    let indyCode = self.toIndyCode(error: error)
                    switch indyCode {
                    // Successful code or did already exists
                    case .Success:
                        guard let data = data else {
                            completion(.failure(.noDataAfterPack))
                            return
                        }
                        completion(.success(data))
                        return
                    // All other indy errors just propagate
                    default:
                        completion(.failure(.indy(error)))
                        return
                    }
                }
                
            }
        } catch let error {
            completion(.failure(.indy(error)))
            return
        }
    
    }
    
    /// See protocol documentation
    internal func decryptMessage(wallet: Wallet, message: Data, verkey: String, completion: @escaping (Result<Data, CryptoServiceError>) -> Void) {
        IndyCrypto.anonDecrypt(message, myKey: verkey, walletHandle: wallet.handle) { error, data in
            if let error = error {
                let indyCode = self.toIndyCode(error: error)
                switch indyCode {
                // Successful code or did already exists
                case .Success:
                    guard let data = data else {
                        completion(.failure(.noDataAfterPack))
                        return
                    }
                    completion(.success(data))
                // All other indy errors just propagate
                default:
                    completion(.failure(.indy(error)))
                    return
                }
            }
            
        }
    }
    
    /// See protocol documentation
    internal func decryptMessage(wallet: Wallet, message: Data, theirDid: String, completion: @escaping (Result<Data, CryptoServiceError>) -> Void) {
        IndyCrypto.unpackMessage(message, walletHandle: wallet.handle) { error, data in
            if let error = error {
                let indyCode = self.toIndyCode(error: error)
                switch indyCode {
                // Successful code or did already exists
                case .Success:
                    guard let data = data else {
                        completion(.failure(.noDataAfterPack))
                        return
                    }
                    completion(.success(data))
                // All other indy errors just propagate
                default:
                    completion(.failure(.indy(error)))
                    return
                }
            }
            
        }
    }
    
    /**
     Convert error to indy error code
     
     - Parameter: Error
     
     - Returns: Indy error code
     */
    private func toIndyCode(error: Error?) -> IndyErrorCode {
        if let err = error as NSError? {
            return IndyErrorCode(rawValue: err.code) ?? .CommonIOError
        } else {
            return .CommonIOError
        }
    }
    
}
