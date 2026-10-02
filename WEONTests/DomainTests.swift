//
//  DomainTests.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import Foundation
import Testing
@testable import WEON

struct InputValidationTests {
    @Test(arguments: [
        ("", "123456", WEONError.emptyEmail),
        ("abc", "123456", .invalidEmailFormat),
        ("a@b.com", "", .emptyPassword),
        ("a@b.com", "123", .shortPassword)
    ])
    func 로그인_입력_검증(email: String, password: String, expected: WEONError) {
        #expect(InputValidationUseCase.validateLogin(email: email, password: password) == expected)
    }

    @Test func 올바른_로그인_입력은_통과() {
        #expect(InputValidationUseCase.validateLogin(email: "a@b.com", password: "123456") == nil)
    }

    @Test func 비밀번호_확인_불일치() {
        #expect(InputValidationUseCase.validateSignUp(email: "a@b.com", password: "123456", passwordCheck: "654321") == .passwordMismatch)
    }

    @Test func 지출_입력_검증() {
        #expect(InputValidationUseCase.validateExpenditure(ExpenditureDraft(storeName: " ", price: 1000)) == .emptyStoreName)
        #expect(InputValidationUseCase.validateExpenditure(ExpenditureDraft(storeName: "분식", price: nil)) == .emptyPrice)
        #expect(InputValidationUseCase.validateExpenditure(ExpenditureDraft(storeName: "분식", price: 0)) == nil)
    }

    @Test func 리뷰는_10글자_이상() {
        #expect(InputValidationUseCase.validateReview(ReviewDraft(body: "맛있어요")) == .shortReviewBody)
        #expect(InputValidationUseCase.validateReview(ReviewDraft(body: "정말 맛있고 친절했어요")) == nil)
    }
}

struct StoreEntityTests {
    @Test(arguments: [(0, true, false), (1, false, true), (2, true, true), (9, false, false)])
    func storeType_변환(storeType: Int, goodInfluence: Bool, mealCard: Bool) {
        let kind = StoreKind(storeType: storeType)
        #expect(kind.contains(.goodInfluence) == goodInfluence)
        #expect(kind.contains(.mealCard) == mealCard)
    }

    @Test func 필터는_두_가지_모두인_가게를_포함() {
        let both = StoreKind(storeType: 2)
        #expect(StoreFilter.mealCard.matches(both))
        #expect(StoreFilter.goodInfluence.matches(both))
        #expect(!StoreFilter.mealCard.matches(StoreKind(storeType: 0)))
    }

    @Test func 거리_표시() {
        #expect(0.35.formattedDistance == "350m")
        #expect(1.26.formattedDistance == "1.3km")
        #expect(0.0.formattedDistance == "-")
    }
}

struct AccountEntityTests {
    @Test func 월_이동() {
        #expect(YearMonth(year: 2026, month: 1).adding(months: -1) == YearMonth(year: 2025, month: 12))
        #expect(YearMonth(year: 2026, month: 12).adding(months: 1) == YearMonth(year: 2027, month: 1))
        #expect(YearMonth(year: 2026, month: 3).apiValue == "2026-03")
    }

    @Test func 사용_비율() {
        #expect(AccountSummary(used: 25_000, balance: 75_000).usedRatio == 0.25)
        #expect(AccountSummary.empty.usedRatio == 0)
        #expect(AccountSummary(used: 120_000, balance: -20_000).usedRatio == 1)
    }

    @Test func 지출을_날짜별로_묶음() {
        let calendar = Calendar(identifier: .gregorian)
        let day1 = calendar.date(from: DateComponents(year: 2026, month: 10, day: 1, hour: 9))!
        let day2 = calendar.date(from: DateComponents(year: 2026, month: 10, day: 2, hour: 12))!
        let items = [
            Expenditure(id: 1, userId: 1, storeName: "A", price: 5000, date: day1, memo: ""),
            Expenditure(id: 2, userId: 1, storeName: "B", price: 7000, date: day2, memo: ""),
            Expenditure(id: 3, userId: 1, storeName: "C", price: 3000, date: day2, memo: "")
        ]
        let groups = ExpenditureGroupingUseCase.groupByDay(items, calendar: calendar)
        #expect(groups.count == 2)
        #expect(groups.first?.total == 10_000)
        #expect(groups.first?.items.map(\.id) == [3, 2])
    }
}
