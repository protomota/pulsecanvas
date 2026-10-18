# Library categories and upstream audit — 2026-10-18

The Library and Studio's shared chooser now filter by **Collection → Category →
Folder**, alongside search and favorites. Native Metal effects have themes such
as Tunnels, Liquid & flow, Drive & flight, Fractal and Dancer. Community effects
retain Cream of the Crop's original categories and subfolders. The top visualizer
strip stays flat; filtering does not reorder it, change identities or alter clips.

GitHub's upstream HEAD was checked on 2026-10-18. It is still the existing pin,
[`0180df21f5e0bd39b9060cc5de420ed2f1f9e509`](https://github.com/projectM-visualizer/presets-cream-of-the-crop/tree/0180df21f5e0bd39b9060cc5de420ed2f1f9e509).
There is no newer pack revision to import.

| Accounting | Count |
|---|---:|
| Upstream `.milk` files | 9,795 |
| Bundled in Creators | 7,766 |
| Explicit exclusions | 2,029 |
| Unaccounted paths | 0 |
| Owner-reviewed rejections, all still excluded | 80 |
| Technical exclusions restored in this update | 8 |

The audit compared every bundled file's Git blob hash to the pinned upstream
tree. Original bytes, filenames, creator titles, embedded notices, the upstream
README and license text remain unchanged. The existing 7,758 catalog entries
keep their order and identities. New admissions append to that catalog.

186 candidates were screened in separate processes using real soundtrack PCM:
162 technical exclusions, twelve samples from the costly custom-shape family,
and twelve previously unaccounted paths. Owner reviews and deliberate
Core Mirror/transition exclusions were preserved. The twelve unaccounted paths
failed loading/rendering and now have retirement records.

Fifteen candidates passed 360-frame GPU runs at 720p and full HD, in landscape
and portrait. Five were then rejected by still inspection for near-solid,
washed-out or edge-only output. Two more rendered black in short consecutive
Studio MP4 sections and remain excluded. The eight admissions are:

- Volcanic Corona
- Volcanic Garden
- Fractal Lattice
- Kaleido Fold
- Lucid Array
- Astral Night
- Sublime Cavern
- Scattered Drift

Four are individually tested exceptions to the high-instance exclusion; the rest
of that expensive family remains excluded. A numerical pass alone is not a
quality endorsement. These checks do not establish compatibility with every song,
GPU, resolution or frame rate. The entire existing library was not GPU-retested.

`preset-admissions.json` records full-HD metrics and SHA-256 hashes separately
from the unchanged Finder curation receipt. `preset-manifest.json` and the
complete notice scan describe the actual bundle. `cream-library-audit.json`
records upstream accounting and rejection reasons. Regenerate that report with:

```sh
gh api 'repos/projectM-visualizer/presets-cream-of-the-crop/git/trees/0180df21f5e0bd39b9060cc5de420ed2f1f9e509?recursive=1' > /tmp/cream-tree.json
python3 scripts/audit-cream-library.py --tree /tmp/cream-tree.json --output docs/cream-library-audit.json
python3 scripts/test-preset-provenance.py
python3 scripts/preset-provenance.py
PULSECANVAS_ADMISSION_EXPORT=1 PULSECANVAS_VALIDATION_DIR='/Volumes/Music/Codex Media/PulseCanvas Studio/Validation' bash scripts/test-projectm-integration.sh
```

This is a technical library refresh. Attribution and testing do not resolve
individual preset or texture permissions. projectM and its assets remain
Creators-only; neither the Mac App Store nor visionOS target bundles them.
See the separate [provenance record](../Sources/PulseCanvas/Resources/ProjectM/Provenance.md).
