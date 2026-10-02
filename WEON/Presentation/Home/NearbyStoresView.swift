//
//  NearbyStoresView.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import SwiftUI

struct NearbyStoresView: View {
    @State private var viewModel: NearbyStoresViewModel

    init(initialFilter: StoreFilter) {
        _viewModel = State(initialValue: NearbyStoresViewModel(filter: initialFilter))
    }

    var body: some View {
        @Bindable var viewModel = viewModel
        List {
            Section {
                ForEach(viewModel.filteredStores) { store in
                    NavigationLink(value: AppRoute.storeDetail(storeId: store.id)) {
                        StoreRow(store: store)
                    }
                }
            } header: {
                VStack(alignment: .leading, spacing: Spacing.m) {
                    Label(viewModel.address ?? "위치 확인 중", systemImage: "location.fill")
                        .font(.seed(13, weight: .bold, relativeTo: .footnote))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, Spacing.l)
                    FilterChipBar(selection: $viewModel.filter)
                }
                .textCase(nil)
                .listRowInsets(EdgeInsets(top: Spacing.s, leading: 0, bottom: Spacing.s, trailing: 0))
            }
        }
        .listStyle(.plain)
        .overlay {
            if viewModel.didLoad && viewModel.filteredStores.isEmpty {
                EmptyStateView(title: "조건에 맞는 식당이 없어요", message: "다른 필터를 선택해 보세요.", actionTitle: "전체 보기") {
                    viewModel.filter = .all
                }
            } else if !viewModel.didLoad {
                ProgressView()
            }
        }
        .navigationTitle("내 주변 식당")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable { await viewModel.load() }
        .task { if !viewModel.didLoad { await viewModel.load() } }
    }
}
