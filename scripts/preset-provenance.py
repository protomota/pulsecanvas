#!/usr/bin/env python3
"""Generate pinned provenance; verify exact app/source subsets without inferring licenses."""
import argparse
import hashlib
import io
import json
import pathlib
import plistlib
import re
import subprocess
import tarfile
import tempfile

REPO = pathlib.Path(__file__).resolve().parents[1]
RESOURCE = pathlib.Path('Sources/PulseCanvas/Resources/ProjectM')
PRESET_COMMIT = '0180df21f5e0bd39b9060cc5de420ed2f1f9e509'
TEXTURE_COMMIT = '6368812f27bc747b517218fbf89d21d59afce4d9'
CREDIT = 'Cream of the Crop pack curated by ISOSCELES'
CREDIT_URL = 'https://www.patreon.com/posts/pack-nestdrop-91682111'
NOTICE_PATTERN = re.compile(
    r'copyright|\blicen[cs]e\b|\bpermission\b|\battribution\b|\bauthor\b|'
    r'\bcreator\b|\bcredits?\b|all rights reserved|public domain|'
    r'\b(?:MIT|BSD|LGPL|GPL|SPDX|CC-BY)\b|creative commons|redistribut|'
    r'commercial|https?://|www\.|©|created by|written by', re.IGNORECASE)
MANIFESTS = ['preset-manifest.json', 'preset-notices.json', 'texture-manifest.json']
CURATION_FILE = 'preset-curation.json'
ADMISSIONS_FILE = 'preset-admissions.json'


def receipt_files(root):
    return [name for name in [CURATION_FILE, ADMISSIONS_FILE] if (root / name).exists()]


def verify_admissions(root, manifest, current, removed, retired):
    path = root / ADMISSIONS_FILE
    if not path.exists():
        require('admissionsSHA256' not in manifest, 'Missing admissions receipt')
        return 0
    require(manifest.get('admissionsSHA256') == digest(path.read_bytes()), 'Admissions receipt differs')
    receipt = json.loads(path.read_text())
    require(receipt['schemaVersion'] == 1 and receipt['upstreamCommit'] == PRESET_COMMIT, 'Wrong admissions pin')
    admitted = receipt['presets']
    ids = {x['id'] for x in admitted}
    require(len(ids) == len(admitted), 'Duplicate admitted identity')
    require(ids <= current and ids.isdisjoint(removed | retired), 'Admissions conflict with curation or retirement')
    for entry in admitted:
        require(entry['id'] == 'projectm:' + entry['path'], 'Admitted upstream identity changed')
        path = pathlib.PurePosixPath(entry['path'])
        require(not path.is_absolute() and '..' not in path.parts, 'Unsafe admission path')
        require(entry.get('visualInspectionApproved') is True, 'Missing visual admission inspection')
        checks = entry['checks']
        require(all(x['id'] == entry['id'] for x in checks), 'Admission check identity differs')
        require({(x['width'], x['height']) for x in checks}.issuperset({(1920, 1080), (1080, 1920)}), 'Missing full-HD admission checks')
        require(all(x['passed'] is True and x['frames'] >= 360 and x['soundtrackPCM'] is True for x in checks), 'Unverified admitted preset')
        require(digest((root / 'Presets' / entry['path']).read_bytes()) == entry['sha256'], 'Admitted bytes changed')
    return len(ids)


def digest(data):
    return hashlib.sha256(data).hexdigest()


def require(condition, message):
    if not condition:
        raise ValueError(message)


def scan_notices(root, entries):
    notices = []
    for entry in entries:
        raw = (root / entry['path']).read_bytes()
        try:
            text = raw.decode('utf-8')
            encoding = 'utf-8'
        except UnicodeDecodeError:
            text = raw.decode('latin-1')
            encoding = 'latin-1'
        hits = [{'line': n, 'text': line} for n, line in enumerate(text.splitlines(), 1)
                if NOTICE_PATTERN.search(line)]
        if hits:
            notices.append({'path': entry['path'], 'sha256': digest(raw),
                            'decoding': encoding, 'candidateLines': hits})
    return {'schemaVersion': 1, 'scannedFiles': len(entries),
            'method': 'Case-insensitive notice/credit/license/URL keyword scan of every file; '
                      'candidate lines are evidence, not license classifications. '
                      'Complete original bytes, including unmatched comments, are preserved '
                      'and verified by the preset manifest.',
            'pattern': NOTICE_PATTERN.pattern, 'filesWithCandidates': len(notices),
            'presets': notices}


