# Installer verification — 2026-10-13

Checkout: `/Users/brad/Documents/GIT_SOURCE/pulsecanvas-studio`.
Remote: `git@github.com:protomota/pulsecanvas.git`.
Starting branch: `claude/native-visualizers-100`.
Review branch: `codex/pulsecanvas-dmg-installer` (uncommitted; nothing pushed).
Read applicable `/Users/brad/AGENTS.md` and `/Users/brad/MEMORY.md`; no repository
AGENTS.md was present. Substantial existing native-development changes were retained.
Only the pre-existing signing script was edited, to embed the TIFF before signing.
All other inventoried pre-existing files retain their initial hashes.
The prior direct app is preserved at `build/direct-before-installer-20261013/`.

## Finished installer

- Signed source: `build/direct/PulseCanvas Studio.app`.
- Final compressed, signed/stapled image:
  `build/direct-distribution/PulseCanvas-Studio-1.0.2-10.dmg`.
- Final byte count: **11,048,478**.
- Final SHA-256: `d83d40624366e4587bdfc977d739dc3434523361b1d2de96bc858e0dc73673c3`.
- Apple result: **Accepted**, submission `81eea2a6-3ce2-433f-b241-aa726e9812aa`.
- Signing identity: `Developer ID Application: Protomota, LLC (22HV69L32T)`.
- Actual native Finder screenshot:
  `build/direct-distribution/PulseCanvas-Installer-1.0.2-10.png` (720 × 520).

The user created the Developer-role `PulseCanvas Notarization` team API key in
App Store Connect. Its one-time download was moved outside the checkout into a
private directory with owner-only file permissions. Credentials were validated and
stored in Keychain under `pulsecanvas-notary`. No private key or credential is
included in source, DMG, patch or verification reports.

The existing release process built and signed the app with hardened runtime and
secure timestamp. The resume path verified the exact existing signed image and
retained its valid Developer ID signature. Apple accepted it; stapling and validation
completed. Gatekeeper accepts both the DMG and its mounted app as **Notarized
Developer ID**. The final Sparkle Ed25519 signature was regenerated after stapling
and independently verified against the app's pinned public key with CryptoKit.

## Results

| Check | Result |
| --- | --- |
| Existing direct Swift build and pinned Sparkle archive hash | Passed |
| Python, shell and CryptoKit Swift syntax/type checks; diff whitespace | Passed |
| TIFF representations | Passed: 720 × 460 at 72 dpi; 1440 × 920 at 144 dpi |
| Mount actual final compressed DMG read-only | Passed |
| Correct app and real `/Applications` symlink | Passed |
| Saved 720 × 520 window at `(160, 160)`; icon view | Passed |
| 104-point icons; 15-point bottom labels; exact positions | Passed |
| No sorting; zero scroll offset; all five saved chrome flags off | Passed |
| Embedded background alias full path and exact artwork bytes | Passed |
| Root contents | Passed: only app, Applications and required `.DS_Store`; no root background |
| Mounted/source app file hashes, permissions and symlink targets | Passed for the final Developer ID signed source |
| Strict deep app signature and DMG signature | Passed |
| Original-resource/catalog/legal payload check | Passed: current 188-effect native catalog and unchanged shader hashes/license |
| Show Hidden Files enabled | Passed: exactly two Finder items; no extra background item |
| Native visual inspection of final image | Passed: default 720 × 520; complete text and readable labels; arrow, dots and footer fit; no scrollbars or clipping |
| Preserve direct bundle ID, updater URL and pinned public key | Passed |
| Apple notarization and staple validation | Passed |
| Gatekeeper DMG and mounted app assessments | Passed: Notarized Developer ID |
| Final Sparkle archive signature against pinned public key | Passed with Sparkle and independent CryptoKit verification |
| Existing public appcast retrieval | Could not verify: `https://pulsecanvas.si/appcast.xml` returned HTTP 404 |

Finder already had `AppleShowAllFiles=1`; that preference was read, never changed.
Finder retained the user's status bar, and the full artwork still fits. The screenshot
captures the actual finished installer window, opened by Finder from the final DMG.
It is not a mockup or the earlier development preview.

Machine-readable `.layout.json`, `.notarization.json`, `.release.json`, `.checks.json`
and `.update-verification.json` beside the DMG contain public verification metadata.
`installer-changes.patch` isolates this task's additions and the two-line signing
script change from unrelated work already present in the checkout.

Earlier ad hoc preview files remain under `build/installer-preview/` for provenance;
they are development artifacts and are superseded by the final image above.
No appcast or website was changed or published. No App Store release was submitted.
This installer work does not resolve licensing or other release blockers.
