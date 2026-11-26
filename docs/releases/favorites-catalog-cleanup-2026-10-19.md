# Favorites after catalog changes

Mac (App Store and Creators) and Vision Pro now refresh saved Radio songs in the
background when the main app view opens. Cleanup does not require opening Radio,
loading a song, or starting playback.

Existing behavior retained:

- Visualizer favorites are intersected with the installed edition's available
  identities during `ProjectMPresets` initialization. Removed/retired native
  effects and removed external presets are discarded, their saved appearances
  are removed, and cleanup is persisted. Backup imports cannot reintroduce
  unavailable effects. This shared library also serves Apple TV.
- Radio song favorites are reconciled against a successfully decoded complete
  music catalog, using stable song IDs. Removed songs are discarded and cleanup
  is persisted; retained songs get current metadata/catalog references. A genre
  subset is not evidence that songs from other stations were removed.
- A failed, offline, canceled or malformed catalog fetch does not erase saved
  songs. Cleanup retries on the next launch or favorites refresh. An empty valid
  complete catalog can remove all songs safely. Removing an audio object while
  leaving its entry in the catalog is a playback/download failure, not proof of
  catalog removal; remove its catalog entry to retire the song.
- Favorite songs and favorite visualizers remain separate. The TV app currently
  offers visualizer favorites, not song favorites. This task did not change the
  separate, untracked mobile work in progress.

Verification:

- `scripts/test-favorites-backup.sh`: passed in both Creators and Store modes,
  including retired/missing identities, invalid scene guards, persisted cleanup,
  backup import and recovery.
- `scripts/test-radio.sh`: passed, including a fresh-instance startup refresh
  that removes a retired song without loading Radio or playing audio, persisted
  cleanup on reopening, offline/subset preservation, and empty/broken libraries.
- `scripts/test-vision-transport.sh`: passed, including fresh-instance background
  cleanup, retaining available favorites, persisted cleanup, missing-song
  playback handling, offline preservation and empty favorites.
- Release Mac and visionOS simulator builds: both `BUILD SUCCEEDED`, exit 0.
  No signing, installation or upload was performed.

No App Store submission, website release or installed-user preferences were
changed by this task. The already-submitted build does not contain this change;
it will require a subsequent app build for the earlier startup timing.
