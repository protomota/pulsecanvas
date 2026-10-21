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

The initial eight plain simulator screenshots were replaced with six designed
marketing slides using the approved iPhone/iPad campaign template. Each canvas is
2853×2007, opaque RGB, with headlines, device frames and enlarged UI details.
Inner landscape and outer portrait captures show the actual 1.2 (8) app: music,
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
and byte counts, and the six-slide order. All twelve existing iPhone/iPad
placements are identical to the pre-upload snapshot. The existing header/search assets
are preserved. No review submission or binary upload is part of this change.

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

The replacement marketing set, contact sheet, local source/output SHA-256 manifest
and server placement verification are in:
`/Volumes/Music/Codex Media/PulseCanvas Studio/App Store/1.2/Duo-marketing/`.
