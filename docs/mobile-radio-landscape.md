# iPad Radio landscape layout

Landscape iPad windows use a bounded layout with no vertical ScrollView. The
preview fills the height remaining after the controls instead of deriving its
height from a full-width 16:9 frame. Visualizer controls and the group picker
share the top row. Song favorites, station selection and Next share a row below
the preview; playback, scrubbing and volume share the next row. Status, loading,
fallback and retry messages remain visible below them. Portrait and iPhone keep
the existing scrolling arrangement.

Verified October 20, 2026 with the native iOS 27 simulators:

- iPad mini (A17 Pro) and iPad Pro 13-inch (M5): the new UI test passed on both.
  It checks no scroll container, all controls hittable and within screen bounds,
  a preview taller than 200 points, visible empty-favorites fallback text, and
  landscape → portrait → opposite-landscape rotation without pausing playback.
- iPhone 17: existing Radio empty-favorites/playback/scrubbing/heart-alignment
  regression test passed with normal `TEST EXECUTE SUCCEEDED` and exit 0.
- Simulator compilation and `git diff --check` passed.

The first iPad run exposed a container accessibility identifier overriding its
children's IDs. Explicitly containing those children fixed this; both final
destination suites passed with zero failures. The iPad xcodebuild process
remained in post-suite result cleanup and was interrupted after its complete
passing per-destination logs were preserved. A normal iPad command exit is not
claimed. Evidence is outside Git in
`/Volumes/Music/Codex Media/PulseCanvas Studio/Mobile QA/2026-10-20-landscape/`.

This change has not been uploaded to TestFlight; 1.1.5 (4) predates it.
