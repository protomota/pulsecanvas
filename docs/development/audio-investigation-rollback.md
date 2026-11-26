# Audio investigation rollback — October 20, 2026

The owner reports that restarting cleared the crackling and requested that the
changes made for this issue be undone. This observation does not establish a
specific root cause. No further playback workaround is included.

## Scope

Restored these files byte-for-byte from `83f23f7^` (`9815199`), before the
investigation changes:

- `Sources/PulseCanvas/AudioController.swift`
- `Sources/PulseCanvas/RadioController.swift`
- `Sources/PulseCanvas/RadioLibrary.swift`
- `scripts/AudioSmoke.swift`
- `scripts/RadioSmoke.swift`

This removes the dedicated AVAudioPlayer Radio transport introduced in
`83f23f7`, the Mac idle-engine lifecycle changes in `a780bcf`, and the Mac
AVPlayer candidate in `8a9d033`, along with their associated tests. It also
restores the preceding cache naming behavior. Radio and Studio again use the
previous AVAudioEngine/AVAudioPlayerNode transport on Mac and mobile. Vision’s
separate transport was not changed by these experiments.

The independent removal of favorite hearts for personal music remains, as do
folder Radio, App Store metadata, and all unrelated work. No user music,
projects, favorites, cached files, device routing or system audio settings were
changed by this rollback. Release build counters remain at their already-used
values; uploaded TestFlight binaries are not modified or replaced by a Git
rollback. Historical delivery and investigation records are retained and marked
as reverted.

## Verification

- Restored audio smoke suite passed, including PCM/FFT, pause/seek/resume,
  section selection and replay, full-song and bounded looping, and stale callbacks.
- Restored Radio smoke suite passed, including personal-folder playback, looping,
  source switching, Studio restoration, favorites and failure handling.
- Mac Debug build passed with code signing disabled.
- All five restored files exactly match `9815199`; personal-song favorite UI and
  uploaded build counters match the prior HEAD unchanged.
- `git diff --check` passed. No new physical-device listening test was performed.
No new TestFlight or website release is part of this rollback.
