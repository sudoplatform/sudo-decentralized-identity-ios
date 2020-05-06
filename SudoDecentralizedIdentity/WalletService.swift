//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Indy

internal typealias WalletHandle = IndyHandle

public enum WalletServiceError: Error {
    case invalidJson
    case keyNotFoundForWalletId
    case indy(Error)
    case general(Error)
    case unknown
}

/**
 A service that handles operations related to wallets
 */

internal protocol WalletService {
    
    /**
     Create a wallet
     
     - Parameter id: The ID for the wallet
     - Parameter completion: A completion handler for after the wallet is created or an error occurs
     */
    func createWallet(id: String, completion: @escaping (Result<Bool, WalletServiceError>) -> Void)
    
    func openWallet(id: String, completion: @escaping (Result<Wallet, WalletServiceError>) -> Void)
    
    func closeWallet(wallet: Wallet, completion: @escaping (Result<Bool, WalletServiceError>) -> Void)
    
    func deleteWallet(wallet: Wallet, completion: @escaping (Result<Bool, WalletServiceError>) -> Void)
    
    func listWallets(completion: @escaping (Result<[String], SudoDecentralizedIdentityClientError>) -> Void)
    
    /**
    func exportWallet(wallet: Wallet, completion: @escaping (Result<URL, WalletServiceError>) -> Void)
    
    func importWallet(path: URL, completion: @escaping (Result<Bool, WalletServiceError>) -> Void)
    */
}


/**
 A representation of the wallet configuration expected by the Indy library
 */
private struct WalletConfig: Codable {
    
    
    /// The wallet storage configuration
    struct WalletStorageConfig: Codable {
        
        /// Path to the wallet
        let path: URL?
    }
    
    /// Wallet ID
    let id: String
    
    /// Storage type
    let storageType: String
    let storageConfig: WalletStorageConfig?
    
    /// Coding keys for converting object properties into JSON keys
    enum CodingKeys: String, CodingKey {
        case id
        case storageType = "storage_type"
        case storageConfig = "storage_config"
    }
    
    /**
     Get a wallet configuration from a wallet ID
     
     - Parameter id: The wallet ID
     
     - Returns: a wallet configuration with default parameters set
     */
    static func fromId(id: String) -> WalletConfig {
        return WalletConfig(id: id, storageType: "default", storageConfig: nil)
    }
    
    /**
     Convert wallet configuration into a JSON string
     
     - Throws: `WalletServiceError.invalidJSON`
                if object cannot be encoded
     
     - Returns: The JSON string
     */
    func json() throws -> String {
        let jsonData = try JSONEncoder().encode(self)
        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            throw WalletServiceError.invalidJson
        }
        return jsonString
    }
    
}

/**
 A representation of the wallet credentials indy object
 */
private struct WalletCredentials: Codable {
    
    struct WalletStorageCredentials: Codable {
        
    }
    
    /// Wallet key
    let key: String
    
    /// Storage credentials
    let storageCredentials: WalletStorageCredentials?
    
    /// Key derivation method
    let keyDerivationMethod: String?
    
    /// Conversion of object properties to JSON keys
    enum CodingKeys: String, CodingKey {
        case key
        case storageCredentials = "storage_credentials"
        case keyDerivationMethod = "key_derivation_method"
    }
    
    /**
     Get wallet credentials from a key
     
     - Parameter: Credentials key
     
     - Returns: Wallet credentials
     */
    static func fromKey(key: String) -> WalletCredentials {
        return WalletCredentials(key: key, storageCredentials: nil, keyDerivationMethod: nil)
    }
    
    /**
     Convert wallet credentials to JSON string
     
     - Throws: `WalletServiceError.invalidJSON`
     
     - Returns: JSON string representation of wallet storage credentials
     */
    func json() throws -> String {
        let jsonData = try JSONEncoder().encode(self)
        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            throw WalletServiceError.invalidJson
        }
        return jsonString
    }
    
}

/**
 Implmentation of the wallet service
 */
internal class WalletServiceImpl: WalletService {
    
    private let CREATE_TIMEOUT = 10.0
    private let OPEN_TIMEOUT = 10.0
    private let CLOSE_TIMEOUT = 10.0
    private let DELETE_TIMEOUT = 10.0
    
    private let indyWallet: IndyWallet
    private let keyStore: KeyStore
    
    /**
     Initialize wallet service implementation
     
     - Parameter: Indy wallet instance
     */
    internal init(indyWallet: IndyWallet = IndyWallet.sharedInstance()!, keyStore: KeyStore = KeyStoreImpl()) {
        self.indyWallet = indyWallet
        self.keyStore = keyStore
    }
    
