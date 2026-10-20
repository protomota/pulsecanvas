# iPhone and iPad 1.1.5 listing — saved October 20, 2026

[App Store Connect listing](https://appstoreconnect.apple.com/apps/6821642700/distribution/ios/version/inflight)
remains **Prepare for Submission**. No Add for Review or Submit for Review action
was taken. Build selection and automatic-release settings were preserved.

The [English copy](mobile-1.1.5.en-US.json) follows the live Mac listing's structure
and tone: native Metal visualizers, Radio, beat-aligned Studio, full-screen
viewing, MP4 export up to 4K60, and a COMPLETELY FREE section with the PulseCanvas
GitHub link near the bottom. It describes iPhone/iPad controls, Files import/save,
background audio, project exchange and iOS/iPadOS 18 requirements instead of Mac
windows, Finder and macOS requirements.

Public copy says **300+** to match the approved mobile artwork. The signed
1.1.5 (5) artifact receipt confirms 336 active Metal effects. The listing does not
advertise personal-folder Radio or Studio's catalog music picker, which arrived
in 1.1.6. Source availability is described without claiming an open-source or MIT
license.

## Saved and checked

| Field | Characters | Limit |
|---|---:|---:|
| Description | 2,350 | 4,000 |
| Promotional text | 154 | 170 |
| Keywords | 82 | 100 |
| Reviewer notes | 3,661 | 4,000 |

- The description and promotion were previously empty. Reviewer notes previously
  described Mac behavior. These are now populated with mobile-specific copy.
- Keywords, marketing/support URLs and copyright match the Mac listing.
- Shared name, subtitle **Music visuals, made by you**, and privacy-policy URL
  already match. Shared categories are Photo & Video and Music; no shared App
  Information change was needed.
- The first iOS version exposes no What's New field in the version-page UI;
  it was left unset. No unrelated age-rating, privacy questionnaire, pricing,
  distribution or release-setting changes were made.
- The API's metadata PATCH returned HTTP 403. Saving through the existing
  signed-in browser succeeded. Fresh official API GETs verified exact saved
  description, promotion, keywords, URLs and reviewer notes against the JSON.
- Reviewer contact/sign-in fields, build selection, version/release settings and
  the Mac listing/reviewer notes are unchanged. The approved artwork was not
  edited or committed.

Local verification snapshots, receipt and screenshot are excluded from Git:
`/Volumes/Music/Codex Media/PulseCanvas Studio/Development/app-store-media-1.1.5/`.
No app source changed, so no new app build or runtime test was required.
