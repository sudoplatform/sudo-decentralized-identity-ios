//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Indy

public enum DidServiceError: Error {
    case invalidJson
    case indy(Error)
    case general(Error)
    case didAndVerkeyNotReturned
    case listDidJsonNotReturned
    case verkeyNotReturned
    case unknown
}

/**
 Service for handling DID operations
 */
internal protocol DidService {
    
    /**
     Create and store a DID in my wallet
     
     - Parameter: Wallet
     - Parameter: Completion handler
     */
    func createAndStoreMyDid(wallet: Wallet, completion: @escaping (Result<Did, DidServiceError>) -> Void)
    
    /**
     Store their DID and verkey
     
     - Parameter: Wallet
     - Parameter: DID to store
     - Parameter: Verkey to store
     */
    func storeTheirDid(wallet: Wallet, did: String, verkey: String, completion: @escaping (Result<Bool, DidServiceError>) -> Void)
    
    /**
     Get key for DID
     
     - Parameter: Wallet
     - Parameter: DID
     - Parameter: Completion handler
     */
    func keyForDid(wallet: Wallet, did: String, completion: @escaping (Result<String, DidServiceError>) -> Void)
    
    /**
     List my DIDs
     
     - Parameter: Wallet
     - Parameter: Completion handler
     */
    func listMyDids(wallet: Wallet, completion: @escaping (Result<[Did], DidServiceError>) -> Void)
    
    /**
     Update metadata for DID - provide metadata in updated DID object (TODO - might be confusing interface)
     
     - Parameter: Wallet
     - Parameter: DID
     */
    func updateMetadata(wallet: Wallet, did: Did, completion: @escaping (Result<Bool, DidServiceError>) -> Void)
    
    /**
     Get verkey for DID
     
     - Parameter: Wallet
     - Parameter: DID
     */
    func verkey(wallet: Wallet, did: String, completion: @escaping(Result<String, DidServiceError>) -> Void)
    
    /**
     Check to see if DID is the primary DID (TODO - needs attention)
     
     - Parameter: DID
     
     - Returns: Whether it is primary
     */
    func isPrimary(did: Did) -> Bool
    
    /**
     Write DID to the ledger
     
     - Parameter: DID
     - Parameter: Verkey
     - Parameter: Ledger
     - Parameter: Completion handler
     */
    func writeToLedger(did: String, verkey: String, ledger: Ledger, completion: @escaping (Result<Bool, DidServiceError>) -> Void)
    
}

/**
 Representation of Indy library's DID detail response
 */
private struct MyDidDetails: Codable {
    
    /// DID
    let did: String? = nil
    
    /// Seed
    let seed: String? = nil
    
    /// Crypt type
    let cryptoType: String? = nil
    
    /// CID
    let cid: Bool? = nil
    
    /// Method name
    let methodName: String? = nil
    
    /// Conversion of object properties to JSON keys
    enum CodingKeys: String, CodingKey {
        case did
        case seed
        case cryptoType = "crypto_type"
        case cid
        case methodName = "method_name"
    }
    
    /**
     JSON representation of DID details
     
     - Throws: `DidServiceError.invalidJson`
                if JSON is not valid
     
     - Returns: JSON respresentation of DID details
     */
    func json() throws -> String {
        let jsonData = try JSONEncoder().encode(self)
        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            throw DidServiceError.invalidJson
        }
        return jsonString
    }
    
}

/**
Representation of Indy library's DID detail response for their DIDs
*/
private struct TheirDidDetails: Codable {
    
    /// DID
    let did: String
    
    /// Verkey
    var verkey: String? = nil
    
    /// Crypto type
    var cryptoType: String? = nil

    /// Conversion of object properties to JSON keys
    enum CodingKeys: String, CodingKey {
        case did
        case verkey
        case cryptoType = "crypto_type"
    }
    
    /**
     Generate JSON from their did details
     
     - Throws: `DidServiceError.invalidJSON`
                if JSON cannot data cannot be converted to a string
     
     - Returns: JSON string
     */
    func json() throws -> String {
        let jsonData = try JSONEncoder().encode(self)
        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            throw DidServiceError.invalidJson
        }
        return jsonString
    }
    
}

/**
 Error when listing DIDs causes an error when processing one of the DIDs
 */
enum ListDidsResponseDidError: Error {
    case invalidMetadata
}