def verify_files(root, entries, suffix=None):
    expected = {entry['path'] for entry in entries}
    require(len(expected) == len(entries), 'Duplicate manifest paths')
    actual = {p.relative_to(root).as_posix() for p in root.rglob('*') if p.is_file()}
    if suffix:
        actual = {p for p in actual if p.lower().endswith(suffix)}
    require(actual == expected, f'Subset differs in {root}: missing {len(expected-actual)}, extra {len(actual-expected)}')
    for entry in entries:
        path = pathlib.PurePosixPath(entry['path'])
        require(not path.is_absolute() and '..' not in path.parts, 'Unsafe manifest path')
        require(not (root / entry['path']).is_symlink(), 'Asset symlinks are unsupported')
        require(digest((root / entry['path']).read_bytes()) == entry['sha256'],
                f'Changed asset bytes: {entry["path"]}')


def verify_resource(root):
    presets = json.loads((root / MANIFESTS[0]).read_text())
    textures = json.loads((root / MANIFESTS[2]).read_text())
    require(presets['upstreamCommit'] == PRESET_COMMIT, 'Wrong preset pin')
    require(textures['upstreamCommit'] == TEXTURE_COMMIT, 'Wrong texture pin')
    require(presets['upstreamMilkCount'] == 9795, 'Wrong upstream tree count')
    expected_count = 7838
    curation_path = root / CURATION_FILE
    if curation_path.exists():
        curation = json.loads(curation_path.read_text())
        require(curation['schemaVersion'] == 1 and curation['initialBundledCount'] == 7838, 'Wrong curation baseline')
        require(presets.get('curationSHA256') == digest(curation_path.read_bytes()), 'Curation receipt differs')
        removed, retained, reviewed = set(), set(), set()
        retired = {x['id'] for x in json.loads((root / 'retired-presets.json').read_text())}
        for batch in curation['batches']:
            all_ids = set(batch['reviewedIDs']); keep = set(batch['retainedIDs']); discard = set(batch['removedIDs'])
            require(batch['completedReview'] is True and batch['selectionSource'] == 'Finder red label', 'Incomplete curation')
            require(len(all_ids) == len(batch['reviewedIDs']) and not (all_ids & reviewed), 'Duplicate reviewed identity')
            require(keep.isdisjoint(discard) and keep | discard == all_ids, 'Curation partition differs')
            removed.update(discard); retained.update(keep); reviewed.update(all_ids)
        require(removed <= retired, 'Removed IDs missing retirement migration records')
        current = {x['id'] for x in presets['presets']}
        require(current.isdisjoint(removed) and retained <= current, 'Curation does not match bundled subset')
        expected_count -= len(removed)
    current = {x['id'] for x in presets['presets']}
    removed = removed if curation_path.exists() else set()
    retired = {x['id'] for x in json.loads((root / 'retired-presets.json').read_text())} if (root / 'retired-presets.json').exists() else set()
    expected_count += verify_admissions(root, presets, current, removed, retired)
    require(presets['bundledCount'] == len(presets['presets']) == expected_count, 'Wrong bundled count')
    require(presets['credit'] == CREDIT and presets['creditURL'] == CREDIT_URL, 'Missing curator credit')
    verify_files(root / 'Presets', presets['presets'])
    verify_files(root / 'Textures', textures['files'])
    require(textures['imageCount'] == sum(x['path'] != 'README.md' for x in textures['files']) == 67,
            'Wrong texture image count')
    require(all(x['path'] == x['upstreamPath'] for x in textures['files']), 'Texture upstream path changed')
    catalog = json.loads((root / 'catalog.json').read_text())
    require(len(catalog) == expected_count and len({x['id'] for x in catalog}) == expected_count, 'Catalog count/identity mismatch')
    by_path = {x['path']: x for x in catalog}
    require(len(by_path) == expected_count, 'Duplicate catalog paths')
    for entry in presets['presets']:
        item = by_path.get(entry['path'])
        require(item is not None, f'Missing catalog entry: {entry["path"]}')
        require(entry['upstreamPath'] == entry['path'], 'Original upstream path changed')
        require(entry['originalTitle'] == pathlib.PurePosixPath(entry['path']).stem,
                'Original creator/title metadata differs from original filename')
        require(all(item[k] == entry[k] for k in ['id', 'originalTitle']), 'Catalog provenance differs')
        require(item['title'] == entry['displayTitle'], 'Display mapping differs')
    for name, sha in presets['upstreamNotices'].items():
        require(digest((root / name).read_bytes()) == sha, f'Changed upstream notice: {name}')
    require(json.loads((root / MANIFESTS[1]).read_text()) == scan_notices(root / 'Presets', presets['presets']),
            'Notice inventory differs from complete scan')
    return presets, textures


