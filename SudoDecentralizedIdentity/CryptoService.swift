//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Indy

/// Crypto service error
public enum CryptoServiceError: Error {
    case failedToEncodeReceiverVerkeys(Error)
    case failedToDecodeResultingData(Error)
    case indyError((IndyErrorCode, String?)?)
}

/// Packed authcrypt or anoncrypt message.
public struct PackedMessage: Codable {
    public let protected: String
    public let ciphertext: String
    public let iv: String
    public let tag: String
}

/// Unpacked authcrypt or anoncrypt message.
public struct UnpackedMessage: Codable {
    public let message: String
    public let senderVerkey: String?
    public let recipientVerkey: String

    enum CodingKeys: String, CodingKey {
        case message
        case senderVerkey = "sender_verkey"
        case recipientVerkey = "recipient_verkey"
    }
}

/// Crypto service protocol. Packs and unpacks encrypted envelopes (Aries RFC 0019).
internal protocol CryptoService {
    /// Packs an encrypted envelope in either authcrypt or anoncrypt mode depending on `senderVerkey`.
    ///
    /// To use a DID with this function, call `DidService.keyForDid` to get the verkey for a specific DID.
    ///
    /// - Parameter wallet: Wallet.
    /// - Parameter message: Message data to encrypt.
    /// - Parameter receiverVerkeys: List of recipient verkeys to encrypt with.
    /// - Parameter senderVerkey: Sender to reveal to recipients. If nil, encrypts in anoncrypt mode.
    /// - Parameter completion: Completion handler.
    /// -   Parameter result: The encrypted data or `CryptoServiceError`.
    func packMessage(wallet: Wallet, message: Data, receiverVerkeys: [String], senderVerkey: String?, completion: @escaping (_ result: Result<PackedMessage, CryptoServiceError>) -> Void)

    /// Unpacks an encrypted envelope in either authcrypt or anoncrypt mode.
    ///
    /// - Parameter wallet: Wallet.
    /// - Parameter message: Message data to decrypt.
    /// - Parameter completion: Completion handler.
    /// -   Parameter result: The decrypted data or `CryptoServiceError`.
    func unpackMessage(wallet: Wallet, message: Data, completion: @escaping (_ result: Result<UnpackedMessage, CryptoServiceError>) -> Void)

    /// Signs the given message..
    ///
    /// - Parameter walletId: Wallet.
    /// - Parameter message: Message to sign.
    /// - Parameter signerVerkey: Verkey to sign with.
    /// - Parameter completion: Completion handler.
    func signMessage(wallet: Wallet, message: Data, signerVerkey: String, completion: @escaping (_ result: Result<Data, CryptoServiceError>) -> Void)

    /// Verifies the given signature for the provided message.
    ///
    /// - Parameter signature: Signature to verify.
    /// - Parameter message: Message to verify signature for.
    /// - Parameter signerVerkey: Verkey message was signed with.
    /// - Parameter completion: Completion handler.
    func verifySignature(_ signature: Data, forMessage message: Data, signerVerkey: String, completion: @escaping (_ result: Result<Void, CryptoServiceError>) -> Void)
}

/// `CryptoService` implementation
internal class CryptoServiceImpl: CryptoService {
    /// Logger
    private let logger: Logger

    /// Instantiates a `CryptoServiceImpl`
    internal init(logger: Logger = LoggerImpl()) {
        self.logger = logger
    }

    func packMessage(wallet: Wallet, message: Data, receiverVerkeys: [String], senderVerkey: String?, completion: @escaping (Result<PackedMessage, CryptoServiceError>) -> Void) {
        let receiversJsonData: Data
        do {
            receiversJsonData = try JSONEncoder().encode(receiverVerkeys)
        } catch let error {
            return completion(.failure(.failedToEncodeReceiverVerkeys(error)))
        }

        let receiversJson = String(decoding: receiversJsonData, as: Unicode.UTF8.self)

        // When nil / null pointer is passed for the `sender`, anoncrypt is used.
        // Note that this differs from the RFC which mentions the empty string.
        IndyCrypto.packMessage(
            message,
            receivers: receiversJson,
            sender: senderVerkey,
            walletHandle: wallet.handle
        ) { error, data in
            switch (data, error.flatMap(self.toIndyCode)) {
            case (.some(let data), .none), (.some(let data), .Success):
                // successfully packed
                do {
                    let packed = try JSONDecoder().decode(PackedMessage.self, from: data)
                    completion(.success(packed))
                } catch let error {
                    completion(.failure(.failedToDecodeResultingData(error)))
                }
            case (_, .some(let errorCode)):
                // error message from indy
                let indyErrorMessage = (error as NSError?)?.userInfo["message"] as? String
                completion(.failure(.indyError((errorCode, indyErrorMessage))))
            case (.none, _):
                // no data, but no error message from indy
                completion(.failure(.indyError(nil)))
            }
        }
    }

    func unpackMessage(wallet: Wallet, message: Data, completion: @escaping (Result<UnpackedMessage, CryptoServiceError>) -> Void) {
        IndyCrypto.unpackMessage(message, walletHandle: wallet.handle) { error, data in
            switch (data, error.flatMap(self.toIndyCode)) {
            case (.some(let data), .none), (.some(let data), .Success):
                // successfully unpacked
                do {
                    let unpacked = try JSONDecoder().decode(UnpackedMessage.self, from: data)
                    completion(.success(unpacked))
                } catch let error {
                    completion(.failure(.failedToDecodeResultingData(error)))
                }
            case (_, .some(let errorCode)):
                // error message from indy
                let indyErrorMessage = (error as NSError?)?.userInfo["message"] as? String
                completion(.failure(.indyError((errorCode, indyErrorMessage))))
            case (.none, _):
                // no data, but no error message from indy
                completion(.failure(.indyError(nil)))
            }
        }
    }

    func signMessage(wallet: Wallet, message: Data, signerVerkey: String, completion: @escaping (Result<Data, CryptoServiceError>) -> Void) {
        IndyCrypto.signMessage(message, key: signerVerkey, walletHandle: wallet.handle) { error, data in
            switch (data, error.flatMap(self.toIndyCode)) {
            case (.some(let data), .none), (.some(let data), .Success):
                // successfully signed
                completion(.success(data))
            case (_, .some(let errorCode)):
                // error message from indy
                let indyErrorMessage = (error as NSError?)?.userInfo["message"] as? String
                completion(.failure(.indyError((errorCode, indyErrorMessage))))
            case (.none, _):
                // no data, but no error message from indy
                completion(.failure(.indyError(nil)))
            }
        }
    }

    func verifySignature(_ signature: Data, forMessage message: Data, signerVerkey: String, completion: @escaping (Result<Void, CryptoServiceError>) -> Void) {
        IndyCrypto.verifySignature(signature, forMessage: message, key: signerVerkey) { error, success in
            switch (success, error.flatMap(self.toIndyCode)) {
            case (true, .none), (true, .Success):
                // successfully verified
                completion(.success(()))
            case (_, .some(let errorCode)):
                // error message from indy
                let indyErrorMessage = (error as NSError?)?.userInfo["message"] as? String
                completion(.failure(.indyError((errorCode, indyErrorMessage))))
            case (false, _):
                // failed, but no error message from indy
                completion(.failure(.indyError(nil)))
            }
        }
    }

    private func toIndyCode(error: Error) -> IndyErrorCode? {
        switch (error as NSError).domain {
        case "IndyErrorDomain":
            return IndyErrorCode(rawValue: (error as NSError).code)
        default:
            return nil
        }
    }
}
