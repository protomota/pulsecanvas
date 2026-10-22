import XCTest

/// UI tests for PulseCanvas Studio on Vision Pro. Every launch uses `-PCUITesting` (VisionLaunchOptions): fresh isolated
/// storage and the bundled demo soundtrack, so results never depend on, or change, the user's own projects.
/// Run: scripts/test-vision-ui.sh [simulator name or UDID]
final class PulseCanvasVisionUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor func testOnboardingSwipesNavigateAndKeepFinalActionExplicit() {
        let app = launch(["-PCOnboardingQA"])
        let progress = app.otherElements["onboardingProgress"]
        XCTAssertTrue(progress.waitForExistence(timeout: 30))
        // Target the window's content: visionOS has no application-wide scene
        // for XCTest to use when synthesizing a spatial swipe.
        let page = app.staticTexts["onboardingTitle"]
        XCTAssertTrue(page.exists)
        func expectStep(_ step: Int) {
            let change = expectation(for: NSPredicate(format: "label BEGINSWITH %@", "Step \(step) of 5"), evaluatedWith: progress)
            wait(for: [change], timeout: 5)
            XCTAssertTrue(app.buttons["onboardingContinue"].isHittable)
        }
        page.swipeRight()
        expectStep(1)
        page.swipeLeft()
        expectStep(2)
        page.swipeRight()
        expectStep(1)
        for step in 2...5 { page.swipeLeft(); expectStep(step) }
        XCTAssertTrue(app.buttons["onboardingRate"].isHittable)
        page.swipeLeft()
        expectStep(5)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Vision-onboarding-swipe-to-support"
        attachment.lifetime = .keepAlways
        add(attachment)
        page.swipeRight()
        expectStep(4)
        app.buttons["onboardingContinue"].tap()
        expectStep(5)
        app.buttons["onboardingContinue"].tap()
        XCTAssertTrue(app.buttons["playPauseButton"].waitForExistence(timeout: 90))
    }

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
        print("RADIO PLAY LABEL: \(play.label)")
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

    @MainActor func testRadioUsesLargePreviewAndBottomControls() {
        let app = launch(["-PCRadio"])
        let play = app.buttons["playPauseButton"]
        XCTAssertTrue(play.waitForExistence(timeout: 90))
        XCTAssertTrue(app.buttons["randomVisualizerButton"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["radioStationPicker"].firstMatch.waitForExistence(timeout: 90))
        XCTAssertFalse(app.buttons["randomizeStyleButton"].exists)
        XCTAssertFalse(app.textFields["visualizerSearchField"].exists)
        XCTAssertFalse(app.sliders["Chaos"].exists)
        let name = app.staticTexts["selectedVisualizerName"]
        XCTAssertTrue(name.exists)
        XCTAssertLessThan(name.frame.midY, app.frame.midY, "Visualizer controls belong above the large preview")
        XCTAssertLessThan(abs(name.frame.midY - app.buttons["randomVisualizerButton"].frame.midY), 50)
        XCTAssertTrue(waitForLabel(play, "Play Radio", timeout: 90), "Actual playback label: \(play.label)")
        let studioTab = app.buttons["Studio"]
        let pinnedFrame = studioTab.frame
        studioTab.tap()
        XCTAssertTrue(app.textFields["visualizerSearchField"].waitForExistence(timeout: 20))
        XCTAssertLessThan(abs(studioTab.frame.minX - pinnedFrame.minX), 2)
        XCTAssertLessThan(abs(studioTab.frame.minY - pinnedFrame.minY), 2)
        app.buttons["Radio"].tap()
        XCTAssertTrue(app.buttons["randomVisualizerButton"].waitForExistence(timeout: 20))
        XCTAssertLessThan(abs(studioTab.frame.minX - pinnedFrame.minX), 2)
        XCTAssertLessThan(abs(studioTab.frame.minY - pinnedFrame.minY), 2)
        play.tap()
        XCTAssertTrue(waitForLabel(play, "Pause Radio", timeout: 120))
        let visualHeart = app.buttons["favoriteRadioVisualizerButton"]
        let songHeart = app.buttons["favoriteRadioSongButton"]
        let songName = app.staticTexts["radioSongName"]
        XCTAssertTrue(songHeart.waitForExistence(timeout: 10))
        for heart in [visualHeart, songHeart] {
            XCTAssertLessThan(abs(heart.frame.width - heart.frame.height), 3, "Radio hearts must have circular button bounds")
        }
        XCTAssertLessThan(visualHeart.frame.maxX, name.frame.minX, "Keep the visualizer heart before its title")
        XCTAssertLessThan(songHeart.frame.maxX, songName.frame.minX, "Keep the song heart before its title")
        let station = app.descendants(matching: .any)["radioStationPicker"].firstMatch
        for item in [songHeart, station, app.buttons["nextRadioSongButton"], app.buttons["favoriteSongsLibraryButton"]] {
            XCTAssertLessThan(abs(item.frame.midY - songName.frame.midY), 4, "Song controls must occupy one horizontal row")
        }
        XCTAssertLessThan(name.frame.midY, songName.frame.midY)
        XCTAssertLessThan(songName.frame.midY, play.frame.midY)
        let oldName = name.label
        app.buttons["randomVisualizerButton"].tap()
        let changed = NSPredicate(format: "label != %@", oldName)
        let changedName = expectation(for: changed, evaluatedWith: name)
        XCTAssertEqual(XCTWaiter().wait(for: [changedName], timeout: 10), .completed)
        XCTAssertTrue(waitForLabel(play, "Pause Radio"))
        play.tap()
        XCTAssertTrue(waitForLabel(play, "Play Radio"))
        if ProcessInfo.processInfo.environment["PULSECANVAS_CAPTURE_APPSTORE"] == "1" {
            Thread.sleep(forTimeInterval: 40)
        }
    }

    @MainActor func testRadioTransportStartsBeforeAnySongIsLoaded() {
        let app = launch(["-PCRadio"])
        let play = app.buttons["playPauseButton"]
        XCTAssertTrue(play.waitForExistence(timeout: 90))
        XCTAssertTrue(waitForLabel(play, "Play Radio", timeout: 90), "Actual playback label: \(play.label)")
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
        XCTAssertTrue(waitForLabel(play, "Play Radio", timeout: 90), "Actual playback label: \(play.label)")
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
        // Opt-in still-capture hold gives Device Hub time to save a native 4K screenshot.
        if let raw = ProcessInfo.processInfo.environment["PULSECANVAS_CAPTURE_STILL_HOLD"],
           let seconds = Double(raw), seconds > 0, seconds <= 60 {
            Thread.sleep(forTimeInterval: seconds)
        }
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

    @MainActor func testInfoOffersRatingsSharingFeedbackAndCredits() throws {
        let app = launch()
        _ = waitForSoundtrack(app)
        app.buttons["visionInfoButton"].tap()
        for action in ["visionSupportReview", "visionSupportShare", "visionSupportFeedback"] {
            XCTAssertTrue(app.buttons[action].waitForExistence(timeout: 10), "Missing support action: \(action)")
            XCTAssertTrue(app.buttons[action].isHittable)
        }
        XCTAssertTrue(app.staticTexts["Free software.\nSupported by people."].exists)
        if ProcessInfo.processInfo.environment["PULSECANVAS_CAPTURE_APPSTORE"] == "1" {
            appStoreCaptureMark("vision-support"); Thread.sleep(forTimeInterval: 25)
        }
        app.buttons["Legal & Credits"].tap()
        XCTAssertTrue(app.staticTexts["Copyright © 2026 Protomota, LLC"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.links["Source code on GitHub"].exists)
        app.buttons["closeVisionInfoButton"].tap()
        XCTAssertTrue(app.buttons["playPauseButton"].waitForExistence(timeout: 10))
    }

    @MainActor func testCaptureAppStoreExportAndSave() throws {
        guard ProcessInfo.processInfo.environment["PULSECANVAS_CAPTURE_APPSTORE"] == "1",
              let audio = ProcessInfo.processInfo.environment["PULSECANVAS_CAPTURE_AUDIO"] else {
            throw XCTSkip("Export capture requires an explicit isolated soundtrack fixture")
        }
        let app = launch(["-PCCaptureAudio", audio, "-PCCaptureScenes", "402,425,341,334,326,325"])
        let play = waitForSoundtrack(app)
        XCTAssertTrue(app.staticTexts["Studio demo"].waitForExistence(timeout: 60))
        play.tap()
        appStoreCaptureMark("save-tour-studio"); Thread.sleep(forTimeInterval: 5)
        app.buttons["exportMP4Button"].tap()
        if app.buttons["Render another video"].waitForExistence(timeout: 1) {
            app.buttons["Render another video"].tap()
        }
        XCTAssertTrue(app.buttons["Render video"].waitForExistence(timeout: 10))
        app.buttons["30 fps"].tap()
        appStoreCaptureMark("save-tour-settings"); Thread.sleep(forTimeInterval: 5)
        app.buttons["Render video"].tap()
        appStoreCaptureMark("save-tour-render-start")
        XCTAssertTrue(app.buttons["Save video"].waitForExistence(timeout: 240))
        appStoreCaptureMark("save-tour-ready"); Thread.sleep(forTimeInterval: 4)
        app.buttons["Save video"].tap()
        appStoreCaptureMark("save-tour-files"); Thread.sleep(forTimeInterval: 5)
        let save = app.buttons["Save"]
        XCTAssertTrue(save.waitForExistence(timeout: 20))
        save.tap()
        XCTAssertTrue(app.staticTexts["Video saved"].waitForExistence(timeout: 30))
        appStoreCaptureMark("save-tour-saved"); Thread.sleep(forTimeInterval: 5)
        appStoreCaptureMark("save-tour-end")
    }

    @MainActor func testCaptureAppStoreRadio() throws {
        guard ProcessInfo.processInfo.environment["PULSECANVAS_CAPTURE_APPSTORE"] == "1" else {
            throw XCTSkip("App Store capture runs only when requested")
        }
        let app = launch(["-PCRadio"])
        let play = app.buttons["playPauseButton"]
        XCTAssertTrue(play.waitForExistence(timeout: 90))
        XCTAssertTrue(waitForLabel(play, "Play Radio", timeout: 90), "Actual playback label: \(play.label)")
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
        app.buttons["randomVisualizerButton"].tap()
        appStoreCaptureMark("radio-fresh-look"); Thread.sleep(forTimeInterval: 8)
        app.buttons["immersiveButton"].tap()
        XCTAssertTrue(app.buttons["backToStudioButton"].waitForExistence(timeout: 60))
        Thread.sleep(forTimeInterval: 6)
        XCTAssertFalse(app.buttons["backToStudioButton"].exists, "Immersive controls must be hidden for the showcase")
        appStoreCaptureMark("radio-immersive-clean")
        Thread.sleep(forTimeInterval: 16)
        appStoreCaptureMark("end")
    }

    @MainActor func testCaptureAppStoreImmersion() throws {
        guard ProcessInfo.processInfo.environment["PULSECANVAS_CAPTURE_APPSTORE"] == "1" else {
            throw XCTSkip("App Store capture runs only when requested")
        }
        let app = launch(["-PCOpenImmersive", "-PCHideRoom", "YES"])
        XCTAssertTrue(app.buttons["backToStudioButton"].waitForExistence(timeout: 120))
        Thread.sleep(forTimeInterval: 6)
        XCTAssertFalse(app.buttons["backToStudioButton"].exists, "Immersive controls must be hidden for the showcase")
        appStoreCaptureMark("immersive-clean")
        Thread.sleep(forTimeInterval: 28)
        appStoreCaptureMark("end")
    }

    @MainActor func testImmersiveControlsKeepFavoritesDistinctAndAligned() throws {
        let app = launch(["-PCRadio"])
        let play = app.buttons["playPauseButton"]
        XCTAssertTrue(play.waitForExistence(timeout: 90))
        XCTAssertTrue(waitForLabel(play, "Play Radio", timeout: 90), "Actual playback label: \(play.label)")
        play.tap()
        XCTAssertTrue(waitForLabel(play, "Pause Radio", timeout: 120))
        // Enter paused so the normal five-second auto-hide cannot race accessibility discovery.
        play.tap()
        XCTAssertTrue(waitForLabel(play, "Play Radio"))
        app.buttons["immersiveButton"].tap()
        XCTAssertTrue(app.buttons["backToStudioButton"].waitForExistence(timeout: 60))
        let immersivePlay = app.buttons["immersivePlayPauseButton"]
        XCTAssertTrue(immersivePlay.waitForExistence(timeout: 10))
        XCTAssertTrue(waitForLabel(immersivePlay, "Play Radio"))
        let song = app.buttons["favoriteImmersiveSongButton"]
        let visualizer = app.buttons["favoriteImmersiveVisualizerButton"]
        XCTAssertTrue(song.waitForExistence(timeout: 10))
        XCTAssertTrue(visualizer.exists)
        XCTAssertEqual(song.label, "Favorite song")
        let originalVisualizer = visualizer.label
        song.tap()
        XCTAssertTrue(waitForLabel(song, "Unfavorite song"))
        XCTAssertEqual(visualizer.label, originalVisualizer)
        visualizer.tap()
        XCTAssertTrue(waitForLabel(visualizer, originalVisualizer == "Favorite visualizer" ? "Unfavorite visualizer" : "Favorite visualizer"))
        XCTAssertEqual(song.label, "Unfavorite song")
        for button in [song, visualizer, app.buttons["backToStudioButton"]] {
            XCTAssertEqual(button.frame.midY, immersivePlay.frame.midY, accuracy: 3, "Immersive controls must share one centered row")
        }
        Thread.sleep(forTimeInterval: 6)
        XCTAssertTrue(app.buttons["backToStudioButton"].exists, "Paused controls must remain visible")
        if ProcessInfo.processInfo.environment["PULSECANVAS_CAPTURE_APPSTORE"] == "1" {
            appStoreCaptureMark("aligned-immersive-controls"); Thread.sleep(forTimeInterval: 25)
        }
    }

    /// Capture distinct, fast-moving native effects on the real one-bar Studio grid.
    @MainActor func testCaptureAppStoreVariety() throws {
        guard ProcessInfo.processInfo.environment["PULSECANVAS_CAPTURE_APPSTORE"] == "1" else {
            throw XCTSkip("App Store capture runs only when requested")
        }
        let scenes = "10,18,16,390,400,416,453,402,425,444,409,319,328,341,360,334,347,326,354,318,325,355,345"
        let app = launch(["-PCOpenImmersive", "-PCHideRoom", "YES", "-PCCaptureScenes", scenes])
        XCTAssertTrue(app.buttons["backToStudioButton"].waitForExistence(timeout: 120))
        Thread.sleep(forTimeInterval: 6)
        XCTAssertFalse(app.buttons["backToStudioButton"].exists)
        appStoreCaptureMark("variety-immersive-clean")
        Thread.sleep(forTimeInterval: 36)
        appStoreCaptureMark("variety-end")
    }

    @MainActor func testCaptureAppStoreElectronicRadio() throws {
        guard ProcessInfo.processInfo.environment["PULSECANVAS_CAPTURE_APPSTORE"] == "1" else {
            throw XCTSkip("App Store capture runs only when requested")
        }
        let scenes = "247,22,314,252,361,330,254,365,306,375,264,332,380,316,338,369,405,210,256,368,340,331,313,352"
        let app = launch(["-PCRadio", "-PCCaptureScenes", scenes])
        let station = app.descendants(matching: .any)["radioStationPicker"].firstMatch
        XCTAssertTrue(station.waitForExistence(timeout: 90))
        station.tap()
        app.buttons["Electronic"].tap()
        let play = app.buttons["playPauseButton"]
        XCTAssertTrue(waitForLabel(play, "Pause Radio", timeout: 120))
        if let desiredSong = ProcessInfo.processInfo.environment["PULSECANVAS_CAPTURE_SONG"] {
            let title = app.staticTexts["radioSongName"]
            for _ in 0..<20 where title.label != desiredSong {
                let previous = title.label
                app.buttons["nextRadioSongButton"].tap()
                let changed = expectation(for: NSPredicate(format: "label != %@", previous), evaluatedWith: title)
                XCTAssertEqual(XCTWaiter().wait(for: [changed], timeout: 120), .completed)
                XCTAssertTrue(waitForLabel(play, "Pause Radio", timeout: 120))
            }
            XCTAssertEqual(title.label, desiredSong, "Requested capture song is not in this station")
        }
        appStoreCaptureMark("electronic-radio-play"); Thread.sleep(forTimeInterval: 5)
        app.buttons["favoriteRadioSongButton"].tap()
        app.buttons["favoriteSongsLibraryButton"].tap()
        XCTAssertTrue(app.buttons["playFavoriteSongsButton"].waitForExistence(timeout: 10))
        appStoreCaptureMark("electronic-radio-favorites"); Thread.sleep(forTimeInterval: 5)
        app.buttons["Done"].tap()
        app.buttons["immersiveButton"].tap()
        XCTAssertTrue(app.buttons["backToStudioButton"].waitForExistence(timeout: 60))
        Thread.sleep(forTimeInterval: 6)
        XCTAssertFalse(app.buttons["backToStudioButton"].exists)
        appStoreCaptureMark("electronic-radio-immersive-clean"); Thread.sleep(forTimeInterval: 20)
        appStoreCaptureMark("electronic-radio-end")
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
