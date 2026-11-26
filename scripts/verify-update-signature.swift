import CryptoKit
import Foundation

// Public inputs only. Never read or export a private update key.
guard CommandLine.arguments.count == 4,
      let signature = Data(base64Encoded: CommandLine.arguments[2]),
      let publicKey = Data(base64Encoded: CommandLine.arguments[3]) else {
    fatalError("Usage: verify-update-signature.swift FILE BASE64_SIGNATURE BASE64_PUBLIC_KEY")
}
let key = try Curve25519.Signing.PublicKey(rawRepresentation: publicKey)
let payload = try Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1]))
guard key.isValidSignature(signature, for: payload) else {
    fatalError("Sparkle signature does not match PulseCanvas's pinned public key")
}
print("Sparkle Ed25519 signature matches PulseCanvas's pinned public key")
