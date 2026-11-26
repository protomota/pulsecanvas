# User backup and restore

Local implementation for Brad's November 10, 2026 portability requirement. No commit, upload or release is implied by this document.

## In the app

- Mac: PulseCanvas Studio menu → Backup & Restore, or Settings → Your data.
- iPhone/iPad: project actions (…) → Settings → Backup & Restore.
- Vision Pro: Settings → Backup & Restore.

**Export Backup** saves one ZIP, using the platform's normal destination picker. It contains a versioned `manifest.json` plus the files required to restore the app's data. **Add project files** includes older projects saved outside the app and their soundtracks. Newly saved projects have an app-managed copy for future backups. Saved/restored projects can be reopened from this panel (or revealed in Finder on Mac).

Included: visualizer identities/favorites and their appearances; song favorites with station/catalog relationships; saved per-visualizer settings; filters, playback and export preferences; current Studio project and managed project files; imported Studio audio; personal Radio playlists/audio; Creators imported presets/textures/notices. Original imported preset bytes are unchanged. The archive does not duplicate bundled effects or demo music.

Excluded: credentials, authorization bookmarks, authentication sessions, purchase/entitlement records, unrelated system defaults, downloaded public Radio caches, generated video exports and redundant automatic favorite snapshots. Radio's public catalog and public tracks remain downloadable. No backup is sent to a server.

The app cannot discover every arbitrary project a user previously saved elsewhere. The panel explicitly asks users to add those older project files. Missing/unreadable referenced audio fails the whole export with an error rather than silently making an incomplete backup. Files up to 100 GB total and 20,000 entries are supported; JSON import is also available for the structured format used in validation. Large music payloads use ZIP rather than base64 JSON. Available disk space and the OS document provider still constrain an export or restore.

## Restore behavior

1. Validate format/version, setting allowlist/types, project/look/song models, unique paths, parent/file conflicts, entry sizes, ZIP CRCs and per-file SHA-256 hashes.
2. Ask before replacing the saved data. No settings or live model data are changed by choosing the file or canceling the confirmation.
3. Stage all files in a fresh, private storage generation. Remap project and playlist references to the restored locations, removing machine-specific authorization bookmarks. A pending marker is published only after staging succeeds.
4. On cold launch, before any app model is constructed, activate the restored settings and storage pointer with one persistent-domain write. A failed settings save restores the previous domain and retains the pending marker. Existing files and the previous generation remain intact.
5. Importing the same backup again is idempotent. A conflicting archive using an existing ID cannot overwrite that generation. Interrupted activation is replay-safe.

After confirmation the UI asks the user to close and reopen PulseCanvas. This avoids old playback/autosave models writing into a newly restored session. Full backups currently restore on their originating platform (macOS, iOS/iPadOS, visionOS); individual `.pulsecanvas` projects remain the cross-platform interchange format. Missing/retired favorites continue to use the app's existing cleanup policy.

Mac uses app-owned `Application Support/PulseCanvas/Documents`, not the user's general Documents directory. Mobile and Vision use their existing app Documents directories. After restore all these owned roots resolve under `Application Support/PulseCanvasBackups/Restores/<backup ID>`. Preferences and roots are switched together. Original external user documents are never overwritten.

ZIPFoundation 0.9.20 provides ZIP64-capable archive handling. This dependency is pinned in SwiftPM/Xcode, and its unchanged MIT license is bundled in Legal and accessible from the backup panel. It is separate from PulseCanvas's MIT license and the Creators edition's existing third-party notices.

## Checks

`bash scripts/test-user-backup.sh` builds an isolated executable on Expand. It exports JSON and ZIP with meaningful favorites, looks, a timeline, stable effect identities, a personal playlist and a real PCM WAV; removes the source workspace/audio; restores into an empty target; verifies all relationships and bytes; re-exports; tests duplicate imports, malformed JSON, unknown versions/settings, damaged hashes, duplicate/traversal paths, missing audio and invalid preference types. It also checks fresh first-run storage and that staging leaves live preferences unchanged. The test never reads or restores Brad's app data.

Build/log evidence for this change is under `/Volumes/Expand/Codex Media/PulseCanvas Studio/Development/user-backup-20261110/`. Actual final pass/fail results are recorded in `verification.md` there, not inferred from the presence of a build product.
