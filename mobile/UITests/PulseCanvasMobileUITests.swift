import XCTest

final class PulseCanvasMobileUITests: XCTestCase {
    override func setUp() { continueAfterFailure = false }
    @MainActor func testBackgroundAudioAndRadioPresentation() throws {
        let app = XCUIApplication()
        XCUIDevice.shared.orientation = .portrait
        app.launchArguments = ["-PCMobileQA", "-PCMobileRadioQA"]
        app.launch()
        let library = app.buttons["mobileLibraryButton"]
        XCTAssertTrue(library.waitForExistence(timeout: 30))
        expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: library)
        waitForExpectations(timeout: 90)
        let studioPlay = app.buttons["mobilePlaybackButton"]
        studioPlay.tap()
        expectation(for: NSPredicate(format: "label == %@", "Pause"), evaluatedWith: studioPlay)
        waitForExpectations(timeout: 15)
        XCUIDevice.shared.press(.home)
        Thread.sleep(forTimeInterval: 3)
        app.activate()
        XCTAssertEqual(studioPlay.label, "Pause", "Studio audio must keep playing in the background")
        studioPlay.tap()
        app.buttons["Radio"].tap()
        let picker = app.buttons["Randomize visualizer group"]
        XCTAssertTrue(picker.waitForExistence(timeout: 15))
        XCTAssertGreaterThanOrEqual(picker.frame.height, 52)
        picker.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        app.buttons["Randomize all"].tap()
        let play = app.buttons["radioPlaybackButton"]
        expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: play)
        waitForExpectations(timeout: 30)
        play.tap()
        expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: app.sliders["radioSongPosition"])
        waitForExpectations(timeout: 30)
        let before = app.staticTexts["radioElapsedTime"].label
        let firstTitle = app.staticTexts["radioCurrentSongTitle"].label
        XCUIDevice.shared.press(.home)
        Thread.sleep(forTimeInterval: 3)
        app.activate()
        XCTAssertEqual(play.label, "Pause", "Radio audio must keep playing in the background")
        XCTAssertNotEqual(app.staticTexts["radioElapsedTime"].label, before, "The Radio clock must advance in the background")
        app.buttons["Present radio"].tap()
        XCTAssertTrue(app.buttons["presentationNextSong"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["Fit project aspect ratio"].exists)
        XCTAssertFalse(app.switches["Fit project aspect ratio"].exists)
        app.buttons["presentationNextSong"].tap()
        app.buttons["Close"].tap()
        expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: app.sliders["radioSongPosition"])
        waitForExpectations(timeout: 30)
        XCTAssertNotEqual(app.staticTexts["radioCurrentSongTitle"].label, firstTitle)
        XCTAssertEqual(play.label, "Pause")
        play.tap()
        app.buttons["Project actions"].tap()
        XCTAssertTrue(app.buttons["Export MP4"].isEnabled, "A loaded Radio song must be exportable")
        app.buttons["Export MP4"].tap()
        XCTAssertTrue(app.buttons["Render video"].waitForExistence(timeout: 10))
        app.buttons["720p"].tap()
        app.buttons["Render video"].coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        XCTAssertTrue(app.buttons["Save video"].waitForExistence(timeout: 180), "The actual current Radio song must render")
        app.buttons["Done"].tap()
        app.buttons["Project actions"].tap(); app.buttons["Export MP4"].tap()
        XCTAssertTrue(app.buttons["Render video"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["Save video"].exists, "A new export visit must not offer a stale previous movie")
        app.buttons["Done"].tap()
    }
    @MainActor func testStudioCentersPlayingCard() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-PCMobileQA", "-PCMobileRadioQA"]
        app.launch()
        let play = app.buttons["mobilePlaybackButton"]
        XCTAssertTrue(play.waitForExistence(timeout: 30))
        expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: app.buttons["mobileLibraryButton"])
        waitForExpectations(timeout: 90)
        play.tap()
        expectation(for: NSPredicate(format: "label == %@", "Pause"), evaluatedWith: play)
        waitForExpectations(timeout: 15)
        app.sliders["Soundtrack position"].adjust(toNormalizedSliderPosition: 0.5)
        let current = app.otherElements["currentStudioClip"]
        let timeline = app.scrollViews["mobileStudioTimeline"]
        XCTAssertTrue(current.waitForExistence(timeout: 10))
        XCTAssertTrue(timeline.exists)
        expectation(for: NSPredicate { _, _ in
            abs(current.frame.midX - timeline.frame.midX) < 24
        }, evaluatedWith: app)
        waitForExpectations(timeout: 15)
        XCTAssertEqual(play.label, "Pause")
        play.tap()
    }
    @MainActor func testRadioEmptyFavoritesAndScrubbing() throws {
        let app = XCUIApplication()
        XCUIDevice.shared.orientation = ProcessInfo.processInfo.environment["PC_MOBILE_LANDSCAPE"] == "1" ? .landscapeLeft : .portrait
        app.launchArguments = ["-PCMobileQA", "-PCMobileRadioQA"]
        app.launch()
        let library = app.buttons["mobileLibraryButton"]
        XCTAssertTrue(library.waitForExistence(timeout: 30))
        expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: library)
        waitForExpectations(timeout: 90)
        app.buttons["Radio"].tap()
        let play = app.buttons["radioPlaybackButton"]
        XCTAssertTrue(play.waitForExistence(timeout: 20))
        expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: play)
        waitForExpectations(timeout: 30)
        app.buttons["Randomize visualizer group"].tap()
        app.buttons["Randomize favorites"].tap()
        let fallback = app.staticTexts["No saved favorite visualizers yet. Playing random visualizers from the full library."]
        XCTAssertTrue(fallback.waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["retryRadioButton"].exists)
        XCTAssertTrue(play.isEnabled)
        play.tap()
        expectation(for: NSPredicate(format: "label == %@", "Pause"), evaluatedWith: play)
        waitForExpectations(timeout: 30)
        let position = app.sliders["radioSongPosition"]
        expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: position)
        waitForExpectations(timeout: 30)
        let visualHeart = app.buttons["Favorite radio visualizer"]
        let songHeart = app.buttons["Favorite song"]
        let visualHeartFrame = visualHeart.frame
        let songHeartFrame = songHeart.frame
        let playFrame = play.frame
        XCTAssertLessThanOrEqual(visualHeartFrame.maxX, songHeartFrame.maxX + 1)
        XCTAssertGreaterThanOrEqual(playFrame.width, 58)
        play.tap(); XCTAssertEqual(play.label, "Play")
        position.adjust(toNormalizedSliderPosition: 0.35)
        XCTAssertEqual(play.label, "Play", "Scrubbing while paused must stay paused")
        play.tap()
        expectation(for: NSPredicate(format: "label == %@", "Pause"), evaluatedWith: play)
        waitForExpectations(timeout: 15)
        app.buttons["Random radio visualizer"].tap()
        XCTAssertEqual(play.label, "Pause", "Randomizing empty favorites must not stop Radio")
        XCTAssertFalse(app.buttons["retryRadioButton"].exists)
        XCTAssertEqual(visualHeart.frame.minX, visualHeartFrame.minX, accuracy: 1)
        XCTAssertEqual(songHeart.frame.minX, songHeartFrame.minX, accuracy: 1)
        XCTAssertEqual(play.frame.width, playFrame.width, accuracy: 1)
        let screenshot = XCTAttachment(screenshot: app.screenshot()); screenshot.name = "Radio empty favorites fallback"; screenshot.lifetime = .keepAlways; add(screenshot)
        play.tap()
    }
    @MainActor func testStudioAndCompactControls() throws {
        let app = XCUIApplication()
        XCUIDevice.shared.orientation = ProcessInfo.processInfo.environment["PC_MOBILE_LANDSCAPE"] == "1" ? .landscapeLeft : .portrait
        app.launchArguments = ["-PCMobileQA"]
        app.launch()
        let library = app.buttons["mobileLibraryButton"]
        XCTAssertTrue(library.waitForExistence(timeout: 30))
        let enabled = NSPredicate(format: "enabled == true")
        expectation(for: enabled, evaluatedWith: library)
        waitForExpectations(timeout: 90)
        XCTAssertFalse(app.staticTexts["mobileRenderError"].exists)
        let first = XCTAttachment(screenshot: app.screenshot()); first.name = "Studio"; first.lifetime = .keepAlways; add(first)
        let play = app.buttons["mobilePlaybackButton"]
        let heart = app.buttons["Favorite visualizer"]
        let name = app.staticTexts["mobileVisualizerName"]
        XCTAssertLessThan(heart.frame.maxX, name.frame.minX)
        let heartFrame = heart.frame
        let playFrame = play.frame
        XCTAssertGreaterThanOrEqual(playFrame.width, 58)
        XCTAssertTrue(play.isHittable); play.tap()
        expectation(for: NSPredicate(format: "label == %@", "Pause"), evaluatedWith: play)
        waitForExpectations(timeout: 15)
        XCTAssertEqual(play.frame.width, playFrame.width, accuracy: 1)
        play.tap()
        XCTAssertEqual(play.label, "Play")
        XCTAssertEqual(play.frame.width, playFrame.width, accuracy: 1)
        app.buttons["Visual style"].tap()
        XCTAssertTrue(app.sliders["Chaos"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.sliders["Motion speed"].exists)
        XCTAssertTrue(app.sliders["Zoom speed"].exists)
        app.sliders["Chaos"].adjust(toNormalizedSliderPosition: 0.8)
        let style = XCTAttachment(screenshot: app.screenshot()); style.name = "Style controls"; style.lifetime = .keepAlways; add(style)
        app.buttons["Done"].tap()
        library.tap()
        let randomizer = app.buttons["Randomize visualizer group"]
        XCTAssertTrue(randomizer.waitForExistence(timeout: 10))
        XCTAssertGreaterThanOrEqual(randomizer.frame.height, 52)
        let search = app.textFields["modalVisualizerSearch"]
        XCTAssertTrue(search.waitForExistence(timeout: 10))
        search.tap(); search.typeText("Mercury")
        let choose = app.buttons.containing(.staticText, identifier: "Mercury Fold").firstMatch
        XCTAssertTrue(choose.waitForExistence(timeout: 10)); choose.tap()
        XCTAssertEqual(app.staticTexts["mobileVisualizerName"].label, "Mercury Fold")
        XCTAssertEqual(heart.frame.minX, heartFrame.minX, accuracy: 1)
        XCTAssertEqual(heart.frame.width, heartFrame.width, accuracy: 1)
        XCTAssertLessThan(heart.frame.maxX, name.frame.minX)
        let aligned = XCTAttachment(screenshot: app.screenshot()); aligned.name = "Leading heart and stable playback"; aligned.lifetime = .keepAlways; add(aligned)
        app.buttons["Present visualizer"].tap()
        XCTAssertTrue(app.buttons["Close"].waitForExistence(timeout: 10))
        let full = XCTAttachment(screenshot: app.screenshot()); full.name = "Full screen"; full.lifetime = .keepAlways; add(full)
        app.buttons["Close"].tap()
        app.buttons["Project actions"].tap()
        app.buttons["Export MP4"].tap()
        XCTAssertTrue(app.buttons["Render video"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["Done"].exists)
        app.buttons["720p"].tap()
        app.buttons["Render video"].tap()
        XCTAssertTrue(app.buttons["Save video"].waitForExistence(timeout: 180), "The actual eight-second native movie must render")
        let export = XCTAttachment(screenshot: app.screenshot()); export.name = "Export settings"; export.lifetime = .keepAlways; add(export)
        let save = app.buttons["Save video"]
        XCTAssertGreaterThanOrEqual(save.frame.height, 52)
        save.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        XCTAssertTrue(app.buttons["DOCPicker.actionButton"].waitForExistence(timeout: 15))
        let files = XCTAttachment(screenshot: app.screenshot()); files.name = "Native Files save destination"; files.lifetime = .keepAlways; add(files)
        app.buttons["DOCPicker.actionButton"].tap()
        let saved = app.staticTexts["Video saved"].waitForExistence(timeout: 20)
        if !saved { print("FILES SAVE RESULT\n" + app.debugDescription) }
        XCTAssertTrue(saved, "The actual native Files save must finish, not just render the movie")
        app.buttons["Done"].tap()
        XCTAssertFalse(app.staticTexts["mobileRenderError"].exists)
    }
}
