# Radio audio playback and personal-song favorites

October 20, 2026. Delivered as 1.1.6 Mac (27), iPhone/iPad (7) and Vision Pro (15).
See the [verified TestFlight delivery](releases/testflight-1.1.6-audio-fix.md).

The owner reported ongoing distortion and popping on Mac and iPhone when playing
personal-folder MP3 and M4A songs. Those files sound clean in other players.

Mac/mobile Radio initially moved to AVAudioPlayer for continuous music playback, matching
the established Vision transport choice. The Studio AVAudioEngine is stopped
while Radio plays, and the independent analyzer still supplies the visual clock,
FFT bands and beat features. Seeking, pause/resume, background audio, next-song
completion and playlist looping use the same public transport controls. Studio
keeps its frame-bounded AVAudioPlayerNode section loops. Returning to Studio
rebuilds its graph while stopped, before configuring the incoming file format.

The subsequent [Mac 1.1.6 (28) candidate](development/mac-radio-media-player.md)
uses AVPlayer for Mac Radio after the owner reported continued crackling with a
USB DAC. The iPhone/iPad path described here remains in place. Its listening
result must be verified separately from the initial 27/7/15 delivery.

The Radio cache also preserves the source extension instead of copying every
format to an M4A-named file. Verified older cache bytes migrate to a correctly
named cache file without redownloading or transcoding. Original user files remain
unchanged. Player duration is used for Radio's final scene boundary so container
priming differences cannot leave a timeline overrun.

Personal-folder songs have no favorite heart in Mac's song list or player, or in
mobile/Vision Radio controls. Personal Radio also hides the catalog-favorites
shortcut. Catalog-song favorites remain available after selecting a catalog
station. Visualizer hearts are retained. The model already rejects adding
personal tracks to catalog-song favorites.

## Verification

- Audio smoke suite passed, including Studio sections and full-song looping,
  plus dedicated Radio clock/FFT updates, pause/seek/resume, completion ownership,
  automatic looping and a return to precise Studio section playback.
- Shared Radio suite passed, including actual end-of-song advance, personal
  playlist wrap/reopen, Studio restoration, favorites and bounded failure paths.
  New format checks verify uppercase WAV and MP3 keep their container extension,
  sample rate, channel count and exact source bytes. Legacy M4A-named cache
  migration succeeds with the original source file absent.
- Vision transport tests passed, including independent Studio/Radio sessions,
  favorites, audio import and personal-folder looping.
- Mac and Vision simulator Debug builds passed. Two native iPhone simulator UI
  tests passed (79.250 seconds, zero failures): background audio/full-screen Radio
  transport and personal-folder playback/Studio isolation. They assert personal
  song hearts and favorites shortcut are absent, visualizer hearts remain, and
  catalog-song hearts return when selecting All music.
- An initial new smoke-test assertion did not compile because a throwing
  initializer was placed inside a nonthrowing precondition closure. It was
  corrected before the passing run; no product-code compilation failed.
- `git diff --check` passed.

The original audible problem was not reproduced using synthetic tones on the
local Mac. A real-time mixer probe on the previous engine showed no sustained
zero gaps or large discontinuities for a 44.1 kHz stereo MP3, 48 kHz stereo WAV
and 96 kHz mono FLAC. Desktop MP3 analysis measured about 0.24 ms median / 0.34 ms
maximum per frame, so this does not establish analysis overload as the cause.
The changes remove the shared Radio engine path and repair a definite cache
container-labeling bug; the owner must confirm the audible result with their
affected files on physical Mac/iPhone hardware. Do not claim those devices or
songs were audibly verified by the automated checks.

Local evidence: `/Volumes/Music/Codex Media/PulseCanvas Studio/Development/audio-folder-fix/`.
