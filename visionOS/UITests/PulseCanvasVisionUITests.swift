import XCTest

/// UI tests for PulseCanvas Studio on Vision Pro. Every launch uses `-PCUITesting` (VisionLaunchOptions): fresh isolated
/// storage and the bundled demo soundtrack, so results never depend on, or change, the user's own projects.
/// Run: scripts/test-vision-ui.sh [simulator name or UDID]
final class PulseCanvasVisionUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    private func launch(_ extra: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-PCUITesting"] + extra
        app.launch()
        return app
    }

    /// Play enables once the bundled soundtrack has been analysed.
    @discardableResult
    private func waitForSoundtrack(_ app: XCUIApplication, timeout: TimeInterval = 90) -> XCUIElement {
        let play = app.buttons["playPauseButton"]
        XCTAssertTrue(play.waitForExistence(timeout: 30), "Play button missing")
        let ready = expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: play)
        wait(for: [ready], timeout: timeout)
        return play
    }

    private func waitForLabel(_ element: XCUIElement, _ label: String, timeout: TimeInterval = 10) -> Bool {
        let changed = expectation(for: NSPredicate(format: "label == %@", label), evaluatedWith: element)
        return XCTWaiter().wait(for: [changed], timeout: timeout) == .completed
    }

    @MainActor func testStudioOpensWithBundledDemo() {
        let app = launch()
        XCTAssertTrue(app.staticTexts["selectedVisualizerName"].waitForExistence(timeout: 30))
        let play = waitForSoundtrack(app)
        XCTAssertEqual(play.label, "Play")
        XCTAssertTrue(app.buttons["immersiveButton"].exists, "Immersive (goggles) button missing")
        XCTAssertTrue(app.buttons["randomVisualizerButton"].exists)
    }

    @MainActor func testPlayAndPauseAdvanceTheSoundtrack() {
        let app = launch()
        let play = waitForSoundtrack(app)
        let elapsed = app.staticTexts["elapsedTime"]
        XCTAssertEqual(elapsed.label, "0:00")
        play.tap()
        XCTAssertTrue(waitForLabel(play, "Pause"), "Playback did not start")
        Thread.sleep(forTimeInterval: 2.5)
        XCTAssertNotEqual(elapsed.label, "0:00", "Time did not advance while playing")
        play.tap()
        XCTAssertTrue(waitForLabel(play, "Play"), "Playback did not pause")
        let paused = elapsed.label
        Thread.sleep(forTimeInterval: 1.5)
        XCTAssertEqual(elapsed.label, paused, "Time advanced while paused")
    }

    @MainActor func testAutoplayLaunchHookStartsPlayback() {
        let app = launch(["-PCAutoplay"])
        let play = app.buttons["playPauseButton"]
        XCTAssertTrue(play.waitForExistence(timeout: 30))
        XCTAssertTrue(waitForLabel(play, "Pause", timeout: 90), "-PCAutoplay did not start playback")
    }

    @MainActor func testRadioTransportStartsBeforeAnySongIsLoaded() {
        let app = launch(["-PCRadio"])
        let play = app.buttons["playPauseButton"]
        XCTAssertTrue(play.waitForExistence(timeout: 90))
        XCTAssertTrue(waitForLabel(play, "Play Radio", timeout: 90))
        XCTAssertTrue(play.isEnabled, "Radio Play must be enabled without a loaded song")
        play.tap()
        XCTAssertTrue(waitForLabel(play, "Pause Radio", timeout: 120), "First Play did not load and play the station")
        play.tap()
        XCTAssertTrue(waitForLabel(play, "Play Radio"), "Radio did not pause")
    }

    @MainActor func testRadioSongFavoritesAndStation() {
        let app = launch(["-PCRadio"])
        let play = app.buttons["playPauseButton"]
        XCTAssertTrue(play.waitForExistence(timeout: 90))
        XCTAssertTrue(waitForLabel(play, "Play Radio", timeout: 90))
        play.tap()
        XCTAssertTrue(waitForLabel(play, "Pause Radio", timeout: 120))
        let heart = app.buttons["favoriteRadioSongButton"]
        XCTAssertTrue(heart.waitForExistence(timeout: 10))
        XCTAssertEqual(heart.label, "Favorite song")
        heart.tap()
        XCTAssertTrue(waitForLabel(heart, "Unfavorite song"))
        app.buttons["favoriteSongsLibraryButton"].tap()
        let favoritesPlay = app.buttons["playFavoriteSongsButton"]
        XCTAssertTrue(favoritesPlay.waitForExistence(timeout: 10) && favoritesPlay.isEnabled)
        favoritesPlay.tap()
        XCTAssertTrue(favoritesPlay.waitForNonExistence(timeout: 10))
        XCTAssertTrue(waitForLabel(play, "Pause Radio", timeout: 120))
        XCTAssertTrue(waitForLabel(heart, "Unfavorite song"))
        app.buttons["favoriteSongsLibraryButton"].tap()
        let remove = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Unfavorite song ")).firstMatch
        XCTAssertTrue(remove.waitForExistence(timeout: 10))
        remove.tap()
        XCTAssertTrue(app.staticTexts["No favorite songs yet"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["playFavoriteSongsButton"].isEnabled)
        app.buttons["Done"].tap()
        XCTAssertTrue(waitForLabel(play, "Play Radio"), "Removing the last favorite must stop the favorites station")
    }

    @MainActor func testClipPickerOnlyOffersSelectionAndSurprise() {
        let app = launch()
        waitForSoundtrack(app)
        let card = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "chooseVisualizer-")).firstMatch
        XCTAssertTrue(card.waitForExistence(timeout: 30))
        card.tap()
        let picker = app.otherElements["clipVisualizerPicker"]
        XCTAssertTrue(picker.waitForExistence(timeout: 10))
        let surprise = app.buttons["surpriseClipVisualizerButton"]
        XCTAssertTrue(surprise.waitForExistence(timeout: 10))
        XCTAssertFalse(picker.sliders.firstMatch.exists, "Style controls must not appear in the clip picker")
        XCTAssertFalse(picker.buttons["Randomize style"].exists)
        surprise.tap()
        XCTAssertTrue(picker.waitForNonExistence(timeout: 10), "Choosing a random visualizer must dismiss the picker")
    }

    @MainActor func testTimelineRandomizerAndFullSliderGrid() {
        let app = launch()
        waitForSoundtrack(app)
        XCTAssertEqual(app.buttons["saveProjectButton"].label, "Save project")
        let chaos = app.sliders["Chaos"], zoom = app.sliders["Zoom speed"], motion = app.sliders["Motion speed"]
        XCTAssertTrue(chaos.exists && zoom.exists && motion.exists)
        XCTAssertEqual(chaos.frame.midY, zoom.frame.midY, accuracy: 2)
        XCTAssertEqual(zoom.frame.midY, motion.frame.midY, accuracy: 2)
        XCTAssertLessThan(chaos.frame.midX, zoom.frame.midX)
        XCTAssertLessThan(zoom.frame.midX, motion.frame.midX)
        for label in ["Brightness", "Depth / fog", "Camera zoom", "Camera rotation", "Blur"] {
            XCTAssertTrue(app.sliders[label].exists, "Missing slider: \(label)")
        }
        let before = app.staticTexts["selectedVisualizerName"].label
        let button = app.buttons["randomizeTimelineButton"]
        XCTAssertTrue(button.isHittable)
        button.tap()
        let sheet = app.otherElements["randomizeTimelineSheet"]
        XCTAssertTrue(sheet.waitForExistence(timeout: 10))
        sheet.buttons["Cancel"].tap()
        XCTAssertTrue(sheet.waitForNonExistence(timeout: 10))
        XCTAssertEqual(app.staticTexts["selectedVisualizerName"].label, before)
        button.tap()
        XCTAssertTrue(sheet.waitForExistence(timeout: 10))
        app.buttons["confirmRandomizeTimelineButton"].tap()
        XCTAssertTrue(sheet.waitForNonExistence(timeout: 10))
        XCTAssertNotEqual(app.staticTexts["selectedVisualizerName"].label, before)
    }

    @MainActor func testVisualizerLaunchHookChoosesTheFirstCard() {
        // Take a visualizer the app itself can use (from Random visualizer), then relaunch asking for it by name.
        let first = launch()
        waitForSoundtrack(first)
        let name = first.staticTexts["selectedVisualizerName"]
        let start = name.label
        for _ in 0..<4 where name.label == start { first.buttons["randomVisualizerButton"].tap(); _ = waitForLabel(name, start, timeout: 2) }
        let wanted = name.label
        XCTAssertNotEqual(wanted, start, "Random visualizer never changed the selection")
        first.terminate()
        let second = launch(["-PCVisualizer", wanted])
        waitForSoundtrack(second)
        XCTAssertTrue(waitForLabel(second.staticTexts["selectedVisualizerName"], wanted), "-PCVisualizer \(wanted) had no effect")
    }

    @MainActor func testRandomVisualizerChangesTheSelection() {
        let app = launch()
        waitForSoundtrack(app)
        let name = app.staticTexts["selectedVisualizerName"]
        let before = name.label
        var changed = false
        for _ in 0..<4 where !changed {   // a random pick can repeat; four tries make a false failure vanishingly rare
            app.buttons["randomVisualizerButton"].tap()
            changed = !waitForLabel(name, before, timeout: 2)
        }
        XCTAssertTrue(changed, "Random visualizer never changed the selection")
    }

    @MainActor func testImmersiveLaunchHookOpensAndReturnsToStudio() {
        let app = launch(["-PCOpenImmersive", "-PCHideRoom", "NO"])
        let back = app.buttons["backToStudioButton"]
        XCTAssertTrue(back.waitForExistence(timeout: 120), "Immersive controls did not appear")
        back.tap()
        XCTAssertTrue(app.buttons["immersiveButton"].waitForExistence(timeout: 30), "Studio did not come back")
    }

    // MARK: - Recorded demo (opt-in)

    private func appStoreCaptureMark(_ name: String) {
        let line = String(format: "APPSTORE-MARK %@ %.3f\n", name, Date().timeIntervalSince1970)
        print(line, terminator: "")
        guard let path = ProcessInfo.processInfo.environment["PULSECANVAS_CAPTURE_MARKS"] else { return }
        if let handle = FileHandle(forWritingAtPath: path) {
            handle.seekToEndOfFile(); handle.write(Data(line.utf8)); try? handle.close()
        } else { try? line.write(toFile: path, atomically: true, encoding: .utf8) }
    }

    @MainActor func testCaptureAppStoreStudio() throws {
        guard ProcessInfo.processInfo.environment["PULSECANVAS_CAPTURE_APPSTORE"] == "1" else {
            throw XCTSkip("App Store capture runs only when requested")
        }
        let app = launch()
        let play = waitForSoundtrack(app)
        play.tap(); appStoreCaptureMark("studio-play")
        Thread.sleep(forTimeInterval: 3)
        app.buttons["randomizeTimelineButton"].tap()
        XCTAssertTrue(app.otherElements["randomizeTimelineSheet"].waitForExistence(timeout: 10))
        appStoreCaptureMark("timeline-options"); Thread.sleep(forTimeInterval: 3)
        app.buttons["confirmRandomizeTimelineButton"].tap()
        appStoreCaptureMark("timeline-randomized"); Thread.sleep(forTimeInterval: 4)
        app.buttons["randomizeStyleButton"].tap()
        appStoreCaptureMark("style"); Thread.sleep(forTimeInterval: 3)
        app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "chooseVisualizer-")).firstMatch.tap()
        XCTAssertTrue(app.buttons["surpriseClipVisualizerButton"].waitForExistence(timeout: 10))
        appStoreCaptureMark("picker"); Thread.sleep(forTimeInterval: 3)
        app.buttons["surpriseClipVisualizerButton"].tap()
        Thread.sleep(forTimeInterval: 3)
        app.buttons["exportMP4Button"].tap()
        if app.buttons["Render another video"].waitForExistence(timeout: 1) {
            app.buttons["Render another video"].tap()
        }
        appStoreCaptureMark("export"); Thread.sleep(forTimeInterval: 4)
        appStoreCaptureMark("end")
    }

    @MainActor func testCaptureAppStoreRadio() throws {
        guard ProcessInfo.processInfo.environment["PULSECANVAS_CAPTURE_APPSTORE"] == "1" else {
            throw XCTSkip("App Store capture runs only when requested")
        }
        let app = launch(["-PCRadio"])
        let play = app.buttons["playPauseButton"]
        XCTAssertTrue(play.waitForExistence(timeout: 90))
        XCTAssertTrue(waitForLabel(play, "Play Radio", timeout: 90))
        play.tap()
        XCTAssertTrue(waitForLabel(play, "Pause Radio", timeout: 120))
        appStoreCaptureMark("radio-play"); Thread.sleep(forTimeInterval: 6)
        app.buttons["favoriteRadioSongButton"].tap()
        app.buttons["favoriteSongsLibraryButton"].tap()
        XCTAssertTrue(app.buttons["playFavoriteSongsButton"].waitForExistence(timeout: 10))
        appStoreCaptureMark("radio-favorites"); Thread.sleep(forTimeInterval: 4)
        app.buttons["playFavoriteSongsButton"].tap()
        XCTAssertTrue(waitForLabel(play, "Pause Radio", timeout: 120))
        app.buttons["randomVisualizerButton"].tap()
        appStoreCaptureMark("radio-shuffle"); Thread.sleep(forTimeInterval: 6)
        app.buttons["randomizeStyleButton"].tap()
        appStoreCaptureMark("radio-style"); Thread.sleep(forTimeInterval: 8)
        appStoreCaptureMark("end")
    }

    /// A paced, human-speed tour for screen recordings; skipped unless PULSECANVAS_CAPTURE_DEMO=1 is passed to the test
    /// runner (TEST_RUNNER_PULSECANVAS_CAPTURE_DEMO=1). Writes "CAPTURE-MARK <name> <unix seconds>" lines to the file in
    /// PULSECANVAS_CAPTURE_MARKS so the recording can be cut on the real moments.
    @MainActor func testCaptureDemoTour() throws {
        let env = ProcessInfo.processInfo.environment
        guard env["PULSECANVAS_CAPTURE_DEMO"] == "1" else { throw XCTSkip("Demo capture runs only when requested") }
        func mark(_ name: String) {
            let line = String(format: "CAPTURE-MARK %@ %.3f\n", name, Date().timeIntervalSince1970)
            print(line, terminator: "")
            guard let path = env["PULSECANVAS_CAPTURE_MARKS"] else { return }
            if let handle = FileHandle(forWritingAtPath: path) {
                handle.seekToEndOfFile(); handle.write(Data(line.utf8)); try? handle.close()
            } else { try? line.write(toFile: path, atomically: true, encoding: .utf8) }
        }
        func pause(_ seconds: Double) { Thread.sleep(forTimeInterval: seconds) }
        var extra: [String] = []
        if let scene = env["PULSECANVAS_CAPTURE_VISUALIZER"] { extra += ["-PCVisualizer", scene] }
        let app = launch(extra)
        let play = waitForSoundtrack(app)
        pause(1.5); mark("studio")
        play.tap(); mark("play"); pause(5)
        for i in 1...3 {
            app.buttons["randomVisualizerButton"].tap(); mark("random-\(i)"); pause(3.5)
        }
        app.buttons["randomizeStyleButton"].tap(); mark("style"); pause(3)
        app.buttons["immersiveButton"].tap(); mark("immersive-tap")
        let back = app.buttons["backToStudioButton"]
        XCTAssertTrue(back.waitForExistence(timeout: 60)); mark("immersive")
        // The tour ends in immersive viewing: its controls auto-hide after five seconds of playback, and the visionOS
        // simulator can't synthesize the tap on the visual that would show them again.
        pause(Double(env["PULSECANVAS_CAPTURE_IMMERSIVE_SECONDS"] ?? "") ?? 15)
        mark("end")
    }
}
