//
//  HomeView.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import SwiftUI

struct HomeView: View {
    @Environment(SessionStore.self) private var session
    @State private var viewModel = HomeViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                hero
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    budgetSection
                    categorySection
                    nearbySection
                }
                .padding(.top, Spacing.xl)
                .padding(.bottom, Spacing.l)
                .background(Color.canvas, in: UnevenRoundedRectangle(topLeadingRadius: Radius.l + 6, topTrailingRadius: Radius.l + 6, style: .continuous))
                .padding(.top, -Spacing.xl)
            }
        }
        .background(Color.canvas)
        .toolbar(.hidden, for: .navigationBar)
        .refreshable { await viewModel.load(isSignedIn: session.isSignedIn) }
        .task(id: session.user) { await viewModel.load(isSignedIn: session.isSignedIn) }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: Spacing.l) {
            Image("WEONLogo")
                .resizable()
                .scaledToFit()
                .frame(height: 40)
                .accessibilityLabel("WE-ON")
                .accessibilityAddTraits(.isHeader)

            HStack(spacing: Spacing.xs) {
                Image(systemName: "location.fill")
                Text(viewModel.address ?? "위치 권한을 허용하면 내 주변을 보여 드려요")
                    .lineLimit(1)
            }
            .font(.seed(13, weight: .bold, relativeTo: .footnote))
            .padding(.horizontal, Spacing.m)
            .padding(.vertical, 6)
            .background(Color.cardSurface.opacity(0.7), in: Capsule())

            Text(session.user.map { "\($0.nickname)님,\n오늘은 어디서 먹을까요?" } ?? "오늘은\n어디서 먹을까요?")
                .font(.seed(28, weight: .bold, relativeTo: .title))
                .lineSpacing(6)

            if let pick = viewModel.nearbyStores.first {
                NavigationLink(value: AppRoute.storeDetail(storeId: pick.id)) {
                    HStack(spacing: Spacing.m) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("가장 가까운 나눔 식당")
                                .font(.seed(12, weight: .bold, relativeTo: .caption))
                                .foregroundStyle(Color.ink.opacity(0.7))
                            Text(pick.name)
                                .font(.seed(17, weight: .bold, relativeTo: .headline))
                                .lineLimit(1)
                        }
                        Spacer(minLength: 0)
                        Text(pick.distanceKm.formattedDistance)
                            .font(.seed(13, weight: .bold, relativeTo: .footnote))
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.title2)
                    }
                    .padding(.horizontal, Spacing.xl)
                    .padding(.vertical, Spacing.m)
                    .overlay { Capsule().strokeBorder(Color.ink.opacity(0.6), lineWidth: 1.5) }
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .foregroundStyle(Color.ink)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Spacing.xl)
        .padding(.top, Spacing.l)
        .padding(.bottom, Spacing.xl + Spacing.xxl)
        // 상태 표시줄 아래까지 배경이 이어지도록 위쪽으로 확장
        .background(alignment: .bottom) {
            LinearGradient(colors: [.brandSoft, .brandLight], startPoint: .top, endPoint: .bottom)
                .padding(.top, -600)
        }
    }

    @ViewBuilder
    private var budgetSection: some View {
        if session.isSignedIn {
            Button {
                session.selectedTab = .account
            } label: {
                BudgetSummaryCard(summary: viewModel.summary ?? .empty)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, Spacing.l)
        }
    }

    private var categorySection: some View {
        HStack(spacing: Spacing.m) {
            NavigationLink(value: AppRoute.nearbyStores(.mealCard)) {
                CategoryTile(title: "아동급식카드\n가맹점", symbol: "creditcard.fill", color: .mealCardStore)
            }
            NavigationLink(value: AppRoute.nearbyStores(.goodInfluence)) {
                CategoryTile(title: "선한 영향력\n가게", symbol: "leaf.fill", color: .benefitStore)
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, Spacing.l)
    }

    private var nearbySection: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            SectionHeader(title: "내 주변 식당", subtitle: "아이들과 한 끼를 나누는 우리 동네 식당이에요") {
                NavigationLink("전체 보기", value: AppRoute.nearbyStores(.all))
                    .font(.seed(14, weight: .bold, relativeTo: .subheadline))
            }
            .padding(.horizontal, Spacing.l)

            if viewModel.nearbyStores.isEmpty && viewModel.didLoad {
                EmptyStateView(title: "주변 식당을 찾지 못했어요", message: "잠시 후 다시 불러와 주세요.", actionTitle: "다시 불러오기") {
                    Task { await viewModel.load(isSignedIn: session.isSignedIn) }
                }
            } else if viewModel.nearbyStores.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 180)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: Spacing.m) {
                        ForEach(viewModel.nearbyStores.prefix(10)) { store in
                            NavigationLink(value: AppRoute.storeDetail(storeId: store.id)) {
                                StoreCard(store: store)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, Spacing.l)
                }
            }
        }
    }
}

private struct CategoryTile: View {
    let title: String
    let symbol: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.l) {
            Image(systemName: symbol)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Color.ink)
                .frame(width: 44, height: 44)
                .background(color, in: RoundedRectangle(cornerRadius: Radius.s, style: .continuous))
            HStack(alignment: .bottom) {
                Text(title)
                    .font(.seed(15, weight: .bold, relativeTo: .headline))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
                Image(systemName: "arrow.right")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(.tertiary)
            }
        }
        .card()
    }
}
