//
//  SearchViewModel.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import Observation

// 검색 화면 상태 관리
@Observable
@MainActor
final class SearchViewModel {
    var keyword = ""
    var filter: StoreFilter = .all
    private(set) var results: [StoreSummary] = []
    // 마지막 검색어 보관, 검색 전에는 nil 지정
    private(set) var searchedKeyword: String?
    private(set) var isLoading = false

    private let dependencies: AppDependencies

    init(dependencies: AppDependencies = .shared) {
        self.dependencies = dependencies
    }

    // 선택한 필터에 맞는 결과 선별
    var filteredResults: [StoreSummary] {
        results.filter { filter.matches($0.kind) }
    }

    // 빈 칸이 아닐 때만 가게 검색 처리
    func search() async {
        let trimmed = keyword.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }
        let coordinate = await dependencies.coordinateOrFallback()
        results = (try? await dependencies.store.searchStores(keyword: trimmed, around: coordinate)) ?? []
        searchedKeyword = trimmed
    }

    // 검색어를 지우면 결과 초기화
    func clear() {
        results = []
        searchedKeyword = nil
    }
}
