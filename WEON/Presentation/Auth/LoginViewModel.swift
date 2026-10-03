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
    // 이메일 인증이 안 된 계정이라 재전송 안내가 필요한지 여부 보관
    var needsVerification = false
    // 인증 메일 재전송 완료 안내 문구 보관
    var message: String?

    private let dependencies: AppDependencies

    init(dependencies: AppDependencies = .shared) {
        self.dependencies = dependencies
    }

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
            let error = WEONError.wrap(error)
            // 인증 전 계정이면 일반 에러 대신 재전송 안내 표시
            if error == .emailNotVerified {
                needsVerification = true
            } else {
                self.error = error
            }
        }
    }

    // 입력한 계정으로 인증 메일 다시 발송
    func resendVerification() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await dependencies.auth.resendVerification(email: email.trimmingCharacters(in: .whitespaces), password: password)
            message = "\(email) 메일함에서 인증 링크를 눌러 주세요."
        } catch {
            self.error = WEONError.wrap(error)
        }
    }
}
