//
//  AuthRepository.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import Foundation

// 로그인과 회원 관리 규칙 정의
protocol AuthRepository: Sendable {
    // 이메일 로그인 처리
    func signIn(email: String, password: String) async throws -> UserProfile
    // 앱을 다시 열었을 때 로그인 상태 복원
    func restoreSession() async -> UserProfile?
    // 회원가입 처리
    func signUp(email: String, password: String) async throws
    // 비밀번호 재설정 메일 발송
    func sendPasswordReset(to email: String) async throws
    // 로그아웃 처리
    func signOut() throws
    // 회원 탈퇴 처리
    func deleteAccount() async throws
}
