//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

enum DidDecodeError: Error {
    case invalidMetadata
}

public struct Did: Hashable {
    public let did: String
    public let verkey: String
    public let tempVerkey: String?
    public let metadata: [String: String]?
    
    public init(did: String, verkey: String, tempVerkey: String? = nil, metadata: [String: String]? = nil) {
        self.did = did
        self.verkey = verkey
        self.tempVerkey = tempVerkey
        self.metadata = metadata
    }
    
    enum CodingKeys: String, CodingKey {
        case did
        case verkey
        case tempVerkey
        case metadata
    }
    
    public func metadataForKey(_ key: MetadataKeys) -> String? {
        guard let metadata = self.metadata, let val = metadata[key.rawValue] else {
            return nil
        }
        return val
    }
}

// Decode meta data from a base64 encoded string
extension Did: Decodable {
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        did = try values.decode(String.self, forKey: .did)
        verkey = try values.decode(String.self, forKey: .verkey)
        tempVerkey = try? values.decode(String.self, forKey: .tempVerkey)
        
        let metadataBase64 = try values.decode(String.self, forKey: .metadata)
        guard let metadataData = Data(base64Encoded: metadataBase64) else {
            throw DidDecodeError.invalidMetadata
        }
        metadata = try? JSONDecoder().decode([String: String].self, from: metadataData)
    }
}

// Convert meta data into base64 encoded string when encoding
extension Did: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(did, forKey: .did)
        try container.encode(verkey, forKey: .verkey)
        try container.encode(tempVerkey, forKey: .tempVerkey)
        
        let metadataJsonStr = try JSONEncoder().encode(metadata)
        let metadata64Data = metadataJsonStr.base64EncodedData()
        guard let metadataStr = String(data: metadata64Data, encoding: .utf8) else {
            throw DidDecodeError.invalidMetadata
        }
        try container.encode(metadataStr, forKey: .metadata)
    }
}
