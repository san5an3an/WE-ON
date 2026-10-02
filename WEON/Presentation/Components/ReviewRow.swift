//
//  ReviewRow.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import SwiftUI

// 리뷰 한 건 표시, 내 리뷰면 수정과 삭제 메뉴 표시
struct ReviewRow: View {
    let review: Review
    var isMine = false
    var showsImage = true
    var onEdit: (() -> Void)?
    var onDelete: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            HStack(spacing: Spacing.s) {
                Circle()
                    .fill(Color.brandSoft)
                    .frame(width: 32, height: 32)
                    .overlay {
                        Text(String(review.userName.prefix(1)))
                            .font(.seed(14, weight: .bold, relativeTo: .subheadline))
                            .foregroundStyle(Color.brandText)
                    }
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: Spacing.xs) {
                        Text(review.userName)
                            .font(.seed(14, weight: .bold, relativeTo: .subheadline))
                        if isMine {
                            Text("내 리뷰")
                                .font(.seed(10, weight: .bold, relativeTo: .caption2))
                                .foregroundStyle(Color.brandText)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.brandSoft, in: Capsule())
                        }
                    }
                    HStack(spacing: Spacing.xs) {
                        StarRow(rating: review.rating)
                        Text(String(review.date.prefix(10)))
                            .font(.seed(11, relativeTo: .caption2))
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                if isMine {
                    Menu {
                        Button("리뷰 수정", systemImage: "pencil") { onEdit?() }
                        Button("리뷰 삭제", systemImage: "trash", role: .destructive) { onDelete?() }
                    } label: {
                        Image(systemName: "ellipsis")
                            .frame(width: 36, height: 36)
                            .contentShape(Rectangle())
                    }
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("리뷰 관리")
                }
            }
            Text(review.body)
                .font(.seed(14, relativeTo: .body))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
            if showsImage, let data = review.imageData {
                DataImage(data: data)
                    .frame(height: 180)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.s, style: .continuous))
            }
        }
        .padding(.vertical, Spacing.s)
    }
}

// 별점을 별 다섯 개로 표시
struct StarRow: View {
    let rating: Int
    var size: CGFloat = 11

    var body: some View {
        HStack(spacing: 1) {
            ForEach(1...5, id: \.self) { index in
                Image(systemName: index <= rating ? "star.fill" : "star")
                    .font(.system(size: size))
                    .foregroundStyle(index <= rating ? Color.yellow : Color.secondary.opacity(0.4))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("별점 \(rating)점")
    }
}
