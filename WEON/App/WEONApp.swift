//
//  WEONApp.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import SwiftUI

// 앱 시작 지점 지정과 로그인 상태 공유
@main
struct WEONApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var session = SessionStore(auth: AppDependencies.shared.auth)

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(session)
                .tint(.brandText)
        }
    }
}
