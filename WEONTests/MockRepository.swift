//
//  MockRepository.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import Foundation
@testable import WEON

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

struct MockAlarmRepository: AlarmRepository {
    func isSubscribed() async throws -> Bool { false }
    func subscribe() async throws {}
    func unsubscribe() async throws {}
}

struct MockLocationRepository: LocationRepository {
    func isAuthorized() async -> Bool { false }
    func currentCoordinate() async -> Coordinate? { nil }
    func address(of coordinate: Coordinate) async throws -> String? { nil }
}

extension AppDependencies {
    static func mock(
        auth: any AuthRepository = MockAuthRepository(),
        store: any StoreRepository = MockStoreRepository(),
        review: any ReviewRepository = MockReviewRepository(),
        account: any AccountRepository = MockAccountRepository()
    ) -> AppDependencies {
        AppDependencies(auth: auth, store: store, review: review, account: account, alarm: MockAlarmRepository(), location: MockLocationRepository())
    }
}
