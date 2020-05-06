//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Security

protocol KeyStore {
    func set(key: String, value: String) throws
    func get(key: String) throws -> String?
}

enum KeyStoreError: Error {
    case invalidValueString
}

extension KeyStoreError {
    var localizedDescription: String {
        switch self {
        case .invalidValueString: return "Unable to convert value string to Data"
        }
    }
}

class KeyStoreImpl: KeyStore {

    func set(key: String, value: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeyStoreError.invalidValueString
        }
        let status = self.set(key: key, data: data)
        if status != noErr {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(status), userInfo: nil)
        }
    }

    func get(key: String) throws -> String? {
        try load(key: key).flatMap { String(data: $0, encoding: .utf8) }
    }

    private func set(key: String, data: Data) -> OSStatus {
        let query = [
            kSecClass as String       : kSecClassGenericPassword as String,
            kSecAttrAccount as String : key,
            kSecValueData as String   : data ] as [String : Any]

        SecItemDelete(query as CFDictionary)

        return SecItemAdd(query as CFDictionary, nil)
    }

    private func load(key: String) throws -> Data? {
        let query = [
            kSecClass as String       : kSecClassGenericPassword,
            kSecAttrAccount as String : key,
            kSecReturnData as String  : kCFBooleanTrue!,
            kSecMatchLimit as String  : kSecMatchLimitOne ] as [String : Any]

        var dataTypeRef: AnyObject? = nil

        let status: OSStatus = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        if status == noErr {
            return dataTypeRef as! Data?
        }
        else if status == errSecItemNotFound {
            return nil
        }
        else {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(status), userInfo: nil)
        }
    }
}