    /// Protocol imlementation (see WalletService protocol documentation)
    internal func createWallet(id: String, completion: @escaping (Result<Bool, WalletServiceError>) -> Void) {
        
        do {
            // Setup config and credentials
            let config = try WalletConfig.fromId(id: id).json()
            let walletKey: String
            if let existingKey = try? self.retrieveKey(id: id) {
                walletKey = existingKey
            } else {
                walletKey = try self.generateKey(id: id)
            }
            let credentials = try WalletCredentials.fromKey(key: walletKey).json()
            
            // Create wallet
            self.indyWallet.createWallet(
                withConfig: config,
                credentials: credentials
            ) { error in
                // Handle errors in creating wallet
                if let error = error {
                    let indyCode = self.toIndyCode(error: error)
                    switch indyCode {
                    // Successful code or wallet already exists
                    case .Success, .WalletAlreadyExistsError:
                        completion(.success(true))
                        return
                    // All other indy errors just propagate
                    default:
                        completion(.failure(.indy(error)))
                        return
                    }
                }
                
                // Default in case no error was returned, assumed successful
                completion(.success(true))
                return
            }
        } catch let error {
            completion(.failure(.indy(error)))
            return
        }
        
    }
    
    /// Protocol imlementation (see WalletService protocol documentation)
    internal func listWallets(completion: @escaping (Result<[String], SudoDecentralizedIdentityClientError>) -> Void) {
        do {
            // Assumes that the wallets are located in $HOME/Documents/.indy_client
            let homeDirectory = URL(fileURLWithPath: NSHomeDirectory()) // TODO inject this
            let documentsDirectory = homeDirectory.appendingPathComponent("Documents")
            let indyDirectory = documentsDirectory.appendingPathComponent(".indy_client")
            
            // If directory does not exist, just return empty
            guard FileManager.default.fileExists(atPath: indyDirectory.path) else {
                completion(.success([]))
                return
            }
            
            let walletDirectory = indyDirectory.appendingPathComponent("wallet")
            let dirContents = try FileManager.default.contentsOfDirectory(at: walletDirectory, includingPropertiesForKeys: nil, options: [])
            let dirs = dirContents.filter { $0.hasDirectoryPath }
            let walletIds = dirs.map { $0.lastPathComponent }
            completion(.success(walletIds))
        } catch let error {
            completion(.failure(.general(error)))
            return
        }
    }
    
    /// Protocol imlementation (see WalletService protocol documentation)
    internal func openWallet(id: String, completion: @escaping (Result<Wallet, WalletServiceError>) -> Void) {
        do {
            // Setup config and credentials
            let config = try WalletConfig.fromId(id: id).json()
            let walletKey = try self.retrieveKey(id: id)
            let credentials = try WalletCredentials.fromKey(key: walletKey).json()
            
            // Open wallet
            self.indyWallet.open(withConfig: config, credentials: credentials) { error, handle in
                
                // Handle errors in creating wallet
                if let error = error {
                    let indyCode = self.toIndyCode(error: error)
                    switch indyCode {
                    // Successful code or wallet already opened
                    case .Success, .WalletAlreadyOpenedError:
                        let wallet = Wallet(id: id, handle: handle)
                        completion(.success(wallet))
                        return
                    // All other indy errors just propagate
                    default:
                        completion(.failure(.indy(error)))
                        return
                    }
                }
                
                // Default in case no error was returned, assumed successful
                let wallet = Wallet(id: id, handle: handle)
                completion(.success(wallet))
                return
            }
        } catch let error {
            completion(.failure(.indy(error)))
            return
        }
        
    }

    /// Protocol imlementation (see WalletService protocol documentation)
    internal func closeWallet(wallet: Wallet, completion: @escaping (Result<Bool, WalletServiceError>) -> Void) {
        
        self.indyWallet.close(withHandle: wallet.handle) { error in
            if let error = error, let nserror = error as NSError?, nserror.code != 0 {
                completion(.failure(.indy(error)))
                return
            } else {
                completion(.success(true))
            }
        }

    }
    
    /// Protocol imlementation (see WalletService protocol documentation)
    internal func deleteWallet(wallet: Wallet, completion: @escaping (Result<Bool, WalletServiceError>) -> Void) {
        do {
            let config = try WalletConfig.fromId(id: wallet.id).json()
            let walletKey = try self.retrieveKey(id: wallet.id)
            let credentials = try WalletCredentials.fromKey(key: walletKey).json()
            
            // Make sure wallet is closed
            self.closeWallet(wallet: wallet) { _ in
                
                self.indyWallet.delete(
                    withConfig: config,
                    credentials: credentials
                ) { error in
                    if let error = error, let nserror = error as NSError?, nserror.code != 0 {
                        completion(.failure(.indy(error)))
                        return
                    } else {
                        completion(.success(true))
                    }
                }
                
            }
        } catch let error {
            completion(.failure(.indy(error)))
            return
        }
    }
    
    
    /*
    public func exportWallet(wallet: Wallet, completion: @escaping (Result<URL, WalletServiceError>) -> Void) {
        <#code#>
    }
    
    public func importWallet(path: URL, completion: @escaping (Result<Bool, WalletServiceError>) -> Void) {
        <#code#>
    }
    */
    
    /**
     Generate a wallet key

     - Parameter: Wallet ID
     
     - Returns: wallet key
     */
    private func generateKey(id: String) throws -> String {
        let key = UUID().uuidString
        try keyStore.set(key: id, value: key)
        return key
    }
    
    /**
     Retrieve a wallet key
     
     - Parameter: Wallet ID
     
     - Returns: Wallet key
     */
    private func retrieveKey(id: String) throws -> String {
        guard let key = try keyStore.get(key: id) else {
            throw WalletServiceError.keyNotFoundForWalletId
        }
        return key
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
