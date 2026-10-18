# PulseCanvas Studio for Apple TV

The first tvOS target is a native Metal viewing app with all 336 current native
visualizers. Its full-screen canvas has a remote-driven control overlay, a
category/favorites visualizer library, hearts, randomization, palettes, Chaos,
zoom and motion controls. The included demo soundtrack works without a connection.
Music and visuals remain synchronized through the shared renderer and audio analysis.

Radio loads station names and catalog links from
<https://radio.pulsecanvas.si/stations.json>, then each station's song catalog.
No stations or song catalog are embedded in the TV app. Downloads are integrity
checked against each track's byte count and SHA-256, stored in the TV cache, and
played locally for deterministic audio analysis. Songs advance automatically;
Next song also selects another visualizer when alternatives exist. Downloads and
playback stop on backgrounding. No microphone, account, tracking or user uploads.

Use the remote's Play/Pause button for transport. Use **Visualizers** to select a
design, the heart to favorite it, **Visual style** for appearance, and **Music &
Radio** for stations. **Hide controls** shows only the picture; a directional
remote press restores the overlay. The Back/Menu button toggles the overlay.
Music uses beat-aligned visualizer scenes. The first TV target does not include
Studio timeline editing, Files import, MP4 export, or Mac project interoperability.

The minimum target is tvOS 18. The build uses the existing PulseCanvas bundle ID
`com.protomota.pulsecanvas` and App Store Connect record, with independent platform
version/build numbers. It excludes projectM, external presets/textures and Sparkle.

```sh
bash scripts/build-tv.sh appletvsimulator
bash scripts/build-tv.sh appletvos
```

For distribution, archive the PulseCanvasTV scheme. A development archive needs
a registered Apple TV. When no development device is registered, archive with
`CODE_SIGNING_ALLOWED=NO`, then export using an App Store distribution profile
for this bundle ID and your existing Apple Distribution certificate. The export
must be signed and verified before upload; an unsigned archive is not distributable.
No private keys or provisioning profiles are stored in this repository.

`verify-platform-bundle.py tv PATH_TO_EXPORTED_APP` checks actual package resources,
icons, distribution signing, privacy, license and engine exclusion. Icons are
packaged from the existing PulseCanvas mark; regenerate with
`python3 scripts/prepare-platform-icons.py` (Pillow required), then regenerate the
Xcode project. UI/remote behavior and sustained performance on hardware need owner
feedback during TestFlight testing. A simulator launch is not a hardware test.
