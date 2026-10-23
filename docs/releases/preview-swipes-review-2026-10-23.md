# Visualizer preview swipes — October 23, 2026

Reviewed and approved by the owner before TestFlight delivery. Includes the
previously approved large-iPad onboarding and grouped Radio controls.

## Behavior

- Swipe left or right on the Studio or Radio visualizer to select another
  visualizer from the selected group/pool. This works in editor previews and
  full-screen presentation on iPhone and iPad.
- Studio replaces the look in the current scene. The soundtrack position, scene
  selection, segment boundaries and other scene assignments stay intact.
  Radio changes its current visualizer without choosing another song.
- Swipes preserve playback/pause state. Vertical drags and tiny movements are
  ignored, parent scrolling remains available, and full-screen taps still
  reveal or hide controls. A swipe does not also activate that tap action.
- VoiceOver has a Change visualizer action and announces the current visualizer.
  Loading and export guards prevent changes during those operations.

One shared mobile gesture modifier calls the editor's preview-randomization
action. That action reuses the established Studio/Radio group randomizers;
it does not call audio seek, next-song or scene-selection methods.

## Verification

Both focused UI tests passed on iPhone 18 Pro and iPad Pro 13-inch (M5), iOS 27
simulators: four passes, zero failures, normal command exits and finalized result
bundles. These new gesture runs used portrait editor and full-screen surfaces.
The prior onboarding/Radio layout checks covered portrait and landscape.

Checks cover both swipe directions, unchanged paused audio position, unchanged
song/current Studio scene, retained playback, selected-group membership through
Library search, vertical/tiny drags, full-screen swipes and tap controls.
Before/after screenshots of all four surfaces were captured natively and reviewed.
Only iPad's stalled post-test diagnostic collector was stopped after the passing
suite; the test process completed successfully.

Evidence and screenshots remain outside Git:
`/Users/brad/Documents/Codex/2026-10-23/pulsecanvas-preview-swipes-review/`.

## Delivery

The owner explicitly approved the combined changes after reviewing the swipe
captures. A fresh signed 1.2 (12) archive/export from `a5aef74` was uploaded,
processed and enabled for the existing internal TestFlight group. See the
[verified delivery](mobile-testflight-1.2-12.md).

The earlier signed 1.2 (12) layout-only candidate in
`/Volumes/Music/Codex Media/PulseCanvas Studio/Platform Builds/ipad-layout-1.2-12-20261023/`
is superseded, does not contain these gestures, and was never uploaded. The
delivery above uses the separate fresh combined-source artifact folder.
