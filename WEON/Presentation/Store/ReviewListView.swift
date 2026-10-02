//
//  ReviewListView.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import SwiftUI

struct ReviewListView: View {
    @Environment(SessionStore.self) private var session
    @State private var viewModel: ReviewListViewModel
    @State private var pendingDelete: Review?
    @State private var editRoute: AppRoute?

    init(store: StoreDetail) {
        _viewModel = State(initialValue: ReviewListViewModel(store: store))
    }

    var body: some View {
        @Bindable var viewModel = viewModel
        List {
            if !viewModel.reviews.isEmpty {
                Section {
                    HStack(spacing: Spacing.m) {
                        Text(String(format: "%.1f", viewModel.averageRating))
                            .font(.seed(36, weight: .bold, relativeTo: .largeTitle))
                        VStack(alignment: .leading, spacing: 4) {
                            StarRow(rating: Int(viewModel.averageRating.rounded()), size: 14)
                            Text("리뷰 \(viewModel.reviews.count)개")
                                .font(.seed(13, relativeTo: .footnote))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, Spacing.s)
                }
            }
            Section {
                ForEach(viewModel.reviews) { review in
                    ReviewRow(
                        review: review,
                        isMine: review.userId == session.user?.id,
                        onEdit: { editRoute = .reviewForm(storeId: viewModel.store.id, storeName: viewModel.store.name, editing: review) },
                        onDelete: { pendingDelete = review }
                    )
                }
            }
        }
        .listStyle(.insetGrouped)
        .overlay {
            if viewModel.didLoad && viewModel.reviews.isEmpty {
                EmptyStateView(title: "작성된 리뷰가 없어요", message: "이 가게의 첫 리뷰를 남겨 주세요.")
            }
        }
        .loadingOverlay(viewModel.isLoading)
        .navigationTitle(viewModel.store.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $editRoute) { route in
            if case let .reviewForm(storeId, storeName, editing) = route {
                ReviewFormView(storeId: storeId, storeName: storeName, editing: editing)
            }
        }
        .confirmationDialog("리뷰를 삭제할까요?", isPresented: Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } }), titleVisibility: .visible, presenting: pendingDelete) { review in
            Button("삭제", role: .destructive) { Task { await viewModel.delete(review) } }
        } message: { _ in
            Text("삭제한 리뷰는 되돌릴 수 없어요.")
        }
        .errorAlert($viewModel.error)
        .refreshable { await viewModel.load() }
        .task { await viewModel.load() }
    }

}
