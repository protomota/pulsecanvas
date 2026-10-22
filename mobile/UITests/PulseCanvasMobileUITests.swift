import XCTest

final class PulseCanvasMobileUITests: XCTestCase {
    override func setUp() { continueAfterFailure = false }
    @MainActor func testPreviewDiceRandomizesStyleWithoutChangingVisualizer() {
        let app = XCUIApplication()
        app.launchArguments = ["-PCMobileQA"]
        XCUIDevice.shared.orientation = .portrait
        defer { XCUIDevice.shared.orientation = .portrait }
        app.launch()
        let library = app.buttons["mobileLibraryButton"]
        XCTAssertTrue(library.waitForExistence(timeout: 30))
        expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: library)
        waitForExpectations(timeout: 90)
        for orientation in [UIDeviceOrientation.portrait, .landscapeLeft] {
            XCUIDevice.shared.orientation = orientation
            let dice = app.buttons["mobileRandomizeStyleButton"]
            let shuffle = app.buttons["Random visualizer"]
            let style = app.buttons["Visual style"]
            expectation(for: NSPredicate { _, _ in
                let controls = [dice, shuffle, style, app.buttons["Present visualizer"]]
                return controls.allSatisfy { $0.isHittable && $0.frame.width >= 44 && $0.frame.height >= 44 && app.windows.firstMatch.frame.contains($0.frame) }
                    && abs(dice.frame.midY - shuffle.frame.midY) < 2
            }, evaluatedWith: app)
            waitForExpectations(timeout: 15)
            for button in [dice, shuffle, style, app.buttons["Present visualizer"]] {
                XCTAssertTrue(button.isHittable)
                XCTAssertGreaterThanOrEqual(button.frame.width, 44)
                XCTAssertGreaterThanOrEqual(button.frame.height, 44)
                XCTAssertTrue(app.windows.firstMatch.frame.contains(button.frame))
            }
            XCTAssertEqual(dice.frame.midY, shuffle.frame.midY, accuracy: 2)
            XCTAssertGreaterThan(dice.frame.midX, shuffle.frame.midX)
            XCTAssertLessThan(dice.frame.midX, style.frame.midX)
            let presentation = app.buttons["mobilePresentationButton"]
            let more = app.buttons["Project actions"]
            XCTAssertEqual(presentation.frame.midY, library.frame.midY, accuracy: 2)
            XCTAssertGreaterThan(presentation.frame.midX, library.frame.midX)
            XCTAssertLessThan(presentation.frame.midX, more.frame.midX)
            for (top, bottom) in [(library, shuffle), (presentation, dice), (more, style)] {
                XCTAssertEqual(top.frame.midX, bottom.frame.midX, accuracy: 1)
                XCTAssertEqual(top.frame.width, bottom.frame.width, accuracy: 1)
                XCTAssertEqual(top.frame.height, bottom.frame.height, accuracy: 1)
            }
            let timeline = app.scrollViews["mobileStudioTimeline"]
            XCTAssertTrue(timeline.exists)
            XCTAssertTrue(app.windows.firstMatch.frame.contains(timeline.frame), "The timeline must remain inside the screen after aligning the controls")
            presentation.tap()
            XCTAssertTrue(app.buttons["Close"].waitForExistence(timeout: 10))
            let close = app.buttons["Close"]
            XCTAssertGreaterThanOrEqual(close.frame.height, 44)
            XCTAssertLessThanOrEqual(app.windows.firstMatch.frame.maxY - close.frame.maxY, 16)
            let presentationShot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            presentationShot.name = orientation == .portrait ? "Compact-presentation-portrait" : "Compact-presentation-landscape"
            presentationShot.lifetime = .keepAlways
            add(presentationShot)
            app.buttons["Close"].tap()
            let name = app.staticTexts["mobileVisualizerName"].label
            style.tap()
            XCTAssertTrue(app.buttons["Reset"].waitForExistence(timeout: 10))
            app.buttons["Reset"].tap()
            let before = ["Chaos", "Motion speed", "Zoom speed"].map { String(describing: app.sliders[$0].value) }
            app.buttons["mobileSheetDone"].tap()
            dice.tap()
            XCTAssertEqual(app.staticTexts["mobileVisualizerName"].label, name)
            style.tap()
            XCTAssertTrue(app.buttons["Reset"].waitForExistence(timeout: 10))
            let after = ["Chaos", "Motion speed", "Zoom speed"].map { String(describing: app.sliders[$0].value) }
            XCTAssertNotEqual(after, before, "Dice changes the current look while keeping the selected visualizer")
            app.buttons["mobileSheetDone"].tap()
            let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            shot.name = orientation == .portrait ? "Preview-dice-portrait" : "Preview-dice-landscape"
            shot.lifetime = .keepAlways
            add(shot)
            app.buttons["Radio"].tap()
            XCTAssertEqual(presentation.label, "Present radio")
            presentation.tap()
            XCTAssertTrue(app.buttons["Close"].waitForExistence(timeout: 10))
            app.buttons["Close"].tap()
            app.buttons["Studio"].tap()
        }
    }

    @MainActor func testLibraryOnlyBrowsingAndSettingsAlwaysRestartOnboarding() {
        verifyLibraryAndOnboardingReplay(landscape: true)
    }

    @MainActor func testPortraitLibraryAndOnboardingReplay() {
        verifyLibraryAndOnboardingReplay(landscape: false)
    }

    @MainActor private func verifyLibraryAndOnboardingReplay(landscape: Bool) {
        let app = XCUIApplication()
        XCUIDevice.shared.orientation = landscape ? .landscapeLeft : .portrait
        defer { XCUIDevice.shared.orientation = .portrait }
        app.launchArguments = ["-PCMobileQA", "-PCOnboardingQA", "-PCOnboardingStep", "4"]
        app.launch()
        XCTAssertTrue(app.buttons["onboardingContinue"].waitForExistence(timeout: 30))
        XCTAssertTrue(app.otherElements["onboardingProgress"].label.contains("Step 5 of 5"))
        app.buttons["onboardingContinue"].tap()
        let library = app.buttons["mobileLibraryButton"]
        XCTAssertTrue(library.waitForExistence(timeout: 30))
        expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: library)
        waitForExpectations(timeout: 90)
        XCTAssertFalse(app.descendants(matching: .any)["sidebarVisualizerList"].exists)
        XCTAssertFalse(app.textFields["sidebarVisualizerSearch"].exists)
        for chooseResult in [false, true] {
            library.tap()
            let search = app.textFields["modalVisualizerSearch"]
            XCTAssertTrue(search.waitForExistence(timeout: 10))
            search.tap(); search.typeText("LED Corridor")
            if chooseResult {
                app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "libraryVisualizer-")).firstMatch.tap()
            } else {
                app.buttons["mobileSheetDone"].tap()
            }
            XCTAssertTrue(search.waitForNonExistence(timeout: 10))
            XCTAssertTrue(app.keyboards.firstMatch.waitForNonExistence(timeout: 10), "Closing Library must dismiss the keyboard and its accessory bar")
            XCTAssertTrue(library.isHittable)
        }
        XCTAssertEqual(app.staticTexts["mobileVisualizerName"].label, "LED Corridor")
        let preview = app.otherElements["mobileVisualizerPreview"]
        XCTAssertTrue(preview.exists)
        XCTAssertLessThan(preview.frame.minX - app.windows.firstMatch.frame.minX, 32)
        XCTAssertLessThan(app.windows.firstMatch.frame.maxX - preview.frame.maxX, 32)
        let editorShot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        editorShot.name = "Editor-without-sidebar-or-keyboard-bar"
        editorShot.lifetime = .keepAlways
        add(editorShot)
        for _ in 0..<2 {
            app.buttons["Project actions"].tap()
            app.buttons["Settings"].tap()
            let welcome = app.buttons["settingsWelcomePulseCanvas"]
            XCTAssertTrue(welcome.waitForExistence(timeout: 10))
            welcome.tap()
            let progress = app.otherElements["onboardingProgress"]
            XCTAssertTrue(progress.waitForExistence(timeout: 10))
            XCTAssertTrue(progress.label.contains("Step 1 of 5"))
            app.buttons["onboardingContinue"].tap()
            XCTAssertTrue(progress.label.contains("Step 2 of 5"))
            app.buttons["onboardingSkip"].tap()
            XCTAssertTrue(library.waitForExistence(timeout: 30))
        }
    }

    @MainActor private func nameSaveDestination(in app: XCUIApplication, prefix: String) {
        let filename = app.textFields["DOCPicker.filenameTextField"]
        XCTAssertTrue(filename.waitForExistence(timeout: 10))
        let value = filename.value as? String ?? ""
        filename.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5)).tap()
        filename.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: value.count + 10) + prefix + UUID().uuidString)
    }
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
        app.buttons["Project actions"].coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
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
        radioPlay.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        XCTAssertTrue(app.buttons["Favorite song"].waitForExistence(timeout: 30))
        let title = app.staticTexts["radioCurrentSongTitle"].label
        app.buttons["Favorite song"].tap()
        app.buttons["Project actions"].coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap(); app.buttons["Choose music"].tap()
        let songs = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "studioMusicSong-"))
        expectation(for: NSPredicate { _, _ in songs.count == 2 }, evaluatedWith: app)
        waitForExpectations(timeout: 30)
        app.buttons["cancelStudioMusic"].tap()
        XCTAssertEqual(radioPlay.label, "Pause", "Canceling the picker must not stop Radio")
        XCTAssertEqual(app.staticTexts["radioCurrentSongTitle"].label, title)
        app.buttons["Project actions"].coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap(); app.buttons["Choose music"].tap()
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
        app.buttons["Project actions"].coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap(); app.buttons["Export MP4"].tap()
        XCTAssertTrue(app.buttons["Render video"].waitForExistence(timeout: 10))
        app.buttons["720p"].tap(); app.buttons["Render video"].tap()
        XCTAssertTrue(app.buttons["Save video"].waitForExistence(timeout: 180), "Library songs must export with the normal Studio renderer")
    }
    @MainActor func testExpandedWorkspaceAndTabSwitching() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-PCMobileQA", "-PCMobileRadioQA"]
        app.launch()
        let library = app.buttons["mobileLibraryButton"]
        XCTAssertTrue(library.waitForExistence(timeout: 30))
        expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: library)
        waitForExpectations(timeout: 90)
        let window = app.windows.firstMatch
        print("EXPANDED window: \(window.frame)")
        print("EXPANDED header: \(app.otherElements["mobileWorkspaceHeader"].frame)")
        if window.frame.width >= 520 && window.frame.width > window.frame.height
            || window.frame.width >= 350 && window.frame.height >= 600 {
            let card = app.otherElements["currentStudioClip"]
            XCTAssertTrue(card.waitForExistence(timeout: 10))
            XCTAssertGreaterThan(card.frame.maxY, window.frame.maxY - 25, "Cards should sit at the bottom of the display")
            XCTAssertLessThanOrEqual(card.frame.maxY, window.frame.maxY + 1)
            XCTAssertTrue(app.buttons["Apply to all"].isHittable)
            XCTAssertTrue(app.buttons["Randomize timeline"].isHittable)
        }
        let sidebar = app.descendants(matching: .any)["sidebarVisualizerList"]
        XCTAssertFalse(sidebar.exists, "Visualizer browsing belongs in Library on every mobile display")
        library.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        let modal = app.descendants(matching: .any)["modalVisualizerList"]
        XCTAssertTrue(modal.waitForExistence(timeout: 10))
        XCTAssertGreaterThan(modal.frame.maxY, window.frame.maxY - 5, "Library picker should use its full height")
        print("PC_EXPANDED_CAPTURE library")
        Thread.sleep(forTimeInterval: 5)
        app.buttons["Done"].coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        for round in 0..<3 {
            let start = Date()
            app.buttons["Radio"].coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            let play = app.buttons["radioPlaybackButton"]
            XCTAssertTrue(play.waitForExistence(timeout: 10))
            print("TAB_SWITCH Radio \(round): \(Date().timeIntervalSince(start)) seconds")
            expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: play)
            waitForExpectations(timeout: 30)
            if round == 0 {
                play.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
                expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: app.sliders["radioSongPosition"])
                waitForExpectations(timeout: 45)
            }
            let back = Date()
            app.buttons["Studio"].coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            XCTAssertTrue(app.buttons["mobilePlaybackButton"].waitForExistence(timeout: 10))
            print("TAB_SWITCH Studio \(round): \(Date().timeIntervalSince(back)) seconds")
        }
        print("PC_EXPANDED_CAPTURE studio")
        Thread.sleep(forTimeInterval: 6)
    }

    /// Real library and export UI for the Duo marketing artwork (no QA fixture data).
    @MainActor func testCaptureDuoMarketingDetails() throws {
        let app = XCUIApplication()
        app.launch()
        let library = app.buttons["mobileLibraryButton"]
        XCTAssertTrue(library.waitForExistence(timeout: 30))
        expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: library)
        waitForExpectations(timeout: 90)
        app.buttons["Studio"].tap()
        library.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        XCTAssertTrue(app.textFields["modalVisualizerSearch"].waitForExistence(timeout: 10))
        print("PC_MARKETING_CAPTURE library")
        Thread.sleep(forTimeInterval: 8)
        app.buttons["Done"].coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        app.buttons["Project actions"].coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        app.buttons["Export MP4"].tap()
        XCTAssertTrue(app.buttons["4K"].waitForExistence(timeout: 15))
        app.buttons["4K"].tap()
        app.buttons["60 fps"].tap()
        print("PC_MARKETING_CAPTURE export")
        Thread.sleep(forTimeInterval: 8)
        app.buttons["Done"].coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
    }
    /// Current production layout with the real soundtrack and live Radio catalog.
    /// The host captures the active display at each marker; no QA fixture UI.
    @MainActor func testCaptureCurrentMarketingLayout() throws {
        if let pose = ProcessInfo.processInfo.environment["PC_MARKETING_ORIENTATION"] {
            XCUIDevice.shared.orientation = pose == "landscape" ? .landscapeLeft : .portrait
        }
        let app = XCUIApplication()
        app.launch()
        func tap(_ element: XCUIElement) {
            element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        }
        func capture(_ name: String) {
            print("PC_CURRENT_CAPTURE \(name) window=\(app.windows.firstMatch.frame)")
            Thread.sleep(forTimeInterval: 7)
        }
        let library = app.buttons["mobileLibraryButton"]
        XCTAssertTrue(library.waitForExistence(timeout: 30))
        expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: library)
        waitForExpectations(timeout: 90)
        tap(app.buttons["Studio"]); tap(library)
        let search = app.textFields["modalVisualizerSearch"]
        XCTAssertTrue(search.waitForExistence(timeout: 10))
        let groups = app.buttons.matching(identifier: "Randomize visualizer group")
        tap(groups.element(boundBy: max(0, groups.count - 1))); app.buttons["Randomize all"].tap()
        search.tap(); search.typeText("LED Corridor\n")
        let choices = app.buttons.containing(.staticText, identifier: "LED Corridor")
        XCTAssertTrue(choices.firstMatch.waitForExistence(timeout: 10))
        let choice = choices.element(boundBy: max(0, choices.count - 1))
        choice.coordinate(withNormalizedOffset: CGVector(dx: 0.25, dy: 0.5)).tap()
        expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: search); waitForExpectations(timeout: 15)
        tap(app.buttons["Visual style"])
        XCTAssertTrue(app.buttons["mobilePalettePicker"].waitForExistence(timeout: 10))
        tap(app.buttons["mobilePalettePicker"]); app.buttons["Blue Hour"].tap()
        app.sliders["Chaos"].adjust(toNormalizedSliderPosition: 0.8)
        tap(app.buttons["Done"])
        tap(app.buttons["Play scene 1"])
        expectation(for: NSPredicate(format: "label == %@", "Pause"), evaluatedWith: app.buttons["mobilePlaybackButton"])
        waitForExpectations(timeout: 15)
        Thread.sleep(forTimeInterval: 2); capture("studio")
        tap(app.buttons["Present visualizer"])
        XCTAssertTrue(app.buttons["Close"].waitForExistence(timeout: 10))
        Thread.sleep(forTimeInterval: 5); capture("fullscreen")
        app.windows.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        XCTAssertTrue(app.buttons["Close"].waitForExistence(timeout: 10)); tap(app.buttons["Close"])
        tap(app.buttons["mobilePlaybackButton"])
        tap(app.buttons["Visual style"])
        XCTAssertTrue(app.navigationBars["Visual style"].waitForExistence(timeout: 10)); capture("style")
        tap(app.buttons["Done"]); tap(app.buttons["Radio"])
        let play = app.buttons["radioPlaybackButton"]
        expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: play); waitForExpectations(timeout: 60)
        tap(play)
        expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: app.sliders["radioSongPosition"]); waitForExpectations(timeout: 90)
        Thread.sleep(forTimeInterval: 2); capture("radio"); tap(play)
        tap(app.buttons["Studio"]); tap(library)
        XCTAssertTrue(search.waitForExistence(timeout: 10)); capture("library"); tap(app.buttons["Done"])
        tap(app.buttons["Project actions"]); app.buttons["Export MP4"].tap()
        XCTAssertTrue(app.buttons["4K"].waitForExistence(timeout: 15))
        app.buttons["4K"].tap(); app.buttons["60 fps"].tap(); capture("export")
        tap(app.buttons["Done"])
    }

    @MainActor func testCaptureDuoStoreScreenshots() throws {
        let app = XCUIApplication()
        app.launch()
        let library = app.buttons["mobileLibraryButton"]
        XCTAssertTrue(library.waitForExistence(timeout: 30))
        expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: library)
        waitForExpectations(timeout: 90)
        app.buttons["Studio"].tap()
        library.tap()
        let search = app.textFields["modalVisualizerSearch"]
        XCTAssertTrue(search.waitForExistence(timeout: 10))
        let groupChoices = app.buttons.matching(identifier: "Randomize visualizer group")
        groupChoices.element(boundBy: max(0, groupChoices.count - 1)).tap()
        app.buttons["Randomize all"].tap()
        search.tap(); search.typeText("Octagon Vault\n")
        let choices = app.buttons.containing(.staticText, identifier: "Octagon Vault")
        let foundChoice = choices.firstMatch.waitForExistence(timeout: 10)
        if !foundChoice { print("LIBRARY SEARCH VALUE: \(String(describing: search.value))\n" + app.debugDescription) }
        XCTAssertTrue(foundChoice)
        // The front sheet follows matching cards/sidebar rows in the hierarchy.
        let choose = choices.element(boundBy: max(0, choices.count - 1))
        XCTAssertTrue(choose.isHittable)
        choose.coordinate(withNormalizedOffset: CGVector(dx: 0.25, dy: 0.5)).tap()
        expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: search)
        waitForExpectations(timeout: 15)
        let play = app.buttons["mobilePlaybackButton"]
        play.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        expectation(for: NSPredicate(format: "label == %@", "Pause"), evaluatedWith: play)
        waitForExpectations(timeout: 15)
        Thread.sleep(forTimeInterval: 3)
        print("PC_STORE_CAPTURE studio")
        Thread.sleep(forTimeInterval: 8)
        app.buttons["Present visualizer"].tap()
        XCTAssertTrue(app.buttons["Close"].waitForExistence(timeout: 10))
        Thread.sleep(forTimeInterval: 5)
        print("PC_STORE_CAPTURE fullscreen")
        Thread.sleep(forTimeInterval: 8)
        app.windows.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        XCTAssertTrue(app.buttons["Close"].waitForExistence(timeout: 10)); app.buttons["Close"].tap()
        play.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        app.buttons["Visual style"].tap()
        XCTAssertTrue(app.navigationBars["Visual style"].waitForExistence(timeout: 10))
        print("PC_STORE_CAPTURE style")
        Thread.sleep(forTimeInterval: 8)
        app.buttons["Done"].tap()
        app.buttons["Radio"].tap()
        let radioPlay = app.buttons["radioPlaybackButton"]
        expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: radioPlay)
        waitForExpectations(timeout: 60)
        radioPlay.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: app.sliders["radioSongPosition"])
        waitForExpectations(timeout: 90)
        Thread.sleep(forTimeInterval: 3)
        print("PC_STORE_CAPTURE radio")
        Thread.sleep(forTimeInterval: 8)
        radioPlay.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
    }
    /// Run on Duo's inner and outer displays; capture real UI while checking
    /// the transport survives a geometry change without resetting the session.
    @MainActor func testAdaptiveWindowStudioAndRadio() throws {
        let app = XCUIApplication()
        XCUIDevice.shared.orientation = .portrait
        app.launchArguments = ["-PCMobileQA", "-PCMobileRadioQA"]
        app.launch()
        let library = app.buttons["mobileLibraryButton"]
        XCTAssertTrue(library.waitForExistence(timeout: 30))
        expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: library)
        waitForExpectations(timeout: 90)
        // Duo can report the inactive display's orientation on the application
        // element; the live window is the correct bounds for layout assertions.
        let window = app.windows.firstMatch
        print("Duo geometry: app=\(app.frame), window=\(window.frame), library=\(library.frame)")
        for button in [app.buttons["Studio"], app.buttons["Radio"], library, app.buttons["Project actions"]] {
            XCTAssertTrue(button.isHittable)
            XCTAssertTrue(window.frame.insetBy(dx: -1, dy: -1).contains(button.frame))
        }
        if window.frame.width >= 850 && window.frame.width > window.frame.height {
            XCTAssertTrue(app.otherElements["mobileStudioLandscape"].exists)
            XCTAssertFalse(app.scrollViews.allElementsBoundByIndex.contains { $0.frame.height > 200 && $0.frame.width > 350 },
                "Wide Studio must not have a vertical scroll container")
            let clip = app.otherElements["currentStudioClip"]
            XCTAssertTrue(clip.waitForExistence(timeout: 10))
            XCTAssertTrue(window.frame.insetBy(dx: -1, dy: -1).contains(clip.frame), "Full scene card must fit vertically")
            XCTAssertTrue(app.buttons["Apply to all"].isHittable)
        }
        library.tap()
        let search = app.textFields["modalVisualizerSearch"]
        XCTAssertTrue(search.waitForExistence(timeout: 10))
        search.tap(); search.typeText("Octagon Vault\n")
        let choices = app.buttons.containing(.staticText, identifier: "Octagon Vault")
        let foundChoice = choices.firstMatch.waitForExistence(timeout: 10)
        if !foundChoice { print("LIBRARY SEARCH VALUE: \(String(describing: search.value))\n" + app.debugDescription) }
        XCTAssertTrue(foundChoice)
        // The front sheet follows matching cards/sidebar rows in the hierarchy.
        let choose = choices.element(boundBy: max(0, choices.count - 1))
        XCTAssertTrue(choose.isHittable)
        choose.coordinate(withNormalizedOffset: CGVector(dx: 0.25, dy: 0.5)).tap()
        expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: search)
        waitForExpectations(timeout: 15)
        XCTAssertEqual(app.staticTexts["mobileVisualizerName"].label, "Octagon Vault")
        let studioPlay = app.buttons["mobilePlaybackButton"]
        studioPlay.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        expectation(for: NSPredicate(format: "label == %@", "Pause"), evaluatedWith: studioPlay)
        waitForExpectations(timeout: 15)
        Thread.sleep(forTimeInterval: 2)
        XCTAssertFalse(app.staticTexts["mobileRenderError"].exists)
        let studio = XCTAttachment(screenshot: app.screenshot())
        studio.name = "Duo Studio"; studio.lifetime = .keepAlways; add(studio)
        app.buttons["Visual style"].tap()
        XCTAssertTrue(app.navigationBars["Visual style"].waitForExistence(timeout: 10))
        let style = XCTAttachment(screenshot: app.screenshot())
        style.name = "Duo Visual style"; style.lifetime = .keepAlways; add(style)
        app.buttons["Done"].tap()
        app.buttons["Radio"].tap()
        let play = app.buttons["radioPlaybackButton"]
        expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: play)
        waitForExpectations(timeout: 30)
        play.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        let scrubber = app.sliders["radioSongPosition"]
        expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: scrubber)
        waitForExpectations(timeout: 30)
        XCTAssertEqual(play.label, "Pause")
        if window.frame.width >= 650 {
            XCTAssertTrue(app.otherElements["mobileRadioLandscape"].exists)
            XCTAssertEqual(app.scrollViews.count, 0)
            for control in [play, scrubber, app.buttons["Next song"], app.buttons["Present radio"], app.buttons["radioStationPicker"]] {
                XCTAssertTrue(control.isHittable)
                XCTAssertTrue(window.frame.insetBy(dx: -1, dy: -1).contains(control.frame))
            }
            XCTAssertGreaterThan(app.otherElements["mobileRadioPreview"].frame.height, 180)
            XCTAssertGreaterThanOrEqual(app.otherElements["mobileRadioPreview"].frame.maxX, window.frame.maxX - 20,
                "Radio preview must extend below the side status region to the trailing margin")
        }
        Thread.sleep(forTimeInterval: 2)
        let radio = XCTAttachment(screenshot: app.screenshot())
        radio.name = "Duo Radio"; radio.lifetime = .keepAlways; add(radio)
        XCUIDevice.shared.orientation = .landscapeLeft
        // Some Duo runtime poses keep the active display orientation fixed
        // even when XCTest rotates the inactive display. Assert live geometry.
        print("Duo window after orientation request: \(window.frame)")
        XCTAssertTrue(app.buttons["Radio"].waitForExistence(timeout: 10))
        XCTAssertEqual(play.label, "Pause", "Resizing must retain playback")
        let rotated = XCTAttachment(screenshot: app.screenshot())
        rotated.name = "Duo Radio landscape"; rotated.lifetime = .keepAlways; add(rotated)
        play.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        app.buttons["Studio"].tap()
        if window.frame.width >= 650 && window.frame.width > window.frame.height {
            XCTAssertTrue(app.otherElements["mobileStudioLandscape"].exists)
            XCTAssertFalse(app.scrollViews.allElementsBoundByIndex.contains { $0.frame.height > 200 && $0.frame.width > 350 })
            for control in [app.buttons["mobilePlaybackButton"], app.buttons["Present visualizer"], app.buttons["Apply to all"], app.otherElements["currentStudioClip"]] {
                XCTAssertTrue(control.isHittable)
                XCTAssertTrue(window.frame.insetBy(dx: -1, dy: -1).contains(control.frame), control.debugDescription)
            }
        }
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
        play.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: app.sliders["radioSongPosition"])
        waitForExpectations(timeout: 30)
        // Keep the short QA song stable while querying every control; a slow
        // first simulator boot can otherwise advance during these assertions.
        play.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        XCTAssertEqual(play.label, "Play")
        if !app.buttons["Favorite radio visualizer"].exists { print("RADIO_CONTROL_DEBUG \(app.debugDescription)") }
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
        play.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        XCUIDevice.shared.orientation = .portrait
        XCTAssertTrue(landscape.waitForExistence(timeout: 10))
        XCTAssertEqual(app.scrollViews.count, 0, "A large portrait window also gives Radio a bounded preview")
        XCTAssertTrue(app.buttons["Studio"].isHittable)
        XCTAssertTrue(app.buttons["Radio"].isHittable)
        XCTAssertLessThan(app.buttons["Studio"].frame.minX, app.frame.minX + 40)
        XCTAssertGreaterThanOrEqual(app.buttons["Studio"].frame.minY, app.frame.minY + 60, "Portrait tabs must also sit below window controls")
        XCUIDevice.shared.orientation = .landscapeRight
        XCTAssertTrue(landscape.waitForExistence(timeout: 10))
        XCTAssertEqual(app.scrollViews.count, 0)
        XCTAssertEqual(play.label, "Pause", "Rotation must not interrupt playback")
        play.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
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
        studioPlay.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        expectation(for: NSPredicate(format: "label == %@", "Pause"), evaluatedWith: studioPlay)
        waitForExpectations(timeout: 15)
        XCUIDevice.shared.press(.home)
        Thread.sleep(forTimeInterval: 3)
        app.activate()
        XCTAssertEqual(studioPlay.label, "Pause", "Studio audio must keep playing in the background")
        studioPlay.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        app.buttons["Radio"].tap()
        let picker = app.buttons["Randomize visualizer group"]
        XCTAssertTrue(picker.waitForExistence(timeout: 15))
        XCTAssertGreaterThanOrEqual(picker.frame.height, 51.9)
        picker.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        app.buttons["Randomize all"].tap()
        let play = app.buttons["radioPlaybackButton"]
        expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: play)
        waitForExpectations(timeout: 30)
        play.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
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
        // Pause before inspecting controls so the genuine four-second idle
        // timer cannot hide them during slow simulator accessibility queries.
        app.buttons["presentationPlayback"].coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        XCTAssertFalse(app.buttons["Fit project aspect ratio"].exists)
        XCTAssertFalse(app.switches["Fit project aspect ratio"].exists)
        app.buttons["presentationPlayback"].coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        app.buttons["presentationNextSong"].coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        app.buttons["Close"].tap()
        expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: app.sliders["radioSongPosition"])
        waitForExpectations(timeout: 30)
        XCTAssertNotEqual(app.staticTexts["radioCurrentSongTitle"].label, firstTitle)
        XCTAssertEqual(play.label, "Pause")
        play.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        app.buttons["Project actions"].coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        XCTAssertTrue(app.buttons["Export MP4"].isEnabled, "A loaded Radio song must be exportable")
        app.buttons["Export MP4"].tap()
        XCTAssertTrue(app.buttons["Render video"].waitForExistence(timeout: 10))
        app.buttons["720p"].tap()
        app.buttons["Render video"].coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        XCTAssertTrue(app.buttons["Save video"].waitForExistence(timeout: 180), "The actual current Radio song must render")
        app.buttons["Done"].tap()
        app.buttons["Project actions"].coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap(); app.buttons["Export MP4"].tap()
        XCTAssertTrue(app.buttons["Render video"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["Save video"].exists, "A new export visit must not offer a stale previous movie")
        app.buttons["Done"].tap()
    }
    /// Additional editor controls not exercised by the playback/export tests.
    @MainActor func testStyleTimelineAndProjectMenus() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-PCMobileQA", "-PCMobileRadioQA"]
        app.launch()
        let library = app.buttons["mobileLibraryButton"]
        XCTAssertTrue(library.waitForExistence(timeout: 30))
        expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: library)
        waitForExpectations(timeout: 90)
        app.buttons["Random visualizer"].tap()
        XCTAssertFalse(app.staticTexts["mobileVisualizerName"].label.isEmpty)
        app.buttons["Favorite visualizer"].tap()
        library.tap()
        let groups = app.buttons.matching(identifier: "Randomize visualizer group")
        groups.element(boundBy: max(0, groups.count - 1)).tap()
        app.buttons["Randomize favorites"].tap()
        XCTAssertTrue(app.textFields["modalVisualizerSearch"].exists)
        XCTAssertTrue(String(describing: groups.element(boundBy: max(0, groups.count - 1)).value).contains("favorites"))
        groups.element(boundBy: max(0, groups.count - 1)).tap()
        app.buttons["Randomize Drive & flight"].tap()
        XCTAssertTrue(String(describing: groups.element(boundBy: max(0, groups.count - 1)).value).contains("Drive & flight"))
        groups.element(boundBy: max(0, groups.count - 1)).tap()
        app.buttons["Randomize all"].tap()
        app.buttons["Done"].tap()
        app.buttons["Favorite visualizer"].tap()
        app.buttons["Visual style"].tap()
        XCTAssertTrue(app.buttons["Reset"].waitForExistence(timeout: 10))
        app.buttons["Reset"].tap()
        let defaultChaos = String(describing: app.sliders["Chaos"].value)
        let styleScroll = app.scrollViews["mobileStyleScroll"]
        func reveal(_ element: XCUIElement) {
            for _ in 0..<16 {
                if element.exists && element.isHittable { return }
                let backwards = element.exists && element.frame.midY < styleScroll.frame.minY + 70
                let start = styleScroll.coordinate(withNormalizedOffset: CGVector(dx: 0.03, dy: backwards ? 0.4 : 0.8))
                let end = styleScroll.coordinate(withNormalizedOffset: CGVector(dx: 0.03, dy: backwards ? 0.75 : 0.4))
                start.press(forDuration: 0.05, thenDragTo: end)
            }
            print("STYLE REVEAL FAILURE: \(styleScroll.frame) target: \(element.debugDescription)\n" + app.debugDescription)
            let failure = XCTAttachment(screenshot: app.screenshot()); failure.name = "Style reveal failure"; failure.lifetime = .keepAlways; add(failure)
        }
        for title in ["Chaos", "Motion speed", "Zoom speed", "Brightness", "Element size", "Depth", "Liquid detail", "Content blur"] {
            let slider = app.sliders[title]
            reveal(slider)
            XCTAssertTrue(slider.isHittable, title)
            slider.adjust(toNormalizedSliderPosition: 0.65)
        }
        let strobe = app.switches["mobileStrobeToggle"]
        reveal(strobe); XCTAssertTrue(strobe.isHittable)
        if strobe.value as? String == "0" { strobe.coordinate(withNormalizedOffset: CGVector(dx: 0.93, dy: 0.5)).tap() }
        XCTAssertEqual(strobe.value as? String, "1")
        for title in ["Strobe sensitivity", "Strobe strength"] {
            let slider = app.sliders[title]; reveal(slider)
            XCTAssertTrue(slider.isHittable); slider.adjust(toNormalizedSliderPosition: 0.45)
        }
        for _ in 0..<6 { if strobe.isHittable { break }; styleScroll.swipeDown() }
        strobe.coordinate(withNormalizedOffset: CGVector(dx: 0.93, dy: 0.5)).tap()
        XCTAssertEqual(strobe.value as? String, "0")
        for _ in 0..<6 { if app.buttons["Reset"].isHittable { break }; styleScroll.swipeDown() }
        app.buttons["Randomize visual style"].tap()
        app.buttons["Reset"].tap()
        XCTAssertEqual(String(describing: app.sliders["Chaos"].value), defaultChaos)
        app.buttons["mobilePalettePicker"].tap()
        app.buttons["Blue Hour"].tap()
        app.buttons["Done"].tap()
        app.buttons["Apply to all"].tap()
        XCTAssertTrue(app.buttons["Apply to all scenes"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["Apply to all scenes"].isEnabled)
        for title in ["Bars per scene", "Chaos", "Zoom speed", "Motion speed"] {
            let toggle = app.switches[title]
            toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.93, dy: 0.5)).tap()
            XCTAssertEqual(toggle.value as? String, "1", "Apply setting must enable: \(title)\n" + app.debugDescription)
        }
        for title in ["Common chaos", "Common zoom speed", "Common motion speed"] {
            app.sliders[title].adjust(toNormalizedSliderPosition: 0.4)
        }
        let bars = app.steppers["mobileCommonBars"]
        XCTAssertTrue(bars.isHittable)
        bars.buttons["mobileCommonBars-Increment"].tap()
        XCTAssertEqual(bars.value as? String, "5")
        app.buttons["Apply to all scenes"].tap()
        XCTAssertTrue(app.buttons["Apply to all"].waitForExistence(timeout: 10))
        app.buttons["Randomize timeline"].tap()
        XCTAssertTrue(app.buttons["Randomize visualizers"].waitForExistence(timeout: 10))
        app.buttons["Randomize visualizers"].tap()
        app.buttons["Randomize timeline"].tap(); app.buttons["Randomize bar lengths"].tap()
        app.buttons["Choose visualizer for scene 1"].tap()
        XCTAssertTrue(app.textFields["modalVisualizerSearch"].waitForExistence(timeout: 10))
        app.buttons["Done"].tap()
    }
    @MainActor func testProjectFileActions() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-PCMobileQA", "-PCMobileRadioQA"]
        app.launch()
        let library = app.buttons["mobileLibraryButton"]
        XCTAssertTrue(library.waitForExistence(timeout: 30))
        expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: library)
        waitForExpectations(timeout: 90)
        for action in ["Open project", "Import audio"] {
            app.buttons["Project actions"].coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            XCTAssertTrue(app.buttons[action].waitForExistence(timeout: 10))
            app.buttons[action].coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            let cancel = app.buttons.matching(identifier: "Cancel").firstMatch
            let presented = cancel.waitForExistence(timeout: 20)
            if !presented { print("FILES ACTION FAILURE: \(action)\n" + app.debugDescription) }
            XCTAssertTrue(presented, "\(action) must present its Files interface")
            print("PC_FILES_CANCEL_BEFORE \(action): \(cancel.frame)")
            cancel.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: cancel)
            waitForExpectations(timeout: 15)
            expectation(for: NSPredicate { _, _ in app.buttons["Project actions"].isHittable }, evaluatedWith: app)
            waitForExpectations(timeout: 10)
        }
        app.buttons["Project actions"].coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap(); app.buttons["Save project"].tap()
        let saveProject = app.buttons["DOCPicker.actionButton"]
        XCTAssertTrue(saveProject.waitForExistence(timeout: 15))
        nameSaveDestination(in: app, prefix: "PulseCanvas-QA-Project-")
        saveProject.tap()
        expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: saveProject)
        waitForExpectations(timeout: 15)
        XCTAssertTrue(app.buttons["Project actions"].isHittable)
        app.buttons["Project actions"].coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap(); app.buttons["About & Support"].tap()
        XCTAssertTrue(app.navigationBars["About & Support"].waitForExistence(timeout: 10))
        app.buttons["Done"].tap()
    }
    @MainActor func testSceneAndExportOptionControls() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-PCMobileQA", "-PCMobileRadioQA"]
        app.launch()
        let library = app.buttons["mobileLibraryButton"]
        XCTAssertTrue(library.waitForExistence(timeout: 30))
        expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: library)
        waitForExpectations(timeout: 90)
        let loop = app.descendants(matching: .any).matching(identifier: "Loop soundtrack").firstMatch
        XCTAssertTrue(loop.isHittable)
        let originalLoop = "\(String(describing: loop.value))-\(loop.isSelected)"
        loop.tap(); XCTAssertNotEqual("\(String(describing: loop.value))-\(loop.isSelected)", originalLoop)
        loop.tap(); XCTAssertEqual("\(String(describing: loop.value))-\(loop.isSelected)", originalLoop)
        app.buttons["Play scene 1"].tap()
        let play = app.buttons["mobilePlaybackButton"]
        expectation(for: NSPredicate(format: "label == %@", "Pause"), evaluatedWith: play)
        waitForExpectations(timeout: 10)
        play.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        let bars = app.steppers["sceneBars-0"]
        XCTAssertTrue(bars.isHittable)
        let before = bars.value as? String
        bars.buttons["sceneBars-0-Increment"].tap()
        XCTAssertNotEqual(bars.value as? String, before)
        bars.buttons["sceneBars-0-Decrement"].tap()
        XCTAssertEqual(bars.value as? String, before)
        app.buttons["Select scene 1"].coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.2)).tap()
        app.buttons["Present visualizer"].tap()
        XCTAssertTrue(app.buttons["Close"].waitForExistence(timeout: 10))
        app.buttons["Randomize"].tap()
        let presentationPlay = app.buttons["presentationPlayback"]
        presentationPlay.tap()
        expectation(for: NSPredicate(format: "label == %@", "Pause"), evaluatedWith: presentationPlay)
        waitForExpectations(timeout: 10); presentationPlay.tap()
        app.buttons["Close"].tap()
        app.buttons["Project actions"].coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap(); app.buttons["Export MP4"].tap()
        XCTAssertTrue(app.buttons["Render video"].waitForExistence(timeout: 10))
        let canvas = app.buttons["mobileExportCanvas"]
        for option in ["4:3 · Landscape", "3:4 · Portrait", "9:16 · Phone", "1:1 · Square", "16:9 · Wide"] {
            canvas.tap(); app.buttons[option].tap()
            XCTAssertTrue(canvas.label.contains(option) || String(describing: canvas.value).contains(option))
        }
        for option in ["1080p", "4K", "720p", "24 fps", "30 fps", "60 fps"] {
            app.buttons[option].tap(); XCTAssertTrue(app.buttons[option].isSelected)
        }
        app.buttons["4K"].tap()
        app.buttons["Render video"].tap()
        let cancel = app.buttons["Cancel export"]
        XCTAssertTrue(cancel.waitForExistence(timeout: 10)); cancel.tap()
        XCTAssertTrue(app.buttons["Render video"].waitForExistence(timeout: 30))
        XCTAssertFalse(app.buttons["Save video"].exists)
        app.buttons["720p"].tap(); app.buttons["30 fps"].tap()
        app.buttons["Done"].tap()
    }
    @MainActor func testRadioFavoriteSongControls() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-PCMobileQA", "-PCMobileRadioQA"]
        app.launch()
        let library = app.buttons["mobileLibraryButton"]
        XCTAssertTrue(library.waitForExistence(timeout: 30))
        expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: library)
        waitForExpectations(timeout: 90)
        app.buttons["Radio"].tap()
        let play = app.buttons["radioPlaybackButton"]
        expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: play)
        waitForExpectations(timeout: 30)
        play.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        XCTAssertTrue(app.buttons["Favorite song"].waitForExistence(timeout: 30))
        let title = app.staticTexts["radioCurrentSongTitle"].label
        app.buttons["Favorite song"].tap()
        app.buttons["Favorite songs"].tap()
        XCTAssertTrue(app.buttons["Play favorite songs"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["Play favorite songs"].isEnabled)
        app.buttons["Play favorite songs"].tap()
        expectation(for: NSPredicate(format: "label == %@", "Favorite songs"), evaluatedWith: app.buttons["radioStationPicker"])
        waitForExpectations(timeout: 10)
        let lists = app.buttons.matching(identifier: "Favorite songs")
        // The song-list button precedes the station picker with the same title.
        lists.firstMatch.tap()
        XCTAssertTrue(app.buttons["Unfavorite \(title)"].waitForExistence(timeout: 10))
        app.buttons["Unfavorite \(title)"].tap()
        XCTAssertFalse(app.buttons["Play favorite songs"].isEnabled)
        app.buttons["Done"].tap()
        app.buttons["radioStationPicker"].tap(); app.buttons["All music"].tap()
        expectation(for: NSPredicate(format: "label == %@", "Pause"), evaluatedWith: play)
        waitForExpectations(timeout: 30)
        let visualHeart = app.buttons["Favorite radio visualizer"]
        visualHeart.tap(); visualHeart.tap()
        if app.sliders["Radio volume"].exists {
            app.sliders["Radio volume"].adjust(toNormalizedSliderPosition: 0.35)
            app.sliders["Radio volume"].adjust(toNormalizedSliderPosition: 0.75)
        }
        play.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
    }
    @MainActor func testStudioCentersPlayingCard() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-PCMobileQA", "-PCMobileRadioQA"]
        app.launch()
        let play = app.buttons["mobilePlaybackButton"]
        XCTAssertTrue(play.waitForExistence(timeout: 30))
        expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: app.buttons["mobileLibraryButton"])
        waitForExpectations(timeout: 90)
        play.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
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
        play.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
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
        play.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
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
        XCTAssertGreaterThanOrEqual(playFrame.width, 57.9)
        play.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap(); XCTAssertEqual(play.label, "Play")
        position.adjust(toNormalizedSliderPosition: 0.35)
        XCTAssertEqual(play.label, "Play", "Scrubbing while paused must stay paused")
        play.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        expectation(for: NSPredicate(format: "label == %@", "Pause"), evaluatedWith: play)
        waitForExpectations(timeout: 15)
        app.buttons["Random radio visualizer"].tap()
        XCTAssertEqual(play.label, "Pause", "Randomizing empty favorites must not stop Radio")
        XCTAssertFalse(app.buttons["retryRadioButton"].exists)
        XCTAssertEqual(visualHeart.frame.minX, visualHeartFrame.minX, accuracy: 1)
        XCTAssertEqual(songHeart.frame.minX, songHeartFrame.minX, accuracy: 1)
        XCTAssertEqual(play.frame.width, playFrame.width, accuracy: 1)
        let screenshot = XCTAttachment(screenshot: app.screenshot()); screenshot.name = "Radio empty favorites fallback"; screenshot.lifetime = .keepAlways; add(screenshot)
        play.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
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
        XCTAssertGreaterThanOrEqual(playFrame.width, 57.9)
        XCTAssertTrue(play.isHittable); play.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        expectation(for: NSPredicate(format: "label == %@", "Pause"), evaluatedWith: play)
        waitForExpectations(timeout: 15)
        XCTAssertEqual(play.frame.width, playFrame.width, accuracy: 1)
        play.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
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
        let randomizers = app.buttons.matching(identifier: "Randomize visualizer group")
        XCTAssertTrue(randomizers.firstMatch.waitForExistence(timeout: 10))
        let randomizer = randomizers.element(boundBy: max(0, randomizers.count - 1))
        XCTAssertGreaterThanOrEqual(randomizer.frame.height, 51.9)
        let search = app.textFields["modalVisualizerSearch"]
        XCTAssertTrue(search.waitForExistence(timeout: 10))
        search.tap(); search.typeText("Mercury\n")
        let choices = app.buttons.containing(.staticText, identifier: "Mercury Fold")
        XCTAssertTrue(choices.firstMatch.waitForExistence(timeout: 10))
        choices.element(boundBy: max(0, choices.count - 1)).coordinate(withNormalizedOffset: CGVector(dx: 0.25, dy: 0.5)).tap()
        XCTAssertEqual(app.staticTexts["mobileVisualizerName"].label, "Mercury Fold")
        XCTAssertEqual(heart.frame.minX, heartFrame.minX, accuracy: 1)
        XCTAssertEqual(heart.frame.width, heartFrame.width, accuracy: 1)
        XCTAssertLessThan(heart.frame.maxX, name.frame.minX)
        let aligned = XCTAttachment(screenshot: app.screenshot()); aligned.name = "Leading heart and stable playback"; aligned.lifetime = .keepAlways; add(aligned)
        app.buttons["Present visualizer"].tap()
        XCTAssertTrue(app.buttons["Close"].waitForExistence(timeout: 10))
        let full = XCTAttachment(screenshot: app.screenshot()); full.name = "Full screen"; full.lifetime = .keepAlways; add(full)
        app.buttons["Close"].tap()
        app.buttons["Project actions"].coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        app.buttons["Export MP4"].tap()
        XCTAssertTrue(app.buttons["Render video"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["Done"].exists)
        app.buttons["720p"].tap()
        app.buttons["Render video"].tap()
        XCTAssertTrue(app.buttons["Save video"].waitForExistence(timeout: 180), "The actual eight-second native movie must render")
        let export = XCTAttachment(screenshot: app.screenshot()); export.name = "Export settings"; export.lifetime = .keepAlways; add(export)
        let save = app.buttons["Save video"]
        XCTAssertGreaterThanOrEqual(save.frame.height, 51.9)
        save.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        XCTAssertTrue(app.buttons["DOCPicker.actionButton"].waitForExistence(timeout: 15))
        let files = XCTAttachment(screenshot: app.screenshot()); files.name = "Native Files save destination"; files.lifetime = .keepAlways; add(files)
        // Debug QA exports have unique names, so prior saved movies remain intact.
        app.buttons["DOCPicker.actionButton"].coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        let saved = app.staticTexts["Video saved"].waitForExistence(timeout: 20)
        if !saved { print("FILES SAVE RESULT\n" + app.debugDescription) }
        XCTAssertTrue(saved, "The actual native Files save must finish, not just render the movie")
        app.buttons["Done"].tap()
        XCTAssertFalse(app.staticTexts["mobileRenderError"].exists)
    }
}
