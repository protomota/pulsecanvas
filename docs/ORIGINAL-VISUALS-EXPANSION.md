> Historical development snapshot. The completed main integration now has 181 reviewed Metal effects with separate Store and Creators builds; see [MAIN-INTEGRATION.md](MAIN-INTEGRATION.md). The active new-claude-visualizers worktree is excluded.

# Original visualizer expansion — 2026-10-13

The user requested removal of copied implementations and **100 additional original Metal designs**. This is active development, not a release. The uploaded build and installed production app were not replaced.

## Withdrawal audit

Twelve active styles used recovered shader functions or reconstructed reference geometry. Their numeric IDs are retired: **0, 1, 2, 3, 5, 6, 7, 8, 9, 11, 13, 14**. These were Prism Wake, Lumen Veil, Pulse Well, Velvet Passage, Facet Flow, Glass Current, Contour Flux, Recursive Corridor, Spiral Tide, Petal Passage, Vapor Run and Scatter Flight.

Additional reconstructed Swift reference fixtures, assembly/expression dumps and obsolete extraction tools have also been withdrawn from the source tree into the local audit backup.

The evidence is the explicit reconstruction descriptions in SurfaceGeometry.swift and MeshGeometry.swift, renderer routing, and the shader extraction manifest. Those geometry files, every recovered LLVM shader/module, the recovered binary shader library and unused prior shader collections have been removed from the shipping source/resources. The source backup and hashes are local under `.build/original-expansion-baseline` and `.build/validation/original-removal-audit.json`.

The app no longer exposes or loads the 7,838 external OpenGL presets or their texture pack. Historical attribution, upstream notices and provenance records are retained separately under `third_party/historical-projectm-notices`; their text was not rewritten or relicensed. Prior engine source/rebuild archives are preserved for historical distributions and excluded from current builds.

Three early styles already had independent spatial Metal implementations and remain: Bead Surge (4), Aurora Fold (10) and Pearl Terrain (12). Independently authored designs 15–99 also remain. Double Twist and Arc Spray now use a newly authored analytic ball-sprite renderer, eliminating their shared dependency on recovered shaders while retaining their geometry.

This audit describes implementation evidence and removal, not a legal clearance opinion or proof that every generic visual concept is unique.

## Identity and user data

Retired IDs are never reused. The catalog has separate active counts and identity capacity; selectors, favorites pickers, keyboard navigation and randomizers use active IDs. Old projects substitute Octagon Vault for retired or withdrawn external effects, while surviving native IDs and bar timing remain stable. Removed styles do not overwrite the substitute's saved settings.

Existing preference bytes and favorite identities remain intact. Migration keeps a copy of the original stored style data before restoring the surviving styles, writes that backup once, and suppresses persistence while restoring both editions. A direct-edition regression caught and corrected an initialization write that could otherwise replace the original preference bytes. Source/project files and soundtrack audio are not modified by migration. The installed production app and user session have not been launched or replaced.

## Additional original designs

The retained baseline is **88 effects**. The completed 100 additions produce **188 active effects**, occupying 200 stable identity slots including the 12 retirements.

Implemented: **100 of 100 additions**, IDs 100–199. These use newly authored Metal functions, the app's own math helpers and colors; they do not translate or load preset formulas, recovered shader modules or proprietary textures.

- Driving: Chromatic Speedway, Iridescent Raceway, Cobalt Catapult, Tangerine Rocket, Prismatic Overdrive, Scarlet Slipstream, Laser Autobahn, Rainbow Riptide, Electric Switchback and Disco Transit.
- Dancing: Velvet Samba, Neon Caper, Carnival Pulse, Ribbon Rumba, Elastic Jive, Liquid Tango, Prism Pirouette, Orbit Salsa, Molten Mambo and Vivid Foxtrot.

The completed additions comprise **35 driving scenes, 35 tunnel compositions and 30 dancing forms**. Additional files NativeVoyage, NativePassage and NativeFestival supply the remaining 80. Each design has its own registered shader function. Their active names, stable IDs and shader hashes are in Sources/PulseCanvas/Resources/NativeVisualizers.json.

Polar color coordinates wrap continuously; cylindrical Voronoi sites use a periodic seed domain. Depth-layer geometry and band assignments follow stable layer identities. This fixes the Arc Jetstream wrap jump detected during motion review. Glacial Sprint keeps procedural rotation with zoom off. The shared float-hash recipes were also replaced by an independently authored deterministic integer mixer. Palettes, saved parameters and effect identities remain stable; procedural site positions may differ.

