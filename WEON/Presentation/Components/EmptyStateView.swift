//
//  EmptyStateView.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import SwiftUI

// 내용이 없을 때 로고와 안내 문구, 버튼 표시
struct EmptyStateView: View {
    let title: String
    var message: String?
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: Spacing.l) {
            Image("WEONLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 96)
                .opacity(0.9)
                .accessibilityHidden(true)
            VStack(spacing: Spacing.s) {
                Text(title)
                    .font(.seed(17, weight: .bold, relativeTo: .headline))
                if let message {
                    Text(message)
                        .font(.seed(14, relativeTo: .subheadline))
                        .foregroundStyle(.secondary)
                }
            }
            .multilineTextAlignment(.center)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.outline)
            }
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity)
    }
}
