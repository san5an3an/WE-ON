//
//  MyPageView.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import SwiftUI

// 내 정보 탭 화면 구성
struct MyPageView: View {
    @Environment(SessionStore.self) private var session
    @State private var viewModel = MyPageViewModel()
    @State private var isLogoutConfirming = false
    @State private var isDeleteConfirming = false
    @State private var isWorking = false
    @State private var farewell = false
    @State private var error: WEONError?
    @State private var isNicknameEditing = false

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                header
                menu
            }
        }
        .background(Color.canvas)
        .toolbar(.hidden, for: .navigationBar)
        .confirmationDialog("로그아웃할까요?", isPresented: $isLogoutConfirming, titleVisibility: .visible) {
            Button("로그아웃", role: .destructive) { signOut() }
        }
        .confirmationDialog("한 번 삭제한 계정은 복구할 수 없어요.\n정말 탈퇴할까요?", isPresented: $isDeleteConfirming, titleVisibility: .visible) {
            Button("탈퇴하기", role: .destructive) { Task { await deleteAccount() } }
        }
        .alert("그동안 이용해 주셔서 감사합니다.", isPresented: $farewell) {
            Button("확인", role: .cancel) {}
        }
        .sheet(isPresented: $isNicknameEditing) {
            NicknameEditView(current: session.user?.nickname ?? "")
        }
        .loadingOverlay(isWorking)
        .errorAlert($error)
        .task(id: session.user) {
            if session.isSignedIn { await viewModel.load() }
        }
    }

    // 프로필과 이번 달 통계를 상단 영역에 배치
    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            if let user = session.user {
                HStack(spacing: Spacing.l) {
                    Circle()
                        .fill(Color.cardSurface)
                        .frame(width: 72, height: 72)
                        .overlay {
                            Image("WEONLogo")
                                .resizable()
                                .scaledToFit()
                                .padding(14)
                        }
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(user.nickname) 님")
                            .font(.seed(22, weight: .bold, relativeTo: .title2))
                        Text(user.email)
                            .font(.seed(14, relativeTo: .subheadline))
                            .foregroundStyle(Color.ink.opacity(0.7))
                    }
                }
              HStack(spacing: 0) {
                if viewModel.didLoad{
                  stat("이번 달 사용액", value: viewModel.summary.used.wonText)
                  Divider().frame(height: 32).overlay(Color.ink.opacity(0.2))
                  stat("남은 예산", value: viewModel.summary.balance.wonText)
                  Divider().frame(height: 32).overlay(Color.ink.opacity(0.2))
                  stat("지출 건수", value: "\(viewModel.expenditureCount)건")
                } else {
                  LottieLoadingView()
                    .frame(maxWidth: .infinity, minHeight: 50)
                }
              }
                .padding(.vertical, Spacing.m)
                .background(Color.white.opacity(0.55), in: RoundedRectangle(cornerRadius: Radius.m, style: .continuous))
            } else {
                VStack(alignment: .leading, spacing: Spacing.m) {
                    Text("로그인하고\n더 많은 기능을 이용해 보세요")
                        .font(.seed(24, weight: .bold, relativeTo: .title2))
                        .lineSpacing(4)
                    Text("가계부로 식비를 관리하고, 다녀온 가게에 리뷰를 남길 수 있어요.")
                        .font(.seed(14, relativeTo: .subheadline))
                        .foregroundStyle(Color.ink.opacity(0.7))
                    Button("로그인 / 회원가입") { session.requireLogin() }
                        .buttonStyle(.outline)
                        .foregroundStyle(Color.ink)
                        .padding(.top, Spacing.s)
                }
            }
        }
        .foregroundStyle(Color.ink)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Spacing.xl)
        .padding(.top, Spacing.xxl)
        .padding(.bottom, Spacing.xl)
        // 상태 표시줄 아래까지 배경이 이어지도록 위쪽 확장
        .background(alignment: .bottom) {
            LinearGradient(colors: [.brandLight, .brand], startPoint: .topLeading, endPoint: .bottomTrailing)
                .padding(.top, -600)
        }
    }

    // 통계 한 칸 표시
    private func stat(_ title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.seed(11, relativeTo: .caption2))
                .foregroundStyle(Color.ink.opacity(0.7))
            Text(value)
                .font(.seed(16, weight: .bold, relativeTo: .headline))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    // 가계부 바로가기, 로그아웃, 탈퇴 메뉴 표시
    private var menu: some View {
        VStack(spacing: 0) {
            if session.isSignedIn {
                MenuRow(title: "닉네임 변경") { isNicknameEditing = true }
                MenuRow(title: "가계부 보기") { session.selectedTab = .account }
                NavigationLink(value: AppRoute.accountSetting) {
                    MenuRowLabel(title: "가계부 설정")
                }
                .buttonStyle(.plain)
                MenuRow(title: "로그아웃") { isLogoutConfirming = true }
                MenuRow(title: "계정 탈퇴", isDestructive: true) { isDeleteConfirming = true }
            }
            HStack {
                Text("앱 버전")
                Spacer()
                Text(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "-")
                    .foregroundStyle(.secondary)
            }
            .font(.seed(16, relativeTo: .body))
            .padding(.vertical, Spacing.l)
        }
        .padding(.horizontal, Spacing.xl)
    }

    // 로그아웃 처리
    private func signOut() {
        do {
            try session.signOut()
        } catch {
            self.error = WEONError.wrap(error)
        }
    }

    // 회원 탈퇴 처리
    private func deleteAccount() async {
        isWorking = true
        defer { isWorking = false }
        do {
            try await session.deleteAccount()
            farewell = true
        } catch {
            self.error = WEONError.wrap(error)
        }
    }
}

// 누르면 동작하는 메뉴 한 줄 표시
private struct MenuRow: View {
    let title: String
    var isDestructive = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            MenuRowLabel(title: title, isDestructive: isDestructive)
        }
        .buttonStyle(.plain)
    }
}

// 메뉴 한 줄 모양 지정
private struct MenuRowLabel: View {
    let title: String
    var isDestructive = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .foregroundStyle(isDestructive ? Color.red : Color.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .font(.seed(16, relativeTo: .body))
            .padding(.vertical, Spacing.l)
            .contentShape(Rectangle())
            Divider()
        }
    }
}
