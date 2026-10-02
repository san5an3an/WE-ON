//
//  SessionStore.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import Observation

enum AppTab: Hashable {
    case home
    case search
    case account
    case myPage
}

@Observable
@MainActor
final class SessionStore {
    private(set) var user: UserProfile?
    private(set) var isRestoring = true
    var isLoginPresented = false
    var selectedTab: AppTab = .home

    private let auth: any AuthRepository

    init(auth: any AuthRepository, user: UserProfile? = nil) {
        self.auth = auth
        self.user = user
    }

    var isSignedIn: Bool { user != nil }

    func restore() async {
        user = await auth.restoreSession()
        isRestoring = false
    }

    func signIn(email: String, password: String) async throws {
        user = try await auth.signIn(email: email, password: password)
        isLoginPresented = false
    }

    func signOut() throws {
        try auth.signOut()
        user = nil
    }

    func deleteAccount() async throws {
        try await auth.deleteAccount()
        user = nil
    }

    func requireLogin() {
        isLoginPresented = true
    }
}
