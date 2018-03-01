//
//  ExampleUITests.swift
//  ExampleUITests
//
//  Created by Martin Barreto on 11/16/15.
//  Copyright © 2015 Xmartlabs. All rights reserved.
//

@testable import Example
import XLActionController
import XCTest


class ExampleUITests: XCTestCase {

    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()
        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testPeriscope() {
        let app = XCUIApplication()
        app.tables.staticTexts["Periscope"].tap()
        app.images["pe-background"].tap()
        XCTAssertEqual(app.collectionViews.cells.count, 2)
        XCTAssert(app.collectionViews.staticTexts["Are you sure you want to block?"].exists)
        app.collectionViews.staticTexts["Block user"].tap()
    }

    func testSkype() {
        let app = XCUIApplication()
        app.tables.staticTexts["Skype"].tap()
        app.images["skype-background"].tap()
        XCTAssertEqual(app.collectionViews.cells.count, 4)
        app.collectionViews.staticTexts["Cancel"].tap()
    }

    func testSpotify() {
        let app = XCUIApplication()
        app.tables.staticTexts["Spotify"].tap()
        app.images["sp-background"].tap()
        XCTAssertEqual(app.collectionViews.cells.count, 5)
        XCTAssert(app.collectionViews.staticTexts["The Fast And The Furious Soundtrack Collection"].exists)
        XCTAssertFalse(app.collectionViews.staticTexts["Start Radio"].exists) // Not visible right now
        app.collectionViews.staticTexts["Go to Album"].tap()
    }

    func testTweetBot() {
        let app = XCUIApplication()
        app.tables.staticTexts["TweetBot"].tap()
        app.images["tb-background"].tap()
        XCTAssertEqual(app.collectionViews.cells.count, 5)
        app.collectionViews.staticTexts["Cancel"].tap()
    }

    func testTwitterCountOfCells() {
        let app = XCUIApplication()
        app.tables.staticTexts["Twitter"].tap()
        app.images["tw-background"].tap()
        XCTAssertEqual(app.collectionViews.cells.count, 2)
        app.collectionViews.staticTexts["Xmartlabs"].tap()
    }
    
    func testYoutubeCellsAddedBeforeShow() {
        let app = XCUIApplication()
        app.tables.staticTexts["YouTube"].tap()
        app.images["yt-background"].tap()
        XCTAssertEqual(app.collectionViews.cells.count, 4)
        app.collectionViews.staticTexts["Add to Playlist..."].tap()
    }

    func testYoutubeDispatchAddCells() {
        let app = XCUIApplication()
        app.tables.staticTexts["Dispatch YouTube"].tap()
        app.images["yt-background"].tap()
        XCTAssertEqual(app.collectionViews.cells.count, 3)
        sleep(3)
        XCTAssertEqual(app.collectionViews.cells.count, 5)
        app.collectionViews.staticTexts["Share..."].tap()
    }
    
    func testYoutubeDispatchRemoveCell() {
        let app = XCUIApplication()
        app.tables.staticTexts["Dispatch YouTube"].tap()
        app.images["yt-background"].tap()
        XCTAssertEqual(app.collectionViews.cells.count, 3)
        sleep(3)
        XCTAssertEqual(app.collectionViews.cells.count, 5)
        sleep(2)
        XCTAssertEqual(app.collectionViews.cells.count, 4)
        sleep(2)
        XCTAssertEqual(app.collectionViews.cells.count, 3)
        sleep(2)
        XCTAssertEqual(app.collectionViews.cells.count, 1)
        app.collectionViews.staticTexts["Add to Favs..."].tap()
    }
    
}
