//
//  RootView.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import SwiftUI

struct RootView: View {
    @Environment(SessionStore.self) private var session

    var body: some View {
        @Bindable var session = session
        ZStack {
            if session.isRestoring {
                SplashView()
                    .transition(.opacity)
            } else {
                MainTabView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: session.isRestoring)
        .sheet(isPresented: $session.isLoginPresented) {
            LoginView()
        }
        .task {
            async let minimumSplash: Void = (try? Task.sleep(for: .milliseconds(900))) ?? ()
            await session.restore()
            _ = await minimumSplash
        }
    }
}

struct SplashView: View {
    var body: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(colors: [.brandSoft, .canvas], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            VStack(alignment: .leading, spacing: Spacing.s) {
                Text("아이들의\n따뜻한 한 끼")
                    .font(.seed(34, relativeTo: .largeTitle))
                Text("우리 동네 나눔 식당")
                    .font(.seed(34, weight: .bold, relativeTo: .largeTitle))
                    .foregroundStyle(Color.brandText)
            }
            .lineSpacing(6)
            .padding(.horizontal, Spacing.xl)
            .padding(.top, 120)
        }
        .overlay(alignment: .bottomTrailing) {
            Image("WEONLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 260)
                .padding(.trailing, Spacing.xl)
                .padding(.bottom, 80)
                .accessibilityLabel("WE-ON")
        }
    }
}
