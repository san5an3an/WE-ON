//
//  StoreComponents.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import SwiftUI

// 아동급식카드, 선한 영향력 배지 표시
struct StoreKindBadges: View {
    let kind: StoreKind
    var compact = false

    var body: some View {
        HStack(spacing: Spacing.xs) {
            if kind.contains(.mealCard) {
                badge("아동급식카드", symbol: "creditcard.fill", color: .mealCardStore)
            }
            if kind.contains(.goodInfluence) {
                badge("선한 영향력", symbol: "leaf.fill", color: .benefitStore)
            }
        }
    }

    // 배지 하나 생성
    private func badge(_ title: String, symbol: String, color: Color) -> some View {
        Label(compact ? "" : title, systemImage: symbol)
            .labelStyle(BadgeLabelStyle(showsTitle: !compact))
            .font(.seed(11, weight: .bold, relativeTo: .caption2))
            .foregroundStyle(Color.ink)
            .padding(.horizontal, compact ? 6 : 8)
            .padding(.vertical, 4)
            .background(color, in: Capsule())
            .accessibilityLabel(title)
    }
}

// compact 모드에서 아이콘만 남기는 Label 스타일 지정
private struct BadgeLabelStyle: LabelStyle {
    let showsTitle: Bool

    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 3) {
            configuration.icon
            if showsTitle { configuration.title }
        }
    }
}

// 평균 별점 표시
struct RatingView: View {
    let rating: Double
    var size: CGFloat = 13

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: "star.fill")
                .foregroundStyle(.yellow)
            Text(rating > 0 ? String(format: "%.1f", rating) : "평가 없음")
                .foregroundStyle(.secondary)
        }
        .font(.seed(size, weight: .bold, relativeTo: .caption))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(rating > 0 ? "별점 \(String(format: "%.1f", rating))점" : "별점 없음")
    }
}

// 가게 목록 한 줄 표시
struct StoreRow: View {
    let store: StoreSummary

    var body: some View {
        HStack(spacing: Spacing.m) {
            StoreThumbnail(kind: store.kind, size: 52)
            VStack(alignment: .leading, spacing: 6) {
                Text(store.name)
                    .font(.seed(16, weight: .bold, relativeTo: .headline))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                HStack(spacing: Spacing.s) {
                    RatingView(rating: store.rating)
                    Label(store.distanceKm.formattedDistance, systemImage: "location.fill")
                        .font(.seed(12, relativeTo: .caption))
                        .foregroundStyle(.secondary)
                }
                StoreKindBadges(kind: store.kind)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, Spacing.s)
        .contentShape(Rectangle())
    }
}

// 홈 화면 가로 목록의 가게 카드 표시
struct StoreCard: View {
    let store: StoreSummary

    var body: some View {
        VStack(spacing: 0) {
            StoreThumbnail(kind: store.kind, size: nil)
                .frame(height: 120)
                .overlay(alignment: .topLeading) {
                    StoreKindBadges(kind: store.kind, compact: true)
                        .padding(Spacing.s)
                }
            VStack(alignment: .leading, spacing: 4) {
                Text(store.name)
                    .font(.seed(15, weight: .bold, relativeTo: .headline))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                HStack(spacing: Spacing.s) {
                    RatingView(rating: store.rating, size: 12)
                    Text(store.distanceKm.formattedDistance)
                        .font(.seed(12, relativeTo: .caption))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(Spacing.m)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.cardSurface)
        }
        .frame(width: 176)
        .clipShape(RoundedRectangle(cornerRadius: Radius.m, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: Radius.m, style: .continuous)
                .strokeBorder(Color.hairline)
        }
    }
}

// 가맹 종류별 색으로 가게 썸네일 표시
struct StoreThumbnail: View {
    let kind: StoreKind
    let size: CGFloat?

    // 가맹 종류에 맞는 색 지정
    private var tint: Color {
        if kind.contains(.goodInfluence) && !kind.contains(.mealCard) { return .benefitStore }
        if kind.contains(.mealCard) && !kind.contains(.goodInfluence) { return .mealCardStore }
        return .brandLight
    }

    var body: some View {
        RoundedRectangle(cornerRadius: size == nil ? 0 : Radius.s, style: .continuous)
            .fill(LinearGradient(colors: [tint.opacity(0.45), tint], startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay {
                Image(systemName: "fork.knife")
                    .font(.system(size: (size ?? 60) * 0.4, weight: .semibold))
                    .foregroundStyle(Color.ink.opacity(size == nil ? 0.35 : 0.8))
            }
            .frame(width: size, height: size)
            .frame(maxWidth: size == nil ? .infinity : nil)
            .accessibilityHidden(true)
    }
}

// 전체, 아동급식카드, 선한 영향력 필터 버튼 표시
struct FilterChipBar: View {
    @Binding var selection: StoreFilter

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.s) {
                ForEach(StoreFilter.allCases, id: \.self) { filter in
                    let isSelected = filter == selection
                    Button {
                        selection = filter
                    } label: {
                        Text(filter.title)
                            .font(.seed(14, weight: isSelected ? .bold : .regular, relativeTo: .subheadline))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .foregroundStyle(isSelected ? Color.ink : Color.primary)
                            .background {
                                if isSelected {
                                    Capsule().fill(LinearGradient.brand)
                                } else {
                                    Capsule().fill(Color.cardSurface)
                                }
                            }
                            .overlay { Capsule().strokeBorder(isSelected ? Color.clear : Color.hairline) }
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
            .padding(.horizontal, Spacing.l)
        }
        .sensoryFeedback(.selection, trigger: selection)
    }
}
