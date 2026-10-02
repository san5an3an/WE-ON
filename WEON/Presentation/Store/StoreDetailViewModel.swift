//
//  StoreDetailViewModel.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import Observation

// 가게 상세 화면 상태 관리
@Observable
@MainActor
final class StoreDetailViewModel {
    private(set) var store: StoreDetail?
    private(set) var recentReviews: [Review] = []
    private(set) var isLoading = false
    private(set) var loadFailed = false

    let storeId: Int
    private let dependencies: AppDependencies

    init(storeId: Int, dependencies: AppDependencies = .shared) {
        self.storeId = storeId
        self.dependencies = dependencies
    }

    // 가게 정보와 최근 리뷰를 동시에 조회
    func load() async {
        isLoading = store == nil
        defer { isLoading = false }
        let coordinate = await dependencies.coordinateOrFallback()
        async let detail = try? dependencies.store.storeDetail(id: storeId, around: coordinate)
        async let reviews = try? dependencies.review.recentReviews(storeId: storeId)
        let loaded = await detail
        recentReviews = await reviews ?? []
        if let loaded {
            store = loaded
        }
        loadFailed = store == nil
    }
}
