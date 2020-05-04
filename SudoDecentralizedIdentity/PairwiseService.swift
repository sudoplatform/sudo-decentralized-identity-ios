//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Indy

/**
 Pairwise service error
 */
public enum PairwiseServiceError: Error {
    case invalidJson
    case indy(Error)
    case general(Error)
    case didAndVerkeyNotReturned
    case listDidJsonNotReturned
    case retrieveJsonNotReturned
    case unknown
}

/**
 Representation of Indy's retrieve pairwise result
 */
public struct RetrievePairwiseResult {
    
    /// My DID
    let myDid: String
    
    /// Pairwise metadata
    let metadata: [String: String]
    
    /// Conversion of object properties to JSON keys
    enum CodingKeys: String, CodingKey {
        case myDid = "my_did"
        case metadata
    }
}

/**
Extension to handle decoding of pairwise result
*/
extension RetrievePairwiseResult: Decodable {
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        myDid = try values.decode(String.self, forKey: .myDid)
        
        // Base64 decode metadata to handle some issues with double-escaping quotes
        let metadataBase64 = try values.decode(String.self, forKey: .metadata)
        guard let metadataData = Data(base64Encoded: metadataBase64) else {
            throw DidDecodeError.invalidMetadata
        }
        metadata = try JSONDecoder().decode([String: String].self, from: metadataData)
    }
}

/**
Extension to handle encoding of pairwise result
*/
extension RetrievePairwiseResult: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(myDid, forKey: .myDid)
        
        let metadataJsonStr = try JSONEncoder().encode(metadata)
        
        // Base64 encode metadata to handle some issues with double-escaping quotes
        let metadata64Data = metadataJsonStr.base64EncodedData()
        guard let metadataStr = String(data: metadata64Data, encoding: .utf8) else {
            throw DidDecodeError.invalidMetadata
        }
        try container.encode(metadataStr, forKey: .metadata)
        
    }
}

/**
 Service that handles pairwise operations
 */
internal protocol PairwiseService {
    
    /**
     Create a pairwise did
     
     - Parameter: Wallet to create the pairwise in, must already contain my DID
     - Parameter: Their DID
     - Parameter: My DID
     - Parameter: Metadata
     - Parameter: Completion handler
     */
    func create(wallet: Wallet, theirDid: String, myDid: String, metadata: [String: String]?, completion: @escaping (Result<Bool, PairwiseServiceError>) -> Void)
    
    /**
     Check to see if pairwise did exists for their did
     
     - Parameter: Wallet to create the pairwise in, must already contain my DID
     - Parameter: Their DID
     - Parameter: Completion handler
     */
    func exists(wallet: Wallet, theirDid: String, completion: @escaping (Result<Bool, PairwiseServiceError>) -> Void)
    
    /**
     List all DIDs in a wallet
     
     - Parameter: Wallet to list DIDs for
     - Parameter: Completion handler
     */
    func list(wallet: Wallet, completion: @escaping (Result<[Pairwise], PairwiseServiceError>) -> Void)
    
    /**
     Retrieve pairwise DID from wallet
     
     - Parameter: Wallet
     - Parameter: Their DID
     - Parameter: Completion handler
     */
    func retrieve(wallet: Wallet, theirDid: String, completion: @escaping (Result<Pairwise, PairwiseServiceError>) -> Void)
    
    /**
     Update pairwise with metadata
     
     - Parameter: Wallet
     - Parameter: Their DID
     - Parameter: Metadata
     - Parameter: Completion handler
     */
    func update(wallet: Wallet, theirDid: String, metadata: [String: String], completion: @escaping (Result<Bool, PairwiseServiceError>) -> Void)
}

/**
 Implementation of PairwiseService protocol
 */
internal class PairwiseServiceImpl: PairwiseService {
    
    private let logger: Logger
    
    internal init(logger: Logger = LoggerImpl()) {
        self.logger = logger
    }
    
    /// Protocol imlementation (see Pairwise protocol documentation)
    internal func create(wallet: Wallet, theirDid: String, myDid: String, metadata: [String : String]?, completion: @escaping (Result<Bool, PairwiseServiceError>) -> Void) {
        
        do {
            let jsonData = try JSONEncoder().encode(metadata)
            let metadata = jsonData.base64EncodedString()

            IndyPairwise.createPairwise(forTheirDid: theirDid, myDid: myDid, metadata: metadata, walletHandle: wallet.handle) { error in
                if let error = error, let nserror = error as NSError?, nserror.code != 0 {
                    completion(.failure(.indy(error)))
                    return
                } else {
                    completion(.success(true))
                    return
                }
            }
        } catch let error {
            completion(.failure(.indy(error)))
            return
        }
    }
    
