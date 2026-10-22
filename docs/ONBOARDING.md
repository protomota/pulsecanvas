# PulseCanvas onboarding

The first launch opens five onboarding pages in the main app surface on macOS,
iPhone/iPad (including Duo), tvOS, and visionOS. It never opens a sheet or popup.
Completing or skipping saves `PulseCanvas.onboarding.completed.v1` locally.
Settings includes “Welcome to PulseCanvas Studio”, matching Jotley’s
“Welcome to Jotley” label. Mac Help also retains a convenient entry point. Replay preserves the externally
owned project/editor models. The direct Mac edition uses the same shared view.

1. Welcome: included music and Radio; how music drives visuals.
2. Visualizers: library, categories, hearts, palettes, motion and Chaos.
3. Studio: soundtrack, scene assignments and bars; TV instead teaches Radio.
4. Play and share: full-screen viewing and platform-specific export instructions;
   TV teaches remote controls and Vision teaches immersion.
5. Optional support: Buy Me a Coffee and App Store rating, with a separate finish
   button. Support actions never complete or gate onboarding.

Coffee actions go directly to https://buymeacoffee.com/protomotalab. The existing
App Store storefront policy is preserved. TV presents a QR code for the selected
support destination. Other platforms open the destination in their browser.

## Design and artwork

Owner-supplied plum background (#322C37), sampled directly from the supplied
color swatch; peach controls (#F2AD8C) and white text with strong contrast. The editor theme is unchanged. Rounded system display
headings and native body text. Wide windows place the illustration beside the
copy; narrow windows stack them. Every page fits without scrolling. Artwork, typography and spacing adapt to short windows. A single-pass measured fit keeps
lesson content within its available space; a horizontal footer frees room in
phone landscape. Onboarding uses a bounded Dynamic Type range to keep every
page visible, with the full text available to VoiceOver. Reduced Motion disables
page transitions. Controls and step status have accessibility identifiers.

The header uses the original violet octagon branding from
`assets/app-icon/PulseCanvas-Octagon.png`, not an SF Symbol substitute.

The five illustrations ship as true RGBA PNGs under
`Sources/PulseCanvas/Resources/Onboarding/`. Created with the built-in imagegen
tool, then edited with `transparent_background: true`. No background color or
edge mask is applied in the app. Original draft JPEGs stay in the ignored local
review folder and are not bundled.

Prompt set: premium tactile 3D editorial illustrations in peach/coral and lilac
glass, brushed metal details, soft cinematic lighting, no text or logos:

- welcome: flowing iridescent ribbon loop around a musical waveform and particles.
- visuals: overlapping glass tiles with particles, liquid folds and a tunnel, plus
  a small heart.
- studio: four glass scene blocks along a glowing waveform with a beat playhead.
- share: landscape, portrait and square visual canvases with an upward arrow.
- support: ceramic coffee cup, translucent star and heart, musical steam.

Final edit prompt: remove the entire dark backdrop and floor; preserve the
central objects, composition, warm light, particles and details; keep glows with
semitransparent alpha, make empty space between objects transparent; no backdrop,
opaque haze, baked checkerboard or text.

## Local verification

All four Xcode app targets build locally. `scripts/test-creator-engagement.sh`
checks the direct coffee URL and the existing storefront/engagement rules in
both Store and direct modes. `PulseCanvasOnboardingUITests` covers five pages,
Back, finish, replay from Settings, skipping, landscape, larger text and the
absence of scroll views. Screenshot capture
uses Debug-only `-PCOnboardingQA -PCOnboardingStep 0…4`; fixture launches using the
existing QA flags bypass first launch unless onboarding QA is explicitly enabled.

Screenshots and local simulator results live in ignored `build/onboarding-review`.
No archive, App Store upload, TestFlight delivery, or website deployment is part
of this change. Release build numbers are unchanged.
