//
//  NicknameEditView.swift
//  WE-ON
//
//  Created by SAN on 10/3/26.
//

import SwiftUI

// 닉네임 변경 시트 구성
struct NicknameEditView: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: NicknameEditViewModel
    @FocusState private var isFocused: Bool

    init(current: String) {
        _viewModel = State(initialValue: NicknameEditViewModel(current: current))
    }

    var body: some View {
        @Bindable var viewModel = viewModel
        NavigationStack {
            VStack(alignment: .leading, spacing: Spacing.l) {
                Text("다른 사람에게 보여질\n닉네임을 정해 주세요")
                    .font(.seed(22, weight: .bold, relativeTo: .title2))
                    .padding(.vertical, Spacing.s)
                FormField(title: "닉네임", message: viewModel.message, isFocused: isFocused, text: $viewModel.nickname) {
                    TextField("2~12자", text: $viewModel.nickname)
                        .textContentType(.nickname)
                        .focused($isFocused)
                        .submitLabel(.done)
                        .onSubmit { if viewModel.canSave { Task { await viewModel.save(with: session) } } }
                }
                Text("리뷰를 쓸 때 이 닉네임으로 표시돼요.")
                    .font(.seed(13, relativeTo: .footnote))
                    .foregroundStyle(.secondary)
                Spacer()
                Button("저장하기") {
                    Task { await viewModel.save(with: session) }
                }
                .buttonStyle(.primary)
                .disabled(!viewModel.canSave)
            }
            .padding(Spacing.xl)
            .navigationTitle("닉네임 변경")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
            }
            .loadingOverlay(viewModel.isSaving)
            .errorAlert($viewModel.error)
            .onChange(of: viewModel.didSave) { _, saved in
                if saved { dismiss() }
            }
            .sensoryFeedback(.success, trigger: viewModel.didSave)
            .onAppear { isFocused = true }
        }
        .presentationDetents([.medium])
    }
}
