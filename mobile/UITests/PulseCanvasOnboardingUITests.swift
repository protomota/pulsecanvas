import XCTest

final class PulseCanvasOnboardingUITests: XCTestCase {
    override func setUp() { continueAfterFailure = false; executionTimeAllowance = 180 }

    @MainActor func testNativeTipsOpenFromOnboardingAndSettings() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-PCMobileQA", "-PCOnboardingQA", "-PCOnboardingStep", "4"]
        app.launch()
        let onboardingTip = app.buttons["onboardingCoffee"]
        XCTAssertTrue(onboardingTip.waitForExistence(timeout: 30))
        onboardingTip.tap()
        let done = app.buttons["tipJarDone"]
        XCTAssertTrue(done.waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Support PulseCanvas"].exists)
        let onboardingShot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        onboardingShot.name = "PulseCanvas-native-tips-onboarding"
        onboardingShot.lifetime = .keepAlways; add(onboardingShot)
        done.tap()
        XCTAssertTrue(app.buttons["onboardingContinue"].isHittable)
        app.buttons["onboardingContinue"].tap()
        let actions = app.buttons["Project actions"]
        XCTAssertTrue(actions.waitForExistence(timeout: 90))
        expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: actions)
        waitForExpectations(timeout: 90)
        actions.tap()
        app.buttons["Settings"].tap()
        let settingsTip = app.buttons["settingsTipPulseCanvas"]
        XCTAssertTrue(settingsTip.waitForExistence(timeout: 10))
        settingsTip.tap()
        XCTAssertTrue(done.waitForExistence(timeout: 10))
        let settingsShot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        settingsShot.name = "PulseCanvas-native-tips-settings"
        settingsShot.lifetime = .keepAlways; add(settingsShot)
        done.tap()
        XCTAssertTrue(settingsTip.waitForExistence(timeout: 5))
        XCTAssertTrue(settingsTip.isHittable)
    }

    @MainActor func testSupporterBadgeIsVisibleInSettings() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-PCMobileQA"]
        app.launchEnvironment["PROTOMOTA_TEST_TIP_STATE"] = "previous"
        app.launch()
        let actions = app.buttons["Project actions"]
        XCTAssertTrue(actions.waitForExistence(timeout: 60))
        actions.tap()
        app.buttons["Settings"].tap()
        let badge = app.descendants(matching: .any)["settingsSupporterBadge"].firstMatch
        XCTAssertTrue(badge.waitForExistence(timeout: 10))
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = "PulseCanvas-supporter-settings"
        shot.lifetime = .keepAlways; add(shot)
        app.buttons["settingsTipPulseCanvas"].tap()
        XCTAssertTrue(app.staticTexts["tipJarSuccessTitle"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.staticTexts["tipJarSuccessTitle"].label, "Thank you for your support")
        app.buttons["tipJarDone"].tap()
        XCTAssertTrue(badge.waitForExistence(timeout: 5))
    }


    @MainActor func testSupportScreenReadability() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-PCMobileQA", "-PCOnboardingQA", "-PCOnboardingStep", "4"]
        app.launchEnvironment["PROTOMOTA_TEST_TIP_STATE"] = "none"
        app.launch()
        XCTAssertTrue(app.buttons["onboardingCoffee"].waitForExistence(timeout: 30))
        app.buttons["onboardingCoffee"].tap()
        XCTAssertTrue(app.buttons["tipJarDone"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["tipJarProduct-com.protomota.pulsecanvas.tip.small"].waitForExistence(timeout: 30))
        defer { XCUIDevice.shared.orientation = .portrait }
        for orientation in [UIDeviceOrientation.portrait, .landscapeLeft] {
            XCUIDevice.shared.orientation = orientation
            let landscape = orientation == .landscapeLeft
            expectation(for: NSPredicate { _, _ in (app.frame.width > app.frame.height) == landscape }, evaluatedWith: app)
            waitForExpectations(timeout: 10)
            for _ in 0..<3 where !app.staticTexts["Keep PulseCanvas growing."].isHittable { app.scrollViews["tipJarContent"].swipeDown() }
            let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            shot.name = "Support-redesign-PulseCanvas-\(orientation.rawValue)"
            shot.lifetime = .keepAlways; add(shot)
            for tier in ["small", "medium", "large"] {
                let product = app.buttons["tipJarProduct-com.protomota.pulsecanvas.tip." + tier]
                for _ in 0..<4 where !product.isHittable { app.scrollViews["tipJarContent"].swipeUp() }
                XCTAssertTrue(product.isHittable && product.isEnabled)
            }
            XCTAssertTrue(app.buttons["tipJarDone"].isHittable)
        }
        app.buttons["tipJarDone"].tap()
        XCTAssertTrue(app.buttons["onboardingContinue"].waitForExistence(timeout: 5))
    }

    @MainActor func testTipSuccessConfirmationKeepsAnotherTipOptional() throws {
        guard ProcessInfo.processInfo.environment["PROTOMOTA_RUN_SANDBOX_CATALOG_TESTS"] == "1" else {
            throw XCTSkip("Explicitly enable the real catalog for success-presentation previews")
        }
        defer { XCUIDevice.shared.orientation = .portrait }
        for state in ["none", "current", "previous"] {
            XCUIDevice.shared.orientation = .portrait
            let app = XCUIApplication()
            app.launchArguments = ["-PCMobileQA", "-PCOnboardingQA", "-PCOnboardingStep", "4"]
            app.launchEnvironment["PROTOMOTA_TEST_TIP_STATE"] = state
            app.launch()
            XCTAssertTrue(app.buttons["onboardingCoffee"].waitForExistence(timeout: 30))
            app.buttons["onboardingCoffee"].tap()
            for tier in ["small", "medium", "large"] {
                XCTAssertTrue(app.buttons["tipJarProduct-com.protomota.pulsecanvas.tip." + tier].waitForExistence(timeout: 30))
            }
            for orientation in [UIDeviceOrientation.portrait, .landscapeLeft] {
                XCUIDevice.shared.orientation = orientation
                let landscape = orientation == .landscapeLeft
                expectation(for: NSPredicate { _, _ in
                    (app.frame.width > app.frame.height) == landscape
                }, evaluatedWith: app)
                waitForExpectations(timeout: 10)
                expectation(for: NSPredicate(format: "hittable == true"), evaluatedWith: app.buttons["tipJarDone"])
                waitForExpectations(timeout: 10)
                if state != "none" {
                    for _ in 0..<4 where !app.staticTexts["tipJarSuccessTitle"].isHittable {
                        app.scrollViews["tipJarContent"].swipeDown()
                    }
                    XCTAssertTrue(app.images["supporterBadgeArtwork"].exists)
                }
                if state == "none" {
                    XCTAssertFalse(app.staticTexts["tipJarSuccessTitle"].exists)
                } else {
                    let title = app.staticTexts["tipJarSuccessTitle"]
                    XCTAssertEqual(title.label, state == "current" ? "Tip completed" : "Thank you for your support")
                    XCTAssertTrue(title.isHittable)
                    XCTAssertTrue(app.staticTexts["tipJarSuccessDetail"].label.contains(state == "current" ? "no further action" : "previous tip"))
                    XCTAssertTrue(app.staticTexts["Leave another tip (optional)"].exists)
                }
                let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
                shot.name = "PulseCanvas-tip-presentation-\(state)-\(orientation.rawValue)"
                shot.lifetime = .keepAlways; add(shot)
                for tier in ["small", "medium", "large"] {
                    let choice = app.buttons["tipJarProduct-com.protomota.pulsecanvas.tip." + tier]
                    for _ in 0..<4 where !choice.isHittable {
                        app.scrollViews["tipJarContent"].swipeUp()
                    }
                    XCTAssertTrue(choice.isEnabled && choice.isHittable, "Another tip stays optional and available")
                }
                XCTAssertTrue(app.buttons["tipJarDone"].isHittable)
                if state != "none" { XCTAssertTrue(app.staticTexts["tipJarSuccessTitle"].exists) }
            }
            app.buttons["tipJarDone"].tap()
            app.terminate()
        }
    }

    @MainActor func testSandboxTipCatalogLoadsThreeConsumables() throws {
        guard ProcessInfo.processInfo.environment["PROTOMOTA_RUN_SANDBOX_CATALOG_TESTS"] == "1" else {
            throw XCTSkip("Enable explicitly when testing the registered app against Apple's sandbox catalog")
        }
        let app = XCUIApplication()
        app.launchArguments = ["-PCMobileQA", "-PCOnboardingQA", "-PCOnboardingStep", "4"]
        app.launch()
        XCTAssertTrue(app.buttons["onboardingCoffee"].waitForExistence(timeout: 30))
        app.buttons["onboardingCoffee"].tap()
        for tier in ["small", "medium", "large"] {
            XCTAssertTrue(app.buttons["tipJarProduct-com.protomota.pulsecanvas.tip." + tier].waitForExistence(timeout: 30),
                          "The real consumable catalog must load without mocked prices")
        }
        defer { XCUIDevice.shared.orientation = .portrait }
        for orientation in [UIDeviceOrientation.portrait, .landscapeLeft] {
            XCUIDevice.shared.orientation = orientation
            let landscape = orientation == .landscapeLeft
            expectation(for: NSPredicate { _, _ in
                (app.frame.width > app.frame.height) == landscape
            }, evaluatedWith: app)
            waitForExpectations(timeout: 10)
            expectation(for: NSPredicate(format: "hittable == true"), evaluatedWith: app.buttons["tipJarDone"])
            waitForExpectations(timeout: 10)
            let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            shot.name = "PulseCanvas-real-sandbox-tip-catalog-\(orientation.rawValue)"
            shot.lifetime = .keepAlways; add(shot)
            XCTAssertTrue(app.buttons["tipJarDone"].isHittable, "Done stays reachable when the tip sheet rotates")
            for tier in ["small", "medium", "large"] {
                let choice = app.buttons["tipJarProduct-com.protomota.pulsecanvas.tip." + tier]
                for _ in 0..<3 where !choice.isHittable {
                    let content = app.scrollViews["tipJarContent"]
                    XCTAssertTrue(content.exists, "Overflowing choices need a scrollable sheet")
                    content.swipeUp()
                }
                XCTAssertTrue(choice.isHittable, "Each tip remains reachable after rotation")
            }
        }
        app.buttons["tipJarDone"].tap()
    }

    @MainActor func testTextStaysTopLeftAlignedAcrossSlidesAndRotation() {
        let app = XCUIApplication()
        app.launchArguments = ["-PCMobileQA", "-PCOnboardingQA"]
        app.launch()
        defer { XCUIDevice.shared.orientation = .portrait }
        let progress = app.otherElements["onboardingProgress"]
        XCTAssertTrue(progress.waitForExistence(timeout: 30))
        for orientation in [UIDeviceOrientation.portrait, .landscapeLeft] {
            XCUIDevice.shared.orientation = orientation
            // Wait for the device's layout to settle before recording origins.
            let landscape = orientation == .landscapeLeft
            let rotated = NSPredicate { _, _ in
                (app.frame.width > app.frame.height) == landscape
            }
            expectation(for: rotated, evaluatedWith: app)
            waitForExpectations(timeout: 10)
            let title = app.staticTexts["onboardingTitle"]
            let subtitle = app.staticTexts["onboardingSubtitle"]
            let titleOrigin = title.frame.origin
            let subtitleOrigin = subtitle.frame.origin
            let buttonOrigin = app.buttons["onboardingContinue"].frame.origin
            for step in 1...5 {
                expectation(for: NSPredicate(format: "label BEGINSWITH %@", "Step \(step) of 5"), evaluatedWith: progress)
                waitForExpectations(timeout: 5)
                XCTAssertEqual(title.frame.minX, titleOrigin.x, accuracy: 1)
                XCTAssertEqual(title.frame.minY, titleOrigin.y, accuracy: 1)
                XCTAssertEqual(subtitle.frame.minX, subtitleOrigin.x, accuracy: 1)
                XCTAssertEqual(subtitle.frame.minY, subtitleOrigin.y, accuracy: 1)
                XCTAssertEqual(title.frame.minX, subtitle.frame.minX, accuracy: 1)
                XCTAssertEqual(app.buttons["onboardingContinue"].frame.minY, buttonOrigin.y, accuracy: 1)
                XCTAssertTrue(app.buttons["onboardingContinue"].isHittable)
                if UIDevice.current.userInterfaceIdiom == .pad && min(app.frame.width, app.frame.height) >= 1000 {
                    let content = app.otherElements["onboardingContent"].frame
                    let centerBetweenControls = (app.buttons["onboardingSkip"].frame.maxY + progress.frame.minY) / 2
                    XCTAssertEqual(content.midY, centerBetweenControls, accuracy: 12, "Center the image and copy between the header and navigation")
                    XCTAssertGreaterThan(title.frame.height, 110, "Large iPads should use the larger title typography")
                }
                let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
                attachment.name = "Onboarding-aligned-\(landscape ? "landscape" : "portrait")-\(step)"
                attachment.lifetime = .keepAlways
                add(attachment)
                if step < 5 { title.swipeLeft() }
            }
            for step in (1...4).reversed() {
                title.swipeRight()
                expectation(for: NSPredicate(format: "label BEGINSWITH %@", "Step \(step) of 5"), evaluatedWith: progress)
                waitForExpectations(timeout: 5)
            }
        }
    }

    @MainActor func testSwipingOverContinueDoesNotFinishOnboarding() {
        let app = XCUIApplication()
        app.launchArguments = ["-PCMobileQA", "-PCOnboardingQA", "-PCOnboardingStep", "4"]
        app.launch()
        let next = app.buttons["onboardingContinue"]
        XCTAssertTrue(next.waitForExistence(timeout: 30))
        next.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.5))
            .press(forDuration: 0.05, thenDragTo: next.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.5)))
        XCTAssertTrue(app.otherElements["onboardingProgress"].label.contains("Step 5 of 5"))
        next.tap()
        XCTAssertTrue(app.buttons["mobileLibraryButton"].waitForExistence(timeout: 30))
    }

    @MainActor func testSwipesNavigateWithoutSkippingPagesOrFinishing() {
        let app = XCUIApplication()
        app.launchArguments = ["-PCMobileQA", "-PCOnboardingQA"]
        app.launch()
        let progress = app.otherElements["onboardingProgress"]
        XCTAssertTrue(progress.waitForExistence(timeout: 30))
        // Use actual content bounds, including on Duo's inner display where
        // the system status region sits beside the application surface.
        let page = app.staticTexts["onboardingTitle"]
        XCTAssertTrue(page.exists)
        func expectStep(_ step: Int) {
            let expected = NSPredicate(format: "label BEGINSWITH %@", "Step \(step) of 5")
            let change = expectation(for: expected, evaluatedWith: progress)
            wait(for: [change], timeout: 5)
            XCTAssertEqual(app.scrollViews.count, 0)
            XCTAssertTrue(app.buttons["onboardingContinue"].isHittable)
        }
        expectStep(1)
        page.swipeRight()
        expectStep(1)
        app.swipeUp()
        expectStep(1)
        let middle = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.45))
        middle.press(forDuration: 0.05, thenDragTo: middle.withOffset(CGVector(dx: -16, dy: 0)))
        expectStep(1)
        page.swipeLeft()
        expectStep(2)
        page.swipeRight()
        expectStep(1)
        let flickStart = page.coordinate(withNormalizedOffset: CGVector(dx: 0.6, dy: 0.5))
        flickStart.press(forDuration: 0.01, thenDragTo: flickStart.withOffset(CGVector(dx: -32, dy: 0)), withVelocity: .fast, thenHoldForDuration: 0)
        expectStep(2)
        page.swipeRight()
        expectStep(1)
        for step in 2...5 {
            page.swipeLeft()
            expectStep(step)
        }
        XCTAssertTrue(app.buttons["onboardingRate"].isHittable)
        page.swipeLeft()
        expectStep(5)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Onboarding-swipe-to-support"
        attachment.lifetime = .keepAlways
        add(attachment)
        page.swipeRight()
        expectStep(4)
        app.buttons["onboardingContinue"].tap()
        expectStep(5)
        app.buttons["onboardingContinue"].tap()
        XCTAssertTrue(app.buttons["mobileLibraryButton"].waitForExistence(timeout: 30))
    }

    @MainActor func testImmediateSkipKeepsSettingsResponsiveWithFullSoundtrack() throws {
        let app = XCUIApplication()
        // Isolated storage, but use the real 2:54 bundled song rather than the
        // eight-second fixture so soundtrack startup isn't hidden by the test.
        app.launchArguments = ["-PCMobileQA", "-PCMobileFullSoundtrackQA", "-PCOnboardingQA"]
        app.launch()
        XCTAssertTrue(app.buttons["onboardingSkip"].waitForExistence(timeout: 15))
        let start = ContinuousClock.now
        app.buttons["onboardingSkip"].tap()
        let actions = app.buttons["Project actions"]
        XCTAssertTrue(actions.waitForExistence(timeout: 3))
        XCTAssertTrue(actions.isEnabled, "Soundtrack preparation must not disable Settings")
        let transition = start.duration(to: .now)
        print("Immediate onboarding skip to enabled editor controls: \(transition)")
        XCTAssertLessThan(transition, .seconds(4), "Leaving onboarding blocked the interface")
        actions.tap()
        XCTAssertTrue(app.buttons["Settings"].waitForExistence(timeout: 3))
        app.buttons["Settings"].tap()
        XCTAssertTrue(app.buttons["settingsWelcomePulseCanvas"].waitForExistence(timeout: 3))
    }

    @MainActor func testNavigationCompletionAndReplay() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-PCMobileQA", "-PCOnboardingQA"]
        app.launch()
        let next = app.buttons["onboardingContinue"]
        XCTAssertTrue(next.waitForExistence(timeout: 30))
        XCTAssertFalse(app.buttons["mobileLibraryButton"].exists, "The editor must stay out of onboarding")
        for step in 1...5 {
            XCTAssertTrue(next.isHittable)
            XCTAssertEqual(app.scrollViews.count, 0, "Onboarding must fit without scrolling")
            XCTAssertTrue(app.buttons["onboardingSkip"].isHittable)
            XCTAssertTrue(app.otherElements["onboardingProgress"].label.contains("Step \(step) of 5"))
            let attachment = XCTAttachment(screenshot: app.screenshot())
            attachment.name = "Onboarding-\(step)"
            attachment.lifetime = .keepAlways
            add(attachment)
            if step < 5 { next.tap() }
        }
        XCTAssertTrue(app.buttons["onboardingRate"].isHittable)
        XCTAssertEqual(app.scrollViews.count, 0, "Every onboarding page must fit without scrolling")
        app.buttons["onboardingBack"].tap()
        XCTAssertTrue(app.otherElements["onboardingProgress"].label.contains("Step 4 of 5"))
        next.tap()
        next.tap()
        XCTAssertTrue(app.buttons["mobileLibraryButton"].waitForExistence(timeout: 90))
        let actions = app.buttons["Project actions"]
        expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: actions)
        waitForExpectations(timeout: 90)
        actions.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        app.buttons["Settings"].tap()
        let welcome = app.buttons["settingsWelcomePulseCanvas"]
        XCTAssertTrue(welcome.waitForExistence(timeout: 10))
        welcome.tap()
        XCTAssertTrue(next.waitForExistence(timeout: 15))
        XCTAssertTrue(app.otherElements["onboardingProgress"].label.contains("Step 1 of 5"))
        app.buttons["onboardingSkip"].tap()
        XCTAssertTrue(app.buttons["mobileLibraryButton"].waitForExistence(timeout: 30))
    }

    @MainActor func testLandscapeAndLargeTextKeepActionsReachable() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-PCMobileQA", "-PCOnboardingQA", "-PCOnboardingStep", "4", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        XCUIDevice.shared.orientation = .landscapeLeft
        defer { XCUIDevice.shared.orientation = .portrait }
        app.launch()
        XCTAssertTrue(app.buttons["onboardingContinue"].waitForExistence(timeout: 30))
        XCTAssertTrue(app.buttons["onboardingContinue"].isHittable)
        XCTAssertTrue(app.buttons["onboardingSkip"].isHittable)
        XCTAssertTrue(app.buttons["onboardingBack"].isHittable)
        XCTAssertEqual(app.scrollViews.count, 0)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Onboarding-landscape-large-text"
        attachment.lifetime = .keepAlways
        add(attachment)
        app.buttons["onboardingSkip"].tap()
        XCTAssertTrue(app.buttons["mobileLibraryButton"].waitForExistence(timeout: 90))
    }
}
