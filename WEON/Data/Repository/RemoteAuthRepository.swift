//
//  RemoteAuthRepository.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import Foundation

// Firebase 인증과 서버 회원 API 호출 담당
struct RemoteAuthRepository: AuthRepository {
    private let firebase: FirebaseAuthClient
    private let client: APIClient

    init(firebase: FirebaseAuthClient = FirebaseAuthClient(), client: APIClient = APIClient()) {
        self.firebase = firebase
        self.client = client
    }

    // 입력값 확인 후 Firebase 로그인과 서버 로그인 진행
    func signIn(email: String, password: String) async throws -> UserProfile {
        if let error = InputValidationUseCase.validateLogin(email: email, password: password) { throw error }
        try await firebase.signIn(email: email, password: password)
        return try await fetchProfile()
    }

    // Firebase 가 유지하는 로그인 상태로 서버 사용자 정보 복원
    func restoreSession() async -> UserProfile? {
        guard firebase.hasVerifiedUser else { return nil }
        return try? await fetchProfile()
    }

    // Firebase 계정 생성, 서버 가입, 인증 메일 발송 순서로 회원가입 진행
    func signUp(email: String, password: String, nickname: String) async throws {
        if let error = InputValidationUseCase.validateSignUp(email: email, password: password, passwordCheck: password, nickname: nickname) { throw error }
        let trimmedNickname = nickname.trimmingCharacters(in: .whitespaces)
        try await firebase.createUser(email: email, password: password)
        do {
            let token = try await firebase.idToken()
            let body = SignUpRequestDTO(firebaseToken: token, email: email, nickname: trimmedNickname.isEmpty ? nil : trimmedNickname)
            try await client.send(Endpoint(path: "/login/signUp", method: .post, body: body))
        } catch {
            // 서버 가입이 실패했을 때만 Firebase 계정을 지워 서버와 상태 맞춤
            try? await firebase.deleteCurrentUser()
            throw error
        }
        // 인증 메일 발송이 실패해도 계정은 유지하고, 로그인 화면에서 다시 받도록 처리
        try? await firebase.sendEmailVerification()
        try? firebase.signOut()
    }

    // 입력값 확인 후 인증 메일 다시 발송
    func resendVerification(email: String, password: String) async throws {
        if let error = InputValidationUseCase.validateLogin(email: email, password: password) { throw error }
        try await firebase.resendVerification(email: email, password: password)
    }

    // 닉네임 확인 후 서버에 변경 요청
    func updateNickname(_ nickname: String) async throws -> UserProfile {
        if let error = InputValidationUseCase.validateNickname(nickname) { throw error }
        let token = try await firebase.idToken()
        let body = NicknameRequestDTO(firebaseToken: token, nickname: nickname.trimmingCharacters(in: .whitespaces))
        let response: LoginResponseDTO = try await client.send(Endpoint(path: "/myPage/nickname", method: .post, body: body))
        return response.toEntity()
    }

    // 입력값 확인 후 비밀번호 재설정 메일 발송
    func sendPasswordReset(to email: String) async throws {
        if let error = InputValidationUseCase.validateEmail(email) { throw error }
        try await firebase.sendPasswordReset(to: email)
    }

    // 로그아웃 처리
    func signOut() throws {
        try firebase.signOut()
    }

    // 서버 회원 정보와 Firebase 계정 순서로 탈퇴 처리
    func deleteAccount() async throws {
        let token = try await firebase.idToken()
        try await client.send(Endpoint(path: "/myPage/delete", method: .post, body: TokenRequestDTO(firebaseToken: token)))
        try await firebase.deleteCurrentUser()
        try? firebase.signOut()
    }

    // 서버에서 로그인한 사용자 정보 조회
    private func fetchProfile() async throws -> UserProfile {
        let token = try await firebase.idToken()
        let response: LoginResponseDTO = try await client.send(Endpoint(path: "/login", method: .post, body: TokenRequestDTO(firebaseToken: token)))
        return response.toEntity()
    }
}
