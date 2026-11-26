import CryptoKit
import Foundation

/// Immutable change files avoid two offline devices overwriting the same cloud file.
/// An explicit tombstone is required to remove an item; an incomplete download is
/// never interpreted as an empty library.
struct CloudSyncChange: Codable, Equatable, Sendable {
    enum Kind: String, Codable, Sendable { case visualFavorite, songFavorite, look, project }
    var schema = 1
    var event = UUID().uuidString
    var device: String
    var sequence: UInt64
    var kind: Kind
    var key: String
    var parent: String?
    var deleted: Bool
    var payload: Data
    var identity: String { kind.rawValue + ":" + key }
    var order: String { String(format: "%020llu", sequence) + device + event }

    func validated() throws -> Self {
        guard schema == 1, UUID(uuidString: event) != nil, UUID(uuidString: device) != nil,
              sequence > 0, sequence < UInt64.max - 1, !key.isEmpty, key.utf8.count <= 2048,
              parent.map({ UUID(uuidString: $0) != nil && $0 != event }) ?? true,
              payload.count <= 2_000_000, !deleted || payload.isEmpty else { throw CocoaError(.fileReadCorruptFile) }
        return self
    }
}

struct CloudSyncLedger: Codable, Sendable {
    var schema = 1
    var device = UUID().uuidString
    var sequence: UInt64 = 0
    var events: [String: CloudSyncChange] = [:]
    var heads: [String: String] = [:]
    var baseline: [String: Data] = [:]
    var pending: Set<String> = []

    var current: [CloudSyncChange] { heads.values.compactMap { events[$0] } }
    static func digest(_ data: Data) -> String { SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined() }
    static func encoded<T: Encodable>(_ value: T) throws -> Data {
        let encoder = JSONEncoder(); encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(value)
    }
    static func read(_ data: Data) throws -> Self {
        guard data.count < 100_000_000 else { throw CocoaError(.fileReadCorruptFile) }
        let ledger = try JSONDecoder().decode(Self.self, from: data)
        guard ledger.schema == 1, UUID(uuidString: ledger.device) != nil,
              ledger.events.allSatisfy({ $0.key == $0.value.event && (try? $0.value.validated()) != nil }),
              ledger.heads.allSatisfy({ ledger.events[$0.value]?.identity == $0.key }),
              ledger.pending.isSubset(of: Set(ledger.events.keys)) else { throw CocoaError(.fileReadCorruptFile) }
        return ledger
    }

    @discardableResult
    mutating func edit(_ kind: CloudSyncChange.Kind, key: String, payload: Data?) throws -> CloudSyncChange? {
        let identity = kind.rawValue + ":" + key
        let previous = heads[identity].flatMap { events[$0] }
        if let previous, previous.deleted == (payload == nil), previous.payload == (payload ?? Data()) { return nil }
        guard sequence < UInt64.max - 2 else { throw CocoaError(.fileWriteUnknown) }
        sequence += 1
        let change = try CloudSyncChange(device: device, sequence: sequence, kind: kind, key: key,
            parent: previous?.event, deleted: payload == nil, payload: payload ?? Data()).validated()
        events[change.event] = change; heads[identity] = change.event; pending.insert(change.event)
        return change
    }

    /// A saved file is based on the revision last opened on this device, which
    /// can differ from a newer cloud head discovered while it was being edited.
    mutating func editProject(key: String, payload: Data, basedOn parent: String?) throws -> CloudSyncChange? {
        let identity = CloudSyncChange.Kind.project.rawValue + ":" + key
        if let head = heads[identity].flatMap({ events[$0] }), !head.deleted, head.payload == payload { return nil }
        guard sequence < UInt64.max - 2 else { throw CocoaError(.fileWriteUnknown) }
        let change = try CloudSyncChange(device: device, sequence: sequence + 1, kind: .project,
            key: key, parent: parent, deleted: false, payload: payload).validated()
        try merge([change])
        pending.insert(change.event)
        return change
    }

