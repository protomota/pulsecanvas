# Onboarding release — October 22, 2026

Released from source
[`a6b367942b826cb00d9744ae28412d7cd2598d33`](https://github.com/protomota/pulsecanvas/commit/a6b367942b826cb00d9744ae28412d7cd2598d33).
Includes five full-screen onboarding pages, transparent illustrations, original
branding, the owner-supplied plum background, matching support button widths,
direct Buy Me a Coffee links, and replay from Settings. Mobile prepares audio and
GPU programs during onboarding and compiles live-preview programs off the UI
thread; preparation progress and Settings remain available after immediate Skip.

## TestFlight delivery

All three uploads passed Apple validation, processed `VALID`, and report
`IN_BETA_TESTING` in the existing **PulseCanvas Mac Beta** internal group.
English tester notes were saved and verified through API and browser reads.

| Platform | Version/build | Build |
|---|---|---|
| Mac | 1.2 (29) | [Open TestFlight build](https://appstoreconnect.apple.com/apps/6821642700/testflight/macos/cfb942a6-60fa-4610-90a7-998f4401c97b) |
| iPhone/iPad | 1.2 (9) | [Open TestFlight build](https://appstoreconnect.apple.com/apps/6821642700/testflight/ios/e8df759b-524b-465d-9936-4be314d6ac4f) |
| Vision Pro | 1.2 (16) | [Open TestFlight build](https://appstoreconnect.apple.com/apps/6821642700/testflight/visionos/5b3d4727-cd7b-44b3-865a-b2142ce6cdd7) |

The group retains all 44 prior builds, with these three added. No testers or
groups were created, and no external beta review or public App Review submission
was made. Before/after API snapshots verify all public platform versions, review
states and selected builds are unchanged. **Apple TV was excluded.**

## Website and Creators Edition

[The production download page](https://pulsecanvas.si/download/) serves
**Creators Edition 1.2 (29)** and its matching source archive. The
[signed update feed](https://pulsecanvas.si/appcast.xml) advertises the same
installer while retaining previous releases.

- [Installer](https://media.pulsecanvas.si/downloads/PulseCanvas-Studio-1.2-29.dmg):
  42,326,821 bytes; SHA-256
  `2dd7977445750c82c3d54820f59461b1d33713092acf6d86bb2d39919526cc9a`.
- [Matching source](https://media.pulsecanvas.si/downloads/PulseCanvas-Creators-1.2-29-source.tar.gz):
  91,040,750 bytes, packaged from the frozen source revision above. Both public
  files were downloaded in full and their hashes matched the local artifacts.
- Developer ID signing, Apple notarization (`Accepted`), stapling, Gatekeeper,
  mounted installer layout/bundle comparison and the pinned Sparkle signature
  passed. Notarization ID: `52d491ea-4b6d-4af2-8428-70b48158e30d`.
- Website source commit:
  [`6c571bf`](https://github.com/protomota/pulsecanvas-website/commit/6c571bf).
  Vercel production deployment: `dpl_G3onhPTGVZTn8dG4YWPb7cdfWiUh`.
  The live page and feed were verified in the browser. Existing website drafts
  were preserved; the release used a separate checkout of the production source.

## Verification and limits

Actual exported Store packages passed signing/profile, version/build, native
resource and exact onboarding artwork checks. Store packages exclude external
engines and Sparkle; Creators retains its existing additional effects library.
All released executables exclude onboarding capture and mobile test fixture hooks.

The mobile onboarding suite passed all three tests, including the full bundled
soundtrack startup case; the corresponding iPad startup test passed. Enabled
controls were observed in roughly 1.4 seconds on iPhone and 2 seconds on iPad,
including XCTest polling. The renderer worker/cache check and 28 matching frame
checks passed. Device Release compilation and shared TV/Vision compilation also
passed; the TV build was a local compile check only. Six website installer tests,
R2 media/download checks, production build and eleven-page SEO checks passed.

Physical-device performance, clean-machine installation and an end-to-end
production Sparkle install were not performed. Distribution verification does
not establish those results or change the existing component licensing notices.

Local evidence is excluded from Git under:
`/Volumes/Music/Codex Media/PulseCanvas Studio/Platform Builds/onboarding-1.2-20261022/`.
It includes signed archives/exports, extracted payload checks, hashes, Apple
validation/upload/processing receipts, tester-note readbacks, public-version and
group snapshots, notarization evidence and screenshots.
