# Mac audio crackle follow-up — October 20, 2026

The owner still reports crackling on musical transients in Mac 1.1.6 (27), while
iPhone/iPad playback in the corresponding update sounds clean. The running Mac
installation was verified to contain the dedicated Radio player. This follow-up
does **not** establish an audible fix for active Radio playback.

## Confirmed idle-output defect and change

Mac Studio eagerly started AVAudioEngine when loading a paused soundtrack.
Pausing AVAudioPlayerNode also left its engine running. Consequently a paused
editor could keep a hardware output callback active alongside another player.

The Mac engine now starts only when playback starts. Pause, Stop and natural
completion without looping pause the engine as well. Prepared resources remain
available for resume. Radio continues using its independent AVAudioPlayer; the
working iOS playback lifecycle is unchanged.

Apple documents that [AVAudioEngine.pause](https://developer.apple.com/documentation/avfaudio/avaudioengine/pause())
stops the engine and audio hardware while retaining prepared resources, and that
`start()` resumes it.

## Verification

- A separate probe compiled against the previous controller reported
  `loadedPaused true hardwareOutputActive true` through Core Audio's own process
  output property, reproducing the idle-output defect.
- The updated audio smoke suite queries the actual audio server, rather than
  private controller state. Paused load and pause have no running hardware output;
  resuming has running output and advances from the paused position without a
  clock jump. Existing section loops, full-song loops, fractional seeks, stale
  callback protection, Radio completion and Studio handoff checks pass.
- Shared Radio smoke suite passed, including personal-folder looping and Studio
  restoration. Mac Debug build passed. `git diff --check` passed.
- No new TestFlight package, website release, user preference migration or
  soundtrack conversion is included in this change. The live installed app was
  not replaced or restarted.

## Active Radio investigation remains open

Mac Core Audio logs show repeated device I/O overload and safety-violation
reports on the current USB output. A leftover, paused development QA instance
was quit normally. Overload reports continued afterward, so that instance cannot
be declared the sole cause. The log evidence does not identify the PulseCanvas
decoder as the cause; other system audio clients are also involved.

One currently playing 44.1 kHz stereo AAC original was decoded with Apple's
AVAudioFile: peak about -0.063 dBFS, zero samples above full scale. An independent
48 kHz resampling check also remained below full scale. This does not establish
that the final hardware output is clean, nor exclude every possible distortion
mechanism.

Next listening checks are whether crackling remains after closing the old test
copy, and whether the same passage crackles through built-in speakers versus the
USB output. Device routing was not changed by the agent. No simulator sessions
or unrelated applications were shut down.

Local diagnostics and logs, excluded from Git:
`/Volumes/Music/Codex Media/PulseCanvas Studio/Development/mac-radio-crackle/`.
No original music or private playback preferences are committed.
