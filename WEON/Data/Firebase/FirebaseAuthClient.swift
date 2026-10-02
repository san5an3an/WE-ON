//
//  FirebaseAuthClient.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import FirebaseAuth
import FirebaseCore
import Foundation

// Firebase 인증 기능 호출 담당
struct FirebaseAuthClient: Sendable {
    // GoogleService-Info.plist 가 없으면 Auth 호출 시 앱이 종료되므로 사전 확인
    private func auth() throws -> Auth {
        guard FirebaseApp.app() != nil else { throw WEONError.missingConfiguration }
        return Auth.auth()
    }

    // 이메일 인증을 마친 로그인 사용자가 있는지 확인
    var hasVerifiedUser: Bool {
        guard let user = try? auth().currentUser else { return false }
        return user.isEmailVerified
    }

    // 이메일과 비밀번호로 Firebase 로그인 후 이메일 인증 여부 확인
    func signIn(email: String, password: String) async throws {
        do {
            let result = try await auth().signIn(withEmail: email, password: password)
            guard result.user.isEmailVerified else { throw WEONError.emailNotVerified }
        } catch let error as WEONError {
            throw error
        } catch {
            throw map(error)
        }
    }

    // Firebase 계정 생성
    func createUser(email: String, password: String) async throws {
        do {
            _ = try await auth().createUser(withEmail: email, password: password)
        } catch let error as WEONError {
            throw error
        } catch {
            throw map(error)
        }
    }

    // 서버 요청에 붙일 ID 토큰 발급
    func idToken() async throws -> String {
        guard let user = try auth().currentUser else { throw WEONError.notSignedIn }
        do {
            return try await user.getIDToken()
        } catch {
            throw map(error)
        }
    }

    // 현재 로그인한 계정의 이메일 조회
    func currentEmail() throws -> String? {
        try auth().currentUser?.email
    }

    // 가입 확인용 인증 메일 발송
    func sendEmailVerification() async throws {
        try await auth().currentUser?.sendEmailVerification()
    }

    // 비밀번호 재설정 메일 발송
    func sendPasswordReset(to email: String) async throws {
        do {
            try await auth().sendPasswordReset(withEmail: email)
        } catch {
            throw map(error)
        }
    }

    // 현재 Firebase 계정 삭제
    func deleteCurrentUser() async throws {
        do {
            try await auth().currentUser?.delete()
        } catch {
            throw map(error)
        }
    }

    // Firebase 로그아웃 처리
    func signOut() throws {
        try auth().signOut()
    }

    // Firebase 에러 코드를 화면 문구용 에러로 변환
    private func map(_ error: Error) -> WEONError {
        guard let code = AuthErrorCode(rawValue: (error as NSError).code) else { return .unknown }
        switch code {
        case .wrongPassword, .invalidCredential: return .wrongPassword
        case .invalidEmail: return .invalidEmailFormat
        case .userNotFound: return .unknownUser
        case .emailAlreadyInUse: return .emailAlreadyInUse
        case .networkError: return .network
        default: return .unknown
        }
    }
}
