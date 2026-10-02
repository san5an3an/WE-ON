//
//  AccountEntity.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import Foundation

struct Expenditure: Identifiable, Hashable, Sendable {
    let id: Int
    let userId: Int
    let storeName: String
    let price: Int
    let date: Date
    let memo: String
}

struct ExpenditureDraft: Equatable, Sendable {
    var date: Date = .now
    var storeName: String = ""
    var memo: String = ""
    var price: Int?

    init(date: Date = .now, storeName: String = "", memo: String = "", price: Int? = nil) {
        self.date = date
        self.storeName = storeName
        self.memo = memo
        self.price = price
    }

    init(editing expenditure: Expenditure) {
        self.init(date: expenditure.date, storeName: expenditure.storeName, memo: expenditure.memo, price: expenditure.price)
    }
}

struct AccountSummary: Equatable, Sendable {
    let used: Int
    let balance: Int

    static let empty = AccountSummary(used: 0, balance: 0)

    var budget: Int { used + balance }

    // 예산 대비 사용 비율 계산
    var usedRatio: Double {
        guard budget > 0 else { return 0 }
        return min(Double(used) / Double(budget), 1)
    }
}

struct YearMonth: Hashable, Comparable, Sendable {
    let year: Int
    let month: Int

    init(year: Int, month: Int) {
        self.year = year
        self.month = month
    }

    init(date: Date, calendar: Calendar = .current) {
        let components = calendar.dateComponents([.year, .month], from: date)
        self.init(year: components.year ?? 2000, month: components.month ?? 1)
    }

    static var current: YearMonth { YearMonth(date: .now) }

    // 서버 요청용 yyyy-MM 문자열 변환
    var apiValue: String { String(format: "%04d-%02d", year, month) }

    var title: String { "\(year)년 \(month)월" }

    func adding(months: Int) -> YearMonth {
        let index = year * 12 + (month - 1) + months
        return YearMonth(year: index / 12, month: index % 12 + 1)
    }

    static func < (lhs: YearMonth, rhs: YearMonth) -> Bool {
        (lhs.year, lhs.month) < (rhs.year, rhs.month)
    }
}

extension Int {
    // 천 단위 콤마를 넣은 원화 표시
    var wonText: String {
        "\(formatted(.number.grouping(.automatic)))원"
    }
}
