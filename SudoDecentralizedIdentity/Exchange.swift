//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/**
 Representation of exchange protocol message thread
 */
public struct MessageThread: Codable {
    public let pthid: String?
    public let thid: String
}

/**
 Representation of exchange protocol DID doc
 */
public struct DidDoc: Codable {
    public struct Service: Codable {
        public let id: String
        public let type: String
        public let endpoint: String
        public let recipientKeys: [String]
        public let routingKeys: [String]

        public enum CodingKeys: String, CodingKey {
            case id, type, recipientKeys, routingKeys
            case endpoint = "serviceEndpoint"
        }

        init(id: String, type: String, endpoint: String, recipientKeys: [String], routingKeys: [String]) {
            self.id = id
            self.type = type
            self.endpoint = endpoint
            self.recipientKeys = recipientKeys
            self.routingKeys = routingKeys
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decode(String.self, forKey: .id)
            type = try container.decode(String.self, forKey: .type)
            endpoint = try container.decode(String.self, forKey: .endpoint)
            recipientKeys = try container.decodeIfPresent([String].self, forKey: .recipientKeys) ?? []
            routingKeys = try container.decodeIfPresent([String].self, forKey: .routingKeys) ?? []
        }
    }

    public struct PublicKey: Codable {
        public enum PublicKeyType: String, Codable {
            case ed25519VerificationKey2018 = "Ed25519VerificationKey2018"
            case rsaVerificationKey2018 = "RsaVerificationKey2018"
            case secp256k1VerificationKey2018 = "Secp256k1VerificationKey2018"

            public var specifierKey: PublicKey.CodingKeys {
                switch self {
                case .ed25519VerificationKey2018: return .publicKeyBase58
                case .rsaVerificationKey2018: return .publicKeyPem
                case .secp256k1VerificationKey2018: return .publicKeyHex
                }
            }
        }

        public let id: String
        public let type: PublicKeyType
        public let controller: String
        public let specifier: String

        public enum CodingKeys: String, CodingKey {
            case id, type, controller
            case publicKeyBase58, publicKeyPem, publicKeyHex
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(id, forKey: .id)
            try container.encode(type, forKey: .type)
            try container.encode(controller, forKey: .controller)
            try container.encode(specifier, forKey: type.specifierKey)
        }

        // TODO: Support referenced URL public keys.
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            try id = container.decode(String.self, forKey: .id)
            try type = container.decode(PublicKeyType.self, forKey: .type)
            try controller = container.decode(String.self, forKey: .controller)
            try specifier = container.decode(String.self, forKey: type.specifierKey)
        }

        init(id: String, type: PublicKeyType, controller: String, specifier: String) {
            self.id = id
            self.type = type
            self.controller = controller
            self.specifier = specifier
        }
    }

    public let context = "https://www.w3.org/ns/did/v1"
    public let id: String?
    public let service: [Service]
    public let publicKey: [PublicKey]
    // TODO: `authentication`

    public enum CodingKeys: String, CodingKey {
        case context = "@context"
        case id, service, publicKey
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        service = try container.decodeIfPresent([Service].self, forKey: .service) ?? []
        publicKey = try container.decodeIfPresent([PublicKey].self, forKey: .publicKey) ?? []
    }

    init(id: String, service: [Service], publicKey: [PublicKey]) {
        self.id = id
        self.service = service
        self.publicKey = publicKey
    }
}

/**
 Representation of exchange protocol connection
 */
public struct Connection: Codable {
    public let did: String
    public let didDoc: DidDoc

    public enum CodingKeys: String, CodingKey {
        case did = "DID"
        case didDoc = "DIDDoc"
    }
}

/*
 {
     "@type": "https://didcomm.org/didexchange/1.0/invitation",
     "@id": "12345678900987654321",
     "label": "Alice",
     "recipientKeys": ["8HH5gYEeNc3z7PYXmd54d4x6qAfCNrqQqEB3nS7Zfu7K"],
     "serviceEndpoint": "https://example.com/endpoint",
     "routingKeys": ["8HH5gYEeNc3z7PYXmd54d4x6qAfCNrqQqEB3nS7Zfu7K"]
 }
 */

