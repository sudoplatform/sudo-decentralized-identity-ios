//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/**
 Exchange service error
 */
public enum ExchangeServiceError: Error {
    case invalidJson
    case failedToEncodeVerkeys
    case noDataAfterPack
    case indy(Error)
    case unknown
}

/**
 Exchange service protocol
 */
internal protocol ExchangeService {

    /**
     Generate an invitation
     
     - Parameter: Label
     - Parameter: Key
     - Parameter: Service endpoint
     
     - Returns: Invitation
     */
    func invitation(label: String, key: String, serviceEndpoint: String) -> Invitation
    
    /**
     Generate exchange request
     
     - Parameter: DID
     - Parameter: Service endpoint
     - Parameter: Label
     - Parameter: Invitation
     
     - Returns: ExchangeRequest
     */
    func exchangeRequest(did: Did, serviceEndpoint: String, label: String, invitation: Invitation) -> ExchangeRequest
    
    /**
     Generate exchange response
     
     - Parameter: DID
     - Parameter: Service endpoint
     - Parameter: Label
     - Parameter: Exchange request
     
     - Returns: ExchangeResponse
     */
    func exchangeResponse(did: Did, serviceEndpoint: String, label: String, exchangeRequest: ExchangeRequest) -> ExchangeResponse
    
    /**
     Generate acknowledgement
     
     - Parameter: DID
     - Parameter: Service endpoint
     
     - Returns: Acknowledgement
     */
    func acknowledgement(did: Did, serviceEndpoint: String, exchangeResponse: ExchangeResponse) -> Acknowledgement
    
}

/**
 Implementation of ExchangeService
 */
internal class ExchangeServiceImpl: ExchangeService {
    
    /// Logger
    private let logger: Logger
    
    /// Sent invitations
    private var sentInvitations: [Invitation] = []
    
    /// Received invitations
    private var receivedInvitations: [Invitation] = []
    
    /// Sent exchange requests
    private var sentExchangeRequests: [ExchangeRequest] = []
    
    /// Received exchange requests
    private var receivedExchangeRequests: [ExchangeRequest] = []
    
    /// Sent exchange responses
    private var sentExchangeResponses: [ExchangeResponse] = []
    
    /// Received exchange responses
    private var receivedExchangeResponses: [ExchangeResponse] = []
    
    /// Sent acknowledgements
    private var sentAcknowledgements: [Acknowledgement] = []
    
    /// Received acknowledgements
    private var receivedAcknowledgements: [Acknowledgement] = []
    
    public init(logger: Logger = LoggerImpl()) {
        self.logger = logger
    }
    
    /// See protocol documentation
    public func invitation(label: String, key: String, serviceEndpoint: String) -> Invitation {
        let id = UUID().uuidString
        let label = label
        let keys = [key]
        let invitation = Invitation(id: id, label: label, recipientKeys: keys, serviceEndpoint: serviceEndpoint, routingKeys: keys)
        self.sentInvitations.append(invitation)
        return invitation
    }
    
    /// See protocol documentation
    public func exchangeRequest(did: Did, serviceEndpoint: String, label: String, invitation: Invitation) -> ExchangeRequest {
        self.receivedInvitations.append(invitation)
        let messageThread = MessageThread(pthid: invitation.id)
        let didDoc = DidDoc(did: did.did, verKey: did.verkey, serviceEndpoint: serviceEndpoint)
        let connection = Connection(did: did.did, didDoc: didDoc)
        let exchangeRequest = ExchangeRequest(id: invitation.id, thread: messageThread, label: label, connection: connection)
        self.sentExchangeRequests.append(exchangeRequest)
        return exchangeRequest
    }
    
    /// See protocol documentation
    public func exchangeResponse(did: Did, serviceEndpoint: String, label: String, exchangeRequest: ExchangeRequest) -> ExchangeResponse {
        self.receivedExchangeRequests.append(exchangeRequest)
        let didDoc = DidDoc(did: did.did, verKey: did.verkey, serviceEndpoint: serviceEndpoint)
        let connection = Connection(did: did.did, didDoc: didDoc)
        let exchangeResponse = ExchangeResponse(id: exchangeRequest.id, thread: exchangeRequest.thread, connection: connection)
        self.sentExchangeResponses.append(exchangeResponse)
        return exchangeResponse
    }
    
    /// See protocol documentation
    public func acknowledgement(did: Did, serviceEndpoint: String, exchangeResponse: ExchangeResponse) -> Acknowledgement {
        self.receivedExchangeResponses.append(exchangeResponse)
        let didDoc = DidDoc(did: did.did, verKey: did.verkey, serviceEndpoint: serviceEndpoint)
        let connection = Connection(did: did.did, didDoc: didDoc)
        let acknowledgement = Acknowledgement(id: exchangeResponse.id, thread: exchangeResponse.thread, connection: connection)
        self.sentAcknowledgements.append(acknowledgement)
        return acknowledgement
    }
}
