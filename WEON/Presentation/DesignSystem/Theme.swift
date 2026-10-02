//
//  Theme.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import SwiftUI

// 앱 색상 토큰 지정
extension Color {
    static let brand = Color("BrandPrimary")
    static let brandLight = Color("BrandLight")
    static let brandText = Color("BrandText")
    static let ink = Color("Ink")
    static let brandSoft = Color("BrandSoft")
    static let benefitStore = Color("BenefitStore")
    static let mealCardStore = Color("MealCardStore")
    static let canvas = Color("Canvas")
    static let cardSurface = Color("CardSurface")
    static let hairline = Color("Hairline")
}

extension Font {
    // LINE Seed 서체를 Dynamic Type 에 맞춰 크기 지정
    static func seed(_ size: CGFloat, weight: SeedWeight = .regular, relativeTo style: Font.TextStyle = .body) -> Font {
        .custom(weight.postScriptName, size: size, relativeTo: style)
    }

    // LINE Seed 서체 굵기 구분
    enum SeedWeight {
        case regular
        case bold

        var postScriptName: String {
            switch self {
            case .regular: "LINESeedSansKR-Regular"
            case .bold: "LINESeedSansKR-Bold"
            }
        }
    }
}

extension LinearGradient {
    // 앱 아이콘과 같은 위쪽 밝은 초록에서 아래쪽 진한 초록으로 이어지는 배경 지정
    static let brand = LinearGradient(colors: [.brandLight, .brand], startPoint: .top, endPoint: .bottom)
    static let warm = LinearGradient(colors: [.mealCardStore, .benefitStore], startPoint: .topLeading, endPoint: .bottomTrailing)
}

// 화면 여백 단계 지정
enum Spacing {
    static let xs: CGFloat = 4
    static let s: CGFloat = 8
    static let m: CGFloat = 12
    static let l: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
}

// 모서리 둥글기 단계 지정
enum Radius {
    static let s: CGFloat = 10
    static let m: CGFloat = 16
    static let l: CGFloat = 22
}

// 흰 배경과 얇은 테두리로 카드 모양 지정
struct CardModifier: ViewModifier {
    var padding: CGFloat = Spacing.l

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.cardSurface, in: RoundedRectangle(cornerRadius: Radius.m, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: Radius.m, style: .continuous)
                    .strokeBorder(Color.hairline, lineWidth: 1)
            }
    }
}

extension View {
    // 카드 모양 적용
    func card(padding: CGFloat = Spacing.l) -> some View {
        modifier(CardModifier(padding: padding))
    }
}
