# iPad onboarding and Radio layout review — October 23, 2026

Prepared for owner confirmation before another TestFlight upload. The existing
TestFlight 1.2 (11) delivery is unchanged.

## Changes

- On large iPad windows (at least 900 points on both axes), center the onboarding
  image and text together in the space between the header and navigation.
  The copy stays left-aligned and reserves the same space on every slide.
- Increase large-iPad titles from 42 to 56 points, descriptions from 17 to 24,
  lesson headings to 23, details to 20 and support notes to 18. Typography scales
  with the preferred text size and the existing fitting behavior remains active.
- Group Radio's Favorite songs, station picker and Next song controls at the
  trailing edge with eight-point gaps. The station picker keeps its natural
  width, capped for longer station names. Compact portrait Radio retains its
  separate song and station rows.
- Record the owner's requirement to show finished changes and obtain explicit
  confirmation before future TestFlight uploads or distribution in AGENTS.md.

## Verification

Native simulator checks passed for large-iPad centering, larger typography,
unchanging title/description positions across all five slides and both
orientations, swipes and short flicks, and large-text navigation. Radio checks
passed for exact eight-point action gaps in portrait and landscape, visible
controls, station fallback messaging and playback through rotation. iPhone
onboarding alignment/large-text and Radio favorites-control regressions passed.

Final iPad onboarding/Radio capture and iPhone Radio commands exited normally
with successful result bundles. Their post-test diagnostic collection stalled;
only those diagnostic collectors were stopped after all tests had passed.
Native screenshot capture uses the whole screen to avoid rotated app-only
capture artifacts. All ten iPad onboarding captures and Radio captures were
reviewed; original attachments are preserved alongside orientation-normalized
review images. No physical-device performance claim is made.

Evidence and previews are outside Git:
`/Users/brad/Documents/Codex/2026-10-23/pulsecanvas-ipad-onboarding-review/`.

No TestFlight upload, beta-group assignment or App Store review action was made
for these changes. Approval is pending.
