#!/usr/bin/env python3
"""Check grouped stations preserve music and reject incomplete publications."""
import contextlib
import importlib.util
import io
import json
from pathlib import Path
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('station_builder', ROOT / 'scripts/build-radio-stations.py')
builder = importlib.util.module_from_spec(spec)
spec.loader.exec_module(builder)


class StationTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.catalog = self.root / 'catalog.json'
        self.names = self.root / 'stations-config.json'
        self.output = self.root / 'ready'
        self.groups = [dict(id='pop', title='Pop', description='Pop music', genres=['K-pop', 'Disco pop']),
                       dict(id='folk', title='Folk & Sea Shanties', description='Folk music', genres=['Bluegrass', 'Sea shanty'])]
        self.tracks = [dict(id=str(i), title=f'Song {i}', genre=genre, audio=f'audio/{i}.m4a',
                            sha256='a' * 64, byteCount=123, duration=45.0)
                       for i, genre in enumerate(['K-pop', 'Disco pop', 'Bluegrass', 'Sea shanty'])]
        self.catalog.write_text(json.dumps(dict(version=1, title='All music', tracks=self.tracks)))

    def build(self):
        self.names.write_text(json.dumps(self.groups))
        with contextlib.redirect_stdout(io.StringIO()):
            builder.build(self.catalog, self.output, self.names)

    def test_grouped_metadata_and_relative_paths(self):
        self.build()
        self.assertEqual((self.output / 'catalog.json').read_bytes(), self.catalog.read_bytes())
        index = json.loads((self.output / 'stations.json').read_text())
        self.assertEqual([x['id'] for x in index['stations']], ['all-music', 'pop', 'folk'])
        gathered = []
        for station in index['stations'][1:]:
            catalog = json.loads((self.output / station['catalog']).read_text())
            self.assertEqual(catalog['title'], station['title'])
            gathered += catalog['tracks']
        self.assertEqual(gathered, self.tracks)

    def test_invalid_mapping_never_replaces_published_index(self):
        for mode in ['unknown', 'duplicate', 'too-many']:
            with self.subTest(mode=mode):
                self.output.mkdir(exist_ok=True)
                index = self.output / 'stations.json'
                index.write_text('existing publication')
                original = json.loads(json.dumps(self.groups))
                if mode == 'unknown': self.groups[0]['genres'] = ['Other']
                if mode == 'duplicate': self.groups[1]['genres'].append('K-pop')
                if mode == 'too-many':
                    self.groups += [dict(id=f'extra-{i}', title='Extra', genres=[f'Genre {i}'], description='') for i in range(6)]
                with self.assertRaises(AssertionError): self.build()
                self.assertEqual(index.read_text(), 'existing publication')
                self.groups = original

    def test_shipped_configuration_caps_total_choices_at_eight(self):
        groups = json.loads((ROOT / 'radio/station-names.json').read_text())
        self.assertLessEqual(len(groups) + 1, 8)
        self.assertTrue(any(len(group['genres']) > 1 for group in groups))


if __name__ == '__main__': unittest.main()
