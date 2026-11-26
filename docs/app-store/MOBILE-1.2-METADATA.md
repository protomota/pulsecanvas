# Mobile 1.2 listing

[App Store Connect version](https://appstoreconnect.apple.com/apps/6821642700/distribution/ios/version/inflight)

The [English copy](mobile-1.2.en-US.json) adds iPhone Duo support to the promotion
and an OPTIMIZED FOR IPHONE DUO section in the description. It preserves the existing mobile
feature copy, free-use statement and PulseCanvas GitHub link.

The editable draft was already version 1.2, Developer Rejected when opened.
This work did not withdraw a review submission. Saving description and promotion
through the signed-in browser succeeded; a fresh official API read verified the
exact text. Metadata writes through the existing API key returned HTTP 403, so
that path was not used to change the listing.

The first iOS release exposes no standalone What's New field. The JSON's
`whatsNew` is prepared release-note text, not a claim that Apple's field was
populated. The saved description contains the Duo update instead.

The screenshot/copy preparation originally retained the previous 1.1.6 (7)
binary. That status is superseded: iOS 1.2 (8) is now in internal TestFlight and
Waiting for Review. See [the verified release receipt](IOS-1.2-8-RELEASE.md).
Other platforms' build/review selections are preserved.

## Duo assets and verification

The initial eight plain simulator screenshots were replaced with six designed
marketing slides using the approved iPhone/iPad campaign template. Each canvas is
2853×2007, opaque RGB, with headlines, device frames and enlarged UI details.
The current inner landscape captures show the actual 1.2 (8) app: music,
Studio, visual style, Radio, Export and Library. Screens retain their original
aspect ratios, and callouts are crops of the same real UI. No QA fixtures or
generated interface elements appear in the captures.

The ordered files are `duo-01-music.png`, `duo-02-studio.png`,
`duo-03-style.png`, `duo-04-radio.png`, `duo-05-export.png`, and
`duo-06-free.png`. Their editable source and rebuild instructions are in
[`duo-marketing-1.2`](../../assets/app-store/duo-marketing-1.2/README.md).
Previous plain screenshots remain in the Asset Library; only their placements
were removed. Fresh official API reads verified six ACTIVE placements, every image
PREPARE_FOR_SUBMISSION, the correct Duo size specification, matching filenames
and byte counts, and the six-slide order. The iPhone/iPad placements were also
refreshed with the current layout on October 21, 2026. The existing header/search assets
are preserved. The artwork refresh itself did not upload or submit a binary; the subsequent
1.2 (8) release is recorded separately below.

Reviewer notes now describe 1.2 and omit the obsolete 1.1.5 (5) build reference.
Fresh API reads verified the exact promotion, description, keywords, URLs and
reviewer notes against the JSON. The shared name/subtitle, existing header/search
assets and other platforms were not changed. The approved iPhone/iPad marketing
design and copy are retained with fresh app captures.

| Saved field | Characters | Limit |
|---|---:|---:|
| Description | 2,623 | 4,000 |
| Promotion | 152 | 170 |
| Reviewer notes | 3,824 | 4,000 |
| Keywords | 82 | 100 |

Local captures, SHA-256 manifest and upload receipt are outside Git:
`/Volumes/Music/Codex Media/PulseCanvas Studio/App Store/1.2/Duo/`
and `/Volumes/Music/Codex Media/PulseCanvas Studio/Development/iphone-duo/`.
The receipt records each file's local checksum, byte count, Apple image and
placement IDs, accepted size specification and final observed order. Apple does
not expose a matching SHA-256; server verification covers filenames, byte counts,
size specifications and processing/placement states.

## Current layout screenshot refresh — October 21, 2026

All 18 English screenshot placements now show the expanded Studio workspace:
visual controls above the larger preview, playback and scene actions below it,
and bottom-aligned timeline cards. Duo uses the full-width workspace with Library
available from its header button. Radio uses its current large preview and
separate visualizer and song controls.

Six slides each cover music, Studio, style, Radio, export and free use:

| Group | Canvas | Captured source |
|---|---|---|
| iPhone Dynamic Island, large | 1320×2868 | iPhone 17 Pro Max, portrait |
| iPhone Duo | 2853×2007 | Duo inner display, landscape |
| iPad 13-inch | 2752×2064 | iPad Pro 13-inch M5, landscape |

The normal 1.2 (8) app uses its real bundled soundtrack and live Radio catalog.
`testCaptureCurrentMarketingLayout` passed on the three source device types.
The test build succeeded. All PNGs passed RGB/native canvas checks, image decode,
local SHA-256 verification and visual review. All 18 replacement placements were
verified ACTIVE with images PREPARE_FOR_SUBMISSION; ordered filenames, exact byte
sizes and accepted specifications matched. The previous placements were removed
without deleting their recoverable Asset Library images. The screenshot-refresh step did not submit a release; the subsequent
1.2 (8) release receipt records the completed submission.

Editable templates and delivered manifests:
[`mobile-marketing-1.2`](../../assets/app-store/mobile-marketing-1.2/README.md) and
[`duo-marketing-1.2`](../../assets/app-store/duo-marketing-1.2/README.md).

Current raw captures, output PNGs, contact sheets, test logs and upload receipt:
`/Volumes/Music/Codex Media/PulseCanvas Studio/App Store/1.2/Layout-refresh/`.
The receipt records every new placement/image ID, local SHA-256, byte count,
Apple specification and processing state. Older output folders are preserved.
