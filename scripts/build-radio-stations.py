#!/usr/bin/env python3
"""Create genre-labeled stations while retaining All Music and original track metadata."""
import argparse
import json
from pathlib import Path
import re


def build(catalog_path, output, names_path):
    catalog_bytes = catalog_path.read_bytes()
    catalog = json.loads(catalog_bytes)
    names = json.loads(names_path.read_text())
    assert catalog['version'] == 1
    assert len({x['id'] for x in names}) == len(names)
    assert len(names) <= 7, 'Keep at most seven genre stations plus All Music'
    genres = [genre for station in names for genre in station['genres']]
    assert len(set(genres)) == len(genres), 'A genre may belong to only one station'
    assert all(station['genres'] and re.fullmatch(r'[a-z0-9-]+', station['id']) for station in names)
    assert all(station['id'] != 'all-music' and station['title'].strip() for station in names)
    unknown = {track['genre'] for track in catalog['tracks']} - set(genres)
    assert not unknown, 'Assign new genres to a station before publishing: ' + ', '.join(sorted(unknown))
    covered = set()
    directory = dict(version=1, stations=[dict(id='all-music', title='All Music',
        description='Every genre, one station', catalog='catalog.json')])
    output.mkdir(parents=True, exist_ok=True)
    for station in names:
        tracks = [x for x in catalog['tracks'] if x['genre'] in station['genres']]
        if not tracks:
            continue
        covered.update(x['id'] for x in tracks)
        filename = 'station-' + station['id'] + '.json'
        # Catalogs share the root so original relative audio URLs remain valid.
        (output / filename).write_text(json.dumps(dict(version=1, title=station['title'], tracks=tracks), indent=2, ensure_ascii=False) + '\n')
        directory['stations'].append({k: station[k] for k in ['id', 'title', 'description']} | dict(catalog=filename))
    assert covered == {x['id'] for x in catalog['tracks']}, 'Some songs need a genre station in station-names.json'
    (output / 'catalog.json').write_bytes(catalog_bytes)
    # Publish this index only after all per-station catalogs are uploaded.
    (output / 'stations.json').write_text(json.dumps(directory, indent=2, ensure_ascii=False) + '\n')
    print(f"Prepared {len(directory['stations'])} stations; {len(covered)} songs; original metadata and audio URLs retained")


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--catalog', required=True, type=Path)
    parser.add_argument('--output', required=True, type=Path)
    parser.add_argument('--names', type=Path, default=Path(__file__).resolve().parents[1] / 'radio/station-names.json')
    args = parser.parse_args()
    build(args.catalog, args.output, args.names)
