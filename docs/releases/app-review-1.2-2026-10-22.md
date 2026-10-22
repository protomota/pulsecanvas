# App Store Review — October 22, 2026

All three new version 1.2 builds were submitted and verified through App Store
Connect's UI and API as **Waiting for Review**. Apple approval is pending.
The existing automatic release after approval setting was retained.

| Platform | Build | Submission |
|---|---|---|
| Mac | 1.2 (29) | [Review receipt](https://appstoreconnect.apple.com/apps/6821642700/distribution/reviewsubmissions/details/a62205a1-5086-4b37-b4a4-8d08d17b994b) |
| iPhone/iPad | 1.2 (9) | [Review receipt](https://appstoreconnect.apple.com/apps/6821642700/distribution/reviewsubmissions/details/43ab74e7-fe7e-4172-b900-815ab9882e26) |
| Vision Pro | 1.2 (16) | [Review receipt](https://appstoreconnect.apple.com/apps/6821642700/distribution/reviewsubmissions/details/e8a86800-1ebf-49e5-9964-bd816cdb3ade) |

The final Mac submission replaces the withdrawn 1.1.5 (24) submission, and iOS
replaces build 8 with build 9. Vision Pro's live 1.1.5 remains available while
1.2 awaits review. Apple TV's version, build selection and review state are
unchanged. These are the same binaries already delivered to TestFlight; source
and artifact validation are recorded in [the release receipt](onboarding-1.2-2026-10-22.md).

## Public marketing copy

Public copy focuses on existing key features and contains no onboarding notes.
Mac and iOS are initial public releases and do not expose a What's New field;
their feature copy is saved as Promotional Text. Mac's description now says
300+ native visualizers to match the current library.

**iPhone/iPad:** Welcome, iPhone Duo. Explore 300+ music-reactive visuals, build
your story in Studio, enjoy Radio and export videos up to 4K60. Completely free.

**Mac:** Your music. Your visual world. Explore 300+ music-reactive visuals,
build in Studio, enjoy Radio and export videos up to 4K60. Completely free.

**Vision Pro What's New:**

Music you can step into.

Explore hundreds of music-reactive visuals, build your story in Studio, enjoy
Radio and watch in full immersion. Export your creations up to 4K60.

Completely free. No accounts or subscriptions.

## Retained assets and evidence

No marketing screenshots or previews were replaced. Mac retains seven screenshots
and three previews; iOS retains six screenshots each for iPhone Duo, 6.7-inch
iPhone and 12.9-inch iPad. Vision Pro's six screenshots and three previews were
inherited from its live version. The copied Vision screenshot filenames,
checksums and order match the originals.

Private reviewer instructions explain first launch and replay from Settings.
Existing review contact information was preserved. No credentials, accounts,
agreements or tester invitations were created.

API state/build readbacks, saved metadata and submission screenshots are retained
outside Git in
`/Volumes/Music/Codex Media/PulseCanvas Studio/Platform Builds/onboarding-1.2-20261022/review/`.
