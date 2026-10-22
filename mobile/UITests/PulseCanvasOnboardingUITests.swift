import XCTest

final class PulseCanvasOnboardingUITests: XCTestCase {
    override func setUp() { continueAfterFailure = false; executionTimeAllowance = 180 }

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
