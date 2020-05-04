//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import SudoDecentralizedIdentity
import Indy

class SudoDecentralizedIdentityClientTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func test_setupWallet_succeeds() {
        let walletId = UUID().uuidString
        let decentralizedClient = DefaultSudoDecentralizedIdentityClient()

        let expectation = XCTestExpectation(description: "Setup wallet")

        decentralizedClient.setupWallet(walletId: walletId) { result in // }, completion: <#T##(Result<Bool, SudoDecentralizedIdentityClientError>) -> Void#>)
            switch result {
            case .success:
                XCTAssert(true)
            case .failure(let error):
                XCTAssertNil(error)
            }
            expectation.fulfill()

        }

        wait(for: [expectation], timeout: 10.0)
    }
    
    func test_listWallets_succeeds() {
        let walletId = UUID().uuidString
        let decentralizedClient = DefaultSudoDecentralizedIdentityClient()

        let setupExpectation = XCTestExpectation(description: "Setup wallet")
        let listExpectation = XCTestExpectation(description: "List wallets")
        
        decentralizedClient.setupWallet(walletId: walletId) { result in // }, completion:    )
            switch result {
            case .success:
                XCTAssert(true)
                decentralizedClient.listWallets() { result in // }(completion: <#T##(Result<[String], SudoDecentralizedIdentityClientError>) -> Void#>)
                    switch result {
                    case .success(let wallets):
                        XCTAssert(wallets.count >= 1)
                        XCTAssert(wallets.contains(walletId))
                    case .failure(let error):
                        XCTAssertNil(error)
                    }
                    listExpectation.fulfill()
                }
 
            case .failure(let error):
                XCTAssertNil(error)
            }
            setupExpectation.fulfill()

        }

        wait(for: [setupExpectation, listExpectation], timeout: 10.0)
    }

    func test_setupWalletTwice_succeeds() {
        let walletId = UUID().uuidString
        let decentralizedClient = DefaultSudoDecentralizedIdentityClient()

        let expectationSetup1 = XCTestExpectation(description: "Setup wallet #1")
        let expectationSetup2 = XCTestExpectation(description: "Setup wallet #2")

        decentralizedClient.setupWallet(walletId: walletId) { result in // }, completion: <#T##(Result<Bool, SudoDecentralizedIdentityClientError>) -> Void#>)
            switch result {
            case .success:
                XCTAssert(true)
                expectationSetup1.fulfill()
                // Try to setup a second time
                decentralizedClient.setupWallet(walletId: walletId) { result in // }, completion: <#T##(Result<Bool, SudoDecentralizedIdentityClientError>) -> Void#>)
                    switch result {
                    case .success:
                        XCTAssert(true)
                    case .failure(let error):
                        XCTAssertNil(error)
                    }
                    expectationSetup2.fulfill()

                }
            case .failure(let error):
                XCTAssertNil(error)
            }

        }

        wait(for: [expectationSetup1, expectationSetup2], timeout: 10.0)
    }

    func test_setupWalletTwoDifferent_succeeds() {
        let walletId1 = UUID().uuidString
        let walletId2 = UUID().uuidString
        let decentralizedClient = DefaultSudoDecentralizedIdentityClient()

        let expectationSetup1 = XCTestExpectation(description: "Setup wallet #1")
        let expectationSetup2 = XCTestExpectation(description: "Setup wallet #2")

        decentralizedClient.setupWallet(walletId: walletId1) { result in // }, completion: <#T##(Result<Bool, SudoDecentralizedIdentityClientError>) -> Void#>)
            switch result {
            case .success:
                XCTAssert(true)
                expectationSetup1.fulfill()
                // Try to setup a second time
                decentralizedClient.setupWallet(walletId: walletId2) { result in // }, completion: <#T##(Result<Bool, SudoDecentralizedIdentityClientError>) -> Void#>)
                    switch result {
                    case .success:
                        XCTAssert(true)
                    case .failure(let error):
                        XCTAssertNil(error)
                    }
                    expectationSetup2.fulfill()

                }
            case .failure(let error):
                XCTAssertNil(error)
            }

        }

        wait(for: [expectationSetup1, expectationSetup2], timeout: 10.0)
    }
    
    func test_createDidNoLedger_succeeds() {
        let walletId = UUID().uuidString
        let label = "some label"
        let decentralizedClient = DefaultSudoDecentralizedIdentityClient()

        let expectationSetup = XCTestExpectation(description: "Setup wallet")
        let expectationCreateDid = XCTestExpectation(description: "Create DID")

        decentralizedClient.setupWallet(walletId: walletId) { result in
            switch result {
            case .success:
                XCTAssert(true)
                expectationSetup.fulfill()

                decentralizedClient.createDid(walletId: walletId, label: label, ledger: nil) { result in
                    switch result {
                    case .success(let did):
                        XCTAssertNotNil(did)
                    case .failure(let error):
                        XCTAssertNil(error)
                    }
                    expectationCreateDid.fulfill()

                }
            case .failure(let error):
                XCTAssertNil(error)
            }

        }

        wait(for: [expectationSetup, expectationCreateDid], timeout: 30.0)
    }