/**
 Representation of Indy library's list DIDs response
 */
internal struct ListDidsResponseDid {
    
    /// DID
    let did: String
    
    /// Verkey
    let verkey: String
    
    /// Metadata
    let metadata: [String: String]?
    
    /// Conversion between object properties and JSON keys
    enum CodingKeys: String, CodingKey {
        case did
        case verkey
        case metadata
    }
}

/**
Extension to handle decoding of list DIDs result
*/
extension ListDidsResponseDid: Decodable {
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        did = try values.decode(String.self, forKey: .did)
        verkey = try values.decode(String.self, forKey: .verkey)
        
        // Base64 decode metadata
        let metadataBase64 = try values.decode(String?.self, forKey: .metadata)
        
        if let metadataBase64 = metadataBase64 {
            guard let metadataData = Data(base64Encoded: metadataBase64) else {
                throw DidDecodeError.invalidMetadata
            }
            metadata = try JSONDecoder().decode([String: String].self, from: metadataData)
        } else {
            metadata = nil
        }
    }
}

/**
Extension to handle encoding of list DIDs result
*/
extension ListDidsResponseDid: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(did, forKey: .did)
        try container.encode(verkey, forKey: .verkey)
        
        let metadataJsonStr = try JSONEncoder().encode(metadata)
        
        // Base64 enccode metadata
        let metadata64Data = metadataJsonStr.base64EncodedData()
        guard let metadataStr = String(data: metadata64Data, encoding: .utf8) else {
            throw DidDecodeError.invalidMetadata
        }
        try container.encode(metadataStr, forKey: .metadata)
    }
}

/**
 Implementation of DID service protocol
 */
internal class DidServiceImpl: DidService {
    
    /// Purpose key for metadata
    private let DID_PURPOSE_KEY = "purpose"
    
    /// Value for primary DID
    private let PRIMARY_DID_PURPOSE = "primary identity DID"
    
    /// Logger
    private let logger: Logger
    
    public init(logger: Logger = LoggerImpl()) {
        self.logger = logger
    }
    
