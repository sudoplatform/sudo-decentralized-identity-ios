//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Indy

/**
 Callback type
 */
public typealias ClientCallback<T> = (Result<T, SudoDecentralizedIdentityClientError>) -> Void

/**
 SSI Service errors
 */
public enum SudoDecentralizedIdentityClientError: Error {
    case createWalletFailed
    case openWalletFailed
    case createPrimaryDidFailed
    case retrievePrimaryDidFailed
    case failedToEncodeMessageUtf8
    case failedToDecodeMessage
    case general(Error)
    case unknown
}

public enum MetadataKeys: String {
    case label = "LABEL"
}

/**
 Sudo Decentralized Identity Client - provides all functionality for decentralized identity-related operations
 */
public protocol SudoDecentralizedIdentityClient {
    
    /**
     Setup wallet. Given a wallet ID, will create the wallet locally.
     Idempotent. If a wallet already exists for an ID, then it just returns
     successful.
     
     - Parameter: Wallet ID
     - Parameter: Completion handler
     */
    func setupWallet(walletId: String, completion: @escaping ClientCallback<Bool>)
    
    /**
     List all local wallets
     
     - Parameter: Completion handler that handles a result of a list of wallet IDs
     */
    func listWallets(completion: @escaping ClientCallback<[String]>)
    
    /**
     Create DID in specific wallet
     
     - Parameter: Wallet ID
     - Parameter: Label for DID
     - Parameter: Ledger to write to (only supports .buildernet and .stagingnet)
     - Parameter: Completion handler that handles a DID or `SudoDecentralizedIdentityClientError`
     */
    func createDid(walletId: String, label: String, ledger: Ledger?, completion: @escaping ClientCallback<Did>)
    
    /**
     Get verkey for a DID
     
     - Parameter: Wallet ID
     - Parameter: DID
     - Parameter: Completion handler that handles the key or `SudoDecentralizedIdentityClientError`
     */
    func keyForDid(walletId: String, did: String, completion: @escaping ClientCallback<String>)
    
    /**
     List DIDs in a specific wallet
     
     - Parameter: Wallet ID
     - Parameter: Completion handler that handles a list of DIDs or `SudoDecentralizedIdentityClientError`
     */
    func listDids(walletId: String, completion: @escaping ClientCallback<[Did]>)
    
    /**
     Create a pairwise
     
     - Parameter: Wallet ID
     - Parameter: Their DID
     - Parameter: Their verkey
     - Parameter: Label
     - Parameter: My DID
     - Parameter: Service endpoint
     - Parameter: Completion handler that handles a boolean result or `SudoDecentralizedIdentityClientError`
     */
    func createPairwise(walletId: String, theirDid: String, theirVerkey: String, label: String, myDid: String, completion: @escaping ClientCallback<Bool>)
    
    /**
     List all pairwise in a wallet
     
     - Parameter: Wallet ID
     - Parameter: Completion handler that handles a list of pairwise or `SudoDecentralizedIdentityClientError`
     */
    func listPairwise(walletId: String, completion: @escaping ClientCallback<[Pairwise]>)

    /// Packs an encrypted envelope in either authcrypt or anoncrypt mode depending on `senderVerkey`.
    ///
    /// To use a DID, see `packMessage(walletId:message:recipientVerkeys:senderDid:completion)`.
    ///
    /// - Parameter walletId: Wallet ID.
    /// - Parameter message: Message data to encrypt.
    /// - Parameter recipientVerkeys: List of recipient verkeys to encrypt with.
    /// - Parameter senderVerkey: Sender to reveal to recipients. If nil, encrypts in authcrypt mode.
    /// - Parameter completion: Completion handler.
    func packMessage(walletId: String, message: Data, recipientVerkeys: [String], senderVerkey: String?, completion: @escaping ClientCallback<Data>)

    /// Unpacks an encrypted envelope in either authcrypt or anoncrypt mode.
    ///
    /// - Parameter walletId: Wallet ID.
    /// - Parameter message: Message data to decrypt.
    /// - Parameter completion: Completion handler.
    func unpackMessage(walletId: String, message: Data, completion: @escaping ClientCallback<UnpackedMessage>)

    /**
     Generate an invitation as part of the exchange process
     
     - Parameter: Wallet ID
     - Parameter: My DID
     - Parameter: Service endpoint
     - Parameter: Completion handler that handles an Invitation or `SudoDecentralizedIdentityClientError`
     */
    func invitation(walletId: String, myDid: String, serviceEndpoint: String, label: String, completion: @escaping ClientCallback<Invitation>)
    
