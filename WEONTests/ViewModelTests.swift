//
//  ViewModelTests.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import Foundation
import Testing
@testable import WEON

// 화면 상태 관리 로직 검사
@MainActor
struct ViewModelTests {
    @Test func 로그인_성공시_세션에_사용자_저장() async {
        let session = SessionStore(auth: MockAuthRepository())
        session.isLoginPresented = true
        let viewModel = LoginViewModel()
        viewModel.email = "a@b.com"
        viewModel.password = "123456"
        await viewModel.signIn(with: session)
        #expect(session.user?.nickname == "위온")
        #expect(session.isLoginPresented == false)
        #expect(viewModel.error == nil)
    }

    @Test func 로그인_실패시_에러_표시() async {
        let auth = MockAuthRepository()
        auth.signInResult = .failure(.emailNotVerified)
        let session = SessionStore(auth: auth)
        let viewModel = LoginViewModel()
        viewModel.email = "a@b.com"
        viewModel.password = "123456"
        await viewModel.signIn(with: session)
        #expect(session.user == nil)
        #expect(viewModel.error == .emailNotVerified)
    }

    @Test func 회원가입은_검증_실패시_요청하지_않음() async {
        let auth = MockAuthRepository()
        let viewModel = SignUpViewModel(dependencies: .mock(auth: auth))
        viewModel.email = "a@b.com"
        viewModel.password = "123456"
        viewModel.passwordCheck = "000000"
        #expect(viewModel.canSubmit == false)
        await viewModel.signUp()
        #expect(auth.signUpCalls == 0)
        #expect(viewModel.error == .passwordMismatch)
    }

    @Test func 검색_결과에_필터_적용() async {
        let viewModel = SearchViewModel(dependencies: .mock())
        viewModel.keyword = "식"
        await viewModel.search()
        #expect(viewModel.results.count == 2)
        viewModel.filter = .goodInfluence
        #expect(viewModel.filteredResults.map(\.id) == [3])
    }

    @Test func 빈_검색어는_요청하지_않음() async {
        let viewModel = SearchViewModel(dependencies: .mock())
        viewModel.keyword = "   "
        await viewModel.search()
        #expect(viewModel.searchedKeyword == nil)
    }

    @Test func 가계부는_미래_달로_이동하지_않음() async {
        let account = MockAccountRepository()
        let viewModel = AccountViewModel(dependencies: .mock(account: account))
        await viewModel.moveMonth(by: 1)
        #expect(viewModel.month == .current)
        await viewModel.moveMonth(by: -1)
        #expect(viewModel.month == YearMonth.current.adding(months: -1))
        #expect(viewModel.canMoveForward)
        #expect(account.requestedMonths.last == YearMonth.current.adding(months: -1))
    }

    @Test func 지출_금액은_숫자만_입력() {
        let viewModel = ExpenditureFormViewModel(editing: nil, dependencies: .mock())
        viewModel.updatePrice(from: "12,5a00")
        #expect(viewModel.draft.price == 12500)
        viewModel.updatePrice(from: "")
        #expect(viewModel.draft.price == nil)
    }

    @Test func 리뷰_삭제시_목록에서_제거() async {
        let review = MockReviewRepository()
        review.reviewList = [
            Review(id: 1, userId: 1, userName: "a", storeId: 1, storeName: "s", date: "2026-10-02", body: "본문입니다 열 글자", rating: 4, imageData: nil),
            Review(id: 2, userId: 2, userName: "b", storeId: 1, storeName: "s", date: "2026-10-02", body: "본문입니다 열 글자", rating: 2, imageData: nil)
        ]
        let store = StoreDetail(id: 1, name: "s", zipCode: 0, roadAddress: "", lotAddress: "", coordinate: .fallback, benefitName: nil, benefitTarget: nil, kind: [], distanceKm: 0, rating: 0, hygieneGrade: "")
        let viewModel = ReviewListViewModel(store: store, dependencies: .mock(review: review))
        await viewModel.load()
        #expect(viewModel.averageRating == 3)
        await viewModel.delete(viewModel.reviews[0])
        #expect(viewModel.reviews.map(\.id) == [2])
        #expect(review.deletedIds == [1])
    }

    @Test func 리뷰_수정_화면은_기존_내용으로_시작() {
        let original = Review(id: 9, userId: 1, userName: "a", storeId: 1, storeName: "s", date: "2026-10-02", body: "기존 리뷰 본문입니다", rating: 3, imageData: nil)
        let viewModel = ReviewFormViewModel(storeId: 1, storeName: "s", editing: original, dependencies: .mock())
        #expect(viewModel.isEditing)
        #expect(viewModel.draft.rating == 3)
        #expect(viewModel.canSubmit)
    }

    @Test func 알림_권한을_거절하면_서버에_등록하지_않음() async {
        let alarm = RecordingAlarmRepository()
        let viewModel = AccountSettingViewModel(dependencies: .mock(alarm: alarm, notification: MockNotificationPermissionRepository(granted: false)))
        await viewModel.setAlarm(true)
        #expect(alarm.subscribeCalls == 0)
        #expect(viewModel.isAlarmOn == false)
        #expect(viewModel.needsNotificationPermission)
    }

    @Test func 알림_권한을_허용하면_서버에_등록() async {
        let alarm = RecordingAlarmRepository()
        let viewModel = AccountSettingViewModel(dependencies: .mock(alarm: alarm))
        await viewModel.setAlarm(true)
        #expect(alarm.subscribeCalls == 1)
        #expect(viewModel.isAlarmOn)
        #expect(viewModel.needsNotificationPermission == false)
    }
}
