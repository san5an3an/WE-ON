//
//  SessionStore.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import Observation

// 하단 탭 종류 구분
enum AppTab: Hashable {
    case home
    case search
    case account
    case myPage
}

// 로그인 사용자와 선택한 탭을 앱 전체에서 공유
@Observable
@MainActor
final class SessionStore {
    private(set) var user: UserProfile?
    private(set) var isRestoring = true
    var isLoginPresented = false
    var selectedTab: AppTab = .home

    // 로그인 처리 담당 Repository 보관
    private let auth: any AuthRepository

    init(auth: any AuthRepository, user: UserProfile? = nil) {
        self.auth = auth
        self.user = user
    }

    var isSignedIn: Bool { user != nil }

    // 앱 시작 시 로그인 상태 복원
    func restore() async {
        user = await auth.restoreSession()
        isRestoring = false
    }

    // 로그인 처리와 로그인 화면 종료
    func signIn(email: String, password: String) async throws {
        user = try await auth.signIn(email: email, password: password)
        isLoginPresented = false
    }

    // 로그아웃 후 사용자 정보 초기화
    func signOut() throws {
        try auth.signOut()
        user = nil
    }

    // 탈퇴 후 사용자 정보 초기화
    func deleteAccount() async throws {
        try await auth.deleteAccount()
        user = nil
    }

    // 로그인 화면 표시
    func requireLogin() {
        isLoginPresented = true
    }
}
