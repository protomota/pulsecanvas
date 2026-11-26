# Main reconciliation — 2026-10-14

Main is based on `origin/main` at `2c4bdd7e33c2e1033e4073b48b08bca6ee7e6c53`. The redundant staged integration was backed up and cleared without committing it. The full original staged/unstaged patches, index, and 300 affected file snapshots are preserved at `/Users/brad/Documents/Codex/2026-10-14/pulsecanvas-main-reconcile/`. A local `codex/before-upstream-sync-20261014` branch retains the previous main HEAD.

The reviewed upstream registry and every `NativeExpansion*.metal` file match the new remote exactly. There are **270 active native designs in 390 permanent slots**, including the 10 fractals, 20 second versions and final designs 300–309 and 314. Existing IDs and retirement choices were preserved. The generated native resource manifest was regenerated from this registry. Earlier local visual versions remain in the backup and were superseded by the reviewed upstream versions.

Unique local release/signing helpers (including `scripts/verify-update-signature.swift`), source/export timing checks, Studio migration backup, feedback click state, App Store marketing assets and submission receipt remain uncommitted. Mesh rendering combines upstream smooth normals with deterministic triangle normals for the faceted fallback, preserving both lighting fixes. Both separate worktree directories were left intact. No user soundtrack, session, presets, review clips or Finder labels were changed.

The actual packaged **TestFlight 1.0.3 (13)** app still contains **240 active designs in 360 slots**. It is not the new main. Its built resource catalog was inspected directly rather than using an earlier source-side generated catalog. Main adds 30 active designs and updated versions of existing designs. A fresh binary/build number is required before testers can see those changes. No new build was uploaded during reconciliation.

Validation results are recorded under `.build/validation/main-reconcile-20261014-final/`; the reconciliation receipt is in the backup folder. Final `swift build`, whitespace checks and seven of eight principal checks passed: feedback state, native migration, soundtrack source timing, surface determinism, Store isolation/270 GPU styles, complete native coverage/Studio exports and export feedback. The fresh wide, phone and square validation exports each decode 7,590 frames with audio; the short 4K60 export decodes 120 frames. Zero-Chaos surface checks completed 7,200 byte-identical GPU frames.

The first preview/export agreement attempt read previous-catalog videos and failed timing. After generating matching videos, its rerun still fails one strict RGB comparison: Feather Vault (native:311), wide frame 5265, mean RGB difference 13.33898 versus a threshold of 12. A focused four-frame direct Metal/encoder-surface comparison at that timestamp and resolution passes byte-for-byte with representative music, blur and strobe. The decoded-video discrepancy remains recorded for follow-up; no claim of a fully passing suite is made. Full historical tests, fresh signed packaging and a new TestFlight upload were not performed.

The retained Sparkle signature helper verified the existing Creators 1.0.4 (14) DMG against its local release feed/public key. No Git commit or push was performed.

## Earlier integration record (historical)

# Completed native worktree integration into main

The completed native-visualizers-100 worktree and the primary checkout’s loose changes are consolidated on main. The active new-claude-visualizers branch/worktree is explicitly excluded at Brad’s request. Its ongoing edits remain intact there. The subsequent completed review promotes 59 designs from the frozen source that generated the review videos, without merging that active branch.

The earlier combined handoff contained 285 offered native effects. The owner’s red-label review kept 181 and withdrew 104 unmarked designs. The first selection had 300 permanent ID slots: 181 active, 119 retired. The completed second review promotes 59 designs and withdraws unmarked 324 Hanging Mobile, giving 360 permanent slots: 240 active, 120 retired. The current worktree implementation and previously recorded mapping of unpublished main IDs 100–199 to combined IDs 200–299 are preserved. No additional renumbering, restoration of unmarked effects, or new visualizers occurs here.

The integration retains curation, music coupling, palettes, tearing fixes, full-library/Store migration, ProjectM resources and provenance, Sparkle direct-release tooling, marketing assets and experiments from completed work. Main-specific deterministic triangle normals and installer artwork/DMG packaging remain included. The main checkout and worktree inputs were backed up before consolidation. User projects, presets, soundtrack files, session data, review videos and Finder labels are not rewritten.

The Store build excludes projectM, imported presets/textures and Sparkle; the Creators build retains the original library, its separate notices and corresponding engine-source/rebuild work. Attribution and source availability do not resolve the upstream Apple-store warning for projectM or unresolved asset permissions.

Published Creators 1.0.3 (11) and TestFlight 1.0.3 (12) contain the 181 reviewed selections. Source configuration now records 1.0.3 (13) for the requested 240-effect TestFlight build. App Review submission is outside this task.

Old main-only OriginalCatalog/OriginalBundle validation tools describe a preceding native-only development snapshot. They remain preserved as historical tools; current native catalog/migration/artifact validation supersedes that contract. Historical documentation has been labeled to avoid mistaking older counts for the active catalog.

Validation results live in the integration receipt and logs. The review previews for IDs 300–359 remain unchanged in the owner’s review folder. Only red-tagged designs are promoted from their captured source. No unreviewed effect has been removed from its worktree.

No commit or push occurs without Brad’s approval, per /Users/brad/AGENTS.md and HANDOFF-merge-prompt.md.
