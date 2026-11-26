# Historical 100-effect Metal development snapshot

**Superseded on 2026-10-13.** Copied legacy implementations and imported effects are now withdrawn; 100 additional original designs are in progress. See [ORIGINAL-VISUALS-EXPANSION.md](ORIGINAL-VISUALS-EXPANSION.md) for current counts, verification and remaining work. The results below describe the preceding snapshot.


Checked on 2026-10-12 in the main PulseCanvas checkout. The development catalog contains **100 native effects**, with unique names, icons and stable `native:0`–`native:99` identities. This is uncommitted, unsigned development work. The uploaded 1.0.2 (10) build still contains 31 effects; see [DISTRIBUTION.md](DISTRIBUTION.md). No installation, signing, upload or release was performed for this expansion.

## Designs and compatibility

IDs 0–30 retain their names and saved-project identities. IDs 31–99 provide 69 additional designs across flowing surfaces, organic forms, sculptural geometry, reflective environments, light, particles, waves and connected tunnels. The `NativeEffects` registry supplies default profiles, labels, icons and shader families. Saved styles take precedence over defaults.

Studio, preview and export use the same shared appearance profiles. Explicit native identities preserve the old 31-effect external-index boundary, so older projects do not silently reinterpret external presets as new native designs. The full-library edition and its original preset/texture provenance remain separate. These changes do not remove existing licensing obligations or unresolved permissions.

## Audio and motion

The soundtrack analyzer computes source-time four-band envelopes and swell. Native visual response uses those values rather than accumulating smoothing from previously rendered frames. Chaos scales audio-driven levels and the music clock. Setting Chaos to zero also clears a retained live music-clock offset; procedural animation and configured zoom remain active.

The expanded designs use local changes in surfaces, waves, cells and particles. Arc Foundry and Fractal Canopy use the shared continuous zoom pass. Arc Foundry has continuous source illumination and fading recycled sparks. Neon Calligraphy rejects invisible stroke regions before testing nearby segments.

Harmonic Trace uses a full-canvas field of layered periodic traces with faded depth transitions. Ring Shepherds keeps its planetary reference fixed while the camera travels. Gyroscopic Garden evaluates neighboring gimbals as a union and maintains clearance above the outer rings, avoiding the large foreground-ring dropout seen in its lower camera path.

The original mesh pass uses explicit triangle normals rather than fragment derivatives. Its targeted regression completed 7,200 GPU frames with identical music/silence/repeated-silence pixels at zero Chaos.

## Verification

These are bounded checks on the development Apple M3 Max, not guarantees for every GPU, timestamp, combination of controls or released binary.

| Check | Verified scope |
| --- | --- |
| Catalog and migration | 100 uniquely named native effects; original native identities, legacy external indices, saved styles, favorites and timelines preserved |
| Source-time audio | 200 scene/orientation checks with actual audio: deterministic seeks, trim/fps invariance, history independence and zero Chaos |
| Canvas coverage | All 100 designs in five shapes at three song positions: 1,500 checks, each with at least 14/16 lit canvas cells |
| Distinctness | All 4,950 pairs under the same palette and controls; closest mean RGB difference 11.9/255 |
| Motion audit | All 100 effects over two seconds in landscape and portrait at zero/full Chaos; no near-black frames or music-driven zero-Chaos differences in these samples |
| Related depth motion | 8,640 actual 30/60fps transitions for four depth styles, early/late timestamps, wide/portrait and three zoom speeds, plus sampled wrap boundaries |
| Studio exports | Three 69-second movies, each with 2,070 decoded frames at 30fps: 1280×720, 720×1280 and 720×720; soundtrack present and no black frames |
| Export agreement | One decoded/reference comparison per added effect in each shape; largest mean RGB errors 10.94, 10.26 and 11.85/255, below the unchanged limit of 12 |
| 4K export sample | 120 decoded frames at 3840×2160/60fps, with audio and three native scene switches; not an all-effect 4K export test |
| Actual app | Unsigned Release build; 100 contiguous IDs, source-matched active shader/audio hashes and application license, no external presets/engine/updater imports |
| Bundled shader execution | 600 GPU checks against the final app's own resources |
| Existing regressions | Studio persistence/shared styles and mixed projectM/Metal exports, including consecutive projectM switches at 4K60, passed |

The complete zoom suite passed after the final camera change: all 100 styles retain animation at zero zoom, change visibly at low/high zoom and restore exact framing at zero; 3,240 tunnel transitions and 8,640 related-depth transitions passed at the tested playback cadences.

## Performance and local artifacts

Completed-frame measurements earlier in the integrated run averaged 7.35 ms at 1080p and 22.44 ms at 4K; the slowest sampled 4K style took 64.25 ms. Other GPU checks overlapped some measurements. After the geometry/camera fix, Gyroscopic Garden averaged 31.35 ms across ten 4K frames. These observations do not establish real-time 4K60 playback for all styles. Offline export writes the requested frame count and frame rate.

The final app is under `.build/integrated100-store/Build/Products/Release/`. Current exports are under `.build/native-expansion/`. Logs are under `.build/validation/integrated100-*`.

The explicitly labeled development source archive and package hash receipt are under `.build/native100-development-package/`. Its archived working-tree source, active shader hashes and bundled audio were checked against the actual app. The packaged source rebuilt successfully, and its generated resource catalog and shader hashes match the tested app. This archive does not replace the committed source archive for uploaded build 10.

Run the focused checks with:

```sh
./scripts/test-store-edition.sh
./scripts/test-native-migration.sh
./scripts/test-native-source-time.sh
./scripts/test-native-expansion.sh --coverage-only
./scripts/test-zoom.sh
./scripts/test-native-expansion.sh --export-only
./scripts/test-native-export-agreement.sh
./scripts/test-surface-determinism.sh
./scripts/test-studio.sh
./scripts/test-projectm-integration.sh
```

The numeric motion audit does not constitute a full artistic review of every effect at every setting. Broader visual review and performance improvements remain useful before release. The production application and user session were not replaced.
