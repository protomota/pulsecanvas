# iPhone Duo — 1.2

The mobile workspace uses the current window's dimensions and safe-area insets,
not the device idiom or a cached screen size. Wide windows gain the inline
visualizer library. Studio in landscape gives the preview the remaining height
and keeps its transport and complete scene cards visible without a vertical
scroll container. On the short folded landscape display, the preview sits beside
the transport and timeline rather than above them. Large/landscape Radio uses a bounded preview with its controls
on screen. Narrow portrait windows retain scrolling where it is needed.

Media extends underneath Duo's trailing status area rather than losing a full
vertical strip. The header and Radio's top control row reserve the reported
trailing inset so buttons do not overlap the system status controls.

## Reproduce the UI regression

Use Xcode 27.1 and the iOS 27.1 simulator runtime with an iPhone Duo device. Run
`PulseCanvasMobileUITests` on both the open inner display and closed outer
display. `testIPadLandscapeRadioFitsWithoutScrolling` is an iPad-specific test;
run it separately on an iPad. `testCaptureDuoStoreScreenshots` uses the real
bundled soundtrack and live Radio instead of the short isolated QA fixtures.

```sh
xcodebuild -project PulseCanvasMobile.xcodeproj -scheme PulseCanvasMobile \
  -destination 'platform=iOS Simulator,id=<Duo simulator UUID>' \
  -derivedDataPath '<external build directory>' \
  -skip-testing:PulseCanvasMobileUITests/PulseCanvasMobileUITests/testIPadLandscapeRadioFitsWithoutScrolling \
  -skip-testing:PulseCanvasMobileUITests/PulseCanvasMobileUITests/testCaptureDuoStoreScreenshots \
  CODE_SIGNING_ALLOWED=NO test
```

The tests cover live window bounds, buttons on screen, full scene-card bounds,
no wide Studio/Radio vertical scroll container, the preview's right edge,
library search and category/favorites filters, visual selection, playback,
seeking, stable control sizes, rotation, background playback, favorite-song and
empty-favorites behavior, personal-folder Radio isolation, full-screen viewing,
next song, all eight style sliders, strobe controls, palettes, reset, style
randomization, common settings, bar lengths, timeline randomization, scene
selection, Files picker presentation/cancellation, About, MP4 rendering and a
completed native Files video save. QA launch hooks are Debug-only and use
isolated temporary projects; Release artifacts are checked for their absence.

Duo's XCTest application frame can describe the inactive display. Layout
assertions use `app.windows.firstMatch.frame`. Screenshot capture must target
the active display port reported by `xcrun simctl io <UUID> enumerate`; XCTest's
application screenshot can return the inactive display. Do not resize those
captures to conceal a layout error.

## Apple references

- [Prepare for iPhone Duo](https://developer.apple.com/iphone-duo/prepare/)
- [Screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications)
- [Asset specifications API](https://developer.apple.com/documentation/appstoreconnectapi/discovering-asset-specifications)

Apple's `IPHONE_DUO_PROFILE` screenshot placement group accepts both inner
(2007×2853 or 2853×2007) and outer (1398×2034 or 2034×1398) captures. These are
one placement group, not two separate legacy screenshot slots.

## Validation environment and limits — October 21, 2026

- Xcode 27.1; iPhone Duo inner window 951×669 and outer window 466×678
  logical points on iOS 27.1 (runtime build 24A94232).
- Short landscape Studio was additionally checked at 956×440 on an iPhone 17
  Pro Max simulator running iOS 27.0. The full card and primary controls fit
  without a vertical scroll container. iPad Pro 11-inch (M5) Radio also passed
  its separate landscape/portrait bounds and control-reachability test.
- Duo's active window does not always rotate when XCTest requests an orientation
  change. Assertions use the actual live bounds; a rotation request alone is not
  evidence of a tested landscape layout. Continuous folding and physical-device
  touch/performance remain device checks; closed Duo landscape is not claimed
  as physically verified.
- The initial full runs had automation failures: an idle full-screen control
  disappeared before a delayed tap; native picker/transport activation points
  were inconsistent; and repeat saves encountered existing test filenames.
  Focused reruns use visible control centers, pause before inspecting the
  full-screen controls, wait for picker dismissal, and keep earlier QA files.
  Debug-only QA video exports get unique filenames. Release keeps its normal
  filename and contains no QA launch hooks or test soundtrack fixtures.
- Xcode sometimes stalled after complete test suites while logging an SDK build
  parsing warning (`invalidDigitCount(94232)`). Only this task's already-finished
  runners were terminated. Per-test results are recorded below; a normal
  successful exit is not claimed for commands that stalled or had earlier
  failing cases. Failed logs were retained alongside the successful reruns.
- Actual completed Files saves were inspected: both saved MP4s contain audio
  and video and decode cleanly, and both saved project files contain valid JSON.
  Common Studio-model and Mac/Vision project-format regression scripts passed.
- Release 1.2 (8) builds successfully. Actual packaged-resource checks confirm
  336 native effects, source-matched resources, both device families, and no
  external engine/preset pack, Sparkle or Debug fixtures. This is an unsigned
  local build, not a signing, TestFlight-upload or App Review result.
- Complete test movies use 720p. All canvas/resolution/frame-rate controls and
  4K cancellation are exercised; a full 4K60 physical-device benchmark is not
  claimed. External review, feedback, sharing and payment actions were not
  submitted. Physical locked-device audio and actual StoreKit prompt appearance
  remain device/storefront checks.

Evidence, logs, receipts and simulator products (excluded from Git):
`/Volumes/Music/Codex Media/PulseCanvas Studio/Development/iphone-duo/`.

## Observed results

All 26 device/test combinations below have passing case evidence, including
focused reruns after the automation corrections described above. This is not
a claim that the initial complete-suite commands exited successfully.

| UI flow | Duo inner | Duo outer |
|---|---|---|
| Personal-folder Radio and catalog return | Pass | Pass |
| Library song, favorites filter, Studio import and render | Pass | Pass |
| Real soundtrack / live Radio screenshot capture | Pass | Pass |
| Window bounds, full-width Radio, landscape Studio | Pass | Pass |
| Background audio, full-screen controls, Radio export | Pass | Pass |
| All style/strobe controls, palette, reset, apply, randomize | Pass | Pass |
| Open/import picker cancellation, project Files save, About | Pass | Pass |
| Loop, scene bars, presentation, output options/cancellation | Pass | Pass |
| Favorite-song list/station, remove favorite, volume | Pass | Pass |
| Playback and current-scene auto-scrolling | Pass | Pass |
| Empty-favorites fallback, pause, seek, randomize | Pass | Pass |
| Style, search, presentation, actual MP4 render and Files save | Pass | Pass |

The iPad Radio bounds test and standard iPhone short-landscape test each
passed separately. Detailed per-case log references and source hashes are in
`final-ui-regression-report.json` in the local evidence directory.
