# Onboarding gestures — October 22, 2026

At the owner's request, all three pending App Store Review submissions were
withdrawn before adding swipe navigation. App Store Connect's UI and API confirm
**Developer Rejected** for Mac 1.2 (29), iPhone/iPad 1.2 (9), and Vision Pro
1.2 (16). Their submission receipts now show Removed. Apple TV was not submitted
or uploaded, and Vision Pro's existing live 1.1.5 was retained.

## Changes

- Swipe left to advance one page and right to go back on iPhone, iPad, Duo and
  Vision Pro. Mac supports dragging and horizontal trackpad navigation.
- Swipes stop at the first and last pages. Completion still requires Start
  creating or Skip onboarding. A drag takes priority over button taps so a swipe
  across Continue or Start creating cannot also activate the button.
- Small drags and vertical movement do not change pages. Existing buttons,
  reduced-motion behavior and Settings replay remain available. The progress
  indicator also supports accessibility increment/decrement actions.
- Lesson icons align with the center of their headings, independent of the
  descriptive text below them. All five pages still fit without scrolling.

The next local Release builds are version 1.2: Mac **30**, mobile **10**, and
Vision Pro **17**. All three unsigned device Release builds compiled, retained
the exact transparent onboarding artwork, and passed the check excluding debug
capture/test hooks. These are local engineering builds; no replacement was
uploaded, resubmitted to review or deployed to the website in this follow-up.
Existing TestFlight builds and marketing screenshots were retained.

## Verification

- iPhone: all five onboarding UI tests passed, including immediate Skip with the
  full bundled soundtrack, button navigation/completion/Settings replay,
  landscape with large text, horizontal swipe navigation/boundaries, and dragging
  over the final primary button without finishing onboarding.
- iPad: both gesture and primary-button drag tests passed.
- Duo: both tests passed on the open inner display and the folded outer display.
  The latter was explicitly selected with Device Hub's Closed control; its test
  screenshot is 1398 × 2034, verifying coverage of the outer display.
- Vision Pro: its onboarding swipe/navigation/completion test passed using the
  actual content element as the spatial gesture target.
- Mac: native UI checks verified forward/back dragging, all five pages, stopping
  at the final page, advancing exactly one page when dragging over Continue,
  and leaving the final page open when dragging over Start creating.

The iPhone, iPad, both Duo display states and Vision Pro checks above run in
simulators. Physical touch/pinch and two-finger Mac trackpad hardware were not
tested; Mac click-and-drag was exercised through native UI control.

Thirty updated native screenshots cover all five pages on Mac, iPhone, iPad,
Duo open/closed and Vision Pro. The local screenshot gallery was refreshed;
Apple TV's earlier screenshots remain separate from this update.

Evidence, local builds, screenshots, API withdrawal receipts and test results
are outside Git at:
`/Volumes/Music/Codex Media/PulseCanvas Studio/Platform Builds/onboarding-swipe-1.2-20261022/`.
Generated project build/cache folders were preserved there and linked from their
original workspace paths after the internal disk filled up during testing.

## Support replay and Library follow-up

- Added **Welcome to PulseCanvas Studio** to the Mac's Ratings & Support page,
  matching the existing entry in mobile and Vision Pro settings.
- Every replay gets a fresh onboarding identity and explicitly starts at screen
  one, including after completing the last page or interrupting an earlier replay.
- On Vision Pro, support dismisses before onboarding opens. The established
  spatial editor stays mounted, covered and inactive during replay, so its
  controls remain usable afterward. Its actions now sit inside the editor window.
- Removed the embedded visualizer list from iPad and Vision Pro. Mobile uses its
  existing Library button; Vision Pro now opens its list from a Library button.
  Mac browsing is unchanged. Apple TV already opens its browser separately and
  was not changed.
- Library search releases keyboard focus on selection, submission or dismissal;
  the editor no longer has an inline search field that can leave the iPad keyboard
  accessory bar onscreen.

Validation: Mac Debug build and native support/restart checks passed. Focused
mobile UI tests passed on iPhone, iPad portrait and landscape, and both Duo QA
devices, covering Library search/selection/dismissal, keyboard removal and two
successive Settings replays after completing screen five. Preview bounds fill
the available mobile width. The Duo inner display was also explicitly opened
and captured natively at 2853 × 2007; the outer capture is 1398 × 2034.
Vision Pro Library selection and repeated support replay tests passed; replay
starts at one, hides editor interactions, keeps Continue reachable, and restores
Settings afterward. These checks use simulators, plus the native Mac app.

