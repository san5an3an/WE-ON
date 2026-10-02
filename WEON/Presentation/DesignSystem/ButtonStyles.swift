//
//  ButtonStyles.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import SwiftUI

// 그라데이션으로 칠한 기본 버튼 모양 지정
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.seed(17, weight: .bold, relativeTo: .headline))
            .foregroundStyle(Color.ink.opacity(isEnabled ? 1 : 0.45))
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(LinearGradient.brand.opacity(isEnabled ? 1 : 0.4), in: Capsule())
            .shadow(color: Color.brand.opacity(isEnabled ? 0.35 : 0), radius: 10, y: 4)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.snappy(duration: 0.15), value: configuration.isPressed)
    }
}

// 연한 초록 배경의 보조 버튼 모양 지정
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.seed(16, weight: .bold, relativeTo: .headline))
            .foregroundStyle(Color.brandText)
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(Color.brandSoft, in: Capsule())
            .overlay { Capsule().strokeBorder(Color.brandLight, lineWidth: 1) }
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

// 노랑에서 주황으로 이어지는 강조 버튼 모양 지정
struct WarmButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.seed(16, weight: .bold, relativeTo: .headline))
            .foregroundStyle(Color.ink)
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(LinearGradient.warm, in: Capsule())
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

// 테두리만 있는 버튼 모양 지정
struct OutlineButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.seed(15, weight: .bold, relativeTo: .subheadline))
            .padding(.horizontal, Spacing.xl)
            .frame(minHeight: 46)
            .overlay { Capsule().strokeBorder(.primary, lineWidth: 1.5) }
            .contentShape(Capsule())
            .opacity(configuration.isPressed ? 0.6 : 1)
    }
}

extension ButtonStyle where Self == OutlineButtonStyle {
    static var outline: OutlineButtonStyle { OutlineButtonStyle() }
}

extension ButtonStyle where Self == WarmButtonStyle {
    static var warm: WarmButtonStyle { WarmButtonStyle() }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    static var secondary: SecondaryButtonStyle { SecondaryButtonStyle() }
}
