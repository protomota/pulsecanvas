# Vision Pro 0.1.0 (5) — TestFlight

Delivered October 18, 2026 to the existing internal **PulseCanvas Mac Beta** group.
App Store Connect's API reports **VALID / IN_BETA_TESTING**. Exact tester notes
were read back; all 19 previously assigned builds remain in the group.

- App: `6821642700`; bundle: `com.protomota.pulsecanvas`; platform: `VISION_OS`
- Archived source: `03c43e1961b87148af8dbf9b7dcd8f3167d3e176`
- Build ID / delivery UUID: `6f8b6a39-e9ba-440f-9806-04c367caf89f`
- [TestFlight build](https://appstoreconnect.apple.com/apps/6821642700/testflight/visionos/6f8b6a39-e9ba-440f-9806-04c367caf89f)
- Native effects: **336**, with no external engine, presets/textures or updater.

## Changes and crash evidence

The actual build-4 headset report was retrieved through App Store Connect's
beta crash feedback API. It records **SIGABRT** during Save video, with
`NSFileWrapper.setPreferredFilename`, SwiftUI's `AnyTransferable` conversion and
`FileExportOperation.makeFiles` in the exception backtrace. It does not identify
a rendering or encoder failure. Raw diagnostic data stays outside Git.

The movie now goes directly to `UIDocumentPickerViewController(forExporting:asCopy:)`,
bypassing that SwiftUI Transferable/FileWrapper conversion. The picker receives
a validated, existing MP4 URL with a fixed filename. Canceling leaves the source
available for another attempt; a successful picker callback marks the copy saved.

The latest completed movie is retained in the app's cache across export-sheet
dismissal and relaunch. A new render replaces it only after successful completion.
Build 5 also attempts recovery of a finalized movie in build 4's temporary
render directory, if the system still retains it. No video library/player is added.
Temporary encoding work is cleaned up by the rendering task, not a view's
`onDisappear`, so presenting or dismissing Files cannot delete its source.

**Hi-hat strobe** groups its visible label and switch on the left. When enabled,
Sensitivity and Strength sliders appear directly underneath, in both the main
style controls and Studio card popup. The popup is taller to accommodate them.
The settings remain shared with Apply to all and Mac-compatible project files.
Audio import uses a tray/down-arrow icon; MP4 export uses a filmstrip.

## Verification

- File lifecycle tests: passed byte-preserving retention after workspace removal,
  retry/recovery, replacement, invalid/missing/empty inputs and scoped recovery
  from a prior render folder without touching unrelated files.
- Transport regressions: passed targeted-card strobe edits and JSON persistence,
  existing card picker, bar timing, Apply to all, looping, Radio, audio relocation,
  autosave and playback checks.
- Release simulator build and device archive: passed.
- Simulator bundle and actual signed IPA: passed exact native assets, icons,
  legal/privacy notices, matching profile, strict Apple Distribution signature
  and absence of external engines/catalogs.
- Apple validation and upload: succeeded without errors.
- Processing, testing-group assignment and internal availability: verified via API.

Mac 1.1.4 remains **WAITING_FOR_REVIEW**. No Mac, website or Apple TV binary was
released and no public App Store submission was replaced.

The simulator shows the grouped label/switch and new icons. Automated pointer
actions did not activate the simulated controls reliably. Native Files picker
presentation, destination saving and cancel/retry still require headset
confirmation. The file lifecycle tests do not establish physical picker behavior.
Rendering/encoding code is unchanged from build 4; its 1080p60/4K60 decoded-output
tests were not repeated for this save/UI change.

## Local evidence

Artifacts remain outside Git under
`/Volumes/Music/Codex Media/PulseCanvas Studio/Platform Builds/0.1.0-5/`:

- IPA: `vision-export/PulseCanvas Vision.ipa` — **10,493,887 bytes**
- SHA-256: `017155e2f8785a8e62523ccbe09fe5e5c7ffb567a4b871aae8c39814d2526c3f`
- `feedback-crashes.json`, `crash-log.json`: private diagnostic evidence
- `vision-delivery-receipt.json`, `vision-test-notes.txt`, `logs/*`
- `vision-studio-layout.png`: actual simulator layout