    /// Only identities present in the previous *local* snapshot can be removed.
    /// Scope excludes designs unavailable in this edition, so a Metal device can't
    /// delete a Creators-only favorite from another device.
    mutating func observe(_ snapshot: [String: Data], scope: Set<String>) throws {
        for identity in snapshot.keys.sorted() {
            guard let pair = Self.split(identity), let payload = snapshot[identity] else { continue }
            if baseline[identity] != payload { _ = try edit(pair.0, key: pair.1, payload: payload) }
        }
        for identity in baseline.keys.sorted() where snapshot[identity] == nil && scope.contains(identity) {
            if let pair = Self.split(identity) { _ = try edit(pair.0, key: pair.1, payload: nil) }
        }
        baseline = snapshot
    }
    static func split(_ identity: String) -> (CloudSyncChange.Kind, String)? {
        guard let separator = identity.firstIndex(of: ":"), let kind = CloudSyncChange.Kind(rawValue: String(identity[..<separator])) else { return nil }
        return (kind, String(identity[identity.index(after: separator)...]))
    }
    func isAncestor(_ event: String, of descendant: CloudSyncChange) -> Bool {
        var parent = descendant.parent, seen = Set<String>()
        while let value = parent, seen.insert(value).inserted {
            if value == event { return true }
            parent = events[value]?.parent
        }
        return false
    }
    /// iCloud can download a child before its parent. Wait for the causal chain
    /// before comparing projects so a delayed ancestor isn't called a conflict.
    func readyChanges(_ incoming: [CloudSyncChange]) -> [CloudSyncChange] {
        var known = Set(events.keys), ready: [CloudSyncChange] = []
        var waiting = incoming
        while !waiting.isEmpty {
            let next = waiting.filter { $0.parent == nil || known.contains($0.parent!) }
            guard !next.isEmpty else { break }
            ready.append(contentsOf: next); known.formUnion(next.map(\.event))
            let processed = Set(next.map(\.event))
            waiting.removeAll { processed.contains($0.event) }
        }
        return ready
    }
    mutating func merge(_ incoming: [CloudSyncChange]) throws {
        // Validate the whole batch before mutating anything.
        let validated = try incoming.map { try $0.validated() }.sorted { $0.order < $1.order }
        var batch: [String: CloudSyncChange] = [:]
        for change in validated {
            if let duplicate = batch[change.event], duplicate != change { throw CocoaError(.fileReadCorruptFile) }
            batch[change.event] = change
            if let existing = events[change.event] {
                guard existing == change else { throw CocoaError(.fileReadCorruptFile) }
            }
        }
        for change in validated {
            if let parent = change.parent.flatMap({ batch[$0] ?? events[$0] }) {
                guard parent.identity == change.identity, parent.sequence < change.sequence else { throw CocoaError(.fileReadCorruptFile) }
            }
        }
        for change in validated where events[change.event] == nil {
            events[change.event] = change; sequence = max(sequence, change.sequence)
        }
        for change in validated {
            let previous = heads[change.identity].flatMap { events[$0] }
            guard let previous else { heads[change.identity] = change.event; continue }
            guard previous.event != change.event else { continue }
            let newer = isAncestor(previous.event, of: change)
            let older = isAncestor(change.event, of: previous)
            if change.kind == .project, !newer, !older, !previous.deleted, !change.deleted, previous.payload != change.payload {
                // Preserve a concurrent project revision as a separate visible copy.
                let loser = previous.order < change.order ? previous : change
                let forkKey = "conflict-" + Self.digest(Data((loser.key + loser.event).utf8))
                let forkIdentity = CloudSyncChange.Kind.project.rawValue + ":" + forkKey
                var fork = loser
                let hex = Array(Self.digest(Data(("fork-" + loser.event).utf8)).prefix(32))
                let pieces = [0..<8, 8..<12, 12..<16, 16..<20, 20..<32].map { String(hex[$0]) }
                fork.event = pieces.joined(separator: "-"); fork.key = forkKey; fork.parent = nil
                events[fork.event] = fork; heads[forkIdentity] = fork.event; pending.insert(fork.event)
            }
            if newer || (!older && previous.order < change.order) { heads[change.identity] = change.event }
        }
    }
}
