# Validation evidence — 2026-10-11

Scope: this Apple silicon Mac. The existing portable app/session was preserved. Minimum supported macOS 14 and a second machine have not been tested here. Distribution version 1.0.0 (1) is uploaded; Apple processing completed; actual TestFlight installation remains pending.

## Builds

SwiftPM release builds. Xcode Release local build and unsigned engineering archive succeed. `scripts/validate-store-artifact.py --local` checks arm64 app/library, macOS 14, explicit version, resources, 7,838 presets, hardened-runtime matching team signatures, three intended sandbox entitlements, no get-task-allow/network/microphone/library-validation exceptions, and privacy manifest. Apple Development identity is existing team 22HV69L32T. Apple Distribution export and Mac Installer Distribution signing succeeded. The final exported app and nested library passed strict codesign checks, matching team 22HV69L32T, hardened runtime, sandbox and resource checks. Its embedded Mac Team Store profile has the correct application identifier, no device list or development debugging entitlement, and a valid expiry. The installer passed pkgutil certificate-chain validation. Apple accepted upload 1.0.0 (1); processing completed and build 1.0.0 (1) is assigned to the internal Mac beta group. An unsigned archive is not a submission package.

Local evidence: `work/app-store/swift-build.log`, `xcode-test-build.log`, `archive-unsigned.log`. Build scripts emit existing OpenGL deprecation warnings; OpenGL execution must continue to be checked on supported macOS releases.

## Tests

- `scripts/test-audio.sh`: bundled audio starts paused; playback, loop/sections and pause pass.
- `scripts/test-studio.sh`: catalog count, style/favorite persistence, stable identities, timeline edits/randomization, migration and project round-trips pass.
- `scripts/test-social-export.sh`: real audio-inclusive MP4 decoding, wide/portrait native output, 4K60, cancellation/destination preservation, Studio shared styles/zoom/blur/chaos and state retention pass.
- `scripts/test-projectm-integration.sh`: library/folder import, identities/favorites/migration, GPU Metal/OpenGL/IOSurface rendering, portrait ProjectM/native/ProjectM Studio MP4, and decoded consecutive ProjectM switches in 4K60 pass on the final run.

The first ProjectM assertion exposed stale metadata: report retained count 7,839 while actual files/catalog are 7,838; report corrected from existing catalog/retired records without changing effects. Two optimized 4K transition attempts also terminated before the final diagnostic run. An unoptimized diagnostic run passed, and the final optimized run passed with per-scene visible-pixel evidence (1,558 / 1,856 / 142 / 769 / 6,613 out of 9,216). This suggests an intermittent transition/visibility issue; **do not dismiss it as fixed by one passing run**. Repeat those checks on the final distribution artifact and second Mac before release.

Compact editor layout check: see `work/app-store/layout-validation.log`; final result recorded in README.md. No new tests mirror bookmark implementation: restart behavior was checked through the actual sandbox UI.

## Actual sandbox UI

Initial ad-hoc sandbox (`com.protomota.pulsecanvas.storetest`) rendered native visuals and imported audio using the native panel. Save/Open project after quit/relaunch retained its bookmark and favorite. Native wide 4K60 exported with AAC audio, 120 video frames, 2s duration. Ad-hoc nested-library loading failed under library validation; no security exception was added.

The matching-team Apple Development test (`com.protomota.pulsecanvas.storevalidation`) started from a new sandbox container because changing the old ad-hoc container's signing identity stalled in sandbox initialization. It loaded the bundled demo paused. Opening a legacy fixture with no bookmark correctly prompted to locate the external audio. After choosing that file, ProjectM and native Studio sections loaded. Actual phone 4K60 exported 2160×3840 H.264 at nominal 60fps with AAC audio, 120 frames and 2s duration. Six decoded samples had visible pixels; this is sampled visibility evidence, not a guarantee that every frame in every effect is bright. Replacing the same existing test MP4 succeeded through NSSavePanel. Saving `Signed-sandbox-studio.pulsecanvas`, quitting/relaunching and opening it recovered the imported audio without a locate prompt.

The separate screenshot demo (`com.protomota.pulsecanvas.storescreenshots`) made a fresh 1440×900 editor. Actual bundled-song Studio export started, was captured, and cancelled successfully. No finished screenshot-only MP4 was left behind.

Native helper inventory: one app executable and one embedded ProjectM dylib; no external runtime helper/XPC executable shipped. Build scripts are build-time only. CMake disables SDL UI and playlist. ProjectM depends on system CoreFoundation/libc++/libSystem; no non-system dependent library omitted. No Intel support claimed.

## Remaining validation

Actual TestFlight installation/launch; repeated ProjectM transition visibility/cancellation under that artifact; long-song 4K60 performance and full-frame black-frame audit; full-screen/aspect/scene-loop/randomization UI smoke on distribution build; clean install and a second supported Mac/macOS 14; privacy-report validation in Xcode; TestFlight when account/rights holds clear. Custom preset import is a legacy helper with no public import control; old portable custom packs need an explicit user-selected migration route before relying on them in sandbox projects.

Final local artifact check passed after the Help changes. The Privacy disclosure was expanded successfully and Open licenses and notices opened the expected Legal folder containing all copied notices. Test apps/windows were closed. The original portable app still showed Spiral Tide, Emberlight, PulseCanvas 3:58, paused at 1:42, preview volume 0.54.

## Distribution and matching source evidence

Export: `build/app-store/export/PulseCanvas Studio.pkg`. Expanded artifact: `work/app-store/distribution-expanded/com.protomota.pulsecanvas.pkg/Payload/PulseCanvas Studio.app`. Actual app/library authority is Apple Distribution: Protomota, LLC (22HV69L32T); package authority is 3rd Party Mac Developer Installer: Protomota, LLC (22HV69L32T). `scripts/validate-store-artifact.py` distribution mode passed. Archive mode intentionally permits the development signature used before export and does not substitute for final distribution validation.

Apple upload log: `work/app-store/apple-upload.log` records Upload succeeded / EXPORT SUCCEEDED. Nonfatal upload warning: missing libprojectM.dylib dSYM UUID 5A86E285-3E15-36D1-B1A9-ECD3F3A6C583. Improve future library crash symbolication; this warning did not block upload.

Matching source snapshot was unpacked into `work/app-store/source-rebuild/PulseCanvas-source` and rebuilt using `scripts/store-release.sh archive-unsigned`; clean-source ARCHIVE SUCCEEDED, evidence `work/app-store/source-rebuild.log`. Public source publication and asset/LGPL distribution-rights review remain pending.

TestFlight server evidence: internal group shows 1 Tester / 1 Build, Brad’s status Invited on 2026-10-11. Screenshot `work/app-store/mac-testflight-invited.png`. The TestFlight Mac client is installed and open; PulseCanvas invitation has not yet been accepted, so no claim of beta installation or Apple-delivered runtime validation.

Apple Build Metadata reports **Binary State: Validated**, com.protomota.pulsecanvas, version 1.0.0, build 1, minimum macOS 14.0, arm64, non-exempt encryption No, and the expected team/application identifiers plus three sandbox entitlements. Evidence `work/app-store/mac-build-validated.png`. Apple reports Includes Symbols Yes for the app; the specific missing ProjectM library dSYM warning still applies.