## Current validation

Final native checks passed on the M3 Max development Mac:

- 188-effect unsigned Xcode Release build; actual app resource catalog, all 14 shader-source hashes and exact application-license bytes matched the working tree. No external presets, recovered shaders or OpenGL/projectM imports.
- Store and direct migration, 12 retirements, stable surviving IDs, 9,783 historical external numeric/explicit fallbacks, original session/favorite preservation, immutable backup and unavailable-ID guards. Both editions suppress persistence while restoring.
- All 188 designs passed five-shape coverage at three song positions (2,820 sampled frames) and all 17,578 pair comparisons with a shared palette. The closest pair differed by 14.6/255; this is sampled pixel distinctness, not proof of unique visual concepts.
- 376 actual-soundtrack scene/orientation checks passed for source envelopes, seeks, trim/fps invariance, audio-history independence and zero Chaos.
- Zero-Chaos isolation passed for every active style in wide/portrait at three zoom speeds with blur/strobe enabled; motion continued. Above-zero beat response passed for every style.
- The 100 additions passed landscape/phone 3-second 60fps audits at zero/full Chaos, with no isolated procedural jumps, near-black or sparse frames. Arc Jetstream's earlier wrap jump was fixed and retested.
- Zoom checks passed active-style flat/slow/fast behavior, deterministic restoration, 3,240 original-tunnel transitions and 8,640 added depth-field transitions. The runner's initial summary printed the 200-slot identity capacity; the tested loops use 188 active IDs. The summary label is corrected in source.
- Studio regression passed bars, randomizers, shared controls, selection/reveal behavior, project round-trips and persistence. Earlier failures used removed/external fixture assumptions; fixtures now exercise the active catalog.
- 1,128 offline checks passed deterministic frames, post-blur white flashes and bass rejection. Seven original geometry designs passed finite geometry, topology and audio response.
- Actual app resources rendered outside the checkout passed 3,384 music/silence comparisons in two orientations, three zoom speeds and three song positions. The harness loads the packaged resources; it does not launch or modify the installed app.
- Real-soundtrack Studio exports of all 169 designs after the legacy boundary decoded successfully in wide, phone and square: 5,070 frames per video, 30fps, 169 seconds, with audio. All 507 section samples matched GPU preview references within the compression tolerance (largest mean RGB error 11.05/255). A 3840×2160 60fps sample decoded all 120 frames with audio. These include all 100 additions.
- Synchronous offscreen timing across all 188 styles averaged 6.05ms at 1080p and 20.92ms at 4K. The slowest 4K sample was Halo Engine, 62.89ms. Pixel readback/waits are included; these measurements do not guarantee 4K60 live playback for every style or Mac.
- Soundtrack MP3, AudioController and AudioAnalysis hashes match the task-start baseline. No installed production app was launched/replaced and no user preference domain was written by the isolated test suites.

The current working-tree source archive and unsigned development app package are local under `.build/original188-development-package`. Packaging receipts record exact files/hashes and whether an archive rebuild has completed. They are not released artifacts. No signing, notarization, commit, push or App Store submission was performed.

Relevant commands: `scripts/test-original-catalog.sh`, `test-native-migration.sh`, `test-store-edition.sh`, `test-studio.sh`, `test-native-source-time.sh`, `test-chaos.sh`, `test-zoom.sh`, `test-native-expansion.sh --require-complete`, `test-native-export-agreement.sh`, `test-original-bundle.sh APP`, and `verify-original-resources.py APP`. Raw receipts and logs are under `.build/validation`.

Historical engine/recovered-geometry checks, Developer ID signing, notarization, live UI interaction, cross-machine performance, long-duration testing of every parameter combination and external releases were not run. No formal rights-clearance conclusion is asserted. Historical source/rebuild compliance and upstream notices remain intact.

## Full addition catalog

The machine-readable catalog is [original-additions.json](original-additions.json).

