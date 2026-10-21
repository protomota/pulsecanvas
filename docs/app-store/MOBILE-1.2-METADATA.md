# Mobile 1.2 listing

[App Store Connect draft](https://appstoreconnect.apple.com/apps/6821642700/distribution/ios/version/inflight)

The [English copy](mobile-1.2.en-US.json) adds iPhone Duo support to the promotion
and a NEW IN 1.2 section in the description. It preserves the existing mobile
feature copy, free-use statement and PulseCanvas GitHub link.

The editable draft was already version 1.2, Developer Rejected when opened.
This work did not withdraw a review submission. Saving description and promotion
through the signed-in browser succeeded; a fresh official API read verified the
exact text. Metadata writes through the existing API key returned HTTP 403, so
that path was not used to change the listing.

The first iOS release exposes no standalone What's New field. The JSON's
`whatsNew` is prepared release-note text, not a claim that Apple's field was
populated. The saved description contains the Duo update instead.

The draft still selected the previous 1.1.6 (7) binary at verification time.
The local 1.2 (8) build is not a TestFlight upload or a review submission.
Do not submit this draft with the previous binary. Existing iPhone/iPad marketing
artwork and other platforms' build/review selections are preserved.

## Duo assets and verification

Eight actual simulator screenshots were added to the English iPhone Duo group:
four inner-display landscape captures (2853×2007) and four outer-display portrait
captures (1398×2034). They show Studio, Radio, full-screen viewing and visual
style. The captures use the bundled soundtrack and live Radio, without QA launch
fixtures. Only conversion to opaque RGB PNG was performed; there was no scaling,
mock UI or replacement of app content.

The final observed order is inner Studio, Radio, full screen, style; outer Radio,
full screen, style, Studio. The outer Studio image initially failed Apple's file
processing. Removing only its placement retained the failed asset in the Asset
Library; uploading the same validated PNG separately succeeded. Fresh API reads
confirm eight ACTIVE placements, all eight images PREPARE_FOR_SUBMISSION, valid
Duo size specifications and no placement errors. The existing API key returned
403 for uploads; the signed-in browser completed them instead.

Reviewer notes now describe 1.2 and omit the obsolete 1.1.5 (5) build reference.
Fresh API reads verified the exact promotion, description, keywords, URLs and
reviewer notes against the JSON. The shared name/subtitle, existing header/search
assets, approved iPhone/iPad artwork and other platforms were not changed.

| Saved field | Characters | Limit |
|---|---:|---:|
| Description | 2,614 | 4,000 |
| Promotion | 156 | 170 |
| Reviewer notes | 3,824 | 4,000 |
| Keywords | 82 | 100 |

Local captures, SHA-256 manifest and upload receipt are outside Git:
`/Volumes/Music/Codex Media/PulseCanvas Studio/App Store/1.2/Duo/`
and `/Volumes/Music/Codex Media/PulseCanvas Studio/Development/iphone-duo/`.
The receipt records each file's local checksum, byte count, Apple image and
placement IDs, accepted size specification and final observed order. Apple does
not expose a matching SHA-256; server verification covers filenames, byte counts,
size specifications and processing/placement states.