    /// Protocol imlementation (see Pairwise protocol documentation)
    internal func exists(wallet: Wallet, theirDid: String, completion: @escaping (Result<Bool, PairwiseServiceError>) -> Void) {
        
        IndyPairwise.isPairwiseExists(forDid: theirDid, walletHandle: wallet.handle) { error, exists in
            if let error = error, let nserror = error as NSError?, nserror.code != 0 {
                completion(.failure(.indy(error)))
                return
            } else {
                completion(.success(exists))
                return
            }
        }
    }
    
    /// Protocol imlementation (see Pairwise protocol documentation)
    internal func list(wallet: Wallet, completion: @escaping (Result<[Pairwise], PairwiseServiceError>) -> Void) {
        
        IndyPairwise.listPairwise(fromWalletHandle: wallet.handle) { error, pairwiseResponseJSON in
            
            self.logger.log("Listed pairwise DIDs with this response:")
            self.logger.log(pairwiseResponseJSON ?? "No response")
            
            if let error = error, let nserror = error as NSError?, nserror.code != 0 {
                completion(.failure(.indy(error)))
                return
            } else {
                guard let pairwiseJson = pairwiseResponseJSON,
                    let jsonData = pairwiseJson.data(using: .utf8) else {
                    completion(.failure(.listDidJsonNotReturned))
                    return
                }
                do {
                    let these = try JSONDecoder().decode([String].self, from: jsonData)
                    // let pairwises = try JSONDecoder().decode([Pairwise].self, from: jsonData)
                    var pairwises: [Pairwise] = []
                    for th in these {
                        guard let pwData = th.data(using: .utf8) else {
                                completion(.failure(.listDidJsonNotReturned))
                                return
                        }
                        let pairwise = try JSONDecoder().decode(Pairwise.self, from: pwData)
                        pairwises.append(pairwise)
                    }
                    completion(.success(pairwises))
                    return
                } catch let error {
                    completion(.failure(.indy(error)))
                    return
                }
            }
        }
    }
    
    /// Protocol imlementation (see Pairwise protocol documentation)
    public func retrieve(wallet: Wallet, theirDid: String, completion: @escaping (Result<Pairwise, PairwiseServiceError>) -> Void) {
        IndyPairwise.getForTheirDid(theirDid, walletHandle: wallet.handle) { error, pairwiseResponseJSON in
            self.logger.log("PairwiseResponseJSON:")
            self.logger.log(pairwiseResponseJSON ?? "none")
            
            if let error = error, let nserror = error as NSError?, nserror.code != 0 {
                completion(.failure(.indy(error)))
                return
            } else {
                
                guard let jsonData = pairwiseResponseJSON?.data(using: .utf8) else {
                    completion(.failure(.retrieveJsonNotReturned))
                    return
                }
                
                do {
                    let pairwiseResult = try JSONDecoder().decode(RetrievePairwiseResult.self, from: jsonData)
                    let pairwise = Pairwise(myDid: pairwiseResult.myDid, theirDid: theirDid, metadata: pairwiseResult.metadata)
                    completion(.success(pairwise))
                    return
                } catch let error {
                    completion(.failure(.indy(error)))
                }
                

            }
        }
    }
    
    /// Protocol imlementation (see Pairwise protocol documentation)
    public func update(wallet: Wallet, theirDid: String, metadata: [String : String], completion: @escaping (Result<Bool, PairwiseServiceError>) -> Void) {
        do {
            let jsonData = try JSONEncoder().encode(metadata)
            guard let metadata = String(data: jsonData, encoding: .utf8) else {
                throw DidServiceError.invalidJson
            }
            IndyPairwise.setPairwiseMetadata(metadata, forTheirDid: theirDid, walletHandle: wallet.handle) { error in
                if let error = error, let nserror = error as NSError?, nserror.code != 0 {
                    completion(.failure(.indy(error)))
                    return
                } else {
                    completion(.success(true))
                    return
                }
            }
        } catch let error {
            completion(.failure(.indy(error)))
            return
        }
    }
}
