//
//  WEONErrorEntity.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import Foundation

// 앱에서 사용자에게 보여줄 에러 종류 구분
enum WEONError: LocalizedError, Equatable, Sendable {
    case emptyEmail
    case invalidEmailFormat
    case emptyPassword
    case shortPassword
    case passwordMismatch
    case wrongPassword
    case unknownUser
    case emailNotVerified
    case emailAlreadyInUse
    case emptyStoreName
    case emptyPrice
    case shortReviewBody
    case notSignedIn
    case missingConfiguration
    case invalidRequest(String?)
    case network
    case server
    case decoding
    case unknown

    // 에러별 안내 문구 지정
    var errorDescription: String? {
        switch self {
        case .emptyEmail: "이메일을 입력해 주세요."
        case .invalidEmailFormat: "올바른 이메일 형식이 아니에요."
        case .emptyPassword: "비밀번호를 입력해 주세요."
        case .shortPassword: "비밀번호는 6자리 이상 입력해 주세요."
        case .passwordMismatch: "비밀번호 확인이 일치하지 않아요."
        case .wrongPassword: "이메일 또는 비밀번호가 올바르지 않아요."
        case .unknownUser: "등록되지 않은 사용자예요."
        case .emailNotVerified: "이메일 인증 후 로그인해 주세요."
        case .emailAlreadyInUse: "이미 가입된 이메일이에요."
        case .emptyStoreName: "가게명을 입력해 주세요."
        case .emptyPrice: "금액을 입력해 주세요."
        case .shortReviewBody: "리뷰는 10글자 이상 입력해 주세요."
        case .notSignedIn: "로그인이 필요해요."
        case .missingConfiguration: "앱 설정 파일이 없어 요청할 수 없어요."
        case .invalidRequest(let message): message ?? "잘못된 요청이에요."
        case .network: "네트워크 연결을 확인해 주세요."
        case .server: "서버에서 오류가 발생했어요. 잠시 후 다시 시도해 주세요."
        case .decoding: "응답을 해석하지 못했어요."
        case .unknown: "알 수 없는 오류가 발생했어요."
        }
    }

    // 임의의 에러를 화면에 띄울 수 있는 WEONError 로 변환
    static func wrap(_ error: Error) -> WEONError {
        (error as? WEONError) ?? .unknown
    }
}
