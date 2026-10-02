//
//  LoginViewModel.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import Observation

@Observable
@MainActor
final class LoginViewModel {
    var email = ""
    var password = ""
    private(set) var isLoading = false
    var error: WEONError?

    var canSubmit: Bool { !email.isEmpty && !password.isEmpty && !isLoading }

    func signIn(with session: SessionStore) async {
        if let error = InputValidationUseCase.validateLogin(email: email, password: password) {
            self.error = error
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            try await session.signIn(email: email.trimmingCharacters(in: .whitespaces), password: password)
        } catch {
            self.error = WEONError.wrap(error)
        }
    }
}
