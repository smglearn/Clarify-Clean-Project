//
//  StableIdentifier.swift
//  Clarify
//
//  Deterministic identifiers for bundled, offline content. Swift's
//  `Hasher` is deliberately randomized between app launches, so it must
//  not be used for IDs that are written to disk.
//

import CryptoKit
import Foundation

enum StableIdentifier {
    /// Builds the same UUID for the same ordered components on every
    /// launch and device. Version 8 marks the value as an application-
    /// defined UUID while the RFC variant bits keep it interoperable with
    /// Foundation's regular UUID encoding.
    static func uuid(_ components: String...) -> UUID {
        let input = components.joined(separator: "\u{001F}")
        var bytes = Array(SHA256.hash(data: Data(input.utf8)).prefix(16))

        bytes[6] = (bytes[6] & 0x0F) | 0x80
        bytes[8] = (bytes[8] & 0x3F) | 0x80

        let value: uuid_t = (
            bytes[0], bytes[1], bytes[2], bytes[3],
            bytes[4], bytes[5], bytes[6], bytes[7],
            bytes[8], bytes[9], bytes[10], bytes[11],
            bytes[12], bytes[13], bytes[14], bytes[15]
        )
        return UUID(uuid: value)
    }
}
