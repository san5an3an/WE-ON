//
//  PasswordResetViewModel.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import Observation

// 비밀번호 재설정 화면 상태 관리
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

    // 메일 보내기 버튼 활성화 여부 계산
    var canSubmit: Bool { InputValidationUseCase.validateEmail(email) == nil && !isLoading }

    // 비밀번호 재설정 메일 발송
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
