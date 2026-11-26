# Radio stations

The public directory at https://radio.pulsecanvas.si/stations.json contains
**eight choices**, including All Music. Station labels describe their genres.

| Station | Current songs | Genres |
|---|---:|---|
| All Music | 15 | Every song |
| Dance Pop | 3 | K-pop, nu-disco, amapiano pop |
| Alternative & Indie | 3 | Art pop, bedroom pop, dark trap-pop |
| Electronic | 3 | Hyperpop, liquid drum and bass, synthwave |
| Latin | 2 | Bossa nova, mariachi/ranchera |
| Folk & Sea Shanties | 2 | Bluegrass, sea shanties |
| Oldies | 1 | 1950s doo-wop |
| Blues | 1 | Delta blues |

`radio/station-names.json` maps original song genre strings to the seven grouped
stations. `scripts/build-radio-stations.py` retains the complete catalog bytes
and every track's identity, metadata, audio path and integrity hash. It rejects
unassigned genres, duplicate genre assignments, and more than seven grouped
stations before replacing an index. Add future songs to an appropriate existing
group, or revise these seven groups to keep the total at eight or fewer.

Preparation runs through `scripts/prepare-radio-library.py`. The uploader sends
audio first, then only the station catalogs referenced by the directory, then
the complete catalog and finally the station index. Stale generated station
files are not republished. Existing remote catalog paths remain available for
older clients and saved favorites but are absent from the current station menu.

On 2026-10-18, the eight-choice directory and its seven grouped catalogs were
published and checked through both R2 and public HTTPS. All 15 original tracks
remain in All Music. No audio or complete-catalog bytes changed in this update.
Names and membership refresh from the online directory; they need no app update.
Leave Radio and reopen it from the editor to refresh an already loaded directory.

The player puts the visualizer name/heart, Randomize, visualizer-group dropdown,
and bars per visualizer in its top bar. Song title/heart, station selection,
music Library, transport and volume stay in the bottom toolbar. A narrow window
can wrap the visualizer controls within the top bar. Open menus pause automatic
control hiding so selections remain usable.
