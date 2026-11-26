#!/usr/bin/env python3
"""Regression checks for tampered subsets/notices and unsafe source archives."""
import importlib.util
import io
import json
import pathlib
import tarfile
import tempfile
import unittest

spec = importlib.util.spec_from_file_location('provenance', pathlib.Path(__file__).with_name('preset-provenance.py'))
provenance = importlib.util.module_from_spec(spec)
spec.loader.exec_module(provenance)


class ProvenanceTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = pathlib.Path(self.temp.name)
        self.original = b'[preset00]\r\n// Copyright Example; permission required\r\n'
        (self.root / 'Creator - Title.milk').write_bytes(self.original)
        self.entries = [{'path': 'Creator - Title.milk', 'sha256': provenance.digest(self.original)}]

    def test_exact_subset(self):
        provenance.verify_files(self.root, self.entries)

    def test_changed_bytes_rejected(self):
        (self.root / self.entries[0]['path']).write_bytes(self.original.replace(b'\r\n', b'\n'))
        with self.assertRaisesRegex(ValueError, 'Changed asset bytes'):
            provenance.verify_files(self.root, self.entries)

    def test_missing_asset_rejected(self):
        (self.root / self.entries[0]['path']).unlink()
        with self.assertRaisesRegex(ValueError, 'missing 1'):
            provenance.verify_files(self.root, self.entries)

    def test_uncataloged_asset_rejected(self):
        (self.root / 'Extra.milk').write_bytes(b'extra')
        with self.assertRaisesRegex(ValueError, 'extra 1'):
            provenance.verify_files(self.root, self.entries)

    def test_duplicate_manifest_path_rejected(self):
        with self.assertRaisesRegex(ValueError, 'Duplicate'):
            provenance.verify_files(self.root, self.entries * 2)

    def test_asset_symlink_rejected(self):
        asset = self.root / self.entries[0]['path']
        original = self.root.parent / (self.root.name + '-original')
        original.write_bytes(self.original)
        self.addCleanup(original.unlink)
        asset.unlink()
        asset.symlink_to(original)
        with self.assertRaisesRegex(ValueError, 'symlinks'):
            provenance.verify_files(self.root, self.entries)

    def test_notice_line_numbers_and_legacy_bytes(self):
        raw = b'[preset00]\r\n// \xa9 Author, all rights reserved\r\n'
        (self.root / self.entries[0]['path']).write_bytes(raw)
        scan = provenance.scan_notices(self.root, self.entries)
        self.assertEqual(scan['scannedFiles'], 1)
        self.assertEqual(scan['presets'][0]['candidateLines'], [{'line': 2, 'text': '// © Author, all rights reserved'}])
        self.assertEqual((self.root / self.entries[0]['path']).read_bytes(), raw)

    def test_archive_traversal_rejected(self):
        self.assert_unsafe_archive('../escape', tarfile.REGTYPE)

    def test_archive_symlink_rejected(self):
        self.assert_unsafe_archive('link', tarfile.SYMTYPE)

    def curation_fixture(self, change=None, wrong_hash=False):
        curation = {'schemaVersion': 1, 'initialBundledCount': 7838, 'batches': [{
            'completedReview': True, 'selectionSource': 'Finder red label',
            'reviewedIDs': ['keep', 'remove'], 'retainedIDs': ['keep'], 'removedIDs': ['remove']}]}
        if change:
            change(curation['batches'][0])
        data = json.dumps(curation).encode()
        (self.root / 'preset-curation.json').write_bytes(data)
        (self.root / 'retired-presets.json').write_text(json.dumps([{'id': 'remove'}]))
        presets = {'upstreamCommit': provenance.PRESET_COMMIT, 'upstreamMilkCount': 9795,
                   'bundledCount': 1, 'presets': [{'id': 'keep'}],
                   'curationSHA256': 'wrong' if wrong_hash else provenance.digest(data)}
        (self.root / 'preset-manifest.json').write_text(json.dumps(presets))
        (self.root / 'texture-manifest.json').write_text(json.dumps({'upstreamCommit': provenance.TEXTURE_COMMIT}))

    def test_changed_curation_receipt_rejected(self):
        self.curation_fixture(wrong_hash=True)
        with self.assertRaisesRegex(ValueError, 'Curation receipt differs'):
            provenance.verify_resource(self.root)

    def test_incomplete_review_rejected(self):
        self.curation_fixture(lambda b: b.update(completedReview=False))
        with self.assertRaisesRegex(ValueError, 'Incomplete curation'):
            provenance.verify_resource(self.root)

    def test_overlap_in_selection_rejected(self):
        self.curation_fixture(lambda b: b.update(removedIDs=['keep', 'remove']))
        with self.assertRaisesRegex(ValueError, 'Curation partition differs'):
            provenance.verify_resource(self.root)

    def test_unreviewed_removals_rejected(self):
        self.curation_fixture()
        with self.assertRaisesRegex(ValueError, 'Wrong bundled count'):
            provenance.verify_resource(self.root)

    def test_missing_retirement_migration_rejected(self):
        self.curation_fixture()
        (self.root / 'retired-presets.json').write_text('[]')
        with self.assertRaisesRegex(ValueError, 'Removed IDs missing retirement'):
            provenance.verify_resource(self.root)

    def admissions_fixture(self, change=None):
        entry = dict(id='projectm:Creator - Title.milk', path='Creator - Title.milk',
                     sha256=provenance.digest(self.original), visualInspectionApproved=True, checks=[
            dict(id='projectm:Creator - Title.milk', width=w, height=h, frames=360, passed=True, soundtrackPCM=True)
            for w, h in [(1920, 1080), (1080, 1920)]])
        if change: change(entry)
        receipt = dict(schemaVersion=1, upstreamCommit=provenance.PRESET_COMMIT, presets=[entry])
        raw = json.dumps(receipt).encode()
        (self.root / 'preset-admissions.json').write_bytes(raw)
        (self.root / 'Presets').mkdir()
        (self.root / 'Presets/Creator - Title.milk').write_bytes(self.original)
        return dict(admissionsSHA256=provenance.digest(raw)), {entry['id']}

    def test_verified_admission(self):
        manifest, current = self.admissions_fixture()
        self.assertEqual(provenance.verify_admissions(self.root, manifest, current, set(), set()), 1)

    def test_admission_cannot_restore_owner_rejection(self):
        manifest, current = self.admissions_fixture()
        with self.assertRaisesRegex(ValueError, 'Admissions conflict'):
            provenance.verify_admissions(self.root, manifest, current, current, set())

    def test_admission_requires_both_orientations(self):
        manifest, current = self.admissions_fixture(lambda e: e['checks'].pop())
        with self.assertRaisesRegex(ValueError, 'Missing full-HD'):
            provenance.verify_admissions(self.root, manifest, current, set(), set())

    def test_admission_rejects_failed_render(self):
        manifest, current = self.admissions_fixture(lambda e: e['checks'][0].update(passed=False))
        with self.assertRaisesRegex(ValueError, 'Unverified admitted'):
            provenance.verify_admissions(self.root, manifest, current, set(), set())

    def test_admission_rejects_wrong_check_identity(self):
        manifest, current = self.admissions_fixture(lambda e: e['checks'][0].update(id='other'))
        with self.assertRaisesRegex(ValueError, 'identity differs'):
            provenance.verify_admissions(self.root, manifest, current, set(), set())

    def test_changed_admission_receipt_rejected(self):
        manifest, current = self.admissions_fixture()
        manifest['admissionsSHA256'] = 'wrong'
        with self.assertRaisesRegex(ValueError, 'Admissions receipt differs'):
            provenance.verify_admissions(self.root, manifest, current, set(), set())

    def assert_unsafe_archive(self, name, kind):
        data = io.BytesIO()
        with tarfile.open(fileobj=data, mode='w') as archive:
            member = tarfile.TarInfo(name)
            member.type = kind
            member.linkname = '/tmp/elsewhere'
            archive.addfile(member)
        data.seek(0)
        with tarfile.open(fileobj=data) as archive, self.assertRaises(ValueError):
            provenance.safe_extract(archive, self.root / 'extract')


if __name__ == '__main__':
    unittest.main()
