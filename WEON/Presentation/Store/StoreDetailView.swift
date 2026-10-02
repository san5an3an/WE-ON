//
//  StoreDetailView.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import SwiftUI

// 가게 상세 화면 구성
struct StoreDetailView: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: StoreDetailViewModel
    // 리뷰 쓰기 화면으로 이동할 값 보관
    @State private var reviewRoute: AppRoute?

    init(storeId: Int) {
        _viewModel = State(initialValue: StoreDetailViewModel(storeId: storeId))
    }

    var body: some View {
        Group {
            if let store = viewModel.store {
                content(store)
            } else if viewModel.loadFailed {
                EmptyStateView(title: "가게를 찾을 수 없어요", message: "네트워크 상태를 확인한 뒤 다시 시도해 주세요.", actionTitle: "다시 시도") {
                    Task { await viewModel.load() }
                }
            } else {
                ProgressView()
            }
        }
        .background(Color.canvas)
        .navigationTitle(viewModel.store?.name ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $reviewRoute) { route in
            if case let .reviewForm(storeId, storeName, editing) = route {
                ReviewFormView(storeId: storeId, storeName: storeName, editing: editing)
            }
        }
        .task { await viewModel.load() }
    }

    // 가게 정보와 하단 리뷰 쓰기 버튼 배치
    private func content(_ store: StoreDetail) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.l) {
                summary(store)
                if store.kind.contains(.goodInfluence) {
                    benefitCard(store)
                }
                infoCard(store)
                mapPreview(store)
                reviewSection(store)
            }
            .padding(Spacing.l)
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                if session.isSignedIn {
                    reviewRoute = .reviewForm(storeId: store.id, storeName: store.name, editing: nil)
                } else {
                    session.requireLogin()
                }
            } label: {
                Label("리뷰 쓰기", systemImage: "square.and.pencil")
            }
            .buttonStyle(.warm)
            .padding(.horizontal, Spacing.l)
            .padding(.vertical, Spacing.s)
            .background(.bar)
        }
    }

    // 가게 이름, 배지, 별점, 거리 표시
    private func summary(_ store: StoreDetail) -> some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            StoreKindBadges(kind: store.kind)
            Text(store.name)
                .font(.seed(26, weight: .bold, relativeTo: .title))
            HStack(spacing: Spacing.m) {
                RatingView(rating: store.rating, size: 14)
                Label("내 위치에서 \(store.distanceKm.formattedDistance)", systemImage: "location.fill")
                    .font(.seed(14, relativeTo: .subheadline))
                    .foregroundStyle(.secondary)
            }
        }
    }

    // 선한 영향력 가게의 혜택과 조건 표시
    private func benefitCard(_ store: StoreDetail) -> some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            Label {
                Text("선한 영향력 혜택")
            } icon: {
                Image(systemName: "gift.fill")
                    .foregroundStyle(Color.benefitStore)
            }
            .font(.seed(15, weight: .bold, relativeTo: .headline))
            infoLine(title: "제공 혜택", value: store.benefitName ?? "-")
            infoLine(title: "제공 조건", value: store.benefitTarget ?? "-")
        }
        .card()
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.benefitStore)
                .frame(width: 4)
                .padding(.vertical, Spacing.l)
        }
    }

    // 주소와 위생등급 표시
    private func infoCard(_ store: StoreDetail) -> some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            infoLine(title: "주소", value: store.shortAddress, copyable: true)
            Divider()
            infoLine(title: "위생등급", value: store.hygieneGrade.isEmpty ? "없음" : store.hygieneGrade)
        }
        .card()
    }

    // 제목과 값 한 줄 표시, 주소는 공유 버튼 추가
    private func infoLine(title: String, value: String, copyable: Bool = false) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.m) {
            Text(title)
                .font(.seed(13, weight: .bold, relativeTo: .footnote))
                .foregroundStyle(.secondary)
                .frame(width: 56, alignment: .leading)
            Text(value)
                .font(.seed(15, relativeTo: .body))
                .textSelection(.enabled)
            Spacer(minLength: 0)
            if copyable {
                ShareLink(item: value) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.footnote)
                }
                .accessibilityLabel("주소 공유")
            }
        }
    }

    // 작은 지도 미리보기, 누르면 큰 지도로 이동
    private func mapPreview(_ store: StoreDetail) -> some View {
        NavigationLink(value: AppRoute.storeMap(store)) {
            ZStack(alignment: .bottomTrailing) {
                NaverMapView(store: store.coordinate, storeName: store.name, isInteractive: false, showsMyLocation: false)
                    .frame(height: 160)
                    .allowsHitTesting(false)
                Label("지도 크게 보기", systemImage: "arrow.up.left.and.arrow.down.right")
                    .font(.seed(12, weight: .bold, relativeTo: .caption))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.regularMaterial, in: Capsule())
                    .padding(Spacing.s)
            }
            .clipShape(RoundedRectangle(cornerRadius: Radius.m, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // 최근 리뷰 3개와 전체 보기 링크 표시
    private func reviewSection(_ store: StoreDetail) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            SectionHeader(title: "리뷰") {
                NavigationLink("전체 보기", value: AppRoute.reviewList(store))
                    .font(.seed(14, weight: .bold, relativeTo: .subheadline))
            }
            if viewModel.recentReviews.isEmpty {
                Text("아직 작성된 리뷰가 없어요. 첫 리뷰를 남겨 주세요!")
                    .font(.seed(14, relativeTo: .body))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 80)
                    .card()
            } else {
                VStack(spacing: 0) {
                    ForEach(viewModel.recentReviews) { review in
                        ReviewRow(review: review, isMine: review.userId == session.user?.id, showsImage: false)
                        if review.id != viewModel.recentReviews.last?.id {
                            Divider()
                        }
                    }
                }
                .card(padding: Spacing.m)
            }
        }
    }
}
