//
//  MockRepository.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import Foundation
@testable import WEON

// 테스트에서 쓰는 가짜 로그인 Repository, 테스트는 MainActor 한 곳에서만 실행해 @unchecked Sendable 사용
final class MockAuthRepository: AuthRepository, @unchecked Sendable {
    var signInResult: Result<UserProfile, WEONError> = .success(UserProfile(id: 1, email: "a@b.com", nickname: "위온"))
    var signUpError: WEONError?
    var resetError: WEONError?
    private(set) var signUpCalls = 0

    func signIn(email: String, password: String) async throws -> UserProfile { try signInResult.get() }
    func restoreSession() async -> UserProfile? { nil }
    func signUp(email: String, password: String) async throws {
        signUpCalls += 1
        if let signUpError { throw signUpError }
    }
    func sendPasswordReset(to email: String) async throws {
        if let resetError { throw resetError }
    }
    func signOut() throws {}
    func deleteAccount() async throws {}
}

// 고정된 가게 3곳을 돌려주는 가짜 가게 Repository
struct MockStoreRepository: StoreRepository {
    var stores: [StoreSummary] = [
        StoreSummary(id: 1, name: "행복 분식", kind: StoreKind(storeType: 1), distanceKm: 0.4, rating: 4.5),
        StoreSummary(id: 2, name: "선한 국밥", kind: StoreKind(storeType: 0), distanceKm: 1.2, rating: 4.0),
        StoreSummary(id: 3, name: "함께 식당", kind: StoreKind(storeType: 2), distanceKm: 2.0, rating: 3.5)
    ]

    func nearbyStores(around coordinate: Coordinate) async throws -> [StoreSummary] { stores }
    func searchStores(keyword: String, around coordinate: Coordinate) async throws -> [StoreSummary] {
        stores.filter { $0.name.contains(keyword) }
    }
    func storeDetail(id: Int, around coordinate: Coordinate) async throws -> StoreDetail { throw WEONError.server }
}

// 작성과 삭제 요청을 기록하는 가짜 리뷰 Repository
final class MockReviewRepository: ReviewRepository, @unchecked Sendable {
    var reviewList: [Review] = []
    private(set) var created: [ReviewDraft] = []
    private(set) var deletedIds: [Int] = []

    func recentReviews(storeId: Int) async throws -> [Review] { Array(reviewList.prefix(3)) }
    func reviews(storeId: Int) async throws -> [Review] { reviewList }
    func createReview(storeId: Int, draft: ReviewDraft) async throws { created.append(draft) }
    func updateReview(id: Int, draft: ReviewDraft) async throws {}
    func deleteReview(id: Int) async throws { deletedIds.append(id) }
}

// 요청한 연월과 예산을 기록하는 가짜 가계부 Repository
final class MockAccountRepository: AccountRepository, @unchecked Sendable {
    var summaryValue = AccountSummary(used: 30_000, balance: 70_000)
    var list: [Expenditure] = []
    private(set) var requestedMonths: [YearMonth] = []
    private(set) var budgets: [Int] = []

    func summary(for month: YearMonth) async throws -> AccountSummary {
        requestedMonths.append(month)
        return summaryValue
    }
    func expenditures(for month: YearMonth) async throws -> [Expenditure] { list }
    func createExpenditure(_ draft: ExpenditureDraft) async throws {}
    func updateExpenditure(id: Int, draft: ExpenditureDraft) async throws {}
    func deleteExpenditure(id: Int) async throws { list.removeAll { $0.id == id } }
    func setBudget(_ amount: Int) async throws { budgets.append(amount) }
}

// 항상 알림 미등록 상태를 돌려주는 가짜 알림 Repository
struct MockAlarmRepository: AlarmRepository {
    func isSubscribed() async throws -> Bool { false }
    func subscribe() async throws {}
    func unsubscribe() async throws {}
}

// 위치 권한이 없는 상태를 흉내 내는 가짜 위치 Repository
struct MockLocationRepository: LocationRepository {
    func isAuthorized() async -> Bool { false }
    func currentCoordinate() async -> Coordinate? { nil }
    func address(of coordinate: Coordinate) async throws -> String? { nil }
}

// 알림 권한 응답을 지정할 수 있는 가짜 알림 권한 Repository
struct MockNotificationPermissionRepository: NotificationPermissionRepository {
    var granted = true
    func requestAuthorization() async -> Bool { granted }
}

// 알림 등록 요청 횟수를 기록하는 가짜 알림 Repository
final class RecordingAlarmRepository: AlarmRepository, @unchecked Sendable {
    private(set) var subscribeCalls = 0
    func isSubscribed() async throws -> Bool { subscribeCalls > 0 }
    func subscribe() async throws { subscribeCalls += 1 }
    func unsubscribe() async throws {}
}

extension AppDependencies {
    // 가짜 Repository 로 채운 의존성 생성
    static func mock(
        auth: any AuthRepository = MockAuthRepository(),
        store: any StoreRepository = MockStoreRepository(),
        review: any ReviewRepository = MockReviewRepository(),
        account: any AccountRepository = MockAccountRepository(),
        alarm: any AlarmRepository = MockAlarmRepository(),
        notification: any NotificationPermissionRepository = MockNotificationPermissionRepository()
    ) -> AppDependencies {
        AppDependencies(auth: auth, store: store, review: review, account: account, alarm: alarm, location: MockLocationRepository(), notification: notification)
    }
}
