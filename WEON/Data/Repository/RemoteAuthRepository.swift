//
//  RemoteAuthRepository.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import Foundation

struct RemoteAuthRepository: AuthRepository {
    private let firebase: FirebaseAuthClient
    private let client: APIClient

    init(firebase: FirebaseAuthClient = FirebaseAuthClient(), client: APIClient = APIClient()) {
        self.firebase = firebase
        self.client = client
    }

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

    func signUp(email: String, password: String) async throws {
        if let error = InputValidationUseCase.validateEmail(email) ?? InputValidationUseCase.validatePassword(password) { throw error }
        try await firebase.createUser(email: email, password: password)
        do {
            let token = try await firebase.idToken()
            try await client.send(Endpoint(path: "/login/signUp", method: .post, body: SignUpRequestDTO(firebaseToken: token, email: email)))
            try await firebase.sendEmailVerification()
            try firebase.signOut()
        } catch {
            // 서버 가입이 실패하면 Firebase 계정도 함께 정리
            try? await firebase.deleteCurrentUser()
            throw error
        }
    }

    func sendPasswordReset(to email: String) async throws {
        if let error = InputValidationUseCase.validateEmail(email) { throw error }
        try await firebase.sendPasswordReset(to: email)
    }

    func signOut() throws {
        try firebase.signOut()
    }

    func deleteAccount() async throws {
        let token = try await firebase.idToken()
        try await client.send(Endpoint(path: "/myPage/delete", method: .post, body: TokenRequestDTO(firebaseToken: token)))
        try await firebase.deleteCurrentUser()
        try? firebase.signOut()
    }

    private func fetchProfile() async throws -> UserProfile {
        let token = try await firebase.idToken()
        let response: LoginResponseDTO = try await client.send(Endpoint(path: "/login", method: .post, body: TokenRequestDTO(firebaseToken: token)))
        return response.toEntity()
    }
}
