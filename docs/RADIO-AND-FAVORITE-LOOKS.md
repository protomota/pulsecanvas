# Radio and favorite looks

Radio on Mac and Vision Pro gives the preview the full window width. Mac groups
its controls below the visual; those controls fade after three idle seconds during
playback. Vision Pro keeps Studio/Radio pinned at the top left in a shared header,
with the visualizer title, round favorite button, randomizer and group selector
above the preview. Below it, one row contains the song title and round favorite
button, station picker, Next song and Favorite songs; playback occupies the final
row. The visualizer heart stays close to its title. Studio keeps its editing
sidebar and sliders. Radio offers group selection and shuffle, rather than an
appearance editor.

New visualizer selections, scene assignments and visualizer timeline shuffles
create randomized looks for non-favorites. The same settings ranges are used on
both platforms. Automatic Radio scene changes also get fresh looks. Randomization
does not enable hi-hat flashes; an explicitly saved favorite may include strobe.

A favorite records every visual setting when its heart is selected. Choosing it
restores that snapshot. Editing or rolling the current style does not overwrite
the saved favorite: remove its heart and favorite the edited look to replace it.
Reset applies the visualizer's defaults to the current shared editor look.

Studio still shares one appearance per visualizer across its clips. New assigned
looks are stored in the project. Normal playback, project reopening, exports and
bar-only edits reuse them, rather than choosing a different random look each frame.
Radio has its own session and cannot overwrite the editor's soundtrack or project.

Favorites backup version 2 includes optional appearance snapshots with stable IDs.
Version 1 ID-only backups remain supported. Installed legacy favorites migrate
once from the editor's saved appearance, falling back to the visualizer's defaults
when no saved appearance exists. Imported snapshots restore their stored look;
missing/retired visualizers stay excluded. Automatic and manual backups use the
same format. User music, favorite lists, and backups are never checked into Git.
