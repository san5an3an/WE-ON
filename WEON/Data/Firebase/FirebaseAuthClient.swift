//
//  FirebaseAuthClient.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import FirebaseAuth
import FirebaseCore
import Foundation

struct FirebaseAuthClient: Sendable {
    // GoogleService-Info.plist 가 없으면 Auth 호출 시 앱이 종료되므로 사전 확인
    private func auth() throws -> Auth {
        guard FirebaseApp.app() != nil else { throw WEONError.missingConfiguration }
        return Auth.auth()
    }

    var hasVerifiedUser: Bool {
        guard let user = try? auth().currentUser else { return false }
        return user.isEmailVerified
    }

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

    func createUser(email: String, password: String) async throws {
        do {
            _ = try await auth().createUser(withEmail: email, password: password)
        } catch let error as WEONError {
            throw error
        } catch {
            throw map(error)
        }
    }

    func idToken() async throws -> String {
        guard let user = try auth().currentUser else { throw WEONError.notSignedIn }
        do {
            return try await user.getIDToken()
        } catch {
            throw map(error)
        }
    }

    func currentEmail() throws -> String? {
        try auth().currentUser?.email
    }

    func sendEmailVerification() async throws {
        try await auth().currentUser?.sendEmailVerification()
    }

    func sendPasswordReset(to email: String) async throws {
        do {
            try await auth().sendPasswordReset(withEmail: email)
        } catch {
            throw map(error)
        }
    }

    func deleteCurrentUser() async throws {
        do {
            try await auth().currentUser?.delete()
        } catch {
            throw map(error)
        }
    }

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
