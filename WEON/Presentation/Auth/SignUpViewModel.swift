//
//  SignUpViewModel.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import Observation

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

    var emailMessage: String? {
        email.isEmpty ? nil : InputValidationUseCase.validateEmail(email)?.errorDescription
    }

    var passwordMessage: String? {
        password.isEmpty ? nil : InputValidationUseCase.validatePassword(password)?.errorDescription
    }

    var passwordCheckMessage: String? {
        passwordCheck.isEmpty || password == passwordCheck ? nil : WEONError.passwordMismatch.errorDescription
    }

    var canSubmit: Bool {
        InputValidationUseCase.validateSignUp(email: email, password: password, passwordCheck: passwordCheck) == nil && !isLoading
    }

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