//    func test_createDidBuilderNet_succeeds() {
//        let walletId = UUID().uuidString
//        let label = "some label"
//        let decentralizedClient = DefaultSudoDecentralizedIdentityClient()
//
//        let expectationSetup = XCTestExpectation(description: "Setup wallet")
//        let expectationCreateDid = XCTestExpectation(description: "Create DID")
//
//        decentralizedClient.setupWallet(walletId: walletId) { result in
//            switch result {
//            case .success:
//                XCTAssert(true)
//                expectationSetup.fulfill()
//
//                decentralizedClient.createDid(walletId: walletId, label: label, ledger: .buildernet) { result in
//                    switch result {
//                    case .success(let did):
//                        XCTAssertNotNil(did)
//                    case .failure(let error):
//                        XCTAssertNil(error)
//                    }
//                    expectationCreateDid.fulfill()
//
//                }
//            case .failure(let error):
//                XCTAssertNil(error)
//            }
//
//        }
//
//        wait(for: [expectationSetup, expectationCreateDid], timeout: 30.0)
//    }

    func test_createDidThenList_succeeds() {
        let walletId = UUID().uuidString
        let label = "some label"
        let decentralizedClient = DefaultSudoDecentralizedIdentityClient()

        let expectationSetup = XCTestExpectation(description: "Setup wallet")
        let expectationCreateDid = XCTestExpectation(description: "Create DID")
        let expectationListDids = XCTestExpectation(description: "List DIDs")

        decentralizedClient.setupWallet(walletId: walletId) { result in // }, completion: <#T##(Result<Bool, SudoDecentralizedIdentityClientError>) -> Void#>)
            switch result {
            case .success:
                XCTAssert(true)
                decentralizedClient.createDid(walletId: walletId, label: label) { result in // }, completion: <#T##(Result<Did, SudoDecentralizedIdentityClientError>) -> Void#>)
                    switch result {
                    case .success(let did):
                        XCTAssertNotNil(did)
                        decentralizedClient.listDids(walletId: walletId) { result in // }, completion: <#T##(Result<[Did], SudoDecentralizedIdentityClientError>) -> Void#>)
                            switch result {
                            case .success(let dids):
                                XCTAssertEqual(dids.count, 1)
                            case .failure(let error):
                                XCTAssertNotNil(error)
                            }
                            expectationListDids.fulfill()
                        }
                    case .failure(let error):
                        XCTAssertNil(error)
                    }
                    expectationCreateDid.fulfill()

                }
            case .failure(let error):
                XCTAssertNil(error)
            }
            expectationSetup.fulfill()
        }

        wait(for: [expectationSetup, expectationCreateDid, expectationListDids], timeout: 15.0)
    }

    func test_createTwoDidsThenList_succeeds() {
        let walletId = UUID().uuidString
        let label = "some label"
        let decentralizedClient = DefaultSudoDecentralizedIdentityClient()

        let expectationSetup = XCTestExpectation(description: "Setup wallet")
        let expectationCreateDid1 = XCTestExpectation(description: "Create DID #1")
        let expectationCreateDid2 = XCTestExpectation(description: "Create DID #2")
        let expectationListDids = XCTestExpectation(description: "List DIDs")

        decentralizedClient.setupWallet(walletId: walletId) { result in // }, completion: <#T##(Result<Bool, SudoDecentralizedIdentityClientError>) -> Void#>)
            switch result {
            case .success:
                XCTAssert(true)
                decentralizedClient.createDid(walletId: walletId, label: label) { result in // }, completion: <#T##(Result<Did, SudoDecentralizedIdentityClientError>) -> Void#>)
                    switch result {
                    case .success(let did):
                        XCTAssertNotNil(did)
                        decentralizedClient.createDid(walletId: walletId, label: label) { result in // }, completion: <#T##(Result<Did, SudoDecentralizedIdentityClientError>) -> Void#>)
                            switch result {
                            case .success(let did):
                                XCTAssertNotNil(did)
                                decentralizedClient.listDids(walletId: walletId) { result in // }, completion: <#T##(Result<[Did], SudoDecentralizedIdentityClientError>) -> Void#>)
                                    switch result {
                                    case .success(let dids):
                                        XCTAssertEqual(dids.count, 2)
                                    case .failure(let error):
                                        XCTAssertNotNil(error)
                                    }
                                    expectationListDids.fulfill()
                                }
                            case .failure(let error):
                                XCTAssertNotNil(error)
                            }
                            expectationCreateDid2.fulfill()
                        }

                    case .failure(let error):
                        XCTAssertNil(error)
                    }
                    expectationCreateDid1.fulfill()

                }
            case .failure(let error):
                XCTAssertNil(error)
            }
            expectationSetup.fulfill()
        }

        wait(for: [expectationSetup, expectationCreateDid1, expectationCreateDid2, expectationListDids], timeout: 20.0)
    }
    
    func test_createPairwise_succeeds() {
        let walletId = UUID().uuidString
        let theirDid = "Hpqu5nR1VBG46aJjgB8wvD"
        let theirVerkey = "AAsKk7JMJpZWd8RVhG4DyGR3qEkGr57xpsS8HPmr8SLp"
        let label = "some label"
        let decentralizedClient = DefaultSudoDecentralizedIdentityClient()

        let expectationSetup = XCTestExpectation(description: "Setup wallet")
        let expectationCreateDid = XCTestExpectation(description: "Create DID")
        let expectationCreatePairwise = XCTestExpectation(description: "Create Pairwise")
        let expectationListPairwise = XCTestExpectation(description: "List Pairwise")

        decentralizedClient.setupWallet(walletId: walletId) { result in // }, completion: <#T##(Result<Bool, SudoDecentralizedIdentityClientError>) -> Void#>)
            switch result {
            case .success:
                XCTAssert(true)
                expectationSetup.fulfill()

                decentralizedClient.createDid(walletId: walletId, label: label) { result in // }, completion: <#T##(Result<Did, SudoDecentralizedIdentityClientError>) -> Void#>)
                    switch result {
                    case .success(let did):
                        XCTAssertNotNil(did)
                        XCTAssertEqual(did.metadataForKey(MetadataKeys.label), label)
                        decentralizedClient.createPairwise(walletId: walletId, theirDid: theirDid,
                                                           theirVerkey: theirVerkey, label: "test", myDid: did.did, serviceEndpoint: "SE") { result in // }, completion:  )
                            switch result {
                            case .success:
                                XCTAssert(true)
                                decentralizedClient.listPairwise(walletId: walletId) { result in // }, completion: <#T##(Result<[Pairwise], SudoDecentralizedIdentityClientError>) -> Void#>)
                                    switch result {
                                    case .success(let pairwises):
                                        print(pairwises)
                                        XCTAssertNotNil(pairwises)
                                        XCTAssertEqual(pairwises.count, 1)
                                        XCTAssertEqual(pairwises.first?.metadataForKey(.label), "test")
                                        XCTAssertEqual(pairwises.first?.metadataForKey(.serviceEndpoint), "SE")
                                    case .failure(let error):
                                        XCTAssertNil(error)
                                    }
                                    expectationListPairwise.fulfill()
                                }
                            case .failure(let error):
                                XCTAssertNil(error)
                            }
                            expectationCreatePairwise.fulfill()
                        }
                    case .failure(let error):
                        XCTAssertNil(error)
                    }
                    expectationCreateDid.fulfill()

                }
            case .failure(let error):
                XCTAssertNil(error)
            }

        }

        wait(for: [expectationSetup, expectationCreateDid, expectationCreatePairwise, expectationListPairwise], timeout: 10.0)
    }
    
    // Create pairwise DIDs using the exchange protocol
    // In this test, Alice = Inviter, Bob = Invitee
    func test_createPairwiseUsingExchangeProtocol_succeeds() {
        let aliceWalletId = UUID().uuidString
        let aliceLabel = "Alice"
        let aliceInvitationServiceEndpoint = "https://alice.com/decentralized-invite"
        let aliceServiceEndpoint = "https://alice.com/decentralized"
        let bobWalletId = UUID().uuidString
        let bobLabel = "Bob"
        let bobServiceEndpoint = "https://bob.com/decentralized"
        
        let exp = expectation(description: "test_createPairwiseEncryptAndDecryptMessage_succeeds")
        DispatchQueue.global(qos: .background).async {
            defer { exp.fulfill() }
            do {
                let aliceClient = DefaultSudoDecentralizedIdentityClient()
                let bobClient = DefaultSudoDecentralizedIdentityClient()
                
                // Setup Alice's wallet with a DID
                _ = try await { aliceClient.setupWallet(walletId: aliceWalletId, completion: $0) }
                let aliceDid = try await { aliceClient.createDid(walletId: aliceWalletId, label: aliceLabel, completion: $0) }
                XCTAssertNotNil(aliceDid)
                
                // Setup Bob's wallet with a DID
                _ = try await { bobClient.setupWallet(walletId: bobWalletId, completion: $0) }
                let bobDid = try await { bobClient.createDid(walletId: bobWalletId, label: bobLabel, completion: $0) }
                XCTAssertNotNil(bobDid)
                
                // Invitation
                
                // Create invitation for alice
                let aliceInvitation = try await { aliceClient.invitation(walletId: aliceWalletId, myDid: aliceDid.did, serviceEndpoint: aliceInvitationServiceEndpoint, label: aliceLabel, completion: $0) }
                XCTAssertEqual(aliceInvitation.label, aliceLabel)
                XCTAssertEqual(aliceInvitation.serviceEndpoint, aliceInvitationServiceEndpoint)
                
                // Exchange Request
                
                // Create an exchange request from Bob
                let bobInvitationReceived = aliceInvitation
                let bobExchangeRequest = bobClient.exchangeRequest(did: bobDid, serviceEndpoint: bobServiceEndpoint, label: bobLabel, invitation: aliceInvitation)
                let bobEncodedExchangeRequest = try JSONEncoder().encode(bobExchangeRequest)
                XCTAssertEqual(bobInvitationReceived.recipientKeys.first!, aliceInvitation.recipientKeys.first!)
                let bobEncryptedExchangeRequest = try await { bobClient.encryptMessage(walletId: bobWalletId, verkey: bobInvitationReceived.recipientKeys.first!, message: bobEncodedExchangeRequest, completion: $0) }
                
                // Exchange Response
                
                // Alice receives the exchange request
                let aliceEncryptedExchangeRequestReceived = bobEncryptedExchangeRequest
                let aliceDecryptedExchangeRequest = try await { aliceClient.decryptMessage(walletId: aliceWalletId, verkey: aliceInvitation.recipientKeys.first!, message: aliceEncryptedExchangeRequestReceived, completion: $0) }
                let aliceExchangeRequestReceived = try JSONDecoder().decode(ExchangeRequest.self, from: aliceDecryptedExchangeRequest)
                XCTAssertEqual(aliceExchangeRequestReceived.id, bobExchangeRequest.id)
                
                // Alice generates pairwise
                _ = try await { aliceClient.createPairwise(walletId: aliceWalletId, theirDid: bobDid.did, theirVerkey: bobDid.verkey, label: aliceExchangeRequestReceived.label, myDid: aliceDid.did, serviceEndpoint: aliceExchangeRequestReceived.connection.didDoc.serviceEndpoint, completion: $0) }
                
                // Alice sends exchange response
                let aliceExchangeResponse = aliceClient.exchangeResponse(did: aliceDid, serviceEndpoint: aliceServiceEndpoint, label: aliceLabel, exchangeRequest: aliceExchangeRequestReceived)
                let aliceEncodedExchangeResponse = try JSONEncoder().encode(aliceExchangeResponse)
                let aliceEncryptedExchangeResponse = try await { aliceClient.encryptMessage(walletId: aliceWalletId, verkey: aliceExchangeRequestReceived.connection.didDoc.verKey, message: aliceEncodedExchangeResponse, completion: $0)}
                
                // Acknowledgement
                
                // Bob receives exchange response
                let bobEncryptedExchangeResponseReceived = aliceEncryptedExchangeResponse
                let bobDecryptedExchangeResponse = try await { bobClient.decryptMessage(walletId: bobWalletId, verkey: bobExchangeRequest.connection.didDoc.verKey, message: bobEncryptedExchangeResponseReceived, completion: $0)}
                let bobExchangeResponseReceived = try JSONDecoder().decode(ExchangeResponse.self, from: bobDecryptedExchangeResponse)
                XCTAssertEqual(bobExchangeResponseReceived.id, aliceExchangeResponse.id)
                
                // Bob generates pairwise
                _ = try await { bobClient.createPairwise(walletId: bobWalletId, theirDid: aliceDid.did, theirVerkey: aliceDid.verkey, label: bobInvitationReceived.label, myDid: bobDid.did, serviceEndpoint: bobExchangeResponseReceived.connection.didDoc.serviceEndpoint, completion: $0) }
                
                // Bob sends acknowledgement
                let bobAcknowledgement = bobClient.acknowledgement(did: bobDid, serviceEndpoint: bobServiceEndpoint, exchangeResponse: bobExchangeResponseReceived)
                let bobEncodedAcknowledgement = try JSONEncoder().encode(bobAcknowledgement)
                let bobEncryptedAcknowledgement = try await { bobClient.encryptMessage(walletId: bobWalletId, verkey: bobExchangeResponseReceived.connection.didDoc.verKey, message: bobEncodedAcknowledgement, completion: $0)}
                
                // Alice receives acknowledgement
                let aliceEncryptedAcknowledgementReceived = bobEncryptedAcknowledgement
                let aliceDecryptedAcknowledgement = try await { aliceClient.decryptMessage(walletId: aliceWalletId, verkey: aliceExchangeResponse.connection.didDoc.verKey, message: aliceEncryptedAcknowledgementReceived, completion: $0)}
                let aliceAcknowledgementReceived = try JSONDecoder().decode(Acknowledgement.self, from: aliceDecryptedAcknowledgement)
                XCTAssertEqual(aliceAcknowledgementReceived.connection.did, bobAcknowledgement.connection.did)
                
                
            } catch {
                XCTFail(error.localizedDescription)
            }
        }
        
        wait(for: [exp], timeout: 20)
        
    }

    func test_encryptAndDecryptMessage_succeeds() {
        let walletIdSender = UUID().uuidString
        let walletIdReceiver = UUID().uuidString

        let exp = expectation(description: "test_createPairwiseEncryptAndDecryptMessage_succeeds")

        DispatchQueue.global(qos: .background).async {
            defer { exp.fulfill() }
            do {
                let decentralizedClient = DefaultSudoDecentralizedIdentityClient()

                _ = try await { decentralizedClient.setupWallet(walletId: walletIdSender, completion: $0) }
                _ = try await { decentralizedClient.setupWallet(walletId: walletIdReceiver, completion: $0) }
                let senderDid = try await {
                    decentralizedClient.createDid(walletId: walletIdSender, label: "Sender", completion: $0)
                }
                let receiverDid = try await {
                    decentralizedClient.createDid(walletId: walletIdReceiver, label: "Receiever", completion: $0)
                }
                _ = try await {
                    decentralizedClient.createPairwise(
                        walletId: walletIdSender,
                        theirDid: receiverDid.did,
                        theirVerkey: receiverDid.verkey,
                        label: "Receiver",
                        myDid: senderDid.did,
                        serviceEndpoint: "SP",
                        completion: $0)
                }
                _ = try await {
                    decentralizedClient.createPairwise(
                        walletId: walletIdReceiver,
                        theirDid: senderDid.did,
                        theirVerkey: senderDid.verkey,
                        label: "Sender",
                        myDid: receiverDid.did,
                        serviceEndpoint: "SP",
                        completion: $0)
                }
                let messageIn = "Test".data(using: .utf16)!
                let encryptedData = try await {
                    decentralizedClient.encryptMessage(
                        walletId: walletIdSender,
                        verkey: receiverDid.verkey,
                        message: messageIn,
                        completion: $0)
                }
                let messageOut = try await {
                    decentralizedClient.decryptMessage(
                        walletId: walletIdReceiver,
                        verkey: receiverDid.verkey,
                        message: encryptedData,
                        completion: $0)
                }
                let out = String(data: messageOut, encoding: .utf16)!
                XCTAssertNotNil(messageOut)
            }
            catch {
                XCTFail(error.localizedDescription)
            }
        }

        waitForExpectations(timeout: 20)
    }
    
    func test_encryptAndDecryptPairwiseMessage_succeeds() {
        let walletIdSender = UUID().uuidString
        let walletIdReceiver = UUID().uuidString
        
        let exp = expectation(description: "test_createPairwiseEncryptAndDecryptMessage_succeeds")

        DispatchQueue.global(qos: .background).async {
            defer { exp.fulfill() }
            do {
                let decentralizedClient = DefaultSudoDecentralizedIdentityClient()

                _ = try await { decentralizedClient.setupWallet(walletId: walletIdSender, completion: $0) }
                _ = try await { decentralizedClient.setupWallet(walletId: walletIdReceiver, completion: $0) }
                let senderDid = try await {
                    decentralizedClient.createDid(walletId: walletIdSender, label: "Sender", completion: $0)
                }
                let receiverDid = try await {
                    decentralizedClient.createDid(walletId: walletIdReceiver, label: "Receiever", completion: $0)
                }
                _ = try await {
                    decentralizedClient.createPairwise(
                        walletId: walletIdSender,
                        theirDid: receiverDid.did,
                        theirVerkey: receiverDid.verkey,
                        label: "Receiver",
                        myDid: senderDid.did,
                        serviceEndpoint: "SP",
                        completion: $0)
                }
                _ = try await {
                    decentralizedClient.createPairwise(
                        walletId: walletIdReceiver,
                        theirDid: senderDid.did,
                        theirVerkey: senderDid.verkey,
                        label: "Sender",
                        myDid: receiverDid.did,
                        serviceEndpoint: "SP",
                        completion: $0)
                }
                let messageIn = "Test"
                let encryptedData = try await {
                    decentralizedClient.encryptPairwiseMessage(
                        walletId: walletIdSender,
                        theirDid: receiverDid.did,
                        message: messageIn,
                        completion: $0)
                }
                let messageOut = try await {
                    decentralizedClient.decryptPairwiseMessage(
                        walletId: walletIdReceiver,
                        theirDid: receiverDid.did,
                        message: encryptedData,
                        completion: $0)
                }
                XCTAssertEqual(messageOut.message, messageIn)
            }
            catch {
                XCTFail(error.localizedDescription)
            }
        }

        waitForExpectations(timeout: 20)
    }
    
    func test_createDidThenInvite_recipientKeyNotNil() {
        let walletId = UUID().uuidString
        let label = "some label"
        let decentralizedClient = DefaultSudoDecentralizedIdentityClient()

        let expectationSetup = XCTestExpectation(description: "Setup wallet")
        let expectationCreateDid = XCTestExpectation(description: "Create DID")
        let expectationInvitation = XCTestExpectation(description: "Invitation")

        decentralizedClient.setupWallet(walletId: walletId) { result in
            switch result {
            case .success:
                XCTAssert(true)
                decentralizedClient.createDid(walletId: walletId, label: label) { result in
                    switch result {
                    case .success(let did):
                        XCTAssertNotNil(did)
                        decentralizedClient.invitation(walletId: walletId, myDid: did.did, serviceEndpoint: "test", label: "aLabel") { result in
                            switch result {
                            case .success(let invitation):
                                XCTAssertNotNil(invitation.recipientKeys.first)
                                expectationInvitation.fulfill()
                                return
                            case .failure(let error):
                                XCTAssertNil(error)
                                return
                            }
                        }
                    case .failure(let error):
                        XCTAssertNil(error)
                    }
                    expectationCreateDid.fulfill()

                }
            case .failure(let error):
                XCTAssertNil(error)
            }
            expectationSetup.fulfill()
        }

        wait(for: [expectationSetup, expectationCreateDid, expectationInvitation], timeout: 15.0)
    }
    
