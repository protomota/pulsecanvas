# Palette accents — simulator review, October 21, 2026

The shared palette stops now include two contrasting accents alongside three
stops from the palette's main color family. Names and integer IDs are unchanged,
so saved projects and favorites continue to resolve the same palettes. Existing
CPU interpolation and Metal interpolation blend the stops; shader uniforms stay
at five stops. Electric Candy's stops are unchanged.

| Palette | Main family | Accents |
|---|---|---|
| Ultraviolet | Violet/lilac | Coral, mint |
| Emberlight | Red/orange/gold | Rose, turquoise |
| Blue Hour | Blue | Aqua, amber |
| Fernlight | Emerald/green/lime | Peach, lavender |

These shared values feed the Mac, mobile and Vision renderer and palette UI.
The mobile Debug 1.2 (8) simulator build succeeded and was installed/launched on
PulseCanvas Duo QA. Visual style is open for manual review. No version/build
number was bumped and no TestFlight upload or App Store submission was made;
Brad requested simulator testing first.

Validation:

- `native-gallery palcheck --size 180x120`: PASS, 1,680 distinct actual GPU outputs
  across all 336 active effects and all five palettes.
- Four representative effects (Aurora Fold, Pearl Terrain, Octagon Vault,
  Event Horizon) rendered with each palette and visually reviewed. Electric Candy
  PNGs matched the pre-change baseline byte for byte on those four effects.
- Live Duo preview shows the revised Blue Hour accents. The existing tests'
  monochromatic frame-average constraints were removed because an individual
  frame can intentionally emphasize an accent. Distinct-palette output checks
  remain; `palcheck` now fails if any effect ignores palette selection.
- `git diff --check`: PASS. The full audio-sync suite, physical-device testing
  and Mac/Vision builds were not run for this simulator preview.

Local captures, palette comparison sheet and validation logs are outside Git:
`/Volumes/Music/Codex Media/PulseCanvas Studio/Development/palette-accents/`.
