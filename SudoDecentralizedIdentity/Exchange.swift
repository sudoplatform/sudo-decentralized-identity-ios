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
    public let pthid: String
}

/**
 Representation of exchange protocol DID doc
 */
public struct DidDoc: Codable {
    public let context = "https://w3id.org/did/v1"
    public let did: String
    public let verKey: String
    public let serviceEndpoint: String
}

/**
 Representation of exchange protocol connection
 */
public struct Connection: Codable {
    public let did: String
    public let didDoc: DidDoc
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
    
    public let type = "https://didcomm.org/didexchange/1.0/invitation"
    
    public let id: String
    
    public let label: String
    
    public let recipientKeys: [String]
    
    public let serviceEndpoint: String
    
    public let routingKeys: [String]
    
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
    
    public let type = "https://didcomm.org/didexchange/1.0/request"
    
    public let id: String
    
    public let thread: MessageThread
    
    public let label: String
    
    public let connection: Connection
    
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
    
    public let type = "https://didcomm.org/didexchange/1.0/response"
    
    public let id: String
    
    public let thread: MessageThread
    
    public let connection: Connection
    
    
}

/**
Representation of exchange protocol acknowledgement
*/
public struct Acknowledgement: Codable {
    
    public let type = "https://didcomm.org/didexchange/1.0/acknowledgement"
    
    public let id: String
    
    public let thread: MessageThread
    
    public let connection: Connection
}
