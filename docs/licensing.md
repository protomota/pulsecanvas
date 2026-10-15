> Historical development snapshot. The completed main integration now has 181 reviewed Metal effects with separate Store and Creators builds; see [MAIN-INTEGRATION.md](MAIN-INTEGRATION.md). The active new-claude-visualizers worktree is excluded.

# PulseCanvas licensing

Current first-party code uses the **PulseCanvas Source-Available Noncommercial License 1.0** in the root [LICENSE](../LICENSE). This is a custom source-available license, not MIT or an OSI-approved open-source license.

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
| Inspect, modify, build or share PulseCanvas code for noncommercial purposes | Allowed with retained license/notices and identified modifications |
| Sell, commercially reuse the code, distribute commercial forks, or offer a monetized hosted version | Requires separate written permission from Protomota |
| Use the unmodified official app to make commercial videos | Allowed; music, presets and other assets still need their own applicable permissions |
| Use or redistribute a third-party component commercially | Follow that component's own license; this does not automatically license the whole PulseCanvas app for commercial redistribution |
| Modify/relink the LGPL combined work for the customer's own use, including commercial own use, and debug those modifications | Required LGPL rights are expressly preserved |
| Use an earlier MIT-licensed release | Its original MIT grant remains unaffected |

The requested restriction is implemented on commercial source reuse rather than on users' video output. It is not retroactive. Third-party copyright and license notices are unchanged.

Application builds include the exact root LICENSE as `PulseCanvas-LICENSE.txt`. Both build routes include it in `Contents/Resources/Legal`; portable builds also retain the existing copy in `Contents/Resources`. Build scripts remove the obsolete `PulseCanvas-MIT-LICENSE.txt` application notice without removing third-party MIT notices. Distribution validation checks exact license bytes and the absence of the obsolete application notice.

The README and prepared source/support page copy describe the current license. The HTML source-download draft still links its historical 1.0.0 (2) archive and explicitly distinguishes that archive's MIT license from current terms. Existing historical rights-request wording is retained with a dated annotation.

Before the authorized review replacement is submitted, update any live listing/site/video copy that describes the current app as MIT or open source to say **free app, source available**. Those external surfaces were not changed by this repository update. The public website/source download must identify the applicable license per release; publishing a new source archive must not relabel older MIT archives. Destinations: https://pulsecanvas.si/source/ and https://appstoreconnect.apple.com/apps/6821642700/distribution/macos/version/inflight .

References: [OSI's commercial-use FAQ](https://opensource.org/faq#commercial) and the bundled [GNU LGPL 2.1](../Sources/PulseCanvas/Resources/ProjectM/ProjectM-LICENSE.txt), especially section 6. The application license explicitly preserves required third-party rights; this change does not establish any previously unresolved asset permissions.
