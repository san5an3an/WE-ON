//
//  SignUpView.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import SwiftUI

struct SignUpView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = SignUpViewModel()
    @FocusState private var focusedField: Field?

    private enum Field {
        case email
        case password
        case passwordCheck
    }

    var body: some View {
        @Bindable var viewModel = viewModel
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.l) {
                Text("이메일로 가입하면\n인증 메일을 보내 드려요")
                    .font(.seed(22, weight: .bold, relativeTo: .title2))
                    .padding(.vertical, Spacing.s)

                FormField(title: "이메일", message: viewModel.emailMessage, isFocused: focusedField == .email, text: $viewModel.email) {
                    TextField("이메일", text: $viewModel.email, prompt: Text(verbatim: "example@email.com"))
                        .textContentType(.username)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($focusedField, equals: .email)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .password }
                }
                FormField(title: "비밀번호", message: viewModel.passwordMessage, isFocused: focusedField == .password, text: $viewModel.password) {
                    SecureField("6자리 이상", text: $viewModel.password)
                        .textContentType(.newPassword)
                        .focused($focusedField, equals: .password)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .passwordCheck }
                }
                FormField(title: "비밀번호 확인", message: viewModel.passwordCheckMessage, isFocused: focusedField == .passwordCheck, text: $viewModel.passwordCheck) {
                    SecureField("비밀번호를 한 번 더 입력", text: $viewModel.passwordCheck)
                        .textContentType(.newPassword)
                        .focused($focusedField, equals: .passwordCheck)
                        .submitLabel(.done)
                }
            }
            .padding(Spacing.xl)
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom) {
            Button("가입하기") {
                focusedField = nil
                Task { await viewModel.signUp() }
            }
            .buttonStyle(.primary)
            .disabled(!viewModel.canSubmit)
            .padding(.horizontal, Spacing.xl)
            .padding(.vertical, Spacing.s)
        }
        .navigationTitle("회원가입")
        .navigationBarTitleDisplayMode(.inline)
        .loadingOverlay(viewModel.isLoading)
        .errorAlert($viewModel.error)
        .alert("인증 메일을 보냈어요", isPresented: Binding(get: { viewModel.didSignUp }, set: { _ in })) {
            Button("확인") { dismiss() }
        } message: {
            Text("\(viewModel.email) 메일함에서 인증을 마친 뒤 로그인해 주세요.")
        }
    }
}
