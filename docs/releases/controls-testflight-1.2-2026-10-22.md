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
| Mac | 5 | Three campaign images and Aurora Fold retained; redundant raw repeats removed; availability refreshed |
| Vision Pro | 6 | Immersion retained; four varied native UI captures and availability refreshed |

Each final slide reads **On all your devices.** and names **iPhone · iPad · Mac ·
Vision Pro**, with real captures of all four apps. The iOS search-results graphic
was also replaced at the owner's follow-up request, retaining its campaign design
with a preserved native purple ribbon fullscreen capture and the current LED
Corridor Studio capture, giving the two phones different visualizers. The Studio phone explicitly shows
the six controls in two aligned rows (Library / Presentation / More above Shuffle
/ Dice / Visual Style), and is labeled Studio. Its final state is
`PREPARE_FOR_SUBMISSION`, 3840 × 2560. The existing header video and all Mac/Vision
preview videos were retained. Medium iPhone sizes inherit the large group.

## Screenshot refinement

The October 22 follow-up replaces repeated featured effects across the mobile
campaign with Mercury Fold, Plasma Bore, Aurora Fold, live Radio selections,
Lotus Resonance and Orbit Loom. The six Studio controls remain visible. The opening screenshot uses glossy
liquid Mercury Fold; Studio uses the purple/cyan Plasma Bore tunnel. The iPhone
Radio image uses Wind Tunnel so the set does not feature Mercury Fold twice. Magnified
controls use full native crops with an opaque matching panel background and equal
padding on all sides (48px iPhone, 64px iPad/Duo). All Duo decorative outline
triangles and the Completely free GitHub label are removed; only the four privacy
and pricing pills remain.

All final placements completed Apple processing. File order, dimensions and file
sizes were read back through the official API. iPad delivery uses high-quality
JPEG copies (quality 97, no chroma subsampling) after PNG ingestion stalled; the
lossless originals remain preserved. No pending images remain in the final sets.

The availability montage uses Ink Bloom on iPhone, Chrome Reef on iPad, Octagon
Vault on Mac and LED Corridor on Vision Pro. Mac's redundant raw LED, Molten Glass
and Studio images were removed while their campaign versions and all preview
videos were retained. Vision now shows Mercury Fold in Studio, Prism Rain behind
Library, Candy Cathedral behind favorites and Vector Tube in Radio, alongside the
existing immersion image. The captured Halo Engine export view had a blank native
preview and was excluded from the marketing set.

The final regular iPhone campaign removes the decorative octagon outlines from
all six slides. iPad artwork remains byte-identical. Duo’s Completely free slide
now shows its actual closed outer display in a fully visible portrait frame.
The Duo availability slide uses a closed Duo Studio capture and labels both the
phone card and subtitle iPhone Duo. Other availability formats remain byte-identical.
The closed-Duo capture scenario passed; native captures are 1398×2034, display 1.

## Capture verification

- The opt-in varied mobile capture scenario passed on iPhone (176.3 seconds),
  iPad (173.8 seconds) and Duo (199.0 seconds). An initial iPad run terminated under
  concurrent simulator load; its sequential rerun passed all seven capture stages.
- Duo captures use the active inner display (--display=3), not the inactive outer
  display. The final captures use the full bundled soundtrack in isolated QA storage.
- Vision's opt-in varied capture scenario passed (62.7 seconds). Each host capture
  is acknowledged before the scenario advances.
- The focused liquid/tunnel capture scenario passed on iPhone, iPad and unfolded
  Duo. iPhone also captured live Radio with Wind Tunnel. It uses the full bundled
  soundtrack in isolated storage and actual native display captures.
- Eighteen mobile/Duo campaign renders passed bounds, decoding and equal-padding
  checks. Contact sheets and the native control crops were visually reviewed.

App Store Review was not resubmitted. All three 1.2 versions remain
**Developer Rejected**; their previous selected draft builds were left in place.
Vision Pro's live 1.1.5, Apple TV, website deployment, external beta groups and
tester membership were unchanged by this delivery.

## Evidence outside Git

