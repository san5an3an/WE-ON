//
//  PasswordResetView.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import SwiftUI

// 비밀번호 재설정 메일 요청 화면 구성
struct PasswordResetView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = PasswordResetViewModel()
    @FocusState private var isEmailFocused: Bool

    var body: some View {
        @Bindable var viewModel = viewModel
        VStack(alignment: .leading, spacing: Spacing.l) {
            Text("가입한 이메일을 입력하면\n비밀번호 재설정 링크를 보내 드려요")
                .font(.seed(22, weight: .bold, relativeTo: .title2))
                .padding(.vertical, Spacing.s)
            FormField(title: "이메일", isFocused: isEmailFocused, text: $viewModel.email) {
                TextField("이메일", text: $viewModel.email, prompt: Text(verbatim: "example@email.com"))
                    .textContentType(.username)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($isEmailFocused)
                    .submitLabel(.send)
                    .onSubmit { Task { await viewModel.send() } }
            }
            Spacer()
            Button("재설정 메일 보내기") {
                Task { await viewModel.send() }
            }
            .buttonStyle(.primary)
            .disabled(!viewModel.canSubmit)
        }
        .padding(Spacing.xl)
        .onAppear { isEmailFocused = true }
        .navigationTitle("비밀번호 찾기")
        .navigationBarTitleDisplayMode(.inline)
        .loadingOverlay(viewModel.isLoading)
        .errorAlert($viewModel.error)
        .alert("메일을 보냈어요", isPresented: Binding(get: { viewModel.didSend }, set: { _ in })) {
            Button("확인") { dismiss() }
        } message: {
            Text("메일함에서 재설정 링크를 확인해 주세요.")
        }
    }
}
