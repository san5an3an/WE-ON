//
//  SearchViewModel.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import Observation

@Observable
@MainActor
final class SearchViewModel {
    var keyword = ""
    var filter: StoreFilter = .all
    private(set) var results: [StoreSummary] = []
    private(set) var searchedKeyword: String?
    private(set) var isLoading = false

    private let dependencies: AppDependencies

    init(dependencies: AppDependencies = .shared) {
        self.dependencies = dependencies
    }

    var filteredResults: [StoreSummary] {
        results.filter { filter.matches($0.kind) }
    }

    func search() async {
        let trimmed = keyword.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }
        let coordinate = await dependencies.coordinateOrFallback()
        results = (try? await dependencies.store.searchStores(keyword: trimmed, around: coordinate)) ?? []
        searchedKeyword = trimmed
    }

    func clear() {
        results = []
        searchedKeyword = nil
    }
}
