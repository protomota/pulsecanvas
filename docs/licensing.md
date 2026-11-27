> Historical development snapshot. The completed main integration now has 181 reviewed Metal effects with separate Store and Creators builds; see [MAIN-INTEGRATION.md](MAIN-INTEGRATION.md). The active new-claude-visualizers worktree is excluded.

# PulseCanvas licensing

Current first-party code is open source and dedicated to the public domain under **The Unlicense** in the root [LICENSE](../LICENSE) (since 2026-11-27; MIT from 2026-11-26).

**Separate unresolved release blocker:** [projectM's official licensing wiki](https://github.com/projectM-visualizer/projectm/wiki/projectM-Licensing#apple-store-compatibility)
explicitly states incompatibility with Apple's stores, including macOS, and
recommends standalone distribution subject to LGPL terms. Dynamic linking, an MIT
or other wrapper license, an EULA exception and a matching source archive do not
resolve that warning. This update records the warning and preserves existing
engine-source/rebuild work; it does not submit, publish or change channels.
Preset and texture permissions remain independently unresolved. The confirmed
ISOSCELES credit, upstream notices, pinned hashes and complete notice scan are
documented in [Provenance.md](../Sources/PulseCanvas/Resources/ProjectM/Provenance.md).

| Activity | Permission under the application-code license |
|---|---|
| Inspect, modify, build, share, sell or commercially reuse PulseCanvas first-party code | Allowed; the Unlicense places it in the public domain |
| Use the official app to make commercial videos | Allowed; music, presets and other assets still need their own applicable permissions |
| Use or redistribute a third-party component | Follow that component's own license; the Unlicense on PulseCanvas code does not relicense it |
| Modify/relink the LGPL combined work, including for commercial own use, and debug those modifications | Required LGPL rights are expressly preserved |

Third-party copyright and license notices are unchanged.

Application builds include the exact root LICENSE as `PulseCanvas-LICENSE.txt`. Both build routes include it in `Contents/Resources/Legal`; portable builds also retain the existing copy in `Contents/Resources`. Build scripts remove the obsolete `PulseCanvas-MIT-LICENSE.txt` application notice without removing third-party MIT notices. Distribution validation checks exact license bytes and the absence of the obsolete application notice.

The README and prepared source/support page copy describe the current license. The HTML source-download draft still links its historical 1.0.0 (2) archive and explicitly distinguishes that archive's MIT license from current terms. Existing historical rights-request wording is retained with a dated annotation.

Live listing, site and video copy should describe the app as **free and open source, public domain (Unlicense)**. Publishing a new source archive must still identify the license per release.

References: [OSI's commercial-use FAQ](https://opensource.org/faq#commercial) and the bundled [GNU LGPL 2.1](../Sources/PulseCanvas/Resources/ProjectM/ProjectM-LICENSE.txt), especially section 6. The application license explicitly preserves required third-party rights; this change does not establish any previously unresolved asset permissions.
