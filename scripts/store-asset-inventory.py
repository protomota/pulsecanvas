#!/usr/bin/env python3
"""Generate release-matched asset hashes and upstream credits, without inventing grants."""
import csv,hashlib,json,pathlib
root=pathlib.Path('Sources/PulseCanvas/Resources/ProjectM');out=pathlib.Path('build/app-store');out.mkdir(parents=True,exist_ok=True)
presets=json.loads((root/'catalog.json').read_text())
with (out/'asset-rights-inventory.csv').open('w') as f:
 w=csv.writer(f);w.writerow(['kind','path','creator_title','sha256','rights_status'])
 for a in presets:
  p=root/'Presets'/a['path'];w.writerow(['preset',a['path'],a.get('originalTitle',''),hashlib.sha256(p.read_bytes()).hexdigest(),'upstream public-domain assumption; affirmative grants unresolved'])
 for p in sorted((root/'Textures').rglob('*')):
  if p.is_file():w.writerow(['texture',str(p.relative_to(root)),'see pack README',hashlib.sha256(p.read_bytes()).hexdigest(),'individual grants unresolved'])
print('Wrote',len(presets),'preset hashes and texture provenance rows')
