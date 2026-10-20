# Mobile export and background listening

## Behavior

The Project actions menu previously disabled Export MP4 whenever Radio was
active, including after its song had finished loading. A loaded Radio song can
now open Export MP4 and render the full current song with its current visualizer.
Studio exports retain their scene timeline and saved appearances. Opening Export
again starts a fresh export visit rather than offering the last song's movie.

Render and Save have full-width touch targets and remain at the bottom of the
export view on small screens. Save opens the native Files destination picker;
the app counts a successful save only after that picker confirms a destination.
The randomizer group dropdown is also larger in Library and Radio, with a
52-point minimum touch height and a hit region across its rounded label.

Backgrounding no longer explicitly pauses Studio or Radio audio. The iOS target
declares background audio, configures the playback audio session, and activates
it only when playback starts. Invisible Metal views stop drawing, per-frame
analysis pauses, and playback position refreshes at most once per second while
backgrounded. Returning restores visualization. An in-progress video render is
cancelled when the app actually enters the background; video export is not a
background task.

Native Now Playing metadata and remote Play/Pause, seeking, and Radio Next use
the same playback controllers. Audio interruptions pause playback, and resume
only when the system allows it and playback had been requested. Disconnecting
the audio route pauses playback. Loading the demo paused does not claim another
app's Now Playing controls.

Mobile presentation always fills its view, removes Fit, and includes Next song
when presenting Radio. Mac and Vision presentation controls are unchanged.

## Verification

- iPhone 17, iOS 27 simulator: both targeted UI tests passed, zero failures.
  These exercise the menu's Export MP4 action while Radio is active, actual
  30-second Radio rendering, a fresh subsequent export visit, an eight-second
  Studio render, and saving that movie through the native Files picker. They
  also check dropdown/button sizing, background-and-return playback for Studio
  and Radio, an advancing Radio clock, full-screen Next changing the song, and
  the absence of Fit.
- The saved iPhone Files-provider movie is H.264/AAC, 1280×720 at 30 fps,
  7.998980 seconds. FFmpeg decoded the full saved file without errors.
- iPad Pro 13-inch (M5), iOS 27 simulator: the same two targeted tests passed,
  zero failures, including Radio export and the actual Files save callback.
- Shared Radio smoke suite passed with command exit 0.
- Debug simulator compilation, Release device archive, manual App Store
  distribution export, strict signature verification, and App Store provisioning
  checks passed. The final signed IPA contains version 1.1.5, build 4, both
  device families, the audio background mode, and 336 native effects. Its
  catalog, shaders, soundtrack, license and privacy manifest match source;
  projectM, external presets, Sparkle and mobile Debug launch fixtures are absent.
- `git diff --check` passed.

An earlier Radio test fixture used an invalid song ID and could fall back to a
cached catalog. The final tests use two valid UUID song IDs, a local generated
soundtrack, and an isolated Radio defaults suite. Earlier exploratory runs also
incorrectly expected the native Files Cancel accessibility element to be a
button. The final iPhone test instead performs the real Save action and verifies
the app's success callback. Xcode's runner remained alive during post-suite
cleanup after the successful iPhone suite; its completed owned process was
terminated. This is a passing XCTest suite, not a claimed normal xcodebuild exit.
The iPad suite also reports two passed tests; its runner cleanup is assessed
separately from those test assertions.

Physical-device lock-screen playback, Bluetooth/headset remote commands,
telephone interruptions, and sustained 4K export performance were not tested.
Simulator Home/background checks do not establish those physical-device results.

Apple references: [media playback configuration](https://developer.apple.com/documentation/avfoundation/configuring-your-app-for-media-playback),
[Now Playing integration](https://developer.apple.com/documentation/mediaplayer/becoming-a-now-playable-app),
[audio interruptions](https://developer.apple.com/documentation/avfaudio/handling-audio-interruptions).

Local test logs are under
`/Volumes/Music/Codex Media/PulseCanvas Studio/Mobile QA/2026-10-20/`.
Final packaging evidence is under
`/Volumes/Music/Codex Media/PulseCanvas Studio/Platform Builds/mobile-1.1.5-4/`.