//    func test_createExchangeRequest_succeeds() {
//        let walletIdSender = UUID().uuidString
//        let walletIdReceiver = UUID().uuidString
//        
//        let eSetupSenderWallet = XCTestExpectation(description: "Setup sender wallet")
//        let eSetupReceiverWallet = XCTestExpectation(description: "Setup receiver wallet")
//        let eCreateSenderDid = XCTestExpectation(description: "Create sender DID")
//        let eInvitation = XCTestExpectation(description: "Create invitation")
//        let eExchangeRequest = XCTestExpectation(description: "Create exchange request")
//        
//        let expectations = [
//            eSetupSenderWallet,
//            eSetupReceiverWallet,
//            eCreateSenderDid,
//            eInvitation,
//            eExchangeRequest
//        ]
//        
//        let decentralizedClient = DefaultSudoDecentralizedIdentityClient()
//        
//        decentralizedClient.setupWallet(walletId: walletIdSender) { result in
//            switch result {
//            case .success:
//                decentralizedClient.setupWallet(walletId: walletIdReceiver) { result in
//                    switch result {
//                    case .success:
//                        decentralizedClient.createDid(walletId: walletIdSender, label: "Sender") { result in
//                            switch result {
//                            case .success(let senderDid):
//                                decentralizedClient.invitation(walletId: walletIdSender, myDid: senderDid.did, serviceEndpoint: "TODO", label: "aLabel") { result in
//                                    switch result {
//                                    case .success(let invitation):
//                                        decentralizedClient.exchangeRequest(walletId: walletIdReceiver, invitation: invitation, label: "aLabel") { result in
//                                            switch result {
//                                            case .success(let exchangeRequest):
//                                                XCTAssertNotNil(exchangeRequest)
//                                            case .failure(let error):
//                                                XCTAssertNil(error)
//                                            }
//                                            eExchangeRequest.fulfill()
//                                        }
//                                    case .failure(let error):
//                                        XCTAssertNil(error)
//                                    }
//                                    eInvitation.fulfill()
//                                }
//                            case .failure(let error):
//                                XCTAssertNil(error)
//                            }
//                            eCreateSenderDid.fulfill()
//                        }
//                        
//                    case .failure(let error):
//                        XCTAssertNil(error)
//                    }
//                    eSetupReceiverWallet.fulfill()
//                }
//            case .failure(let error):
//                XCTAssertNil(error)
//            }
//            eSetupSenderWallet.fulfill()
//        }
//        
//        wait(for: expectations, timeout: 20.0)
//    }
    
