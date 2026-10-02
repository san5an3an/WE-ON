//
//  InputValidationUseCase.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import Foundation

enum InputValidationUseCase {
    static let minimumPasswordLength = 6
    static let minimumReviewLength = 10

    static func validateEmail(_ email: String) -> WEONError? {
        let trimmed = email.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { return .emptyEmail }
        if !trimmed.contains("@") || !trimmed.contains(".") { return .invalidEmailFormat }
        return nil
    }

    static func validatePassword(_ password: String) -> WEONError? {
        if password.isEmpty { return .emptyPassword }
        if password.count < minimumPasswordLength { return .shortPassword }
        return nil
    }

    static func validateLogin(email: String, password: String) -> WEONError? {
        validateEmail(email) ?? validatePassword(password)
    }

    static func validateSignUp(email: String, password: String, passwordCheck: String) -> WEONError? {
        if let error = validateLogin(email: email, password: password) { return error }
        return password == passwordCheck ? nil : .passwordMismatch
    }

    static func validateExpenditure(_ draft: ExpenditureDraft) -> WEONError? {
        if draft.storeName.trimmingCharacters(in: .whitespaces).isEmpty { return .emptyStoreName }
        guard let price = draft.price, price >= 0 else { return .emptyPrice }
        return nil
    }

    static func validateReview(_ draft: ReviewDraft) -> WEONError? {
        draft.body.trimmingCharacters(in: .whitespacesAndNewlines).count < minimumReviewLength ? .shortReviewBody : nil
    }
}
