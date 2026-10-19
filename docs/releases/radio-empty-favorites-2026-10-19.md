# Radio: empty favorite visualizers and mobile transport

The shared visualizer filter previously returned no candidates when Favorites
was selected without any saved favorites. Radio's `canStart` required at least
one candidate, so Play was disabled. The mobile Retry button incorrectly treated
that disabled state as a catalog failure.

## Changes

- Shared candidate selection falls back to all installed visuals when the
  Favorites group has no favorites. Custom category/collection constraints are
  retained; a genuinely unavailable category stays empty. Preferences and
  favorite looks are preserved. Saving the first favorite restores the
  favorites-only selection automatically; removing the last restores random
  fill. Radio, Studio, Library and randomizers use this shared behavior across
  Mac, mobile, Vision Pro and Apple TV source.
- Mac/mobile Radio and Vision Pro Radio show a message explaining the fallback.
  Song-favorites stations retain their separate, explicit songs-only behavior.
- The shared Radio model tracks actual catalog-loading errors separately from
  candidate availability. Mobile Retry appears only after such an error and
  clears as soon as a new load starts.
- Mobile Radio has an icon Play/Pause button beside elapsed time, a seekable
  playhead and duration. It can pause a pending track request. Seeking commits
  on slider release and preserves playing/paused state. High-rate progress
  observations are confined to the transport and throttled to 10 Hz.
- Mac Radio's progress display is now seekable through the same guarded model
  operation. Vision Pro already has a seekable transport.
- Mobile and Vision Studio center the active card when playback switches scenes
  (including a playing seek). Paused browsing does not trigger auto-scrolling.
  Mac Studio already centers the active card when the selected segment changes.
- When shortening bar lengths creates more cards, the shared Mac/mobile Studio
  now continues the existing visualizer sequence. Previously, every appended
  card copied the last scene, producing long stretches of identical visuals.
  Existing assignments and styles remain intact. Vision already cycles the
  sequence in its corresponding timeline-fill operation.
- Mobile stays at version 1.1.5 and advances its independent build number to 2.
  The Debug-only Radio UI fixture uses a local 30-second excerpt and catalog;
  the normal export fixture remains eight seconds. Neither is in Release.

## Verification

- Shared Radio smoke suite passed, exit 0: cold start with empty favorites,
  live removal of the last favorite, randomization, pause/resume, seek while
  paused/playing, favorites restored, next song, catalog failure/recovery,
  empty catalog, retired-song cleanup and bounded unavailable-song retries.
- Shared visualizer-pool suite passed, exit 0: scoped fallback, persistence,
  Studio randomizers, saved favorites and genuinely missing categories.
- Full Creators Studio suite passed, exit 0, including a new shrink/expand
  regression: three different long scenes become 24 one-bar scenes cycling
  those three designs, with original scene order and shared styles retained.
- A separate iPhone Studio UI test passed: one test, zero failures, 15.041
  seconds. A seek during actual playback changes the active scene and places
  its card within 24 points of the horizontal timeline's center while audio
  remains playing.
- Vision transport suite passed, exit 0, including empty-favorites visualizer
  and whole-timeline randomization, category filtering, real audio playback,
  station/song favorites and project persistence. Initial runs stopped at old
  assertions requiring empty favorites to fail; those expectations were updated.
  Atomic failure coverage remains against a genuinely missing category.
- New iPhone 17 UI test passed: one test, zero failures, 25.330 seconds. iPad
  equivalent passed: one test, zero failures, 34.674 seconds. Both use the real
  playback model and confirm the fallback, absence of Retry on successful load,
  Play/Pause, enabled scrubber, paused seek, resume and uninterrupted randomize.
  The first phone attempt checked scrubber availability before audio preparation
  finished; the test now waits for that legitimate loading transition.
- Simulator test suites completed, but Xcode's post-suite cleanup stalled. The
  phone command was terminated after its passed suite; normal exit-0 completion
  of the UI-test command is not claimed. Incomplete xcresult bundles could not
  export screenshot attachments; the text logs are retained.
- Release iOS archive and signed distribution export passed. The actual exported
  IPA passes native resource/catalog checks and strict signature verification:
  1.1.5 (2), 336 effects, iPhone+iPad, Apple Distribution for Protomota, LLC,
  matching App Store profile and no Debug fixture or external engine assets.
- Unsigned Release device builds for Mac and Vision Pro both passed, exit 0.
  Neither was uploaded or substituted into its existing review submission.

Physical-device installation/performance and manual Mac/Vision UI interaction
were not checked in this change. Evidence is outside Git under
`/Volumes/Music/Codex Media/PulseCanvas Studio/Mobile QA/radio-fix/` and
`/Volumes/Music/Codex Media/PulseCanvas Studio/Platform Builds/mobile-1.1.5-2/`.
