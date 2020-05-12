//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Indy

/**
 Exchange service error
 */
public enum ExchangeServiceError: Error {
    case failedToEncodeConnection(Error)
    case failedToDecodeConnection(Error)
    case failedToSignMessage(CryptoServiceError)
    case failedToVerifySignature(CryptoServiceError)
    case failedToVerifySignatureInvalidSignedData
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

    /// Signs an exchange response.
    ///
    /// - Parameter walletId: Wallet containing the DID present in the exchange response.
    /// - Parameter exchangeResponse: `ExchangeResponse` to sign.
    /// - Parameter completion: Completion handler.
    func signExchangeResponse(wallet: Wallet, exchangeResponse: ExchangeResponse, completion: @escaping (Result<SignedExchangeResponse, ExchangeServiceError>) -> Void)

    /// Verifies the signature present on the signed exchange response.
    /// Returns the exchange response with the signed data and timestamp decoded if the signature is valid, or an error otherwise.
    ///
    /// - Parameter exchangeResponse: Signed exchange response to verify.
    /// - Parameter completion: Completion handler.
    func verifySignedExchangeResponse(_ exchangeResponse: SignedExchangeResponse, completion: @escaping (Result<(ExchangeResponse, Date), ExchangeServiceError>) -> Void)
    
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

    /// Crypto Service
    private let cryptoService: CryptoService
    
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
    
    public init(logger: Logger = LoggerImpl(), cryptoService: CryptoService = CryptoServiceImpl()) {
        self.logger = logger
        self.cryptoService = cryptoService
    }
    
    /// See protocol documentation
    public func invitation(label: String, key: String, serviceEndpoint: String) -> Invitation {
        let id = UUID().uuidString
        let label = label
        let keys = [key]
        let invitation = Invitation(id: id, label: label, recipientKeys: keys, serviceEndpoint: serviceEndpoint, routingKeys: [])
        self.sentInvitations.append(invitation)
        return invitation
    }
    
    /// See protocol documentation
    public func exchangeRequest(did: Did, serviceEndpoint: String, label: String, invitation: Invitation) -> ExchangeRequest {
        self.receivedInvitations.append(invitation)
        let requestId = UUID().uuidString
        let didDoc = DidDoc(
            id: did.did,
            service: [DidDoc.Service(
                id: "\(did.did);indy",
                type: "IndyAgent",
                endpoint: serviceEndpoint,
                recipientKeys: [did.verkey]
            )],
            publicKey: [DidDoc.PublicKey(
                id: "\(did.did)#keys-1",
                type: .ed25519VerificationKey2018,
                controller: did.did,
                specifier: did.verkey
            )]
        )
        let connection = Connection(did: did.did, didDoc: didDoc)
        let exchangeRequest = ExchangeRequest(id: requestId, label: label, connection: connection)
        self.sentExchangeRequests.append(exchangeRequest)
        return exchangeRequest
    }
    
    /// See protocol documentation
    public func exchangeResponse(did: Did, serviceEndpoint: String, label: String, exchangeRequest: ExchangeRequest) -> ExchangeResponse {
        self.receivedExchangeRequests.append(exchangeRequest)
        let messageThread = MessageThread(pthid: nil, thid: exchangeRequest.id)
        let didDoc = DidDoc(
            id: did.did,
            service: [DidDoc.Service(
                id: "\(did.did);indy",
                type: "IndyAgent",
                endpoint: serviceEndpoint,
                recipientKeys: [did.verkey]
            )],
            publicKey: [DidDoc.PublicKey(
                id: "\(did.did)#keys-1",
                type: .ed25519VerificationKey2018,
                controller: did.did,
                specifier: did.verkey
            )]
        )
        let connection = Connection(did: did.did, didDoc: didDoc)
        let exchangeResponse = ExchangeResponse(id: UUID().uuidString, thread: messageThread, connection: connection)
        self.sentExchangeResponses.append(exchangeResponse)
        return exchangeResponse
    }

