# PulseCanvas iCloud sync

Local implementation for macOS (Metal and Creators), iPhone/iPad and visionOS.
No tvOS target. This does not upload or release a build.

## User experience

- Mac: **PulseCanvas Studio → Settings → iCloud**.
- iPhone/iPad: **Project actions (•••) → Settings → iCloud**.
- Vision Pro: **Information → iCloud**.
- Off by default. Enabling asks before merging favorites/looks and uploading saved
  projects with their soundtracks. Use the same Apple Account on every device.
- Favorites include their saved appearances. Public Radio song favorites and saved
  per-effect looks sync. Unsupported designs are ignored on editions that cannot
  render them; that device cannot remove another edition's favorites.
- Explicitly saved/imported projects appear in **iCloud projects**. Open downloads
  the project and audio into local storage. Unsaved live timelines are not replaced.
- Audio is content-addressed separately: changing a visual control does not upload
  another soundtrack object. Opening a project verifies both hashes and sizes.
- Personal Radio albums, authorization bookmarks, volume, playback, cached Radio
  downloads, purchases and support clicks stay on each device. User ZIP backups
  remain a separate feature. A full backup restore switches sync off until re-enabled.
- Turning sync off keeps local data and existing cloud copies. Removing an iCloud
  project removes its synced list entry; existing local files remain available.
- Account changes stop sync and require confirmation before merging with another
  account. Corrupt local sync history fails closed and is preserved for recovery.

## Storage and conflict behavior

Shared native iCloud Documents container: `iCloud.com.protomota.pulsecanvas`.
There is no CloudKit schema, public database, custom server or third-party sync SDK.

```
PulseCanvasData/Changes/<event UUID>.json   immutable per-item changes/tombstones
Documents/Projects/<SHA-256>.json         sanitized portable project metadata
Documents/Audio/<SHA-256>.audio           original soundtrack bytes
```

These are internal app documents, not a Finder-visible project browser. Access uses
NSMetadataQuery, on-demand ubiquitous downloads and NSFileCoordinator. Change
metadata is private to the user's container. Device bookmarks and original audio
paths are stripped before upload. The soundtrack filename is preserved in metadata.

The local `Support/CloudSync/state.json` stores device identity, pending writes,
last local snapshots and project revision bases. It is not synced or included in
user backups. Empty/partial downloads never mean "delete everything". A removal
requires a tombstone derived from the preceding local snapshot and edition scope.
Children wait for their parent event before application. Favorite/look conflicts
use logical sequence plus stable device/event ordering. Concurrent project revisions
keep a deterministic conflict copy. A local file's base remains the last revision
opened on that device, even when a newer cloud head arrives during editing.

Changes debounce for two seconds and retry every 30 seconds while the app runs;
query updates also trigger checks. Status means files were saved into iCloud Drive,
not that a second device has acknowledged receipt. Apple controls transfer timing.
Background synchronization while the app is suspended is not implemented.
Deleted/obsolete immutable audio/project objects are retained; automatic cloud
storage compaction is not implemented. Deleting a list entry does not reclaim them.

## Apple configuration required before shipping

November 10, 2026: the owner approved registering the shared container and assigning
it to `com.protomota.pulsecanvas`. Both operations completed in Apple Developer;
reopening the App ID verified iCloud enabled and exactly that container selected.
Existing provisioning profiles need regeneration following this capability change.
Real account-to-account-device transfer and the requested proof recording remain
unverified pending test-device sign-in. No build was distributed.

These account changes and real-device acceptance are **not verified by local
unsigned builds**. Do not advertise sync as shipped or release until completed.

1. Open [Apple Developer Identifiers](https://developer.apple.com/account/resources/identifiers/list).
   Select the Protomota team. Filter **iCloud Containers** and register
   `iCloud.com.protomota.pulsecanvas` if it does not already exist. Do not create a
   second container for each platform.
2. On that same page, filter **App IDs**, open `com.protomota.pulsecanvas`, enable
   **iCloud → iCloud Documents**, choose the shared container and save. Associate
   every release App ID used by the supported targets with that same container.
   Do not enable a differently named container just to satisfy signing.
3. Open all three Xcode projects. In each app target's **Signing & Capabilities**,
   choose Protomota and automatic signing. Verify iCloud Documents and that container.
   The checked-in platform entitlements and project generators declare them.
4. Regenerate/download distribution profiles at
   [Apple Developer Profiles](https://developer.apple.com/account/resources/profiles/list).
   For Creators, create a **Developer ID** profile for the exact release bundle ID
   with this container. The ad-hoc Creators Local build cannot use iCloud.
5. Creators release signing now requires `PULSECANVAS_ICLOUD_PROFILE` pointing to
   that local `.provisionprofile`. `scripts/sign-direct-release.sh` validates its
   expiry, team, distribution type, exact bundle ID and capabilities, embeds the
   profile, updates container Info metadata and signs the outer app with the
   required entitlements. Missing/incorrect profiles stop signing. Keep the profile
   and generated entitlements in the external build folder, outside Git.
6. Inspect the actual signatures with `codesign -d --entitlements :- <app>` and
   `security cms -D -i <embedded profile>`; verify the shared container and matching
   team/application identity. Do not infer working iCloud from a successful compile.
7. Test two signed devices with the same Apple Account and iCloud Drive enabled.
   Add a favorite/look/song on A, observe it on B, remove it offline on B, reconnect
   and verify A. Save a project with a personal soundtrack; open it on a fresh B
   without the original file, verify cuts/looks/audio and playback. Edit that
   project offline on both devices and verify both revisions survive. Test
   account sign-out/change, unavailable storage, low quota and turning sync off.
   Verify Creators-only favorites survive opening the Metal editions.
8. Review public privacy/App Store copy for optional Apple-hosted user-content
   synchronization before a release. Keep the current release untouched until Brad
   approves the finished build and upload explicitly.

Apple references: [Configuring iCloud services](https://developer.apple.com/documentation/xcode/configuring-icloud-services/),
[Synchronizing documents](https://developer.apple.com/documentation/uikit/synchronizing-documents-in-the-icloud-environment),
[macOS supported capabilities](https://developer.apple.com/help/account/reference/supported-capabilities-macos).

## Local verification

Run `bash scripts/test-cloud-sync.sh` for causal merges, explicit deletions,
edition scope, restart persistence, conflict copies, payload validation and project
plus exact soundtrack round trips. `bash scripts/test-cloud-app-data.sh` exercises
the actual favorites, Studio and Radio models in both Mac editions, immutable
coordinated file operations and corrupt-history preservation. Fixtures/output go
to `/Volumes/Expand/Codex Media/PulseCanvas Studio/Development/icloud-20261110`.
These tests do not sign in to an Apple Account or demonstrate a cloud transfer.

Also build all supported targets and run backup/favorites/Radio/Vision interchange
regressions. Record results and limitations with the specific source used; build
artifacts and test logs remain outside Git.
