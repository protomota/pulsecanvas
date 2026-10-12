#!/usr/bin/env python3
"""Regression checks for tampered subsets/notices and unsafe source archives."""
import importlib.util
import io
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