    /// See protocol documentation
    public func acknowledgement(did: Did, serviceEndpoint: String, exchangeResponse: ExchangeResponse) -> Acknowledgement {
        self.receivedExchangeResponses.append(exchangeResponse)
        let messageThread = MessageThread(pthid: exchangeResponse.thread.pthid, thid: exchangeResponse.id)
        let didDoc = DidDoc(
            id: did.did,
            service: [DidDoc.Service(
                id: "\(did.did);indy",
                type: "IndyAgent",
                endpoint: serviceEndpoint,
                recipientKeys: [did.verkey]
            )],
            publicKey: [DidDoc.PublicKey(
                id: "\(did.did)#keys-1",
                type: .ed25519VerificationKey2018,
                controller: did.did,
                specifier: did.verkey
            )]
        )
        let connection = Connection(did: did.did, didDoc: didDoc)
        let acknowledgement = Acknowledgement(id: UUID().uuidString, thread: messageThread, connection: connection)
        self.sentAcknowledgements.append(acknowledgement)
        return acknowledgement
    }

    internal func signExchangeResponse(wallet: Wallet, exchangeResponse: ExchangeResponse, completion: @escaping (Result<SignedExchangeResponse, ExchangeServiceError>) -> Void) {
        // Compute data to sign - concatenation of timestamp bytes and Connection JSON.
        let connectionJson: Data
        do {
            connectionJson = try JSONEncoder().encode(exchangeResponse.connection)
        } catch let error {
            return completion(.failure(.failedToEncodeConnection(error)))
        }
        let timestampBytes = Data(withUnsafeBytes(of: UInt64(Date().timeIntervalSince1970).bigEndian, Array.init))
        let toSign = (timestampBytes + connectionJson)

        func base64URLEncodedString(_ data: Data) -> String {
            return data.base64EncodedString()
                .replacingOccurrences(of: "+", with: "-")
                .replacingOccurrences(of: "/", with: "_")
        }

        // The signer corresponds to the did doc presented in the exchange response.
        let signer = exchangeResponse.connection.didDoc.publicKey[0].specifier

        cryptoService.signMessage(
            wallet: wallet,
            message: toSign,
            signerVerkey: signer
        ) { result in
            completion(result.map { signature in
                return SignedExchangeResponse(
                    id: exchangeResponse.id,
                    thread: exchangeResponse.thread,
                    signedConnection: SignedEd25519Sha512Single(
                        signedData: base64URLEncodedString(toSign),
                        signature: base64URLEncodedString(signature),
                        signer: signer
                    )
                )
            }.mapError(ExchangeServiceError.failedToSignMessage))
        }
    }

    public func verifySignedExchangeResponse(_ exchangeResponse: SignedExchangeResponse, completion: @escaping (Result<(ExchangeResponse, Date), ExchangeServiceError>) -> Void) {
        func base64URLDecodedString(_ base64url: String) -> Data? {
            let base64 = base64url
                .replacingOccurrences(of: "-", with: "+")
                .replacingOccurrences(of: "_", with: "/")
            return Data(base64Encoded: base64)
        }

        // NOTE: Aries RFC 0234's ed25519sha256_single signature scheme indicates that
        // the signer field should be base64URL encoded. aca-py does not do this.

        guard let signature = base64URLDecodedString(exchangeResponse.signedConnection.signature),
            let signedData = base64URLDecodedString(exchangeResponse.signedConnection.signedData) else {
                return completion(.failure(.failedToVerifySignatureInvalidSignedData))
        }

        cryptoService.verifySignature(
            signature,
            forMessage: signedData,
            signerVerkey: exchangeResponse.signedConnection.signer
        ) { result in
            completion(result
                .mapError(ExchangeServiceError.failedToVerifySignature)
                .flatMap { _ -> Result<(ExchangeResponse, Date), ExchangeServiceError> in
                    let timestampBytes = signedData.prefix(8)
                    let connectionJson = signedData.advanced(by: 8)

                    let connection: Connection
                    do {
                        connection = try JSONDecoder().decode(Connection.self, from: connectionJson)
                    } catch let error {
                        return .failure(.failedToDecodeConnection(error))
                    }

                    let timestampInt = UInt64(bigEndian: timestampBytes.withUnsafeBytes { $0.load(as: UInt64.self) })
                    let timestamp = Date(timeIntervalSince1970: TimeInterval(timestampInt))

                    return .success((ExchangeResponse(
                        id: exchangeResponse.id,
                        thread: exchangeResponse.thread,
                        connection: connection
                    ), timestamp))
                })
        }
    }
}
