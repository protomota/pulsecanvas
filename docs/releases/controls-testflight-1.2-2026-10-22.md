# Controls update — TestFlight and store artwork

Completed October 22, 2026. Release application source: `67405e1`.

## TestFlight

| Platform | Version / build | Processing | Internal testing |
| --- | --- | --- | --- |
| iPhone, iPad, Duo | 1.2 (10) | VALID | IN_BETA_TESTING |
| Mac | 1.2 (30) | VALID | IN_BETA_TESTING |
| Vision Pro | 1.2 (17) | VALID | IN_BETA_TESTING |

Signed distribution archives and exports passed package verification and Apple's
upload validation. All three uploads completed. The builds were added to the
existing **PulseCanvas Mac Beta** internal group; its 47 prior builds were retained.
English tester notes remain short, feature-focused marketing copy.

- [Mobile build](https://appstoreconnect.apple.com/apps/6821642700/testflight/ios/b39be17f-d514-4da0-a8cf-5cab4111ee5f)
- [Mac build](https://appstoreconnect.apple.com/apps/6821642700/testflight/macos/572913ca-6300-4883-9250-a3088d803fe8)
- [Vision Pro build](https://appstoreconnect.apple.com/apps/6821642700/testflight/visionos/4f16f374-195e-431b-a62e-da4f87ef0fb3)

## App Store artwork

English (U.S.) version 1.2 screenshot placements were saved through App Store
Connect's web uploader. The existing API key permits readback and TestFlight
management, but screenshot writes returned 403; those failed API attempts did
not change placements. Final API readback verified file names, order, dimensions,
processing state and local/uploaded file sizes.

| Screenshot group | Final count | Change |
| --- | --- | --- |
| iPhone large Dynamic Island | 7 | Six current campaign images plus availability slide |
| iPad 13-inch | 7 | Six current campaign images plus availability slide |
| iPhone Duo | 7 | Six current campaign images plus availability slide |
| Mac | 8 | Existing seven retained; availability slide appended |
| Vision Pro | 7 | Existing immersion image retained; five native UI captures refreshed; availability slide appended |

Each final slide reads **On all your devices.** and names **iPhone · iPad · Mac ·
Vision Pro**, with real captures of all four apps. The iOS search-results graphic
was also replaced at the owner's follow-up request, retaining its campaign design
with current fullscreen and Studio captures. The Studio phone explicitly shows
the six controls in two aligned rows (Library / Presentation / More above Shuffle
/ Dice / Visual Style), and is labeled Studio. Its final state is
`PREPARE_FOR_SUBMISSION`, 3840 × 2560. The existing header video and all Mac/Vision
preview videos were retained. Medium iPhone sizes inherit the large group.

## Capture verification

- iPhone and iPad current marketing-layout capture scenarios passed.
- Duo's current capture scenario passed, six stages, 151.3 seconds. Capture the
  active inner screen with `simctl io <UDID> screenshot --display=3`; the default
  outer screen can be inactive/black. Final images were visually checked after
  correcting this simulator capture issue. The Studio timeline retains the QA
  simulator's short existing project; these are native app pixels.
- Vision's opt-in current-store-layout test passed, five stages, 249.8 seconds.
  An optional acknowledgment directory holds each stage for its native screenshot.
- Campaign contact sheets, individual availability slides and uploaded artwork
  were visually reviewed. Layout renderers check decoded images and bounds.

App Store Review was not resubmitted. All three 1.2 versions remain
**Developer Rejected**; their previous selected draft builds were left in place.
Vision Pro's live 1.1.5, Apple TV, website deployment, external beta groups and
tester membership were unchanged by this delivery.

## Evidence outside Git

Primary internal artifact folder:
`/Users/brad/Documents/Codex/2026-10-22/pulsecanvas-controls-release-rescue/`

- `art/raw/`: native captures; `art/mobile/` and `art/duo/`: rendered campaigns.
- `art/all-devices/`: five availability slides and checksum manifest.
- `art/search-six-controls/`: final search-results image and checksum manifest.
- `delivery/testflight-delivery-receipt.json`: successful build delivery receipt.
- `delivery/screenshots-delivery-receipt.json`: all five final ordered sets.
- `delivery/ios-six-controls-placements-final.json`: corrected search-results placement readback.
- `delivery/app-store-search-proof.png`, `app-store-all-devices-proof.png`: web proof.

Original archives, exports, upload logs and validation evidence remain at
`/Volumes/Music/Codex Media/PulseCanvas Studio/Platform Builds/control-release-1.2-20261022/`.
The external volume disconnected during capture work; evidence required to finish
and verify artwork was copied to the internal artifact folder. Existing build
caches and repository symlinks were preserved.
