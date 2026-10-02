//
//  ExpenditureGroupingUseCase.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import Foundation

// 하루 동안의 지출 묶음 보관
struct ExpenditureDayGroup: Identifiable, Hashable, Sendable {
    let day: Date
    let items: [Expenditure]

    var id: Date { day }
    // 하루 지출 합계 계산
    var total: Int { items.reduce(0) { $0 + $1.price } }
}

// 가계부 목록 날짜별 묶음 처리
enum ExpenditureGroupingUseCase {
    // 지출 내역을 최근 날짜부터 하루 단위로 묶어 정렬
    static func groupByDay(_ expenditures: [Expenditure], calendar: Calendar = .current) -> [ExpenditureDayGroup] {
        Dictionary(grouping: expenditures) { calendar.startOfDay(for: $0.date) }
            .map { ExpenditureDayGroup(day: $0.key, items: $0.value.sorted { $0.id > $1.id }) }
            .sorted { $0.day > $1.day }
    }
}