/**
 Representation of exchange protocol invitation
 */
public struct Invitation: Codable {
    
    public let type = "did:sov:BzCbsNYhMrjHiqZDTUASHg;spec/connections/1.0/invitation"
    
    public let id: String
    
    public let label: String

    public let imageURL: String?

    // TODO: support DID invitation

    public let recipientKeys: [String]
    
    public let serviceEndpoint: String
    
    public let routingKeys: [String]?

    public enum CodingKeys: String, CodingKey {
        case type = "@type"
        case id = "@id"
        case imageURL = "imageUrl"
        case label, recipientKeys, serviceEndpoint, routingKeys
    }
    
}

/*
 {
   "@id": "a46cdd0f-a2ca-4d12-afbf-2e78a6f1f3ef",
   "@type": "https://didcomm.org/didexchange/1.0/request",
   "~thread": { "pthid": "did:example:21tDAKCERh95uGgKbJNHYp#invitation" },
   "label": "Bob",
   "connection": {
     "did": "B.did@B:A",
     "did_doc": {
         "@context": "https://w3id.org/did/v1"
         // DID Doc contents here.
     }
   }
 }
 */

/**
Representation of exchange protocol exchange request
*/
public struct ExchangeRequest: Codable {
    
    public let type = "did:sov:BzCbsNYhMrjHiqZDTUASHg;spec/connections/1.0/request"
    
    public let id: String

    public let label: String

    public let connection: Connection

    public enum CodingKeys: String, CodingKey {
        case type = "@type"
        case id = "@id"
        case label, connection
    }

}

/// Representation of the value of a signed field using the ed25519Sha512_single signature scheme.
///
/// # Reference
/// [Aries RFC 0234 Signature Decorator](https://github.com/hyperledger/aries-rfcs/blob/master/features/0234-signature-decorator/README.md)
public struct SignedEd25519Sha512Single: Codable {
    public let type = "did:sov:BzCbsNYhMrjHiqZDTUASHg;spec/signature/1.0/ed25519Sha512_single"
    public let signedData: String
    public let signature: String
    public let signer: String

    public enum CodingKeys: String, CodingKey {
        case type = "@type"
        case signature, signer
        case signedData = "sig_data"
    }
}

/*
 {
   "@type": "https://didcomm.org/didexchange/1.0/response",
   "@id": "12345678900987654321",
   "~thread": {
     "thid": "<The Thread ID is the Message ID (@id) of the first message in the thread>"
   },
   "connection": {
     "did": "A.did@B:A",
     "did_doc": {
       "@context": "https://w3id.org/did/v1"
       // DID Doc contents here.
     }
   }
 }
 */

/**
Representation of exchange protocol exchange response
*/
public struct ExchangeResponse: Codable {
    
    public let type = "did:sov:BzCbsNYhMrjHiqZDTUASHg;spec/connections/1.0/response"
    
    public let id: String
    
    public let thread: MessageThread
    
    public let connection: Connection

    public enum CodingKeys: String, CodingKey {
        case type = "@type"
        case id = "@id"
        case thread = "~thread"
        case connection
    }
    
}

/// Representation of exchange protocol exchange response with signed `connection` field.
public struct SignedExchangeResponse: Codable {
    public let type = "did:sov:BzCbsNYhMrjHiqZDTUASHg;spec/connections/1.0/response"

    public let id: String

    public let thread: MessageThread

    public let signedConnection: SignedEd25519Sha512Single

    public enum CodingKeys: String, CodingKey {
        case type = "@type"
        case id = "@id"
        case thread = "~thread"
        case signedConnection = "connection~sig"
    }
}

/**
Representation of exchange protocol acknowledgement
*/
public struct Acknowledgement: Codable {
    
    public let type = "did:sov:BzCbsNYhMrjHiqZDTUASHg;spec/connections/1.0/acknowledgement"
    
    public let id: String
    
    public let thread: MessageThread
    
    public let connection: Connection

    public enum CodingKeys: String, CodingKey {
        case type = "@type"
        case id = "@id"
        case thread = "~thread"
        case connection
    }
}