Latest evidence is outside Git in
`/Volumes/Music/Codex Media/PulseCanvas Studio/Platform Builds/onboarding-support-20261022/`.
The local review gallery has an `updates.html` page with Mac support/replay and
updated editor screenshots. No deployment, upload or review submission was made
for this follow-up; the pending local version/build numbers remain unchanged.

## Vision Pro layout correction

Restored a separate floating control bar below the window. Its actions use neutral
icons with hover labels instead of prominent text buttons. The top-right shuffle,
dice and Library buttons remain unchanged. Visual Style opens a dedicated
1000 × 720 control panel; its scroll area uses the available panel height rather
than a 250-point strip in the editor. The Studio preview keeps its 16:9 proportions
and has over 400 points of height in the default window.

The ornament explicitly hides during onboarding and returns afterward. The
repeated support replay UI test passed with the floating bar. The control-panel
test passed for opening/closing the panel, the full slider grid, the additional
strobe sliders, preview proportions, the retained top-right controls, and timeline
randomization. The updated Debug app was launched in a separate Vision Pro
simulator window with the bundled demo for the owner to test. No deployment or
App Store submission was made.

Evidence: `/Volumes/Music/Codex Media/PulseCanvas Studio/Platform Builds/vision-layout-20261022/`.

## Vision Pro top Visual Style button

Moved Visual Style from the floating lower bar into the top-right header, between
the dice and Library buttons. The same slider panel opens from this button.
The focused simulator UI test passed: header alignment and order, opening and
closing the style panel, slider accessibility, preview size, and timeline
randomization. The updated Debug app is open in the dedicated Vision QA simulator.

The local browser preview is a static PNG, not an interactive app. Automated
spatial taps passed, but native mouse injection through the computer-use tool
did not activate either PulseCanvas controls or the simulator's system Settings
app, including after a data-preserving simulator restart. Direct physical mouse
interaction remains unverified; this is not recorded as an app input fix.

Evidence: `/Volumes/Music/Codex Media/PulseCanvas Studio/Platform Builds/vision-top-controls-20261022/`.
No deployment or review submission was made.

## Mobile preview dice

Added the dice action immediately after shuffle in the shared Studio preview
toolbar for iPhone, iPad and Duo. It randomizes and saves the current visual style
without choosing a different visualizer, matching the existing style-panel action.
The adjacent style and presentation controls remain available.

The focused UI test passed on iPhone, iPad and the folded Duo display, checking
44-point targets within the window, header order, and changed style parameters
with the same visualizer. It requests both portrait and landscape; screenshot
attachments preserve the actual layouts. The test waits for rotation to settle
before measuring controls. On the open Duo, automation did not satisfy the frame
expectation after unfolding; a direct native click on the dice changed the paused
visualizer's appearance while retaining LED Corridor. A native 2853 × 2007
screenshot confirms the open-display toolbar fits.

Evidence: `/Volumes/Music/Codex Media/PulseCanvas Studio/Platform Builds/mobile-dice-20261022/`.
The local screenshot review page is `http://127.0.0.1:8766/mobile-dice.html`.
No deployment, TestFlight upload or App Store submission was made.

## Mobile control placement and presentation spacing

Moved the presentation launcher into the shared mobile header between Library
and More, for both Studio and Radio. In Studio the six actions form two aligned
rows of three: Library / Presentation / More over Shuffle / Dice / Visual Style.
All six use 48 × 44-point buttons and the same eight-point horizontal gaps.
Both rows share their trailing inset, including Duo's corner status area.
Short landscape windows keep the action row above the preview/timeline columns,
with tighter spacing to keep the timeline inside the screen.

The full-screen presentation bar now sits at the bottom edge with eight points
of vertical padding and 44-point buttons. It no longer reserves an additional
bottom safe-area strip. This also applies to Radio presentation.

The focused iPhone and iPad UI checks passed in portrait and landscape for button
alignment and sizing, opening/closing Studio and Radio presentation, current-style
randomization, and the compact bar's lower placement. Native Duo open/folded
captures confirm the aligned editor columns, and a direct click on the relocated
launcher opened presentation on the inner display. Native presentation capture
shows the reduced bottom padding.

Evidence: `/Volumes/Music/Codex Media/PulseCanvas Studio/Platform Builds/mobile-controls-20261022/`.
Screenshot gallery: `http://127.0.0.1:8766/mobile-controls.html`.
No deployment, upload or App Store submission was made.
