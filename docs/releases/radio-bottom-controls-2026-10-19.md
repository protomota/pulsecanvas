# Radio preview and favorite looks — October 19, 2026

Source: [44e64351d22c3b3f2f318382d0d926281d0a1a15](https://github.com/protomota/pulsecanvas/commit/44e64351d22c3b3f2f318382d0d926281d0a1a15), committed and pushed to `main`.

## TestFlight delivery

- [Mac 1.1.5 (24)](https://appstoreconnect.apple.com/apps/6821642700/testflight/macos/9852df8c-214f-43f4-b343-572390b96371)
- [Vision Pro 1.0 (10)](https://appstoreconnect.apple.com/apps/6821642700/testflight/visionos/8e4b1270-69fe-4761-b104-2e2dde88da8b)

Both builds passed Apple validation and upload, processed `VALID`, and report
`IN_BETA_TESTING`. English tester notes were read back exactly. The existing
PulseCanvas Mac Beta internal group now has 26 builds; all 24 prior builds were
retained. External beta review was not submitted. Mac 1.1.4 remains
`WAITING_FOR_REVIEW`; its version identity and state match the pre-upload record.

## Behavior

Radio uses a full-width preview and grouped bottom controls on Mac and Vision Pro.
The Vision Pro Radio sidebar, browser, search, style dice and slider grid are gone.
Studio retains its editing controls. Song and visualizer favorites have distinct
labels and groups. Mac Radio controls continue to hide after three idle seconds.

New non-favorite selections and visualizer timeline shuffles create fresh settings.
Favorites snapshot all appearance settings and restore them on selection. Editing
or rolling a current look preserves its saved favorite. Favorites backup version 2
includes snapshots; version 1 remains readable. Existing ID-only favorites migrate
once from editor settings or fallback defaults. Reset explicitly applies defaults.
Playback, reopening, export and bars-only edits preserve stored Studio looks.
Radio's separate session cannot overwrite the editor project or soundtrack.

See [behavior and migration details](../RADIO-AND-FAVORITE-LOOKS.md).

## Verification

Passed with normal command exit 0:

- Mac Studio selection, favorite snapshot restoration, explicit Reset, shared looks,
  project round trips, timeline randomization and bars-only timing/performance.
- Favorites backup tests in Creators and Store configurations: snapshots, restore to
  another preference store, version 1 compatibility, retired-ID pruning, invalid
  input, automatic recovery, daily backups and backup-failure reporting.
- Mac Radio regression suite: independent project state, playback/skip, favorites,
  group filtering, station loading/refresh and failure handling.
- Shared visualizer-pool tests and Vision project/transport tests: category/favorite
  cascade, favorite look restore, fresh non-favorites, playback, loops, exact bar cuts,
  autosave and missing-audio relocation.
- Vision/Mac project interchange and actual decoded H.264/AAC exports at 1080p60
  and 4K60: 240 frames, three visible sections, nonblack output, full audio.
- Store metadata limits and whitespace checks.

The real Vision Pro UI song-favorites test passed in 37.030 seconds. The final
large-preview/bottom-controls test passed with zero failures in 77.993 seconds,
including layout, absence of editing controls, playback and visualizer changes
without stopping audio. Xcode stalled during cleanup after its passing suite;
only that owned command was interrupted. This is not a claim of a normal UI-test
command exit. An intermediate container accessibility identifier had propagated
to all buttons; it was removed and the individual controls were retested.

The Mac layout and auto-hide were inspected in an isolated local app. User
projects, soundtrack and favorite preferences were not replaced. `mobile/`, owned
by another agent, remained untracked and untouched.

Final distribution archives/exports passed code-signature, provisioning, version,
privacy/legal and native-resource checks. Each contains 336 native Metal effects,
with no community presets, projectM/OpenGL or Sparkle. Release capture hooks are
absent. A preliminary export of an unsigned Mac archive lacked sandbox
entitlements and was discarded; the delivered package was rebuilt through a signed
Xcode archive and passed the sandbox and App Store signature checks.

Physical headset testing, physical Mac installation from TestFlight, external
beta review and completed rating/payment/share actions remain unrun. No website
release or public App Review replacement was made.

## Local artifacts and evidence

`/Volumes/Music/Codex Media/PulseCanvas Studio/Platform Builds/radio-bottom-controls/`

| Artifact | Bytes | SHA-256 |
|---|---:|---|
| Mac App Store PKG | 10,792,005 | `d31b88cf47e61e78cbe0e1f4dee6f09ada6283b571eb48660d68c211d84bdf3d` |
| Vision Pro IPA | 10,760,491 | `49d3816f91ecab76bf4f0e6dcf59effca364f024bf9b9df63b537631d67632e4` |

Signed outputs: `mac-export-signed/PulseCanvas Studio.pkg` and
`vision-export/PulseCanvas Vision.ipa`. Logs, artifact receipt, Apple processing,
notes, group before/after snapshots and screenshots remain local. They contain no
private signing keys and are excluded from Git.