    /**
     Generate an exchange request as part of the exchange process
     
     - Parameter: DID to use
     - Parameter: Service endpoint
     - Parameter: Label
     - Parameter: Invitation
     */
    func exchangeRequest(did: Did, serviceEndpoint: String, label: String, invitation: Invitation) -> ExchangeRequest
    
    /**
     Generate an exchange response as part of the exchange process
     
     - Parameter: DID to use
     - Parameter: Service endpoint
     - Parameter: Label
     - Parameter: ExchangeRequest
     */
    func exchangeResponse(did: Did, serviceEndpoint: String, label: String, exchangeRequest: ExchangeRequest) -> ExchangeResponse

    /// Signs an exchange response.
    ///
    /// - Parameter walletId: Wallet containing the DID present in the exchange response.
    /// - Parameter exchangeResponse: `ExchangeResponse` to sign.
    /// - Parameter completion: Completion handler.
    func signExchangeResponse(walletId: String, exchangeResponse: ExchangeResponse, completion: @escaping ClientCallback<SignedExchangeResponse>)

    /// Verifies the signature present on the signed exchange response.
    /// Returns the exchange response with the signed data and timestamp decoded if the signature is valid, or an error otherwise.
    ///
    /// - Parameter exchangeResponse: Signed exchange response to verify.
    /// - Parameter completion: Completion handler.
    func verifySignedExchangeResponse(_ exchangeResponse: SignedExchangeResponse, completion: @escaping ClientCallback<(ExchangeResponse, Date)>)
    
    /**
     Generate an acknowledgement as part of the exchange process
     
     - Parameter: DID to use
     - Parameter: Service endpoint
     - Parameter: ExchangeResponse
     */
    func acknowledgement(did: Did, serviceEndpoint: String, exchangeResponse: ExchangeResponse) -> Acknowledgement
    
}

/**
 Implementation of SudoDecentralizedIdentityClient protocol
 */
public class DefaultSudoDecentralizedIdentityClient: SudoDecentralizedIdentityClient {
    
    /// Wallet service
    private let walletService: WalletService
    
    /// DID service
    private let didService: DidService
    
    /// Pairwise service
    private let pairwiseService: PairwiseService
    
    /// Crypto service
    private let cryptoService: CryptoService
    
    /// Exchange service
    private let exchangeService: ExchangeService
    
    /// Wallet cache
    private let walletCache: WalletCache
    
    private let logger: Logger


    public init() {
        let indyWallet = IndyWallet.sharedInstance()! // TODO?
        self.walletService = WalletServiceImpl(indyWallet: indyWallet)
        self.didService = DidServiceImpl()
        self.pairwiseService = PairwiseServiceImpl()
        self.walletCache = WalletCacheImpl()
        self.cryptoService = CryptoServiceImpl()
        self.exchangeService = ExchangeServiceImpl()
        self.logger = LoggerImpl()
    }
    
    /**
     Internal intializer that allows for injection of services
     */
    internal init(walletService: WalletService = WalletServiceImpl(indyWallet: IndyWallet.sharedInstance()!),
                  didService: DidService = DidServiceImpl(),
                  pairwiseService: PairwiseService = PairwiseServiceImpl(),
                  cryptoService: CryptoService = CryptoServiceImpl(),
                  exchangeService: ExchangeService = ExchangeServiceImpl(),
                  walletCache: WalletCache = WalletCacheImpl(),
                  logger: Logger = LoggerImpl()) {
        self.walletService = walletService
        self.didService = didService
        self.pairwiseService = pairwiseService
        self.cryptoService = cryptoService
        self.exchangeService = exchangeService
        self.walletCache = walletCache
        self.logger = logger
    }
    
    /// Protocol imlementation (see SudoDecentralizedIdentityClient protocol documentation)
    public func setupWallet(walletId: String, completion: @escaping ClientCallback<Bool>) {
        
        // Check to see if the wallet exists, if not, create it
        self.walletService.createWallet(id: walletId) { result in
            
            switch result {
            // Continue if creation was successful
            case .success:
                
                // Open wallet
                self.walletService.openWallet(id: walletId) { result in
                    switch result {
                    // Continue if wallet was successfully opened
                    case .success(let wallet):
                        self.walletCache.store(wallet: wallet)
                        completion(.success(true))
                    case .failure(let error):
                        completion(.failure(.general(error)))
                        return
                    }
                }
            case .failure(let error):
                completion(.failure(.general(error)))
                return
            }
            
        }
    }
    
