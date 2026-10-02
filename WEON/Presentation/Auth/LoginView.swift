//
//  LoginView.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import SwiftUI

struct LoginView: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = LoginViewModel()
    @State private var isPasswordVisible = false
    @FocusState private var focusedField: Field?

    private enum Field {
        case email
        case password
    }

    var body: some View {
        @Bindable var viewModel = viewModel
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    VStack(alignment: .leading, spacing: Spacing.s) {
                        Image("WEONLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 56)
                            .accessibilityHidden(true)
                        Text("WE-ON에 오신 걸\n환영해요")
                            .font(.seed(28, weight: .bold, relativeTo: .largeTitle))
                        Text("아이들의 따뜻한 한 끼를 함께 찾아요.")
                            .font(.seed(15, relativeTo: .subheadline))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, Spacing.xl)

                    VStack(spacing: Spacing.l) {
                        FormField(title: "이메일", isFocused: focusedField == .email, text: $viewModel.email) {
                            TextField("이메일", text: $viewModel.email, prompt: Text(verbatim: "example@email.com"))
                                .accessibilityIdentifier("login.email")
                                .textContentType(.username)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .focused($focusedField, equals: .email)
                                .submitLabel(.next)
                                .onSubmit { focusedField = .password }
                        }
                        FormField(title: "비밀번호", isFocused: focusedField == .password) {
                            HStack {
                                Group {
                                    if isPasswordVisible {
                                        TextField("6자리 이상", text: $viewModel.password)
                                    } else {
                                        SecureField("6자리 이상", text: $viewModel.password)
                                    }
                                }
                                .textContentType(.password)
                                .textInputAutocapitalization(.never)
                                .focused($focusedField, equals: .password)
                                .submitLabel(.go)
                                .onSubmit { Task { await viewModel.signIn(with: session) } }
                                Button {
                                    isPasswordVisible.toggle()
                                } label: {
                                    Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                                        .foregroundStyle(.secondary)
                                }
                                .accessibilityLabel(isPasswordVisible ? "비밀번호 숨기기" : "비밀번호 보기")
                            }
                        }
                    }

                    Button("로그인") {
                        focusedField = nil
                        Task { await viewModel.signIn(with: session) }
                    }
                    .buttonStyle(.primary)
                    .disabled(!viewModel.canSubmit)

                    HStack(spacing: Spacing.l) {
                        NavigationLink("비밀번호 찾기") { PasswordResetView() }
                            .foregroundStyle(.secondary)
                        Divider().frame(height: 14)
                        NavigationLink("회원가입") { SignUpView() }
                            .fontWeight(.bold)
                    }
                    .font(.seed(14, relativeTo: .subheadline))
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, Spacing.xl)
            }
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel("닫기")
                }
            }
            .loadingOverlay(viewModel.isLoading)
            .errorAlert($viewModel.error)
        }
    }
}
