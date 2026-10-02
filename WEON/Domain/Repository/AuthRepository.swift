//
//  AuthRepository.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import Foundation

protocol AuthRepository: Sendable {
    func signIn(email: String, password: String) async throws -> UserProfile
    func restoreSession() async -> UserProfile?
    func signUp(email: String, password: String) async throws
    func sendPasswordReset(to email: String) async throws
    func signOut() throws
    func deleteAccount() async throws
}
