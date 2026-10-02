//
//  TabNavigationUITests.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import XCTest

// 탭 이동과 로그인 화면 진입을 실제 앱으로 확인
final class TabNavigationUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    // 탭 4개와 로그인, 회원가입 화면을 차례로 열고 화면마다 스크린샷 저장
    @MainActor
    func test_탭_이동과_로그인_화면() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["홈"].waitForExistence(timeout: 10))
        attach(app, name: "홈")

        app.tabBars.buttons["검색"].tap()
        XCTAssertTrue(app.staticTexts["어떤 식당을 찾고 있나요?"].waitForExistence(timeout: 5))
        attach(app, name: "검색")

        app.tabBars.buttons["가계부"].tap()
        XCTAssertTrue(app.staticTexts["로그인이 필요해요"].waitForExistence(timeout: 5))
        attach(app, name: "가계부")

        app.tabBars.buttons["내 정보"].tap()
        let loginButton = app.buttons["로그인 / 회원가입"]
        XCTAssertTrue(loginButton.waitForExistence(timeout: 5))
        attach(app, name: "내 정보")

        loginButton.tap()
        XCTAssertTrue(app.buttons["회원가입"].waitForExistence(timeout: 5))
        app.textFields["login.email"].tap()
        app.textFields["login.email"].typeText("san@weon.app")
        attach(app, name: "로그인")

        app.buttons["회원가입"].tap()
        XCTAssertTrue(app.navigationBars["회원가입"].waitForExistence(timeout: 5))
        attach(app, name: "회원가입")
    }

    // 현재 화면 스크린샷을 테스트 결과에 첨부
    @MainActor
    private func attach(_ app: XCUIApplication, name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
