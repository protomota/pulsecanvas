# Mac Radio media-player candidate — 1.1.6 (28)

> **Reverted — October 20, 2026.** The AVPlayer candidate described below was reverted at the owner’s request after a restart cleared the reported crackling. Build 28 remains a historical TestFlight upload; current source uses the earlier engine transport.
> See [rollback details](audio-investigation-rollback.md).

[TestFlight delivery verified](../releases/mac-testflight-1.1.6-28.md).

The owner reports that Mac Radio still crackles through a DX3 Pro+ USB DAC with
1.1.6 (27). iPhone/iPad playback sounds clean. Built-in Mac speakers did not
reveal the same crackle, although that listening comparison was less sensitive.
These observations narrow the investigation; they do not establish a hardware
fault or prove a fix.

Mac Radio now uses AVPlayer for its fully local music files. Apple documents
[AVPlayer](https://developer.apple.com/documentation/avfoundation/avplayer) as a
playback path for local and remote media. This candidate replaces Mac Radio's
AVAudioPlayer output path while preserving its independent source analysis and
the exact AVAudioPlayerNode section player used in Studio. iPhone/iPad keep their
working AVAudioPlayer branch. Vision has its separate existing transport.

The wrapper forwards volume, desired play/pause state, playback time and real
end/error notifications to the existing Radio controller. Pending exact seeks
publish their latest target until AVPlayer finishes; revision checks ignore old
seek completions. Song-end notifications are checked against the current player
and playback position to avoid stale rewinds or duplicate advances. Original
music, cached audio bytes and user preferences are unchanged. No output device,
system sample rate or DAC configuration is changed.

## Verification before packaging

- Updated audio smoke suite passed: hardware-idle behavior, clock/FFT updates,
  rapid asynchronous seeks, pause/resume, one Radio-owned completion, full-song
  looping, Studio section handoff and existing precise Studio loops.
- Shared Radio suite passed, including actual automatic song advance, personal
  folder looping, prefetch, source switching, failures and Studio restoration.
- Additional real-file transport checks passed for 44.1 kHz stereo AAC/M4A,
  48 kHz stereo MP3, 48 kHz stereo WAV and 96 kHz mono FLAC. Each checked playback
  clock advance, seeking, resume and exactly one completion. These tests ran
  muted; they are not an audible DAC validation.
- Mac Debug and iOS simulator builds passed. The iOS build verifies the unchanged
  AVAudioPlayer conditional branch still compiles. No new physical iOS listening
  test was performed.
- `git diff --check` passed. The preceding Mac idle-hardware change remains in
  place; see [its verification](mac-audio-hardware-lifecycle.md).

The affected DAC still needs a listening test with this candidate before the
reported crackle can be marked resolved. Device-overload logs alone cannot
prove the new output is clean. Source decoding and a separate resampling probe
previously found no over-range PCM in the examined source passage.

Local diagnostic evidence, excluded from Git:
`/Volumes/Music/Codex Media/PulseCanvas Studio/Development/mac-radio-crackle/`.
Build and delivery evidence:
`/Volumes/Music/Codex Media/PulseCanvas Studio/Platform Builds/mac-1.1.6-28/`.
