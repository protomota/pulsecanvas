# iPhone and iPad onboarding — 1.2 (11)

Uploaded and enabled October 23, 2026. Application source: `ab26393`.

## Changes

- Swipe left or right to move one onboarding slide at a time. Deliberate short
  flicks now work alongside longer drags. Vertical movement and tiny drags are
  ignored; swipes stop at the first and last slides.
- Titles, descriptions and both lesson rows reserve their largest required
  space across the five slides. Each text area stays top- and left-aligned at
  the same position as the slides change, in portrait and landscape. Layout
  adapts to window size and text size without measuring each slide differently.
- Swiping across Start creating does not complete onboarding. Buttons, Skip,
  Settings replay and reduced-motion support remain available. Hidden measuring
  content is excluded from accessibility and interaction.

## Verification

- All six onboarding UI tests passed on iPhone 18 Pro and all six passed on
  iPad Pro 13-inch (M5), using iOS 27 simulators. Both commands exited normally
  with successful, finalized result bundles.
- The alignment regression measures title and description origins through all
  five slides in portrait and landscape, with a one-point tolerance. The suite
  also covers short flicks, forward/back swipes, boundaries, vertical/tiny drags,
  swiping over the final button, button completion, Settings replay, large text,
  and immediate Skip while loading the full bundled soundtrack.
- Native screenshots of all five slides on both devices were reviewed. Both
  lesson rows keep consistent positions as their descriptions change length.
- Signed Release archive and App Store distribution export succeeded. The
  exported IPA passed strict signature/profile checks, exact onboarding artwork
  verification, and the native-resource verification, including both device
  families and absence of Debug test hooks. Apple package validation succeeded.

Simulator checks do not establish physical-device touch performance.

## Delivery

Apple accepted the upload and processing reached **VALID**. Fresh API readback
confirms iOS **1.2 (11)** is **IN_BETA_TESTING** in the existing **PulseCanvas Mac
Beta** internal group. Its 50 previous builds were retained; the group now has
51 builds. The English tester notes describe swiping and consistent text
alignment. No tester membership, external beta, App Store review submission or
other platform build was changed.

- [TestFlight build 1.2 (11)](https://appstoreconnect.apple.com/apps/6821642700/testflight/ios/710a8797-d233-4f1b-9dc1-692f4cde64d1)
- [Application source](https://github.com/protomota/pulsecanvas/commit/ab2639372d5b9d4bc8955880f3be26eb6830b8d4)

Evidence, archives, exported IPA, screenshots, results and delivery logs remain
outside Git at:
`/Volumes/Music/Codex Media/PulseCanvas Studio/Platform Builds/mobile-onboarding-1.2-11-20261023/`.

IPA SHA-256:
`946f48c2a0e2a2a2528cc32de6d4c4c14b3f272bf157b8ba5a24659a4f1c5b01`.
