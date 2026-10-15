import Foundation

/// Timing follows the beat grid; each card can request its own bar length.
struct StudioSegment: Codable, Identifiable, Sendable {
    let start: Double
    let end: Double
    var scene: Int
    var bars: Int? = nil
    var id: Double { start }
}

enum StudioTimeline {
    /// Each scene is dealt once. Favorites lead; unused library scenes fill the tail.
    /// Return nil when uniqueness is impossible without changing the clip timing.
    static func randomizedScenes(current: [Int], favorites: [Int], available: [Int]) -> [Int]? {
        let availableSet = Set(available)
        let preferred = Set(favorites).intersection(availableSet)
        var choices = preferred.shuffled() + availableSet.subtracting(preferred).shuffled()
        guard current.count <= choices.count else { return nil }
        var result: [Int] = []
        for (index, previous) in current.enumerated() {
            let favoritesLeft = choices.prefix(while: { preferred.contains($0) }).count
            // Reserve enough remaining slots to include every preferred scene.
            let requiredFavorites = favoritesLeft >= current.count - index
            let eligible = requiredFavorites ? 0..<favoritesLeft : choices.indices
            let candidate = eligible.first(where: { choices[$0] != previous }) ?? eligible.lowerBound
            result.append(choices.remove(at: candidate))
            // With an exactly full pool the final slot may retain its old scene.
            // Swap earlier assignments where both cards can still change.
            if result[index] == previous,
               let swap = (0..<index).first(where: { result[$0] != previous && current[$0] != previous }) {
                result.swapAt(swap, index)
            }
        }
        return result
    }

    static func index(at time: Double, in segments: [StudioSegment]) -> Int? {
        guard !segments.isEmpty else { return nil }
        var low = 0, high = segments.count
        while low < high { let mid = (low + high) / 2; if segments[mid].start <= time { low = mid + 1 } else { high = mid } }
        return max(0, min(segments.count - 1, low - 1))
    }
    static func valid(_ segments: [StudioSegment], sceneCount: Int) -> Bool {
        guard segments.count <= 10_000 else { return false }
        for (index, segment) in segments.enumerated() {
            guard segment.start.isFinite, segment.end.isFinite, segment.start >= 0, segment.end > segment.start,
                  segment.bars.map({ $0 > 0 && $0 <= Int.max / 4 }) ?? true,
                  (0..<sceneCount).contains(segment.scene), index == 0 ? segment.start == 0 : abs(segments[index-1].end - segment.start) < 0.001 else { return false }
        }
        return true
    }
}
