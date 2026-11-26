# Vision Pro 1.1.5 (12) — pinned workspace and Radio layout

Released to the existing internal TestFlight group on October 19, 2026.

- [Vision Pro 1.1.5 (12)](https://appstoreconnect.apple.com/apps/6821642700/testflight/visionos/1f51a7aa-9dfb-44f7-a4fd-f220dfc9404a)
- Source: [d34946663a77ea320c66d8e76692c73fbad45fed](https://github.com/protomota/pulsecanvas/commit/d34946663a77ea320c66d8e76692c73fbad45fed), pushed to `main`.

Studio/Radio stays at the same top-left position in both modes. The Radio
visualizer title, favorite heart, randomizer and group selector sit above the
full-width preview. Below it, the song title and favorite heart share a row with
the station picker, Next song and Favorite songs. Playback, progress, times and
volume occupy the row underneath. Both icon-only hearts are circular; the
visualizer heart sits closer to its title. Studio retains its library and style
controls. The shared release version remains 1.1.5; only Vision's independent
build number advances to 12.

## Verification

- Both targeted native simulator UI tests passed with normal `TEST SUCCEEDED`
  completion: 2 tests, 0 failures, 129.217 seconds. They cover Radio playback,
  song favorites and station selection, random visualizers without stopping
  playback, and the new layout.
- Layout assertions check the workspace switch stays within 2 points of its
  original position across mode changes, visualizer controls sit above the
  preview, the heart bounds are square within 3 points, the visualizer
  title-to-heart gap is under 32 points, and the song-row centers align within
  4 points. Radio has no visualizer browser or style sliders.
- The actual simulator layout was visually inspected and captured. A physical
  headset installation, interaction and sustained-performance test was not run.
- Device archive and distribution export succeeded. The actual extracted IPA
  passed version/build, icon, resource, signing-team/profile and strict code
  signature checks. It contains 336 native effects and no external engine or
  catalog. Debug capture hooks are absent from the release executable.
- Apple validation and upload succeeded without errors. Processing is `VALID`;
  fresh API reads confirm `IN_BETA_TESTING`, exact English tester notes and
  membership in the existing internal group. All 27 previous group builds were
  retained; the group now has 28 builds.
- Vision 1.1.5 remains `PREPARE_FOR_SUBMISSION`. Mac 1.1.4 remains
  `WAITING_FOR_REVIEW`. No public App Review or external beta submission was
  made, and no build was expired or removed.

## Local evidence

`/Volumes/Music/Codex Media/PulseCanvas Studio/Platform Builds/1.1.5-12/`

- IPA: `vision-export/PulseCanvas Vision.ipa`, 10,759,017 bytes
- SHA-256: `edb6be9cae9a96aef9ec3a1f2144073fd5b997935e7a44ffadc8022051a29750`
- Apple delivery/build ID: `1f51a7aa-9dfb-44f7-a4fd-f220dfc9404a`
- `artifact-receipt.json`, archive/export/validation/upload/processing logs,
  testing-state and notes readbacks, and before/after group snapshots are local
  and excluded from Git.
- Actual UI proof: `radio-layout-simulator.png` and `radio-layout-detail.png`.