def pinned_snapshot(checkout, commit, destination):
    # Read Git objects at the pin, never an upstream working tree with local changes.
    data = subprocess.check_output(['git', '-C', str(checkout), 'archive', commit])
    with tarfile.open(fileobj=io.BytesIO(data)) as archive:
        safe_extract(archive, destination)


def safe_extract(archive, destination):
    # Compatible with Apple's Python 3.9; reject traversal, links and special files.
    for member in archive.getmembers():
        path = pathlib.PurePosixPath(member.name)
        require(not path.is_absolute() and '..' not in path.parts, 'Unsafe archive path')
        require(member.isfile() or member.isdir(), 'Archive links/special files are unsupported')
    archive.extractall(destination)


def generate(preset_checkout, texture_checkout):
    root = REPO / RESOURCE
    catalog = json.loads((root / 'catalog.json').read_text())
    with tempfile.TemporaryDirectory() as temp:
        temp = pathlib.Path(temp)
        upstream = temp / 'presets'
        textures = temp / 'textures'
        pinned_snapshot(preset_checkout, PRESET_COMMIT, upstream)
        pinned_snapshot(texture_checkout, TEXTURE_COMMIT, textures)
        upstream_count = len(list(upstream.rglob('*.milk')))
        require(upstream_count == 9795, 'Unexpected pinned upstream tree')
        entries = []
        for item in sorted(catalog, key=lambda item: item['path']):
            path = item['path']
            raw = (root / 'Presets' / path).read_bytes()
            require(raw == (upstream / path).read_bytes(), f'Preset differs from pin: {path}')
            entries.append({'path': path, 'upstreamPath': path, 'sha256': digest(raw),
                            'id': item['id'], 'originalTitle': item['originalTitle'],
                            'displayTitle': item['title']})
        notices = {'Preset-README.md': 'README.md', 'Preset-notice.md': 'LICENSE.md'}
        for bundled, source in notices.items():
            require((root / bundled).read_bytes() == (upstream / source).read_bytes(),
                    f'Upstream notice changed: {bundled}')
        preset_manifest = {
            'schemaVersion': 1,
            'upstreamRepository': 'https://github.com/projectM-visualizer/presets-cream-of-the-crop',
            'upstreamCommit': PRESET_COMMIT, 'upstreamMilkCount': upstream_count,
            'bundledCount': len(entries), 'credit': CREDIT, 'creditURL': CREDIT_URL,
            'rightsStatus': 'Unresolved individual author permissions; upstream public-domain assumption '
                            'is not documented permission from every author. No MIT/BSD/clearance claim.',
            'upstreamNotices': {name: digest((root / name).read_bytes()) for name in notices},
            'presets': entries}
        if (root / CURATION_FILE).exists():
            preset_manifest['curationSHA256'] = digest((root / CURATION_FILE).read_bytes())
        if (root / ADMISSIONS_FILE).exists():
            preset_manifest['admissionsSHA256'] = digest((root / ADMISSIONS_FILE).read_bytes())
        texture_entries = []
        for path in sorted((root / 'Textures').rglob('*')):
            if not path.is_file():
                continue
            relative = path.relative_to(root / 'Textures').as_posix()
            require(path.read_bytes() == (textures / relative).read_bytes(), f'Texture differs from pin: {relative}')
            texture_entries.append({'path': relative, 'upstreamPath': relative, 'sha256': digest(path.read_bytes())})
        texture_manifest = {
            'schemaVersion': 1,
            'upstreamRepository': 'https://github.com/projectM-visualizer/presets-milkdrop-texture-pack',
            'upstreamCommit': TEXTURE_COMMIT,
            'imageCount': sum(entry['path'] != 'README.md' for entry in texture_entries),
            'rightsStatus': 'Individual asset grants unresolved; README recommends inclusion but '
                            'does not supply per-texture licenses. Separate from preset and engine terms.',
            'files': texture_entries}
        for name, value in zip(MANIFESTS, [preset_manifest, scan_notices(root / 'Presets', entries), texture_manifest]):
            (root / name).write_text(json.dumps(value, indent=2, ensure_ascii=False) + '\n')
    verify_resource(root)


