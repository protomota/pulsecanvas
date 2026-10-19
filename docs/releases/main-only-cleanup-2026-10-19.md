# Main-only Git cleanup — October 19, 2026

The owner requested that all completed work be on `main`, with no other branches.

- Every local branch tip and both extra remote branch tips were verified as
  ancestors of `main`. No additional commit merge was necessary.
- In the old `native-visualizers-100` worktree, all 153 changed/new source and
  supporting file blobs were found in `main`'s reachable history. Its 71 deleted
  files are also absent from current `main`. Later versions on `main` were not
  overwritten with this older snapshot. Only its two handoff documents were
  unique to that working copy.
- A verified Git bundle of all refs, exact dirty-worktree patches, working-file
  archives and an audit manifest were saved outside Git under
  `/Volumes/Music/Codex Media/PulseCanvas Studio/Git Safety/2026-10-19-main-only-163318/`.
- Four branch-attached worktrees were detached at their existing commits. Their
  porcelain working status was compared byte-for-byte before and after. All
  worktree directories, local media and ignored products remain in place.
- Nine extra local branches were deleted with `git branch -d`, after the ancestry
  checks. The already-merged remote branches `new-claude-visualizers` and
  `tunnel-motion` were deleted. A fresh `git ls-remote --heads origin` reports only
  `refs/heads/main`. No history rewrite or force push was used.
- The owner explicitly requested preserving untracked `mobile/` as unfinished
  work. It was not inspected, staged, committed, removed or otherwise changed.

The startup favorites fix is committed on `main` as `fa0ca2f`; its tests and
build checks are recorded in [the favorites receipt](favorites-catalog-cleanup-2026-10-19.md).
This cleanup does not submit a new app release or change the active App Review
submission.