    /// Protocol imlementation (see SudoDecentralizedIdentityClient protocol documentation)
    public func listWallets(completion: @escaping ClientCallback<[String]>) {
        queue(completion) {
            try await { self.walletService.listWallets(completion: $0) }
        }
    }
    
    /**
     Get a handle for a wallet
     If the wallet is already open, return handle immediately, otherwise open it.
     The wallet must have already been created.
     
     - Parameter: Wallet ID
     - Parameter: Completion handler that handles a handle or `SSIServieError`
     */
    private func handleFor(walletId: String, completion: @escaping ClientCallback<Int32>) {
        // Any open wallet will be in the cache, so check there first
        if let wallet = self.walletCache.get(walletId: walletId) {
            self.logger.log("Found cached wallet '\(wallet.id)' with handle '\(wallet.handle)'")
            completion(.success(wallet.handle))
            return
        }
        
        // Open wallet
        self.walletService.openWallet(id: walletId) { result in
            switch result {
            // Continue if wallet was successfully opened
            case .success(let wallet):
                self.walletCache.store(wallet: wallet)
                self.logger.log("Successfully opened wallet '\(wallet.id)' with handle '\(wallet.handle)'")
                completion(.success(wallet.handle))
            case .failure(let error):
                self.logger.log("Failed to open wallet '\(walletId)' with error '\(error.localizedDescription)'")
                completion(.failure(.general(error)))
                return
            }
        }
    }

    /**
     Get a wallet for a wallet id
     If the wallet is already open, return wallet immediately, otherwise open it.
     The wallet must have already been created.

     - Parameter: Wallet ID
     - Parameter: Completion handler that handles a wallet or `SSIServieError`
     */
    private func wallet(walletId: String, completion: @escaping ClientCallback<Wallet>) {
        queue(completion) {
            let walletHandle = try await { self.handleFor(walletId: walletId, completion: $0) }
            return Wallet(id: walletId, handle: walletHandle)
        }
    }

    /// Protocol imlementation (see SudoDecentralizedIdentityClient protocol documentation)
    public func createDid(walletId: String, label: String, ledger: Ledger? = nil, completion: @escaping ClientCallback<Did>) {

        queue(completion) {
            let wallet = try await { self.wallet(walletId: walletId, completion: $0) }
            let did = try await { self.didService.createAndStoreMyDid(wallet: wallet, completion: $0) }
            let didWithMetadata = Did(did: did.did,
                                      verkey: did.verkey,
                                      tempVerkey: nil,
                                      metadata: [MetadataKeys.label.rawValue: label])
            _ = try await { self.didService.updateMetadata(wallet: wallet, did: didWithMetadata, completion: $0) }
            guard let ledger = ledger else {
                return didWithMetadata
            }
            _ = try await { self.didService.writeToLedger(did: did.did, verkey: did.verkey, ledger: ledger, completion: $0) }
            return didWithMetadata
        }
    }
    
    /// Protocol imlementation (see SudoDecentralizedIdentityClient protocol documentation)
    public func keyForDid(walletId: String, did: String, completion: @escaping ClientCallback<String>) {
        // Check for wallet in cache
        queue(completion) {
            let wallet = try await { self.wallet(walletId: walletId, completion: $0) }
            return try await { self.didService.keyForDid(wallet: wallet, did: did, completion: $0) }
        }
    }
    
    /// Protocol imlementation (see SudoDecentralizedIdentityClient protocol documentation)
    public func listDids(walletId: String, completion: @escaping ClientCallback<[Did]>) {
        // Check for wallet in cache
        queue(completion) {
            let wallet = try await { self.wallet(walletId: walletId, completion: $0) }
            return try await { self.didService.listMyDids(wallet: wallet, completion: $0) }
        }
    }
    
    /// Protocol imlementation (see SudoDecentralizedIdentityClient protocol documentation)
    public func createPairwise(walletId: String, theirDid: String, theirVerkey: String, label: String, myDid: String, completion: @escaping ClientCallback<Bool>) {
        // Check for wallet in cache
        queue(completion) {
            let wallet = try await { self.wallet(walletId: walletId, completion: $0) }
            _ = try await { self.didService.storeTheirDid(wallet: wallet, did: theirDid, verkey: theirVerkey, completion: $0) }
            let metadata = [MetadataKeys.label.rawValue: label]
            return try await {
                self.pairwiseService.create(wallet: wallet,
                                            theirDid: theirDid,
                                            myDid: myDid,
                                            metadata: metadata,
                                            completion: $0)
            }
        }
    }

