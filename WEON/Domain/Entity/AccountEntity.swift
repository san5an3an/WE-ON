//
//  AccountEntity.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import Foundation

// 가계부 지출 한 건 보관
struct Expenditure: Identifiable, Hashable, Sendable {
    let id: Int
    let userId: Int
    let storeName: String
    let price: Int
    let date: Date
    let memo: String
}

// 지출 추가와 수정 화면의 입력값 보관
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

// 한 달 가계부 요약 보관
struct AccountSummary: Equatable, Sendable {
    let used: Int
    let balance: Int

    // 데이터가 없을 때 쓰는 빈 요약 지정
    static let empty = AccountSummary(used: 0, balance: 0)

    // 사용액과 잔액을 더한 한 달 예산 계산
    var budget: Int { used + balance }

    // 예산 대비 사용 비율 계산
    var usedRatio: Double {
        guard budget > 0 else { return 0 }
        return min(Double(used) / Double(budget), 1)
    }
}

// 가계부 조회 단위인 연월 보관
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

    // 오늘이 속한 연월 계산
    static var current: YearMonth { YearMonth(date: .now) }

    // 서버 요청용 yyyy-MM 문자열 변환
    var apiValue: String { String(format: "%04d-%02d", year, month) }

    // 화면에 보여줄 연월 문구 표시
    var title: String { "\(year)년 \(month)월" }

    // 몇 달 앞뒤의 연월 계산
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
