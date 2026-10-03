//
//  InputValidationUseCase.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import Foundation

// 로그인, 가계부, 리뷰 입력값 확인 담당
enum InputValidationUseCase {
    static let minimumPasswordLength = 6
    static let minimumReviewLength = 10
    static let nicknameLength = 2...12

    // 이메일 빈 값과 형식 확인
    static func validateEmail(_ email: String) -> WEONError? {
        let trimmed = email.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { return .emptyEmail }
        if !trimmed.contains("@") || !trimmed.contains(".") { return .invalidEmailFormat }
        return nil
    }

    // 비밀번호 빈 값과 길이 확인
    static func validatePassword(_ password: String) -> WEONError? {
        if password.isEmpty { return .emptyPassword }
        if password.count < minimumPasswordLength { return .shortPassword }
        return nil
    }

    // 로그인 입력값 확인
    static func validateLogin(email: String, password: String) -> WEONError? {
        validateEmail(email) ?? validatePassword(password)
    }

    // 회원가입 입력값과 비밀번호 확인값 일치 여부 확인
    static func validateSignUp(email: String, password: String, passwordCheck: String, nickname: String = "") -> WEONError? {
        if let error = validateLogin(email: email, password: password) { return error }
        if password != passwordCheck { return .passwordMismatch }
        return nickname.trimmingCharacters(in: .whitespaces).isEmpty ? nil : validateNickname(nickname)
    }

    // 앞뒤 공백을 뺀 닉네임 글자 수 확인
    static func validateNickname(_ nickname: String) -> WEONError? {
        nicknameLength.contains(nickname.trimmingCharacters(in: .whitespaces).count) ? nil : .invalidNickname
    }

    // 가게명과 금액 입력 여부 확인
    static func validateExpenditure(_ draft: ExpenditureDraft) -> WEONError? {
        if draft.storeName.trimmingCharacters(in: .whitespaces).isEmpty { return .emptyStoreName }
        guard let price = draft.price, price >= 0 else { return .emptyPrice }
        return nil
    }

    // 리뷰 본문 최소 글자 수 확인
    static func validateReview(_ draft: ReviewDraft) -> WEONError? {
        draft.body.trimmingCharacters(in: .whitespacesAndNewlines).count < minimumReviewLength ? .shortReviewBody : nil
    }
}
