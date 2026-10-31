# Git workflow

The owner has authorized committing and pushing completed PulseCanvas changes to
GitHub `main` as the default workflow. Do this when finishing work without asking
again, unless a newer instruction says to wait.

Before uploading or distributing another TestFlight build, show the owner the
finished changes and obtain explicit confirmation. Git commit/push authorization
does not authorize TestFlight uploads.

Preserve concurrent edits and existing worktrees. Keep credentials, user data,
local build products, caches, and rendered review videos out of Git. Never force
push to resolve concurrent updates.

# Current external storage — October 30, 2026

The canonical external root is `/Volumes/Expand/`. For working references that
still use `/Volumes/Music/`, replace only that prefix and preserve the remaining
path exactly. Verify each mapped target exists before using it. Do not recreate
the Music mount or move/duplicate the mirrored data. Keep historical transcripts
and release records unchanged.

Verified PulseCanvas storage: `/Volumes/Expand/Codex Media/PulseCanvas Studio/`.
The checkout's `.build` and `build` links use the existing mirrored
`Platform Builds/onboarding-swipe-1.2-20261022/project-build-cache` and
`project-build-output` folders beneath that root. The October 23 favorite-gesture
release artifacts also exist under `Platform Builds/favorite-gestures-1.2-20261023/`.
Use Expand for future media, build caches, scripts, manifests, and outputs.

# Supported platforms

Apple TV development was discontinued by the owner on October 31, 2026. Do not
recreate a tvOS target or include Apple TV in future builds or release work.
Supported app targets are macOS, iOS/iPadOS (including Duo), and visionOS.
Historical release records may still describe the retired Apple TV prototype.
