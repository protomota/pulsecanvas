# iPhone/iPad Home Screen name — TestFlight 1.3 (18)

Released to the existing internal TestFlight group on October 31, 2026.

The iPhone/iPad target now uses `PulseCanvas` for both `CFBundleDisplayName`
and `CFBundleName`, removing `Studio` from the Home Screen label. Simulator
screenshots confirmed that the complete name fits on both iPhone and iPad.

- Apple build ID: `b6f8fa57-9aa1-4fee-8d72-2aba7761aec7`.
- Apple processing: `VALID`; internal testing: `IN_BETA_TESTING`.
- Existing group membership verified: `PulseCanvas Mac Beta`
  (`e06555d7-c301-4fd1-9ab3-572521a25ba6`), also used by earlier mobile builds.
- TestFlight notes describe the shorter name and ask testers to check the icon
  label, launching, Settings and the supporter screen.
- Existing App Store version build selections were preserved. No App Review
  submission or public App Store release was made.

The Release archive and exported IPA passed the native-resource and onboarding
artifact checks, iPhone/iPad device-family checks, strict code-signature checks,
and distribution-profile validation. Release-only checks confirmed that debug
capture and purchase-test fixtures are absent. The exported IPA contains the
correct full display name.

Export reused the valid local Apple Distribution identity and the same manual
profile as earlier successful iPhone/iPad releases. Although named `PulseCanvas
Vision App Store`, that existing Apple profile explicitly supports iOS, xrOS and
visionOS. No certificate, account permission or security setting was changed.

IPA SHA-256:
`a363e9c23c8e61e5d38af6267335e19f38b1d4322beaff1c30845c5db595e4af`.

Artifacts and receipts are under
`/Volumes/Expand/Developer/CodexBuilds/Releases-20261031/`:

- `PulseCanvas-Mobile-Home-Name-1.3-18.xcarchive`
- `PulseCanvas-Mobile-Home-Name-1.3-18-Export/`
- `PulseCanvas-Mobile-Home-Name-18-Evidence/`

Home Screen screenshots:

- `/Volumes/Expand/Developer/CodexBuilds/PulseCanvas-Home-Name-iPhone-20261031.png`
- `/Volumes/Expand/Developer/CodexBuilds/PulseCanvas-Home-Name-iPad-20261031.png`

This change is confined to the iOS/iPadOS bundle metadata. It does not require a
Mac desktop installer or website deployment; the desktop distribution is unchanged.
