//
//  ReviewListViewModel.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import Observation

// 리뷰 목록 상태 관리
@Observable
@MainActor
final class ReviewListViewModel {
    private(set) var reviews: [Review] = []
    private(set) var isLoading = false
    private(set) var didLoad = false
    var error: WEONError?

    let store: StoreDetail
    private let dependencies: AppDependencies

    init(store: StoreDetail, dependencies: AppDependencies = .shared) {
        self.store = store
        self.dependencies = dependencies
    }

    // 리뷰 별점 평균 계산
    var averageRating: Double {
        guard !reviews.isEmpty else { return 0 }
        return Double(reviews.reduce(0) { $0 + $1.rating }) / Double(reviews.count)
    }

    // 리뷰 전체 조회
    func load() async {
        defer { didLoad = true }
        reviews = (try? await dependencies.review.reviews(storeId: store.id)) ?? []
    }

    // 리뷰 삭제 후 목록에서 제거
    func delete(_ review: Review) async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await dependencies.review.deleteReview(id: review.id)
            reviews.removeAll { $0.id == review.id }
        } catch {
            self.error = WEONError.wrap(error)
        }
    }
}