//    func test_createExchangeResponse_succeeds() {
//         let walletIdSender = UUID().uuidString
//         let walletIdReceiver = UUID().uuidString
//
//         let eSetupSenderWallet = XCTestExpectation(description: "Setup sender wallet")
//         let eSetupReceiverWallet = XCTestExpectation(description: "Setup receiver wallet")
//         let eCreateSenderDid = XCTestExpectation(description: "Create sender DID")
//         let eInvitation = XCTestExpectation(description: "Create invitation")
//         let eExchangeRequest = XCTestExpectation(description: "Create exchange request")
//        let eExchangeResponse = XCTestExpectation(description: "Create exchange response")
//
//         let expectations = [
//             eSetupSenderWallet,
//             eSetupReceiverWallet,
//             eCreateSenderDid,
//             eInvitation,
//             eExchangeRequest,
//             eExchangeResponse
//         ]
//
//         let decentralizedClient = DefaultSudoDecentralizedIdentityClient()
//
//         decentralizedClient.setupWallet(walletId: walletIdSender) { result in
//             switch result {
//             case .success:
//                 decentralizedClient.setupWallet(walletId: walletIdReceiver) { result in
//                     switch result {
//                     case .success:
//                         decentralizedClient.createDid(walletId: walletIdSender, label: "Sender") { result in
//                             switch result {
//                             case .success(let senderDid):
//                                decentralizedClient.invitation(walletId: walletIdSender, myDid: senderDid.did, serviceEndpoint: "TODO", label: "aLabel") { result in
//                                     switch result {
//                                     case .success(let invitation):
//                                        let exchangeRequest = decentralizedClient.exchangeRequest(did: senderDid, serviceEndpoint: "endpoint", label: "label", invitation: invitation)
//                                        let exchangeResponse = decentralizedClient.exchangeResponse(did: senderDid, serviceEndpoint: "endpoint", label: "label", exchangeRequest: exchangeRequest)
//                                     case .failure(let error):
//                                         XCTAssertNil(error)
//                                     }
//                                     eInvitation.fulfill()
//                                 }
//                             case .failure(let error):
//                                 XCTAssertNil(error)
//                             }
//                             eCreateSenderDid.fulfill()
//                         }
//
//                     case .failure(let error):
//                         XCTAssertNil(error)
//                     }
//                     eSetupReceiverWallet.fulfill()
//                 }
//             case .failure(let error):
//                 XCTAssertNil(error)
//             }
//             eSetupSenderWallet.fulfill()
//         }
//
//         wait(for: expectations, timeout: 20.0)
//     }
}
