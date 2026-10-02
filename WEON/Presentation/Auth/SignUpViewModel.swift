//
//  SignUpViewModel.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import Observation

// 회원가입 화면 상태 관리
@Observable
@MainActor
final class SignUpViewModel {
    var email = ""
    var password = ""
    var passwordCheck = ""
    private(set) var isLoading = false
    private(set) var didSignUp = false
    var error: WEONError?

    private let dependencies: AppDependencies

    init(dependencies: AppDependencies = .shared) {
        self.dependencies = dependencies
    }

    // 이메일 입력칸 아래 안내 문구 지정
    var emailMessage: String? {
        email.isEmpty ? nil : InputValidationUseCase.validateEmail(email)?.errorDescription
    }

    // 비밀번호 입력칸 아래 안내 문구 지정
    var passwordMessage: String? {
        password.isEmpty ? nil : InputValidationUseCase.validatePassword(password)?.errorDescription
    }

    // 비밀번호 확인칸 아래 안내 문구 지정
    var passwordCheckMessage: String? {
        passwordCheck.isEmpty || password == passwordCheck ? nil : WEONError.passwordMismatch.errorDescription
    }

    // 가입하기 버튼 활성화 여부 계산
    var canSubmit: Bool {
        InputValidationUseCase.validateSignUp(email: email, password: password, passwordCheck: passwordCheck) == nil && !isLoading
    }

    // 입력값 확인 후 회원가입 진행
    func signUp() async {
        if let error = InputValidationUseCase.validateSignUp(email: email, password: password, passwordCheck: passwordCheck) {
            self.error = error
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            try await dependencies.auth.signUp(email: email.trimmingCharacters(in: .whitespaces), password: password)
            didSignUp = true
        } catch {
            self.error = WEONError.wrap(error)
        }
    }
}
