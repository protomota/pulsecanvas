# Apple TV and Vision Pro TestFlight delivery — 2026-10-18

Both native-only targets are processed and assigned to the existing **PulseCanvas
Mac Beta** internal tester group under app `6821642700`. The group name predates
these platforms; it is shared across them. Apple's API reports `IN_BETA_TESTING`
for both, and the group contains the owner's existing internal tester.

| Platform | Version/build | Apple build ID |
|---|---|---|
| Apple TV | 0.1.0 (2) | `96699347-0197-491c-ad35-2b461ab75102` |
| Vision Pro | 0.1.0 (1) | `aa0733f2-b37b-4e35-a13c-f9b9f9e5d14e` |

Sources are committed at
[`b5e71bc37b0d9ba2af9ea84756f5fd484fbbe6e1`](https://github.com/protomota/pulsecanvas/commit/b5e71bc37b0d9ba2af9ea84756f5fd484fbbe6e1).
Both use the existing universal bundle ID, `com.protomota.pulsecanvas`, and Apple
Distribution certificate. Required App Store provisioning profiles were created
through the signed-in Account Holder session and kept outside Git. No certificate
or API key was created. The intermediate, unassigned TV build 1 was expired after
build 2 was available; no tester was given that interim build.

## Scope

Both apps include all 336 native Metal visualizers, palettes, original IDs and
audio analysis, with layered icons, privacy manifests and first-party legal text.
Neither contains projectM, community presets, external textures or Sparkle.

- [Apple TV](../APPLE_TV.md): a full-screen player with remote focus, favorites,
  category browsing, randomization, visual controls, bundled demo audio and
  server-driven Radio. No Studio editor, Files import or video export yet.
- [Vision Pro](../VISION_PRO.md): editable Studio scenes, per-scene bars, Files
  import, project backups/autosave, visual controls and a curved immersive viewing
  screen. No MP4 export, Radio or Mac document interchange yet. The viewing screen
  is a textured surface in space, not a volumetric environment.

Radio's TV station names, genres and song catalogs remain entirely server driven:
<https://radio.pulsecanvas.si/stations.json>. Downloads are integrity checked and
cached; audio analysis uses local bytes. No embedded radio catalogs were found in
the exported packages.

## Verification

- visionOS and tvOS simulator and device-target compilation passed.
- Both final IPAs passed Apple's validation **without errors or warnings**, uploaded
  successfully, processed `VALID`, and were assigned to the internal tester group.
- Actual exported payloads passed strict signing/profile checks, icon checks,
  exact native shader/audio byte comparisons, 336-effect catalog checks, privacy
  and license comparisons, and external-engine/catalog exclusion checks.
- Vision project tests passed for defaults, categories, stable IDs, per-scene bar
  timing, migration, malformed data and project round trips. Transport tests passed
  for real audio import/analysis, play/pause/seek, bands, editing, shared looks,
  autosave, and Radio audio loading without duplicate cache copies.
- Twenty provenance regression tests passed. The revised source packager includes
  both platform projects while retaining all installer artwork, documentation,
  notices and existing engine rebuild sources.
- TV simulator checks verified a rendered preview, remote visualizer selection,
  full category menu labels, and Play/Pause with an advancing soundtrack clock.
- Vision simulator installation/launch showed the native Studio preview. Automated
  gaze/tap interactions and entering/exiting immersion remain **unverified**.
  Headset comfort, texture orientation and sustained GPU/audio performance require
  real-device testing. Physical Apple TV testing was not performed.

Package hashes:

| IPA | Bytes | SHA-256 |
|---|---:|---|
| Apple TV 0.1.0 (2) | 11,179,606 | `0fdbb8bbc5a3baa3d51a0caca8c16641aeb8d81cb3a1d22c8dbfd88c68689108` |
| Vision Pro 0.1.0 (1) | 9,397,611 | `0947833f7d5961e7a4e465578e19a3d179ccc2663120f2529fe133dce9447004` |

## Mac reminder change

[`894f9d3`](https://github.com/protomota/pulsecanvas/commit/894f9d3da031308c1b98d9ad3ed8fea39230de2c)
changes the Creators reminder so **any one** click on Rate, Tip, Share or Feedback
closes it and stops future automatic reminders across exports and Radio, including
after relaunch. About/More Information can still open the screen manually. An
explicit Reset saved clicks can resume reminders on the next eligible milestone.
A click does not assert that the external review, tip, share or feedback completed.
The native share picker remains alive independently of the closing reminder.

Portable and Store engagement tests passed, including all four actions
independently, persistence, migration, reset and concurrent-window deduplication.
A full Mac Store compilation also passed. Apple's one-time native review request
remains independent and ungated. **No new Mac binary was published for this change.**

The existing Mac **1.1.4 / build 21** submission remained **Waiting for Review**
with its original build attached. Mac TestFlight/website 1.1.5 (23) was not replaced.
No public platform review submission, website deployment or Sparkle feed update
was made during this task. Unfinished `mobile/` work was preserved separately.
