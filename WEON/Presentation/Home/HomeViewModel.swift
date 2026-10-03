//
//  HomeViewModel.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import Observation

// 홈 화면 상태 관리
@Observable
@MainActor
final class HomeViewModel {
    // 현재 위치 주소 보관
    private(set) var address: String?
    private(set) var nearbyStores: [StoreSummary] = []
    // 로그인했을 때만 이번 달 가계부 요약 보관
    private(set) var summary: AccountSummary?
    private(set) var isLoading = false
    private(set) var didLoad = false

    private let dependencies: AppDependencies

    init(dependencies: AppDependencies = .shared) {
        self.dependencies = dependencies
    }

    // 주변 가게, 가계부 요약, 주소를 동시에 조회
    func load(isSignedIn: Bool) async {
        isLoading = true
        defer {
            isLoading = false
            didLoad = true
        }
        let isAuthorized = await dependencies.location.isAuthorized()
        let coordinate = await dependencies.coordinateOrFallback()

        async let stores = try? dependencies.store.nearbyStores(around: coordinate)
        async let summary = isSignedIn ? try? dependencies.account.summary(for: .current) : nil
        async let address = isAuthorized ? try? dependencies.location.address(of: coordinate) : nil

        nearbyStores = await stores ?? []
        self.summary = await summary
        self.address = isAuthorized ? (await address ?? "현재 위치") : nil
    }
}
