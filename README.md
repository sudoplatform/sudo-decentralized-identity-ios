# Sudo Decentralized Identity iOS SDK

## Overview
The Sudo Decentralized Identity SDK is designed to provide a simple, easy-to-use interface for applications providing decentralized identity functionality.
It is built on top of the [Hyperledger Aries](https://github.com/hyperledger/indy-sdk) library.

Please see the [Sudo Platform Developer Docs](https://docs.sudoplatform.com) for an overview of the Sudo Platform.

## Version Support
| Technology             | Supported version |
| ---------------------- | ----------------- |
| iOS Deployment Target  | 11.0+             |
| Swift language version | 5.0               |
| Xcode version          | 11.0+             |

## Integration Instructions

Add this line to your [Podfile](https://docs.sudoplatform.com/guides/getting-started#ios-only-setup-cocoapods-in-a-project):

```ruby
pod 'SudoDecentralizedIdentity'
```

Install pod dependencies by running the following command in your project directory:

```sh
pod install --repo-update
```

This will update the local CocoaPods repository and install the latest version of the Decentralized Identity SDK.

## Public Interfaces

### Sudo Decentalized Identity Client

The main entrypoint to the Sudo Decentralized Identity SDK is the Sudo Decentralized Identity client. This service exposes all decentralized identity-related operations.

It consists of the following operations:

* Wallet: setup, list
* DID: create, list
* Pairwise: create, list, encrypt, decrypt
* Exchange flow: invitation, exchange request, exchange response, acknowledgement


#### Initialize the service:

```swift
let decentralizedClient = DefaultSudoDecentralizedIdentityClient()
```

#### Setup a wallet using an ID

To setup a wallet using an ID:

```swift
let walletId = "my-wallet"
decentralizedClient.setupWallet(walletId: walletId) { result in
    switch result {
    case .success:
        print("Wallet created")
    case .failure(let error):
        print("An error occurred")
    }
}
```

This method is idempotent. It can be called multiple times and only one wallet
will be created.

#### List wallets

To list all wallets:

```swift

decentralizedClient.listWallets { result in
    switch result {
    case .success(let walletIds):
        print("Wallet created")
    case .failure(let error):
        print("An error occurred")
    }
}
```

#### Create a DID

To create a DID in a wallet:

```swift
let walletId = "my-wallet"
let label = "Bob"
decentralizedClient.createDid(walletId: walletId, label: label, ledger: nil) -> Did { result in
    switch result {
    case .success(let did):
        print("Did created"
    case .failure(let error):
        print("An error occurred")
    }
}
```

If the `ledger` parameter is nil, the DID is not written to the ledger. Valid options for ledger
are `.buildernet` and `.stagingnet` corresponding to the non-production Sovrin ledgers.

#### List DIDs

List all DIDs in a specific wallet:

```swift
let walletId = "my-wallet"
decentralizedClient.listDids(walletId: walletId) { result in
	// Result<[Did], SudoDecentralizedIdentityClientError>
    switch result {
    case .success(let dids):
        print("Dids listed")
    case .failure(let error):
        print("An error occurred")
    }
}
```

#### Create pairwise DID

Create a pairwise DID:

```swift
let walletId = "my-wallet"
let myDid = "mydid"
let 
let theirDid = "theirdid"

decentralizedClient.createPairwise(
    walletId: walletId, theirDid: theirDid, theirVerkey: theirVerkey, 
    label: label, myDid: myDid) { result in

    switch result {
    case .success:
        print("Pairwise created")
    case .failure(let error):
        print("An error occurred")
    }
}
```

#### List pairwise

List pairwise DIDs:

```swift

let walletId = "my-wallet"

decentralizedClient.listPairwise(walletId: walletId) { result in

    switch result {
    case .success(let pairwises):
        print("Pairwise listed")
    case .failure(let error):
        print("An error occurred")
    }

}
```

#### Encrypt data using a verkey

```swift

let walletId = "my-wallet"
let theirVerkey = "theirVerkey"
let message: Data = "my message".data(using: .utf8)! // any Data to encrypt

decentralizedClient.encryptMessage(walletId: String, verkey: String, message: message) {

    switch result {
    case .success(let encryptedMessage):
        print("Message encrypted")
    case .failure(let error):
        print("An error occurred")
    }
}
```

#### Decrypt data using a verkey

```swift

let walletId = "my-wallet"
let myVerkey = "myVerkey"
let encryptedMessage: Data = ...

decentralizedClient.decryptMessage(walletId: String, verkey: String, message: encryptedMessage) {

    switch result {
    case .success(let decryptedMessage):
        print("Message decrypted, data: \(decryptedMessage)")
    case .failure(let error):
        print("An error occurred")
    }
}
```

#### Encrypt message using pairwise

To encrypt a message using a pairwise:

```swift
let walletId = "my-wallet"
let theirDid = "theirDid"
let message = "my message"

decentralizedClient.encryptPairwiseMessage(walletId: walletId, theirDid: theirDid, message: message) { result in

    switch result {
    case .success(let encryptedMessage):
        print("Message encrypted")
    case .failure(let error):
        print("An error occurred")
    }
}
```

#### Decrypt message using pairwise

To decrypt a message using a pairwise:

```swift
let walletId = "my-wallet"
let theirDid = "theirDid"
let encryptedMessage: Data = ...

decentralizedClient.decryptPairwiseMessage(walletId: walletId, theirDid: String, message: encryptedMessage) { result in

    switch result {
    case .success(let decryptedMessage):
        print("Message decrypted: \(decryptedMessage.message)")
    case .failure(let error):
        print("An error occurred")
    }
}
```

#### Generate invitation for pairwise exchange

To generate an invitation for a pairwise exchange:

```swift
let walletId = "my-wallet"
let myDid = "myDid"
let serviceEndpoint = "some.service.endpoint"

decentralizedClient.invitation(walletId: walletId, myDid: myDid, serviceEndpoint: serviceEndpoint) { result in

    switch result {
    case .success(let invitation):
        print("Invitation created")
    case .failure(let error):
        print("An error occurred")
    }

}
```

#### Generate an exchange request from an invitation

To generate an exchange request from an invitation:

```swift
let walletId = "my-wallet"

decentralizedClient.exchangeRequest(walletId: walletId, invitation: invitation) { result in

    switch result {
    case .success(let exchangeRequest):
        print("Exchange request created")
    case .failure(let error):
        print("An error occurred")
    }

}
```

#### Generate an exchange response from an exchange request

To generate an exchange response from an exchange request:

```swift
let walletId = "my-wallet"

decentralizedClient.exchangeResponse(walletId: walletId, exchangeRequest: exchangeRequest) { result in

    switch result {
    case .success(let exchangeResponse):
        print("Exchange response created")
    case .failure(let error):
        print("An error occurred")
    }

}
```

#### Generate an acknowledgement from an exchange response

To generate an exchange response from an exchange request:

```swift
let walletId = "my-wallet"

decentralizedClient.acknowledgement(walletId: walletId, exchangeResponse: exchangeResponse) { result in

    switch result {
    case .success(let acknowledgement):
        print("Acknowledgment created")
    case .failure(let error):
        print("An error occurred")
    }

}
```

### Public Objects

#### Did

A representation of a decentralized identitifer

```swift
public struct Did: Hashable, Codable {
    public let did: String
    public let verkey: String
    public let tempVerkey: String?
    public let metadata: [String: String]?
}
```

#### Pairwise

A representation of a pairwise

```swift
public struct Pairwise: Hashable, Codable {
    public let myDid: String
    public let theirDid: String
    public let metadata: [String: String]
}
```

#### Pairwise exchange

```swift
public struct Invitation: Codable {
    public let type = "https://didcomm.org/didexchange/1.0/invitation"
    public let id: String
    public let label: String
    public let recipientKeys: [String]
    public let serviceEndpoint: String
    public let routingKeys: [String]

}

public struct MessageThread: Codable {
    let pthid: String
}

public struct DidDoc: Codable {
    let context = "https://w3id.org/did/v1"
    let did: String
    let verKey: String

}

public struct Connection: Codable {
    let did: String
    let didDoc: DidDoc
}

public struct ExchangeRequest: Codable {
    let type = "https://didcomm.org/didexchange/1.0/request"
    let id: String
    let thread: MessageThread
    let label: String
    let connection: Connection
}

public struct ExchangeResponse: Codable {
    let type = "https://didcomm.org/didexchange/1.0/response"
    let id: String
    let thread: MessageThread
    let connection: Connection
}

public struct Acknowledgement: Codable {
    let type = "https://didcomm.org/didexchange/1.0/acknowledgement"
    let id: String
    let thread: MessageThread
    let connection: Connection
}
```

## Tests

Integration tests that exercise the functionality of the library can be found in `SudoDecentralizedIdentityIntegrationTests`.

## Questions and Support
File any issues you find on the project's GitHub repository. Be careful not to share any Personally Identifiable Information (PII) or sensitive account information (API keys, credentials, etc.) when reporting an issue.

For general inquiries related to the Sudo Platform, please contact [partners@sudoplatform.com](mailto:partners@sudoplatform.com)