def verify_app(app):
    info = plistlib.loads((app / 'Contents/Info.plist').read_bytes())
    config = ((REPO / 'Version.xcconfig').read_text() + '\n' + (REPO / 'macOS/Release.xcconfig').read_text())
    for field, key in [('CFBundleShortVersionString', 'MARKETING_VERSION'),
                       ('CFBundleVersion', 'CURRENT_PROJECT_VERSION')]:
        expected = re.search(r'^' + key + r'\s*=\s*(\S+)', config, re.MULTILINE).group(1)
        require(info[field] == expected, f'App version/build differs from source: {field}')
    resources = app / 'Contents/Resources'
    roots = (list(resources.glob('Resources/ProjectM'))
             + list(resources.glob('*.bundle/Resources/ProjectM'))
             + list(resources.glob('*.bundle/Contents/Resources/Resources/ProjectM')))
    require(len(roots) == 1, 'Expected one bundled ProjectM resource tree')
    root = roots[0]
    verify_resource(root)
    require(set(resources.rglob('*.milk')) == set((root / 'Presets').rglob('*.milk')),
            'Unexpected presets outside the intended bundled subset')
    curation_files = receipt_files(REPO / RESOURCE)
    for name in MANIFESTS + ['Preset-README.md', 'Preset-notice.md', 'Provenance.md', 'catalog.json'] + curation_files:
        require((root / name).read_bytes() == (REPO / RESOURCE / name).read_bytes(), f'App differs from checkout: {name}')
    legal = resources / 'Legal'
    for name in MANIFESTS + ['Preset-README.md', 'Preset-notice.md', 'Provenance.md'] + curation_files:
        require((legal / name).read_bytes() == (root / name).read_bytes(), f'Legal resource differs: {name}')
    require((legal / 'Texture-provenance.md').read_bytes() == (root / 'Textures/README.md').read_bytes(), 'Texture notice differs')
    require((legal / 'PulseCanvas-LICENSE.txt').read_bytes() == (REPO / 'LICENSE').read_bytes(), 'Application license differs')
    require((legal / 'ProjectM-LGPL-2.1.txt').read_bytes() == (REPO / '.build/projectm/source/LICENSE.txt').read_bytes(), 'Engine license differs')
    require((legal / 'Third-Party-Notices.md').read_bytes() == (REPO / 'third_party/PROJECTM.md').read_bytes(), 'Component notices differ')
    vendors = REPO / '.build/projectm/source/vendor'
    for name, source in [('hlslparser-MIT.txt', vendors / 'hlslparser/LICENSE'),
                         ('projectm-eval-MIT.txt', vendors / 'projectm-eval/LICENSE.md')]:
        require((legal / name).read_bytes() == source.read_bytes(), f'Vendor license differs: {name}')
    for source in sorted((vendors / 'stb_image').iterdir()):
        if source.suffix in ['.c', '.h']:
            require((legal / source.name).read_bytes() == source.read_bytes(), f'Embedded vendor notices differ: {source.name}')
    info = plistlib.loads((app / 'Contents/Info.plist').read_bytes())
    config = ((REPO / 'Version.xcconfig').read_text() + '\n' + (REPO / 'macOS/Release.xcconfig').read_text())
    version = re.search(r'^MARKETING_VERSION\s*=\s*(\S+)', config, re.M).group(1)
    build = re.search(r'^CURRENT_PROJECT_VERSION\s*=\s*(\S+)', config, re.M).group(1)
    # Portable development bundles use their existing development version.
    if (resources / 'Resources/ProjectM').exists():
        require(info['CFBundleShortVersionString'] == version and info['CFBundleVersion'] == build,
                'App version/build differs from source configuration')


