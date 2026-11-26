# Duo workspace refinements — October 21, 2026

The mobile Studio preview now uses the available height instead of keeping a
16:9 preview inside a tall empty region. Bounded layouts keep the soundtrack
transport and complete scene cards at the bottom. Timeline scrolling bleeds to
the workspace edges, with inset first/last cards. The visualizer name, favorite,
randomizer, style and presentation controls sit above the preview; music and
scene actions sit below it.

On phones, including Duo, the Library opens with the header grid button rather
than occupying a permanent column. Large iPad windows retain their inline
Library. Both the inline list and picker list extend to the bottom. Side camera
insets apply to controls, while media and the timeline use the available width.
The Duo header uses clear corner-status space and reserves room for the system
status cluster. Apply to all and Shuffle scenes have distinct icons/text.

The redundant Studio label/icon above the timeline is removed from mobile, Mac
and Vision Pro. Workspace tabs and timeline actions remain.

## Switching performance

Every recreated preview previously compiled all native Metal libraries and base
pipelines again on the main actor. Renderers now reuse compiled GPU programs per
Metal device. Command queues, mutable render targets, buffers, clocks and audio
remain separate. The renderer reuse test checked four recreations and 28 exact
GPU frame matches; one measured cold setup was 2.786 seconds and the warm setups
were 0.026–0.034 seconds. These are renderer setup measurements, not end-to-end
physical-device navigation timings.

Radio retains the already analyzed Studio soundtrack during playback and restores
that file/analysis on the playback actor. It no longer decodes and analyzes the
whole Studio song synchronously when leaving Radio. The existing Radio smoke
suite now verifies file/analyzer identity reuse as well as the restored position,
volume, paused state and timeline. Mobile Radio reuses its loaded catalog when
reopened; explicit Retry still reloads it. No audio format, mixer or output-device
routing changes are included.

## Verification

Evidence and local builds are outside Git:
`/Volumes/Music/Codex Media/PulseCanvas Studio/Development/iphone-duo/expanded-workspace/`

- Native renderer reuse test: passed (28 exact GPU frames, no extra library builds).
- Radio smoke suite, including retained Studio file/analysis restore: passed.
- Mac debug build and Vision simulator debug build: passed.
- Mobile simulator build-for-testing and unsigned iOS Release build: passed.
- Duo outer display: expanded-workspace bounds, full-height picker, repeated
  tab switches, clip/bar controls, presentation, export settings and cancel: passed.
- Standard iPhone: adaptive Studio/Radio plus scene/export controls: passed.
- iPad: adaptive Studio/Radio plus landscape Radio bounds/no vertical scroll: passed.
- Live unfolded Duo: visually inspected full-width Studio and opened Library
  from its header button. Picker and timeline reach the lower edge.

An early inner-portrait XCTest library tap did not open the picker; Duo's active
and inactive display coordinate mappings make those scripted taps unreliable.
An initial iPad Radio check also failed to locate the visualizer heart; its
standalone rerun passed. Some completed Duo XCTest suites leave xcodebuild running
with `invalidDigitCount(94232)` SDK-record errors, so per-case results were checked
and only the completed owned test processes were stopped. Continuous physical
fold/rotation automation is not certified by these results. The screenConfig
geometry experiment changed the isolated framebuffer's orientation; it is not
counted as a successful portrait-layout test.

The app remains version 1.2, local build 8. No App Store submission, TestFlight
upload, website deployment or version bump is part of this change. Marketing
screenshots made before these UI refinements need recapturing before submission.
