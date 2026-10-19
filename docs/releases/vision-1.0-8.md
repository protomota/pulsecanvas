# Vision Pro 1.0 (8) — TestFlight

Delivered October 19, 2026. App Store Connect verified **VALID / IN_BETA_TESTING**
for build `e7c7d3ea-30b1-4147-9748-1a367f62107c`. Tester notes were read back exactly. The existing internal
group retained all 22 prior builds (23 total).

- [TestFlight build](https://appstoreconnect.apple.com/apps/6821642700/testflight/visionos/e7c7d3ea-30b1-4147-9748-1a367f62107c)
- Archived source: `7b509df` (Radio favorites and App Store capture hooks)
- Native effects: 336; bundle: `com.protomota.pulsecanvas`

## Radio song favorites

Vision Pro now offers a song heart beside the current title in the window and
immersive controls. Favorite songs in the left column opens a scrollable browser
with play and remove actions. Play favorite songs, and Favorite songs in the
station menu, use a favorites-only queue for Next and automatic advancement.
One saved song repeats; multiple picks avoid consecutive repeats. Empty favorites
stop with guidance instead of falling back to other songs. The saved list persists
in UserDefaults across launches and updates in the same installation. A successful
full-catalog refresh updates metadata and removes retired songs; subset and failed
reads never establish removal. Selecting a retired favorite reports its removal
rather than substituting an unrelated track. UI tests use isolated preference suites.

Mac already had song hearts, the Library → Favorite songs tab, and a favorites
music filter. It now adds a direct Play favorite songs button in that tab and
labels the Radio header correctly in favorites mode. Those Mac changes are on
main for its next build; no Mac binary was uploaded by this delivery.

## Verification

- Mac Radio smoke tests passed, including direct favorites playback from the
  Library and switching from a genre, persistent hearts, exact-track playback,
  favorites-only advancement, empty lists and catalog pruning.
- Vision transport tests passed: save/remove persistence, restored station mode,
  one/multiple/empty favorites, genre subset retention, exact/retired song handling,
  full-library restoration, failed-refresh retention and persisted pruning.
- Mac SwiftUI typecheck passed (an existing Swift 6 isolation warning in
  CreatorThanksView remains; this target uses Swift 5).
- Vision simulator test build passed. Targeted XCTest reported one passing test
  with zero failures for save heart, open browser, Play favorites, remove last song
  and stopped playback. The runner stalled in post-suite cleanup and was stopped
  after the pass; this is not a claim of a normal xcodebuild test exit. An earlier
  attempt was stopped after detecting a launch-hook timing race in the test, then
  corrected to await Radio mode before tapping Play.
- Fresh Studio and Radio opt-in capture tests each reported a passing suite.
- Release device archive and distribution export passed. The actual IPA passed
  native-resource, icon, legal/privacy, profile and signature checks. Apple
  validation/upload succeeded. API verification confirmed platform/version,
  processing, internal availability, exact tester notes and retained group builds.
- Physical headset verification remains unrun.

Mac 1.1.4 remains WAITING_FOR_REVIEW. No App Store review submission or website
release was made.

## Local evidence

`/Volumes/Music/Codex Media/PulseCanvas Studio/Platform Builds/1.0-8/`

- IPA: `vision-export/PulseCanvas Vision.ipa`, 10,639,062 bytes
- SHA-256: `796e7cec741ab4a47b65dc053e868bc4d32bd8c9883c5d91a532941868524cc2`
- Delivery receipt, actual payload checks, Apple logs and final API/group snapshots
  remain outside Git.
