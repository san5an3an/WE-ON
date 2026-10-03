//
//  LoginView.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import SwiftUI

// 이메일 로그인 화면 구성
struct LoginView: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = LoginViewModel()
    @State private var isPasswordVisible = false
    @FocusState private var focusedField: Field?

    // 키보드 포커스를 옮길 입력칸 구분
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
            // 인증 전 계정이면 인증 메일 재전송 선택지 표시
            .alert("이메일 인증이 필요해요", isPresented: $viewModel.needsVerification) {
                Button("인증 메일 다시 보내기") { Task { await viewModel.resendVerification() } }
                Button("닫기", role: .cancel) {}
            } message: {
                Text("가입할 때 받은 메일의 인증 링크를 누른 뒤 다시 로그인해 주세요. 메일을 못 받았다면 다시 보내 드릴게요.")
            }
            .alert("인증 메일을 다시 보냈어요", isPresented: Binding(get: { viewModel.message != nil }, set: { if !$0 { viewModel.message = nil } })) {
                Button("확인", role: .cancel) {}
            } message: {
                Text(viewModel.message ?? "")
            }
        }
    }
}
