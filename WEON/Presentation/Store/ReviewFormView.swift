//
//  ReviewFormView.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import PhotosUI
import SwiftUI

// 리뷰 작성과 수정 화면 구성
struct ReviewFormView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: ReviewFormViewModel
    // 사진 보관함에서 고른 사진 보관
    @State private var photoItem: PhotosPickerItem?
    @FocusState private var isEditorFocused: Bool

    init(storeId: Int, storeName: String, editing: Review?) {
        _viewModel = State(initialValue: ReviewFormViewModel(storeId: storeId, storeName: storeName, editing: editing))
    }

    var body: some View {
        @Bindable var viewModel = viewModel
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                ratingSection
                bodySection
                photoSection
            }
            .padding(Spacing.l)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color.canvas)
        .navigationTitle(viewModel.isEditing ? "리뷰 수정" : "리뷰 쓰기")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Button(viewModel.isEditing ? "수정 완료" : "리뷰 등록") {
                Task { await viewModel.submit() }
            }
            .buttonStyle(.primary)
            .disabled(!viewModel.canSubmit)
            .padding(.horizontal, Spacing.l)
            .padding(.vertical, Spacing.s)
            .background(.bar)
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("완료") { isEditorFocused = false }
            }
        }
        .loadingOverlay(viewModel.isSaving)
        .errorAlert($viewModel.error)
        .onChange(of: photoItem) { _, item in
            Task {
                viewModel.draft.imageData = try? await item?.loadTransferable(type: Data.self)
            }
        }
        .onChange(of: viewModel.didSave) { _, saved in
            if saved { dismiss() }
        }
        .sensoryFeedback(.success, trigger: viewModel.didSave)
    }

    // 별점 선택 영역 표시
    private var ratingSection: some View {
        VStack(spacing: Spacing.m) {
            Text(viewModel.storeName)
                .font(.seed(14, weight: .bold, relativeTo: .subheadline))
                .foregroundStyle(.secondary)
            Text("맛은 어떠셨나요?")
                .font(.seed(22, weight: .bold, relativeTo: .title2))
            HStack(spacing: Spacing.s) {
                ForEach(1...5, id: \.self) { score in
                    Button {
                        viewModel.draft.rating = score
                    } label: {
                        Image(systemName: score <= viewModel.draft.rating ? "star.fill" : "star")
                            .font(.system(size: 34))
                            .foregroundStyle(score <= viewModel.draft.rating ? Color.yellow : Color.secondary.opacity(0.4))
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(score)점")
                }
            }
            .sensoryFeedback(.selection, trigger: viewModel.draft.rating)
        }
        .frame(maxWidth: .infinity)
        .card(padding: Spacing.xl)
    }

    // 리뷰 본문 입력 영역과 글자 수 표시
    private var bodySection: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text("리뷰 내용")
                .font(.seed(13, weight: .bold, relativeTo: .footnote))
                .foregroundStyle(.secondary)
            ZStack(alignment: .topLeading) {
                if viewModel.draft.body.isEmpty {
                    Text("음식 맛, 친절함, 혜택 이용 경험을 자유롭게 남겨 주세요.")
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 8)
                }
                TextEditor(text: Bindable(viewModel).draft.body)
                    .focused($isEditorFocused)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 160)
            }
            .font(.seed(15, relativeTo: .body))
            .padding(Spacing.m)
            .background(Color.cardSurface, in: RoundedRectangle(cornerRadius: Radius.s, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: Radius.s, style: .continuous)
                    .strokeBorder(isEditorFocused ? Color.brand : Color.hairline)
            }
            HStack {
                Text("최소 \(InputValidationUseCase.minimumReviewLength)글자 이상 입력해 주세요")
                Spacer()
                Text("\(viewModel.bodyLength)자")
                    .foregroundStyle(viewModel.bodyLength >= InputValidationUseCase.minimumReviewLength ? Color.brandText : Color.secondary)
                    .monospacedDigit()
            }
            .font(.seed(12, relativeTo: .caption))
            .foregroundStyle(.secondary)
        }
    }

    // 사진 첨부와 삭제 영역 표시
    private var photoSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text("사진 (선택)")
                .font(.seed(13, weight: .bold, relativeTo: .footnote))
                .foregroundStyle(.secondary)
            if let data = viewModel.draft.imageData {
                DataImage(data: data)
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.m, style: .continuous))
                    .overlay(alignment: .topTrailing) {
                        Button {
                            photoItem = nil
                            viewModel.draft.imageData = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.white, .black.opacity(0.5))
                        }
                        .padding(Spacing.s)
                        .accessibilityLabel("사진 삭제")
                    }
            } else {
                PhotosPicker(selection: $photoItem, matching: .images) {
                    Label("사진 추가", systemImage: "photo.badge.plus")
                        .frame(maxWidth: .infinity, minHeight: 96)
                }
                .buttonStyle(.secondary)
            }
        }
    }
}
