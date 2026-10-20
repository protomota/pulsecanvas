import XCTest

final class PulseCanvasMobileUITests: XCTestCase {
    override func setUp() { continueAfterFailure = false }
    @MainActor func testPersonalFolderRadioStaysOutOfStudio() throws {
        let app = XCUIApplication()
        XCUIDevice.shared.orientation = .portrait
        app.launchArguments = ["-PCMobileQA", "-PCMobileRadioQA", "-PCMobileFolderQA"]
        app.launch()
        let library = app.buttons["mobileLibraryButton"]
        XCTAssertTrue(library.waitForExistence(timeout: 30))
        expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: library)
        waitForExpectations(timeout: 90)
        app.buttons["Radio"].tap()
        let title = app.staticTexts["radioCurrentSongTitle"]
        expectation(for: NSPredicate(format: "label == %@", "Personal song"), evaluatedWith: title)
        waitForExpectations(timeout: 60)
        XCTAssertEqual(app.buttons["radioPlaybackButton"].label, "Pause")
        XCTAssertFalse(app.buttons["Favorite song"].exists)
        XCTAssertFalse(app.buttons["Favorite songs"].exists)
        XCTAssertTrue(app.buttons["Favorite radio visualizer"].exists)
        app.buttons["Project actions"].tap()
        XCTAssertFalse(app.buttons["Export MP4"].isEnabled)
        app.buttons["Choose music"].tap()
        let songs = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "studioMusicSong-"))
        expectation(for: NSPredicate { _, _ in songs.count == 2 }, evaluatedWith: app)
        waitForExpectations(timeout: 30)
        XCTAssertFalse(app.buttons["Use Personal song in Studio"].exists)
        app.buttons["cancelStudioMusic"].tap()
        app.buttons["Next song"].tap()
        expectation(for: NSPredicate(format: "label == %@", "Pause"), evaluatedWith: app.buttons["radioPlaybackButton"])
        waitForExpectations(timeout: 30)
        XCTAssertEqual(title.label, "Personal song", "A one-song album loops")
        app.buttons["radioStationPicker"].tap()
        XCTAssertTrue(app.buttons["Choose music folder…"].exists)
        app.buttons["All music"].tap()
        XCTAssertTrue(app.buttons["Favorite song"].waitForExistence(timeout: 30))
        XCTAssertTrue(title.label.hasPrefix("Radio test soundtrack"))
    }

    @MainActor func testChooseLibrarySongAsStudioSoundtrack() throws {
        let app = XCUIApplication()
        XCUIDevice.shared.orientation = .portrait
        app.launchArguments = ["-PCMobileQA", "-PCMobileRadioQA"]
        app.launch()
        let library = app.buttons["mobileLibraryButton"]
        XCTAssertTrue(library.waitForExistence(timeout: 30))
        expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: library)
        waitForExpectations(timeout: 90)
        app.buttons["Radio"].tap()
        let radioPlay = app.buttons["radioPlaybackButton"]
        expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: radioPlay)
        waitForExpectations(timeout: 30)
        radioPlay.tap()
        XCTAssertTrue(app.buttons["Favorite song"].waitForExistence(timeout: 30))
        let title = app.staticTexts["radioCurrentSongTitle"].label
        app.buttons["Favorite song"].tap()
        app.buttons["Project actions"].tap(); app.buttons["Choose music"].tap()
        let songs = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "studioMusicSong-"))
        expectation(for: NSPredicate { _, _ in songs.count == 2 }, evaluatedWith: app)
        waitForExpectations(timeout: 30)
        app.buttons["cancelStudioMusic"].tap()
        XCTAssertEqual(radioPlay.label, "Pause", "Canceling the picker must not stop Radio")
        XCTAssertEqual(app.staticTexts["radioCurrentSongTitle"].label, title)
        app.buttons["Project actions"].tap(); app.buttons["Choose music"].tap()
        expectation(for: NSPredicate { _, _ in songs.count == 2 }, evaluatedWith: app)
        waitForExpectations(timeout: 30)
        app.buttons["Favorites"].tap()
        XCTAssertEqual(songs.count, 1)
        let search = app.textFields["studioMusicSearch"]
        search.tap(); search.typeText("no such song\n")
        XCTAssertTrue(app.staticTexts["No matching favorite songs"].waitForExistence(timeout: 5))
        app.buttons["clearStudioMusicSearch"].tap()
        expectation(for: NSPredicate { _, _ in songs.count == 1 }, evaluatedWith: app)
        waitForExpectations(timeout: 5)
        XCTAssertFalse(app.buttons["clearStudioMusicSearch"].exists)
        app.buttons["Use \(title) in Studio"].coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: app.buttons["cancelStudioMusic"])
        waitForExpectations(timeout: 90)
        XCTAssertTrue(app.buttons["Studio"].isSelected)
        XCTAssertTrue(app.staticTexts[title].exists, "Studio must show the song title rather than a cache hash")
        XCTAssertTrue(app.buttons["Play scene 1"].exists, "Loading a library song creates the Studio timeline")
        app.buttons["mobilePlaybackButton"].tap()
        expectation(for: NSPredicate(format: "label == %@", "Pause"), evaluatedWith: app.buttons["mobilePlaybackButton"])
        waitForExpectations(timeout: 15)
        app.buttons["mobilePlaybackButton"].tap()
        app.buttons["Project actions"].tap(); app.buttons["Export MP4"].tap()
        XCTAssertTrue(app.buttons["Render video"].waitForExistence(timeout: 10))
        app.buttons["720p"].tap(); app.buttons["Render video"].tap()
        XCTAssertTrue(app.buttons["Save video"].waitForExistence(timeout: 180), "Library songs must export with the normal Studio renderer")
    }
    @MainActor func testIPadLandscapeRadioFitsWithoutScrolling() throws {
        let app = XCUIApplication()
        XCUIDevice.shared.orientation = .landscapeLeft
        app.launchArguments = ["-PCMobileQA", "-PCMobileRadioQA"]
        app.launch()
        let library = app.buttons["mobileLibraryButton"]
        XCTAssertTrue(library.waitForExistence(timeout: 30))
        expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: library)
        waitForExpectations(timeout: 90)
        for tab in [app.buttons["Studio"], app.buttons["Radio"]] {
            XCTAssertTrue(tab.isHittable)
            XCTAssertLessThan(tab.frame.midX, app.frame.midX, "iPad workspace tabs stay left-aligned")
            XCTAssertGreaterThanOrEqual(tab.frame.minY, app.frame.minY + 60, "Tabs must sit below the window-control strip")
        }
        app.buttons["Radio"].tap()
        let landscape = app.otherElements["mobileRadioLandscape"]
        XCTAssertTrue(landscape.waitForExistence(timeout: 15))
        XCTAssertEqual(app.scrollViews.count, 0, "Landscape Radio must fit without a scroll container")
        let play = app.buttons["radioPlaybackButton"]
        expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: play)
        waitForExpectations(timeout: 30)
        play.tap()
        expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: app.sliders["radioSongPosition"])
        waitForExpectations(timeout: 30)
        let controls = [app.buttons["Randomize visualizer group"], app.buttons["Random radio visualizer"],
                        app.buttons["Present radio"], app.buttons["Favorite radio visualizer"],
                        app.buttons["Favorite song"], app.buttons["Favorite songs"], app.buttons["Next song"],
                        app.buttons["radioStationPicker"], play, app.sliders["radioSongPosition"], app.sliders["Radio volume"]]
        for control in controls {
            XCTAssertTrue(control.isHittable, "\(control.identifier) must be reachable without scrolling")
            XCTAssertTrue(app.frame.insetBy(dx: -1, dy: -1).contains(control.frame), "\(control.identifier) must stay on screen")
        }
        XCTAssertGreaterThan(app.otherElements["mobileRadioPreview"].frame.height, 200)
        app.buttons["Randomize visualizer group"].tap()
        app.buttons["Randomize favorites"].tap()
        let message = app.staticTexts["No saved favorite visualizers yet. Playing random visualizers from the full library."]
        XCTAssertTrue(message.waitForExistence(timeout: 10))
        XCTAssertTrue(message.isHittable)
        XCTAssertEqual(app.scrollViews.count, 0, "Fallback messaging must also fit")
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Landscape Radio — all controls visible"; screenshot.lifetime = .keepAlways; add(screenshot)
        XCUIDevice.shared.orientation = .portrait
        expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: landscape)
        waitForExpectations(timeout: 10)
        XCTAssertTrue(app.scrollViews.firstMatch.exists, "Portrait keeps the compact-screen layout")
        XCTAssertTrue(app.buttons["Studio"].isHittable)
        XCTAssertTrue(app.buttons["Radio"].isHittable)
        XCTAssertLessThan(app.buttons["Studio"].frame.minX, app.frame.minX + 40)
        XCTAssertGreaterThanOrEqual(app.buttons["Studio"].frame.minY, app.frame.minY + 60, "Portrait tabs must also sit below window controls")
        XCUIDevice.shared.orientation = .landscapeRight
        XCTAssertTrue(landscape.waitForExistence(timeout: 10))
        XCTAssertEqual(app.scrollViews.count, 0)
        XCTAssertEqual(play.label, "Pause", "Rotation must not interrupt playback")
        play.tap()
    }
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
