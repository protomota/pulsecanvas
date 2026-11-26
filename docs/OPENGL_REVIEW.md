# OpenGL review batches — 2026-10-14

## Media storage

Review clips, native reels and generated render archives live on the **Music** drive:

`/Volumes/Music/Codex Media/PulseCanvas Studio/Review and Renders/`

OpenGL batches are in `OpenGL-Effects-Review/`; Metal review clips are in
`Metal-Effects-Review-2026-10-13/`. Historical checkout paths link to the moved
files, preserving old receipts and commands. Source code and app builds remain
in the checkout. Original preset bytes and completed curation decisions are unchanged.

Future OpenGL batches default to that external review folder and use
`/Volumes/Music/Codex Media/PulseCanvas Studio/Render Work/OpenGL/` for scratch
files. The runner requires the Music volume to be mounted and rejects output
or scratch paths on the main drive; it does not fall back to internal storage.

From the main checkout, the next batch can be rendered with:

```sh
python3 scripts/render-opengl-review-batch.py \
  --source-root .build/local-creators-20261014 --batch 5 --count 100
```

The storage migration inventory, SHA-256 checks and Finder metadata are recorded
in `/Volumes/Music/Codex Media/PulseCanvas Studio/storage-migration.json`.

A local Creators app was built from a frozen current-source snapshot at `.build/local-creators-20261014/`. The app is `build/local-testing/PulseCanvas Studio Creators Local.app`, with 270 active native effects and all 7,838 bundled OpenGL presets. Resource bytes, preset provenance and deep/strict local ad-hoc signing were checked; the app was launched and shows 8,108 selectable visualizers. `LOCAL_BUILD` keeps the local preferences separate and disables update code without changing normal direct-release behavior. No website, App Store or TestFlight release occurred.

Batch 001 contains **100 separate ten-second, 1280 × 720 / 30 fps videos with audio**, rendered through the actual Creators engine and export pipeline. All 30,000 output frames were decoded for validation; duration, audio, file hashes and original preset hashes were checked. No hard rendering failure occurred. `0006 - Mercury Forest.mp4` is flagged as very dark but remains in the batch for human review. No preset was removed.

Review path: `/Users/brad/Documents/GIT_SOURCE/pulsecanvas-studio/.claude/worktrees/native-visualizers-100/.build/deliverables/OpenGL-Effects-Review/Batch-001/`. Existing Metal review artifacts and tags were not rewritten. The new folder is open in a separate Finder window.

The parent review README explains the red Finder-label workflow and how to resume or render Batch 002. Only a completed, explicitly authorized batch may later withdraw unmarked presets; unrendered and unfinished batches remain intact. Per-video provenance and settings are in `manifest.json` and `index.csv`. The batch runner refuses to overwrite rated clips or resume with a changed catalog. Hard shader/translator failures are isolated per process and logged, never silently pruned.

Tools: `scripts/build-creators-local.sh`, `scripts/build-opengl-review-renderer.sh`, `scripts/OpenGLReviewRender.swift`, and `scripts/render-opengl-review-batch.py`. Local app/review receipts and renderer/tool hashes are in `.build/local-creators-20261014/`. No commit or push performed.

## Completed first-batch curation

On 2026-10-14 the owner completed Batch 001 and authorized removing unmarked effects. The 62 red-labelled presets were retained; 38 unmarked preset files and catalog entries were removed from current main. The review videos, Finder tags and original frozen rendering snapshot remain unchanged. Current Creators source has 7,800 OpenGL effects; its curation manifest and notice/hash inventories document the subset. Retired identity records preserve project migration. The published website release is unchanged.

Batch 002 renders the next 100 original catalog positions from the same frozen snapshot. None of its unreviewed effects may be pruned yet.

Batch 002 completed: 100 videos (catalog positions 101–200), 30,000 decoded frames, no render failures and no very-dark warnings. File hashes, music streams and preset hashes passed. It is open in Finder. After explicit owner authorization, 38 untagged Batch 001 review videos and 144 untagged videos in the completed Metal review folder were moved to macOS Trash. All 356 tagged videos were preserved; the 100 unreviewed Batch 002 clips were excluded from cleanup. Removal receipts and recoverable Trash paths are in `.build/validation/review-video-trash-receipt.json`. The native effect catalog was not altered by the video cleanup.

## Completed second-batch curation

The owner completed Batch 002 on 2026-10-14: 78 red-tagged effects were retained; 22 unselected preset files and catalog entries were withdrawn, with retirement records for saved-project migration. Their 22 review videos were moved to macOS Trash. Tagged video bytes/tags and original rendering manifests remain unchanged. The current source/local Creators library has 7,778 OpenGL effects, while the 270 native effects and all unreviewed OpenGL effects remain intact. Provenance and migration checks passed. No commit or website release. Batch 003 continues from original catalog index 200 using the frozen rendering snapshot.

Batch 003 completed: 100 ten-second clips, original catalog positions 201–300, 30,000 decoded frames, no hard render failures. Soundtrack, preset/file hashes and packaged preset inventory passed. The refreshed local app shows 8,048 visualizers and preserves the Glass Chamber soundtrack/session. Batch 003 is unreviewed; its clips/effects are retained for the next picks.

## Completed third-batch curation

The owner completed Batch 003 on 2026-10-14: 80 red-tagged picks were retained and 20 unselected preset files/catalog entries were withdrawn, with retirement records for saved-project migration. The 20 rejected review videos are recoverable in macOS Trash. Picked video bytes/tags and the original rendering manifest are unchanged. Current source/local Creators library: 7,758 OpenGL effects and 270 native designs. All unreviewed effects remain intact. Provenance and migration checks passed; no commit or website release. Batch 004 continues from original catalog index 300 using the frozen rendering snapshot.

Batch 004 completed: 100 ten-second clips, original catalog positions 301–400, 30,000 decoded frames, no hard render failures. Audio, preset/file hashes and packaged inventory checks passed. The updated local app shows 8,028 visualizers and retains the Glass Chamber soundtrack/session. Batch 004 remains unreviewed and is preserved for the next picks.
