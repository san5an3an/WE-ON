//
//  SearchView.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import SwiftUI

// 가게 검색 탭 화면 구성
struct SearchView: View {
    @State private var viewModel = SearchViewModel()

    var body: some View {
        @Bindable var viewModel = viewModel
        List {
            if viewModel.searchedKeyword != nil {
                Section {
                    ForEach(viewModel.filteredResults) { store in
                        NavigationLink(value: AppRoute.storeDetail(storeId: store.id)) {
                            StoreRow(store: store)
                        }
                    }
                } header: {
                    FilterChipBar(selection: $viewModel.filter)
                        .textCase(nil)
                        .listRowInsets(EdgeInsets(top: Spacing.s, leading: 0, bottom: Spacing.s, trailing: 0))
                }
            }
        }
        .listStyle(.plain)
        .overlay { emptyState }
        .loadingOverlay(viewModel.isLoading)
        .navigationTitle("검색")
        .searchable(text: $viewModel.keyword, placement: .navigationBarDrawer(displayMode: .always), prompt: "가게명, 행정구역, 주소로 검색")
        .onSubmit(of: .search) { Task { await viewModel.search() } }
        .onChange(of: viewModel.keyword) { _, newValue in
            if newValue.isEmpty { viewModel.clear() }
        }
    }

    // 검색 전 안내와 검색 결과 없음 안내 표시
    @ViewBuilder
    private var emptyState: some View {
        if let keyword = viewModel.searchedKeyword, viewModel.filteredResults.isEmpty, !viewModel.isLoading {
            EmptyStateView(title: "‘\(keyword)’ 검색 결과가 없어요", message: "검색어를 바꾸거나 필터를 전체로 바꿔 보세요.\n\n현재위치 기준, 20km 거리만 검색돼요.")
        } else if viewModel.searchedKeyword == nil {
            EmptyStateView(title: "어떤 식당을 찾고 있나요?", message: "가게 이름이나 동네 이름으로 검색하면\n아동급식카드 가맹점과 선한 영향력 가게를 찾아 드려요.")
        }
    }
}
