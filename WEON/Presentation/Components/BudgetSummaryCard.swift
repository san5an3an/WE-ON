//
//  BudgetSummaryCard.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import Charts
import SwiftUI

// 사용액과 잔액을 도넛 차트로 표시
struct BudgetSummaryCard: View {
    let summary: AccountSummary
    var title = "이번 달 가계부"

    // 차트 조각 하나의 이름, 금액, 색 보관
    private struct Slice: Identifiable {
        let name: String
        let amount: Int
        let color: Color
        var id: String { name }
    }

    // 예산이 없으면 회색 원 하나만 표시
    private var slices: [Slice] {
        guard summary.budget > 0 else {
            return [Slice(name: "예산 없음", amount: 1, color: .hairline)]
        }
        return [
            Slice(name: "사용액", amount: summary.used, color: .brand),
            Slice(name: "잔액", amount: max(summary.balance, 0), color: .brandLight)
        ]
    }

    var body: some View {
        HStack(spacing: Spacing.l) {
            Chart(slices) { slice in
                SectorMark(angle: .value("금액", slice.amount), innerRadius: .ratio(0.68), angularInset: 1.5)
                    .foregroundStyle(slice.color)
                    .cornerRadius(4)
            }
            .chartLegend(.hidden)
            .frame(width: 104, height: 104)
            .overlay {
                VStack(spacing: 0) {
                    Text("\(Int(summary.usedRatio * 100))%")
                        .font(.seed(20, weight: .bold, relativeTo: .title3))
                    Text("사용")
                        .font(.seed(11, relativeTo: .caption2))
                        .foregroundStyle(.secondary)
                }
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Spacing.s) {
                Text(title)
                    .font(.seed(14, weight: .bold, relativeTo: .subheadline))
                    .foregroundStyle(.secondary)
                amountRow("사용액", amount: summary.used, color: .brandText)
                amountRow("잔액", amount: summary.balance, color: summary.balance < 0 ? .red : .primary)
                if summary.budget > 0 {
                    Text("예산 \(summary.budget.wonText)")
                        .font(.seed(12, relativeTo: .caption))
                        .foregroundStyle(.secondary)
                } else {
                    Text("가계부 설정에서 예산을 정해 보세요")
                        .font(.seed(12, relativeTo: .caption))
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
        }
        .card()
        .accessibilityElement(children: .combine)
    }

    // 금액 한 줄 표시
    private func amountRow(_ label: String, amount: Int, color: Color) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.s) {
            Text(label)
                .font(.seed(13, relativeTo: .footnote))
                .foregroundStyle(.secondary)
                .frame(width: 40, alignment: .leading)
            Text(amount.wonText)
                .font(.seed(18, weight: .bold, relativeTo: .headline))
                .foregroundStyle(color)
                .monospacedDigit()
        }
    }
}
