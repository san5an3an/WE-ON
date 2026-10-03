//
//  RequestDTO.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import Foundation

// 로그인 토큰만 보내는 요청 Body 생성
struct TokenRequestDTO: Encodable, Sendable {
    let firebaseToken: String
}

// 회원가입 요청 Body 생성
struct SignUpRequestDTO: Encodable, Sendable {
    let firebaseToken: String
    let email: String
    // 비어 있으면 키 자체를 보내지 않아 서버 기본 닉네임 사용
    let nickname: String?
}

// 닉네임 변경 요청 Body 생성
struct NicknameRequestDTO: Encodable, Sendable {
    let firebaseToken: String
    let nickname: String
}

// 현재 위치 요청 Body 생성, 서버 키 이름 curLogt 는 경도 표시
struct LocationRequestDTO: Encodable, Sendable {
    let curLat: Double
    let curLogt: Double

    init(_ coordinate: Coordinate) {
        curLat = coordinate.latitude
        curLogt = coordinate.longitude
    }
}

// 연월 단위 가계부 조회 요청 Body 생성
struct YearMonthRequestDTO: Encodable, Sendable {
    let firebaseToken: String
    let yearMonth: String
}

// 지출 추가와 수정 요청 Body, 추가할 때는 accountId 생략
struct ExpenditureRequestDTO: Encodable, Sendable {
    let firebaseToken: String
    let accountId: Int?
    let restaurant: String
    let price: Int
    let date: String
    let body: String

    init(token: String, accountId: Int? = nil, draft: ExpenditureDraft) {
        firebaseToken = token
        self.accountId = accountId
        restaurant = draft.storeName.trimmingCharacters(in: .whitespaces)
        price = draft.price ?? 0
        date = APIDateFormat.day.string(from: draft.date)
        body = draft.memo
    }
}

// 지출 삭제 요청 Body 생성
struct ExpenditureDeleteRequestDTO: Encodable, Sendable {
    let firebaseToken: String
    let accountId: Int
}

// 이번 달 예산 저장 요청 Body 생성
struct BudgetRequestDTO: Encodable, Sendable {
    let firebaseToken: String
    let amount: Int
}

// 지출 알림 등록과 해제 요청 Body 생성
struct AlarmRequestDTO: Encodable, Sendable {
    let firebaseToken: String
    let FCMToken: String
}

// 리뷰 작성 요청 Body 생성
struct ReviewCreateRequestDTO: Encodable, Sendable {
    let firebaseToken: String
    let storeId: Int
    let date: String
    let body: String
    let rating: Int
    let reviewImage: String?

    // 사진이 없을 때도 reviewImage 키를 null 로 전송
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(firebaseToken, forKey: .firebaseToken)
        try container.encode(storeId, forKey: .storeId)
        try container.encode(date, forKey: .date)
        try container.encode(body, forKey: .body)
        try container.encode(rating, forKey: .rating)
        try container.encode(reviewImage, forKey: .reviewImage)
    }

    private enum CodingKeys: String, CodingKey {
        case firebaseToken, storeId, date, body, rating, reviewImage
    }
}

// 리뷰 수정 요청 Body 생성
struct ReviewUpdateRequestDTO: Encodable, Sendable {
    let firebaseToken: String
    let reviewId: Int
    let date: String
    let body: String
    let rating: Int
    let reviewImage: String?

    // 사진이 없을 때도 reviewImage 키를 null 로 전송
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(firebaseToken, forKey: .firebaseToken)
        try container.encode(reviewId, forKey: .reviewId)
        try container.encode(date, forKey: .date)
        try container.encode(body, forKey: .body)
        try container.encode(rating, forKey: .rating)
        try container.encode(reviewImage, forKey: .reviewImage)
    }

    private enum CodingKeys: String, CodingKey {
        case firebaseToken, reviewId, date, body, rating, reviewImage
    }
}

// 리뷰 삭제 요청 Body 생성
struct ReviewDeleteRequestDTO: Encodable, Sendable {
    let firebaseToken: String
    let reviewId: Int
}