Primary internal artifact folder:
`/Users/brad/Documents/Codex/2026-10-22/pulsecanvas-controls-release-rescue/`

- `art/variety/raw/`: final native captures and control crops; `art/variety/mobile/` and `art/variety/duo/`: final campaigns.
- `art/variety/all-devices/`: final availability slides and checksum manifest.
- `art/search-variety/`: final search-results image and checksum manifest.
- `delivery/testflight-delivery-receipt.json`: successful build delivery receipt.
- `delivery/screenshots-clean-closed-delivery-receipt.json`: final ordered sets after liquid/tunnel refinement.
- `art/liquid-tunnel/`: final native opening/Studio captures, crops and campaign renders; previously accepted stages are preserved.
- `delivery/ios-variety-placements-final.json`: final search-results placement readback.
- `delivery/app-store-free-no-github-proof.png`: actual saved App Store preview.
- `art/liquid-tunnel/duo-new-pair.jpg`: final liquid/tunnel comparison.
- `delivery/app-store-liquid-tunnel-proof.png`: saved App Store gallery proof.

Original archives, exports, upload logs and validation evidence remain at
`/Volumes/Music/Codex Media/PulseCanvas Studio/Platform Builds/control-release-1.2-20261022/`.
The external volume disconnected during capture work; evidence required to finish
and verify artwork was copied to the internal artifact folder. Existing build
caches and repository symlinks were preserved.

Final background/closed-device artifact folders:

- `art/iphone-clean-background/`: six cleaned iPhone slides, uploads and manifest.
- `art/closed-duo/`: native closed-Duo captures, six Duo renders, availability
  artwork, uploads and review sheet.

Uploaded-image proof:

- `delivery/app-store-iphone-clean-background-proof.png`
- `delivery/app-store-closed-duo-free-proof.png`
- `delivery/app-store-closed-duo-devices-proof.png`


## October 23 — fuller closed-Duo free artwork

Replaced the sparse Completely free composition with a two-column layout: large
closed Duo showing a full-screen Oil Marble capture, a larger headline, four
equal-size value pills, and Visualizers / Radio / 4K export highlights. A subtle
second chassis edge makes the folded form visible. The Library image is removed.
The image is the native closed outer display (1398×2034, display 1), preserved at
its original aspect ratio. Output remains 2853×2007. The other five Duo campaign
slides are byte-identical and all-device artwork is unchanged.

The focused native capture test and all six render checks passed. The renderer
checks outer-display dimensions, copy bounds and clearance, and fully visible
phone bounds. Sources, renders, JPEG, and delivery record are preserved under
`art/duo-free-hero/` and `delivery/duo-free-hero-delivery.json` in the internal
artifact folder above.

Uploaded `duo-06-free-closed-hero.jpg` to position 6 after Apple Account sign-in
was restored on October 23. App Store Connect finished processing; the official
API readback verifies filename, byte size, dimensions and all seven positions.
The other six placement and image IDs are unchanged. The prior free artwork
remains recoverable in the Asset Library. Saved browser proof:
`delivery/app-store-duo-free-hero-proof.png`.

No new app binaries or review submissions are part of this screenshot refinement.
All three 1.2 review states remain Developer Rejected.


## October 23 — recognizable folded shell and caption removal

Corrected the hardware framing on the Duo free and availability images to match
the closed Device Hub reference: straight hinge edge on the left, rounded outer
corners on the right and the outer camera cutout. The real closed-display captures
and native proportions are unchanged. Removed the device-name caption beneath
the phone on Completely free.

Uploaded `duo-06-free-folded.jpg` and `duo-07-all-devices-folded.jpg` to positions
6 and 7. Both processed successfully; API readback verified the seven-image
order, native output dimensions, file sizes and unchanged first-five placement
and image IDs. The other four availability renders and first five Duo campaign
renders are byte-identical. All three 1.2 review states remain Developer Rejected.

Evidence: `art/duo-folded-shell/`, `delivery/duo-folded-shell-delivery.json`,
`delivery/duo-folded-shell-final-placements.json`, and actual browser proof
`delivery/app-store-duo-folded-free-proof.png` in the internal artifact folder.
