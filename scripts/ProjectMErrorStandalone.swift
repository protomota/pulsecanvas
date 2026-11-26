import Foundation

/// For engine-only test builds that compile ProjectMEngine.swift without ProjectMPresets.swift,
/// where the app defines this error. Keep it identical to that definition.
struct ProjectMError: LocalizedError {
    let message: String
    init(_ message: String) {self.message = message}
    var errorDescription: String? {message}
}
