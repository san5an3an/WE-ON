//
//  MainTabView.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import SwiftUI

// 홈, 검색, 가계부, 내 정보 탭 구성
struct MainTabView: View {
    @Environment(SessionStore.self) private var session

    var body: some View {
        @Bindable var session = session
        TabView(selection: $session.selectedTab) {
            NavigationStack {
                HomeView().appRouteDestinations()
            }
            .tabItem { Label("홈", systemImage: "house") }
            .tag(AppTab.home)

            NavigationStack {
                SearchView().appRouteDestinations()
            }
            .tabItem { Label("검색", systemImage: "magnifyingglass") }
            .tag(AppTab.search)

            NavigationStack {
                AccountView().appRouteDestinations()
            }
            .tabItem { Label("가계부", systemImage: "creditcard") }
            .tag(AppTab.account)

            NavigationStack {
                MyPageView().appRouteDestinations()
            }
            .tabItem { Label("내 정보", systemImage: "person.crop.circle") }
            .tag(AppTab.myPage)
        }
    }
}
