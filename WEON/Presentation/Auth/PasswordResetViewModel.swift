//
//  PasswordResetViewModel.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import Observation

@Observable
@MainActor
final class PasswordResetViewModel {
    var email = ""
    private(set) var isLoading = false
    private(set) var didSend = false
    var error: WEONError?

    private let dependencies: AppDependencies

    init(dependencies: AppDependencies = .shared) {
        self.dependencies = dependencies
    }

    var canSubmit: Bool { InputValidationUseCase.validateEmail(email) == nil && !isLoading }

    func send() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await dependencies.auth.sendPasswordReset(to: email.trimmingCharacters(in: .whitespaces))
            didSend = true
        } catch {
            self.error = WEONError.wrap(error)
        }
    }
}