def verify_source(path, revision=None):
    with tempfile.TemporaryDirectory() as temp:
        with tarfile.open(path) as archive:
            safe_extract(archive, temp)
        root = pathlib.Path(temp) / 'PulseCanvas-source'
        verify_resource(root / RESOURCE)
        require(set(root.rglob('*.milk')) == set((root / RESOURCE / 'Presets').rglob('*.milk')),
                'Unexpected presets outside the source subset')
        curation_files = receipt_files(REPO / RESOURCE)
        for name in MANIFESTS + ['Preset-README.md', 'Preset-notice.md', 'Provenance.md', 'catalog.json'] + curation_files:
            require((root / RESOURCE / name).read_bytes() == (REPO / RESOURCE / name).read_bytes(), f'Source differs: {name}')
        for name in ['LICENSE', 'Version.xcconfig', 'macOS/Release.xcconfig', 'third_party/projectm-source.tar.gz',
                     'third_party/PROJECTM.md', 'Sources/PulseCanvas/PulseCanvasApp.swift',
                     'scripts/build-projectm.sh', 'scripts/build-app.sh', 'scripts/store-release.sh',
                     'scripts/preset-provenance.py']:
            require((root / name).read_bytes() == (REPO / name).read_bytes(), f'Source build input differs: {name}')
        require((root / 'docs/licensing.md').is_file() and (root / 'docs/app-store/LICENSES.md').is_file(),
                'Source licensing guidance missing')
        if revision:
            require((root / 'REVISION.txt').read_text().strip() == revision, 'Source revision differs')
            # Verify the entire committed build input set, not just the manifests.
            inputs = ['Version.xcconfig', 'Sources', 'scripts', 'radio', 'macOS', 'PulseCanvas.xcodeproj', 'PulseCanvasMobile.xcodeproj', 'mobile', 'PulseCanvasVision.xcodeproj',
                      'visionOS', 'third_party', 'assets', 'packaging',
                      'Package.swift', 'LICENSE', 'README.md', 'AGENTS.md', 'docs']
            snapshot = subprocess.check_output(['git', '-C', str(REPO), 'archive', revision, *inputs])
            with tarfile.open(fileobj=io.BytesIO(snapshot)) as committed:
                expected = set()
                for member in committed.getmembers():
                    if member.isfile():
                        expected.add(member.name)
                        require((root / member.name).read_bytes() == committed.extractfile(member).read(),
                                f'Committed source input differs: {member.name}')
                actual = {p.relative_to(root).as_posix() for p in root.rglob('*') if p.is_file()}
                require(actual == expected | {'BUILD.txt', 'REVISION.txt'}, 'Source package file set differs')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--generate', action='store_true')
    parser.add_argument('--presets-checkout', type=pathlib.Path, default=REPO.parent / 'projectm-presets')
    parser.add_argument('--textures-checkout', type=pathlib.Path, default=REPO.parent / 'projectm-textures')
    parser.add_argument('--app', type=pathlib.Path)
    parser.add_argument('--source', type=pathlib.Path)
    parser.add_argument('--revision')
    args = parser.parse_args()
    if args.generate:
        generate(args.presets_checkout, args.textures_checkout)
    presets, textures = verify_resource(REPO / RESOURCE)
    if args.app:
        verify_app(args.app)
    if args.source:
        verify_source(args.source, args.revision)
    notices = json.loads((REPO / RESOURCE / MANIFESTS[1]).read_text())
    print(json.dumps({'verifiedPresets': len(presets['presets']), 'upstreamMilkFiles': presets['upstreamMilkCount'],
                      'verifiedTextureImages': textures['imageCount'], 'scannedPresets': notices['scannedFiles'],
                      'presetsWithNoticeCandidates': notices['filesWithCandidates'],
                      'app': str(args.app) if args.app else None, 'sourceArchive': str(args.source) if args.source else None}, indent=2))


if __name__ == '__main__':
    main()
