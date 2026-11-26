#if os(macOS) && DIRECT_BUILD && !STORE_BUILD
import CryptoKit
import Foundation

struct PulseMCPSeed: RandomNumberGenerator {
    private var state: UInt64
    init(_ seed: String) {
        state = SHA256.hash(data: Data(seed.utf8)).prefix(8).reduce(0) { ($0 << 8) | UInt64($1) }
    }
    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var result = state
        result = (result ^ (result >> 30)) &* 0xBF58476D1CE4E5B9
        result = (result ^ (result >> 27)) &* 0x94D049BB133111EB
        return result ^ (result >> 31)
    }
}
#endif
