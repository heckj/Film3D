//
//  Film3DUITestsLaunchTests.swift
//  Film3DUITests
//
//  Created by Joseph Heck on 2/15/22.
//

import XCTest

class Film3DUITestsLaunchTests: XCTestCase {

    /// Determines whether the tests in this class should run multiple times, once for each of the target application's UI configurations.
    ///
    /// Returns false by default. If overridden in a UI test subclass to return true, each test in that
    /// class will run multiple times, once for each supported UI configuration of the default target application.
    ///
    /// Supported UI configurations are detected by Xcode according to the settings of the default target app
    /// for the UI test target and may include:
    ///
    /// - Appearances (e.g. light mode, dark mode)
    /// - Orientations (e.g. portrait, landscape)
    /// - Localizations (e.g. en_US, zh_CN)
    ///
    /// Given the above example, one UI configuration would be {dark mode, landscape, en_US}, another would be
    /// {light mode, portrait, zh_CN}, and so forth. The number of combinations determines the number of times each
    /// test will run. The UI configuration is used automatically when calling `XCUIApplication.launch()` in each test.
    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        // Insert steps here to perform after app launch but before taking a screenshot,
        // such as logging into a test account or navigating somewhere in the app

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