    /// Protocol imlementation (see SudoDecentralizedIdentityClient protocol documentation)
    public func listPairwise(walletId: String, completion: @escaping ClientCallback<[Pairwise]>) {
        // Check for wallet in cache
        queue(completion) {
            let wallet = try await { self.wallet(walletId: walletId, completion: $0) }
            return try await { self.pairwiseService.list(wallet: wallet, completion: $0) }
        }
    }

    public func packMessage(walletId: String, message: Data, recipientVerkeys: [String], senderVerkey: String?, completion: @escaping ClientCallback<Data>) {
        queue(completion) {
            let wallet = try await { self.wallet(walletId: walletId, completion: $0) }
            return try await {
                self.cryptoService.packMessage(
                    wallet: wallet,
                    message: message,
                    receiverVerkeys: recipientVerkeys,
                    senderVerkey: senderVerkey,
                    completion: $0
                )
            }
        }
    }

    public func unpackMessage(walletId: String, message: Data, completion: @escaping ClientCallback<UnpackedMessage>) {
        queue(completion) {
            let wallet = try await { self.wallet(walletId: walletId, completion: $0) }
            return try await {
                self.cryptoService.unpackMessage(
                    wallet: wallet,
                    message: message,
                    completion: $0
                )
            }
        }
    }

    /// Protocol imlementation (see SudoDecentralizedIdentityClient protocol documentation)
    public func invitation(walletId: String, myDid: String, serviceEndpoint: String, label: String, completion: @escaping ClientCallback<Invitation>) {
        // Check for wallet in cache
        queue(completion) {
            let wallet = try await { self.wallet(walletId: walletId, completion: $0) }
            let key = try await { self.didService.keyForDid(wallet: wallet, did: myDid, completion: $0) }
            let id = UUID().uuidString
            let keys = [key]
            return Invitation(id: id,
                              label: label,
                              recipientKeys: keys,
                              serviceEndpoint: serviceEndpoint,
                              routingKeys: [])
        }
    }
    
    /// Protocol imlementation (see SudoDecentralizedIdentityClient protocol documentation)
    public func exchangeRequest(did: Did, serviceEndpoint: String, label: String, invitation: Invitation) -> ExchangeRequest {
        return self.exchangeService.exchangeRequest(did: did, serviceEndpoint: serviceEndpoint, label: label, invitation: invitation)
    }

    public func exchangeResponse(did: Did, serviceEndpoint: String, label: String, exchangeRequest: ExchangeRequest) -> ExchangeResponse {
        return self.exchangeService.exchangeResponse(did: did, serviceEndpoint: serviceEndpoint, label: label, exchangeRequest: exchangeRequest)
    }

    public func signExchangeResponse(walletId: String, exchangeResponse: ExchangeResponse, completion: @escaping ClientCallback<SignedExchangeResponse>) {
        queue(completion) {
            let wallet = try await { self.wallet(walletId: walletId, completion: $0) }
            return try await { self.exchangeService.signExchangeResponse(wallet: wallet, exchangeResponse: exchangeResponse, completion: $0) }
        }
    }

    public func verifySignedExchangeResponse(_ exchangeResponse: SignedExchangeResponse, completion: @escaping ClientCallback<(ExchangeResponse, Date)>) {
        queue(completion) {
            return try await { self.exchangeService.verifySignedExchangeResponse(exchangeResponse, completion: $0) }
        }
    }
    
    /// Protocol imlementation (see SudoDecentralizedIdentityClient protocol documentation)
    public func acknowledgement(did: Did, serviceEndpoint: String, exchangeResponse: ExchangeResponse) -> Acknowledgement {
        return self.exchangeService.acknowledgement(did: did, serviceEndpoint: serviceEndpoint, exchangeResponse: exchangeResponse)
    }

    /**
     Queues a block for dispatch which can execute synchronously.
     This allows the caller to execute synchronous logic, preventing nested callback handlers.
     The errors are also mapped to the SudoDecentralizedIdentityClientError type automatically.

     - Parameter: The handler which will be called from the queue upon result or error from `execute`
     - Parameter: The synchronous closure which should return the requisite value or throw
     */
    private func queue<T>(_ handler: @escaping ClientCallback<T>, execute: @escaping () throws -> T) {
        DispatchQueue.global(qos: .default).async {
            do {
                handler(.success(try execute()))
            } catch let error as SudoDecentralizedIdentityClientError {
                handler(.failure(error))
            } catch let error {
                handler(.failure(.general(error)))
            }
        }
    }
}
