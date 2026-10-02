//
//  LoginViewModel.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import Observation

// 로그인 화면 상태 관리
@Observable
@MainActor
final class LoginViewModel {
    var email = ""
    var password = ""
    private(set) var isLoading = false
    var error: WEONError?

    // 로그인 버튼 활성화 여부 계산
    var canSubmit: Bool { !email.isEmpty && !password.isEmpty && !isLoading }

    // 입력값 확인 후 로그인 진행
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