| ID | Design | Family |
| --- | --- | --- |
| 100 | Chromatic Speedway | Driving |
| 101 | Iridescent Raceway | Driving |
| 102 | Cobalt Catapult | Driving |
| 103 | Tangerine Rocket | Driving |
| 104 | Prismatic Overdrive | Driving |
| 105 | Scarlet Slipstream | Driving |
| 106 | Laser Autobahn | Driving |
| 107 | Rainbow Riptide | Driving |
| 108 | Electric Switchback | Driving |
| 109 | Disco Transit | Driving |
| 110 | Velvet Samba | Dancing |
| 111 | Neon Caper | Dancing |
| 112 | Carnival Pulse | Dancing |
| 113 | Ribbon Rumba | Dancing |
| 114 | Elastic Jive | Dancing |
| 115 | Liquid Tango | Dancing |
| 116 | Prism Pirouette | Dancing |
| 117 | Orbit Salsa | Dancing |
| 118 | Molten Mambo | Dancing |
| 119 | Vivid Foxtrot | Dancing |
| 120 | Fuchsia Flyway | Driving |
| 121 | Amber Aqueduct | Driving |
| 122 | Photon Overpass | Driving |
| 123 | Indigo Escalator | Driving |
| 124 | Solar Slalom | Driving |
| 125 | Glacial Sprint | Driving |
| 126 | Velvet Voyage | Driving |
| 127 | Plasma Rally | Driving |
| 128 | Crystal Causeway | Driving |
| 129 | Luminous Lift | Driving |
| 130 | Arc Jetstream | Driving |
| 131 | Ruby Rollway | Driving |
| 132 | Neon Regatta | Driving |
| 133 | Radiant Runway | Driving |
| 134 | Electric Viaduct | Driving |
| 135 | Orbit Express | Driving |
| 136 | Molten Highway | Driving |
| 137 | Violet Flight | Driving |
| 138 | Emerald Launch | Driving |
| 139 | Coral Driftway | Driving |
| 140 | Azure Ascent | Driving |
| 141 | Festival Cruise | Driving |
| 142 | Quantum Sled | Driving |
| 143 | Citrus Surge | Driving |
| 144 | Starlight Pursuit | Driving |
| 145 | Saffron Spindle | Tunnels |
| 146 | Opaline Iris | Tunnels |
| 147 | Electric Helicoid | Tunnels |
| 148 | Ultramarine Arcade | Tunnels |
| 149 | Fuchsia Furnace | Tunnels |
| 150 | Amber Aperture | Tunnels |
| 151 | Aurora Corkscrew | Tunnels |
| 152 | Prism Portals | Tunnels |
| 153 | Magenta Conduit | Tunnels |
| 154 | Verdant Spiral | Tunnels |
| 155 | Sapphire Cascade | Tunnels |
| 156 | Garnet Gallery | Tunnels |
| 157 | Luminous Nautilus | Tunnels |
| 158 | Indigo Infinity | Tunnels |
| 159 | Golden Gyre | Tunnels |
| 160 | Liquid Labyrinth | Tunnels |
| 161 | Photon Petals | Tunnels |
| 162 | Neon Needle | Tunnels |
| 163 | Celestial Coil | Tunnels |
| 164 | Chrome Comet | Tunnels |
| 165 | Candy Cathedral | Tunnels |
| 166 | Scarlet Siphon | Tunnels |
| 167 | Emerald Echo | Tunnels |
| 168 | Arctic Raceway | Tunnels |
| 169 | Plasma Passage | Tunnels |
| 170 | Violet Velocity | Tunnels |
| 171 | Tangerine Turbine | Tunnels |
| 172 | Cerulean Shell | Tunnels |
| 173 | Disco Helix | Tunnels |
| 174 | Iridescent Descent | Tunnels |
| 175 | Solar Serpent | Tunnels |
| 176 | Rainbow Reactor | Tunnels |
| 177 | Velvet Wormhole | Tunnels |
| 178 | Crystal Carousel | Tunnels |
| 179 | Neon Maelstrom | Tunnels |
| 180 | Radiant Rondo | Dancing |
| 181 | Fuchsia Fandango | Dancing |
| 182 | Satin Shuffle | Dancing |
| 183 | Chromatic Charleston | Dancing |
| 184 | Prismatic Polka | Dancing |
| 185 | Neon Bolero | Dancing |
| 186 | Pearlescent Swing | Dancing |
| 187 | Solar Sway | Dancing |
| 188 | Liquid Limbo | Dancing |
| 189 | Violet Vogue | Dancing |
| 190 | Disco Ripple | Dancing |
| 191 | Gilded Groove | Dancing |
| 192 | Aurora Waltz | Dancing |
| 193 | Elastic Anthem | Dancing |
| 194 | Crimson Cadence | Dancing |
| 195 | Sapphire Stomp | Dancing |
| 196 | Coral Crescendo | Dancing |
| 197 | Electric Encore | Dancing |
| 198 | Luminous Lockstep | Dancing |
| 199 | Festival Finale | Dancing |
