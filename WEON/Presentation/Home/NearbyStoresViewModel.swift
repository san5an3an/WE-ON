//
//  NearbyStoresViewModel.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import Observation

@Observable
@MainActor
final class NearbyStoresViewModel {
    var filter: StoreFilter
    private(set) var address: String?
    private(set) var stores: [StoreSummary] = []
    private(set) var isLoading = false
    private(set) var didLoad = false

    private let dependencies: AppDependencies

    init(filter: StoreFilter, dependencies: AppDependencies = .shared) {
        self.filter = filter
        self.dependencies = dependencies
    }

    var filteredStores: [StoreSummary] {
        stores.filter { filter.matches($0.kind) }
    }

    func load() async {
        isLoading = true
        defer {
            isLoading = false
            didLoad = true
        }
        let isAuthorized = await dependencies.location.isAuthorized()
        let coordinate = await dependencies.coordinateOrFallback()
        stores = (try? await dependencies.store.nearbyStores(around: coordinate)) ?? []
        address = isAuthorized ? ((try? await dependencies.location.address(of: coordinate)) ?? "현재 위치") : "위치 정보 제공에 동의해 주세요"
    }
}