    /// Protocol imlementation (see DidService protocol documentation)
    internal func createAndStoreMyDid(wallet: Wallet, completion: @escaping (Result<Did, DidServiceError>) -> Void) {
        
        do {
            let didJson = try MyDidDetails().json()
            IndyDid.createAndStoreMyDid(didJson, walletHandle: wallet.handle) { error, did, verkey in
                
                // Handle errors in creating and storing DID
                if let error = error {
                    let indyCode = self.toIndyCode(error: error)
                    switch indyCode {
                    // Successful code or did already exists
                    case .Success, .DidAlreadyExistsError:
                        guard let did = did, let verkey = verkey else {
                            completion(.failure(.didAndVerkeyNotReturned))
                            return
                        }
                        self.logger.log("Did and verkey created:")
                        self.logger.log("Did: \(did)")
                        self.logger.log("Verkey: \(verkey)")
                        let newDid = Did(did: did, verkey: verkey, tempVerkey: nil, metadata: [:])
                        completion(.success(newDid))
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
    
    /// Protocol imlementation (see DidService protocol documentation)
    internal func storeTheirDid(wallet: Wallet, did: String, verkey: String, completion: @escaping (Result<Bool, DidServiceError>) -> Void) {
        do {
            let theirDidDetails = TheirDidDetails(did: did, verkey: verkey, cryptoType: nil)
            let identityJSON = try theirDidDetails.json()
            IndyDid.storeTheirDid(identityJSON, walletHandle: wallet.handle) { error in
                if let error = error, let nserror = error as NSError?, nserror.code != 0 {
                    completion(.failure(.indy(error)))
                    return
                } else {
                    completion(.success(true))
                    return
                }
            }
        } catch let error {
            completion(.failure(.general(error)))
            return
        }
    }
    
    /// Protocol imlementation (see DidService protocol documentation)
    internal func keyForDid(wallet: Wallet, did: String, completion: @escaping (Result<String, DidServiceError>) -> Void) {
        
        IndyDid.key(forLocalDid: did, walletHandle: wallet.handle) { error, key in
            if let error = error, let nserror = error as NSError?, nserror.code != 0 {
                completion(.failure(.indy(error)))
                return
            } else {
                guard let key = key else {
                    completion(.failure(.verkeyNotReturned))
                    return
                }
                completion(.success(key))
                return
            }
        }
    }
    
    /// Protocol imlementation (see DidService protocol documentation)
    internal func listMyDids(wallet: Wallet, completion: @escaping (Result<[Did], DidServiceError>) -> Void) {
        
        IndyDid.listMyDids(withMeta: wallet.handle) { error, listDidsResponseJSON in
            
            self.logger.log("Listed DIDs with this response:")
            self.logger.log(listDidsResponseJSON ?? "No response")
            
            if let error = error, let nserror = error as NSError?, nserror.code != 0 {
                completion(.failure(.indy(error)))
                return
            } else {
                guard let jsonData = listDidsResponseJSON?.data(using: .utf8) else {
                    completion(.failure(.listDidJsonNotReturned))
                    return
                }
                do {
                    let responseDids = try JSONDecoder().decode([ListDidsResponseDid].self, from: jsonData)
                    var dids: [Did] = []
                    for did in responseDids {
                        dids.append(Did(did: did.did, verkey: did.verkey, tempVerkey: nil, metadata: did.metadata))
                    }
                    completion(.success(dids))
                    return
                    
                } catch let error {
                    completion(.failure(.general(error)))
                    return
                }
            }
        }
    }
    
    /// Protocol imlementation (see DidService protocol documentation)
    internal func updateMetadata(wallet: Wallet, did: Did, completion: @escaping (Result<Bool, DidServiceError>) -> Void) {
        
        do {
            let jsonData = try JSONEncoder().encode(did.metadata)
            let metadataStr = jsonData.base64EncodedString()

            IndyDid.setMetadata(metadataStr, forDid: did.did, walletHandle: wallet.handle) { error in
                if let error = error, let nserror = error as NSError?, nserror.code != 0 {
                    completion(.failure(.indy(error)))
                    return
                } else {
                    completion(.success(true))
                    return
                }
            }
        } catch let error {
            completion(.failure(.general(error)))
            return
        }
    }
    
    /// Protocol imlementation (see DidService protocol documentation)
    internal func verkey(wallet: Wallet, did: String, completion: @escaping (Result<String, DidServiceError>) -> Void) {
        IndyDid.key(forLocalDid: did, walletHandle: wallet.handle) { error, verkey in
            if let error = error {
                let indyCode = self.toIndyCode(error: error)
                switch indyCode {
                // Successful code or did already exists
                case .Success:
                    guard let verkey = verkey else {
                        completion(.failure(.verkeyNotReturned))
                        return
                    }
                    completion(.success(verkey))
                    return
                // All other indy errors just propagate
                default:
                    completion(.failure(.indy(error)))
                    return
                }
            }
        }
    }
    
    /// Protocol imlementation (see DidService protocol documentation)
    internal func isPrimary(did: Did) -> Bool {
        
        guard let metadata = did.metadata else {
            return false
            
        }
        guard let purpose = metadata[self.DID_PURPOSE_KEY] else {
            return false
        }
        
        return purpose == self.PRIMARY_DID_PURPOSE
    }
    
    /// Protocol imlementation (see DidService protocol documentation)
    internal func writeToLedger(did: String, verkey: String, ledger: Ledger, completion: @escaping (Result<Bool, DidServiceError>) -> Void) {

        let payload = SelfServePayload(did: did, verkey: verkey, network: ledger.rawValue, paymentaddr: "")
        guard let payloadData = try? JSONEncoder().encode(payload) else {
            completion(.failure(.unknown)) // TODO
            return
        }
        
        let url = URL(string: "https://selfserve.sovrin.org/nym")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let task = URLSession.shared.uploadTask(with: request, from: payloadData) { data, response, error in
    
            if let error = error {
                completion(.failure(.general(error))) // TODO
                return
            }
            guard let response = response as? HTTPURLResponse,
                (200...299).contains(response.statusCode) else {
                    completion(.failure(.unknown)) // TODO
                    return
            }
            if let data = data,
                let dataString = String(data: data, encoding: .utf8) {
                
                print ("got data: \(dataString)")
                completion(.success(true))
            
            }
        }

        task.resume()
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

struct SelfServePayload: Codable {
    let did: String
    let verkey: String
    let network: String
    let paymentaddr: String
}

public enum Ledger: String {
    case buildernet
    case stagingnet
}
