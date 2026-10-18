#!/usr/bin/env python3
"""Account for the pinned upstream tree and verify every bundled Git blob."""
import argparse
import collections
import hashlib
import json
from pathlib import Path

root = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--tree', type=Path, required=True, help='GitHub recursive Git tree JSON at the pin')
parser.add_argument('--output', type=Path, required=True)
args = parser.parse_args()
assets = root / 'Sources/PulseCanvas/Resources/ProjectM'
tree = json.loads(args.tree.read_text())
manifest = json.loads((assets / 'preset-manifest.json').read_text())
assert tree['sha'] == manifest['upstreamCommit'] and not tree.get('truncated')
upstream = {x['path']: x['sha'] for x in tree['tree'] if x['type'] == 'blob' and x['path'].endswith('.milk')}
catalog = json.loads((assets / 'catalog.json').read_text())
retired = json.loads((assets / 'retired-presets.json').read_text())
active = {x['path'] for x in catalog}
excluded = {x['id'].removeprefix('projectm:') for x in retired}
assert len(upstream) == 9795 and len(active) == len(catalog)
assert active.isdisjoint(excluded) and active | excluded == set(upstream), 'Upstream accounting differs'
for path in active:
    raw = (assets / 'Presets' / path).read_bytes()
    git_blob = hashlib.sha1(b'blob ' + str(len(raw)).encode() + b'\0' + raw).hexdigest()
    assert git_blob == upstream[path], f'Changed upstream bytes: {path}'
for local, original in [('Preset-README.md', 'README.md'), ('Preset-notice.md', 'LICENSE.md')]:
    raw = (assets / local).read_bytes()
    blob = next(x['sha'] for x in tree['tree'] if x['path'] == original)
    assert hashlib.sha1(b'blob ' + str(len(raw)).encode() + b'\0' + raw).hexdigest() == blob
curation = json.loads((assets / 'preset-curation.json').read_text())
removed = {x for batch in curation['batches'] for x in batch['removedIDs']}
assert all(x.removeprefix('projectm:') in excluded for x in removed)
receipt = json.loads((assets / 'preset-admissions.json').read_text())
report = dict(schemaVersion=1, upstreamCommit=tree['sha'], upstreamMilkCount=len(upstream),
    bundledCount=len(active), retiredCount=len(excluded), missingCount=0,
    exactUpstreamBlobMatches=len(active), upstreamNoticesUnchanged=True,
    ownerReviewedRejectionsPreserved=len(removed), restoredCount=len(receipt['presets']),
    restoredReceipt='Sources/PulseCanvas/Resources/ProjectM/preset-admissions.json',
    exclusionsByReason=dict(sorted(collections.Counter(x['reason'] for x in retired).items())),
    rightsStatus='Technical compatibility evidence only; individual preset and texture permissions remain unresolved.')
args.output.parent.mkdir(parents=True, exist_ok=True)
args.output.write_text(json.dumps(report, indent=2) + '\n')
print(json.dumps({k: report[k] for k in ['bundledCount', 'retiredCount', 'missingCount', 'restoredCount']}))
