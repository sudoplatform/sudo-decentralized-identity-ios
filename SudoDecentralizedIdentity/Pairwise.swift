//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/**
 Error that occurs during pairwise decoding
 */
enum PairwiseDecodeError: Error {
    case invalidMetadata
}

/**
 Representation of the pairwise reflecting Indy library
 */
public struct Pairwise: Hashable {
    
    /// My DID
    public let myDid: String
    
    /// Their DID
    public let theirDid: String
    
    /// Pairwise metadata
    public let metadata: [String: String]
    
    /**
     Initialize
     
     - Parameter: My DID
     - Parameter: Their DID
     - Parameter: Pairwise metadata
     
     */
    public init(myDid: String, theirDid: String, metadata: [String: String]) {
        self.myDid = myDid
        self.theirDid = theirDid
        self.metadata = metadata
    }
    
    /// Conversion between object properties and JSON keys
    enum CodingKeys: String, CodingKey {
        case myDid = "my_did"
        case theirDid = "their_did"
        case metadata
    }
    
    public func metadataForKey(_ key: MetadataKeys) -> String? {
        guard let val = self.metadata[key.rawValue] else {
            return nil
        }
        return val
    }
}

/**
 Extension to handle decoding of pairwise object
 */
extension Pairwise: Decodable {
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        myDid = try values.decode(String.self, forKey: .myDid)
        theirDid = try values.decode(String.self, forKey: .theirDid)
        
        // Base64 decode metadata to handle some issues with double-escaping quotes
        let metadataBase64 = try values.decode(String.self, forKey: .metadata)
        guard let metadataData = Data(base64Encoded: metadataBase64) else {
            throw PairwiseDecodeError.invalidMetadata
        }
        metadata = try JSONDecoder().decode([String: String].self, from: metadataData)
    }
}

/**
 Extension to handle encoding of pairwise object
 */
extension Pairwise: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(myDid, forKey: .myDid)
        try container.encode(theirDid, forKey: .theirDid)
        
        let metadataJsonStr = try JSONEncoder().encode(metadata)
        
        // Base64 encode metadata to handle some issues with double-escaping quotes
        let metadata64Data = metadataJsonStr.base64EncodedData()
        guard let metadataStr = String(data: metadata64Data, encoding: .utf8) else {
            throw PairwiseDecodeError.invalidMetadata
        }
        try container.encode(metadataStr, forKey: .metadata)
        
    }
}
