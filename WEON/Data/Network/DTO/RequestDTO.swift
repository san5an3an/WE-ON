//
//  RequestDTO.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import Foundation

struct TokenRequestDTO: Encodable, Sendable {
    let firebaseToken: String
}

struct SignUpRequestDTO: Encodable, Sendable {
    let firebaseToken: String
    let email: String
}

struct LocationRequestDTO: Encodable, Sendable {
    let curLat: Double
    let curLogt: Double

    init(_ coordinate: Coordinate) {
        curLat = coordinate.latitude
        curLogt = coordinate.longitude
    }
}

struct YearMonthRequestDTO: Encodable, Sendable {
    let firebaseToken: String
    let yearMonth: String
}

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

struct ExpenditureDeleteRequestDTO: Encodable, Sendable {
    let firebaseToken: String
    let accountId: Int
}

struct BudgetRequestDTO: Encodable, Sendable {
    let firebaseToken: String
    let amount: Int
}

struct AlarmRequestDTO: Encodable, Sendable {
    let firebaseToken: String
    let FCMToken: String
}

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

struct ReviewUpdateRequestDTO: Encodable, Sendable {
    let firebaseToken: String
    let reviewId: Int
    let date: String
    let body: String
    let rating: Int
    let reviewImage: String?

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

struct ReviewDeleteRequestDTO: Encodable, Sendable {
    let firebaseToken: String
    let reviewId: Int
}
