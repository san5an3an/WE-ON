//
//  ResponseDTO.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import Foundation

struct ErrorResponseDTO: Decodable {
    let ErrorMessage: String
}

struct LoginResponseDTO: Decodable {
    let userId: Int
    let email: String
    let userName: String

    func toEntity() -> UserProfile {
        UserProfile(id: userId, email: email, nickname: userName)
    }
}

struct SimpleStoreDTO: Decodable {
    let storeId: Int
    let storeName: String
    let storeType: Int
    let curDist: Double
    let totalRating: Double

    func toEntity() -> StoreSummary {
        StoreSummary(id: storeId, name: storeName, kind: StoreKind(storeType: storeType), distanceKm: curDist, rating: totalRating)
    }
}

struct StoreDTO: Decodable {
    let storeId: Int
    let storeName: String
    let refinezipCd: Int
    let refineRoadnmAddr: String
    let refineLotnoAddr: String
    let refineWGS84Lat: Double
    let refineWGS84Logt: Double
    let prodName: String?
    let prodTarget: String?
    let storeType: Int
    let curDist: Double
    let totalRating: Double
    let hygieneGrade: String

    func toEntity() -> StoreDetail {
        StoreDetail(
            id: storeId,
            name: storeName,
            zipCode: refinezipCd,
            roadAddress: refineRoadnmAddr,
            lotAddress: refineLotnoAddr,
            coordinate: Coordinate(latitude: refineWGS84Lat, longitude: refineWGS84Logt),
            benefitName: prodName,
            benefitTarget: prodTarget,
            kind: StoreKind(storeType: storeType),
            distanceKm: curDist,
            rating: totalRating,
            hygieneGrade: hygieneGrade
        )
    }
}

struct ReviewDTO: Decodable {
    let userId: Int
    let userName: String
    let reviewId: Int
    let storeId: Int
    let storeName: String
    let date: String
    let body: String
    let rating: Int
    let reviewImage: String?

    func toEntity() -> Review {
        Review(
            id: reviewId,
            userId: userId,
            userName: userName,
            storeId: storeId,
            storeName: storeName,
            date: date,
            body: body,
            rating: rating,
            imageData: reviewImage.flatMap { Data(base64Encoded: $0, options: .ignoreUnknownCharacters) }
        )
    }
}

struct ExpenditureDTO: Decodable {
    let userId: Int
    let accountId: Int
    let restaurant: String
    let price: Int
    let date: String
    let body: String

    func toEntity() -> Expenditure {
        Expenditure(
            id: accountId,
            userId: userId,
            storeName: restaurant,
            price: price,
            date: APIDateFormat.day.date(from: date) ?? .now,
            memo: body
        )
    }
}

struct AccountSummaryDTO: Decodable {
    let balance: Int
    let charge: Int

    func toEntity() -> AccountSummary {
        AccountSummary(used: charge, balance: balance)
    }
}

struct AlarmStateDTO: Decodable {
    let exist: Bool
}

struct KakaoAddressResponseDTO: Decodable {
    struct Document: Decodable {
        let road_address: AddressName?
        let address: AddressName?
    }

    struct AddressName: Decodable {
        let address_name: String
    }

    let documents: [Document]

    // 지번 주소를 우선하고 없으면 도로명 주소 표시
    var firstAddress: String? {
        documents.first.flatMap { $0.address?.address_name ?? $0.road_address?.address_name }
    }
}

enum APIDateFormat {
    case day
    case dateTime

    private var pattern: String {
        switch self {
        case .day: "yyyy-MM-dd"
        case .dateTime: "yyyy-MM-dd HH:mm:ss"
        }
    }

    private var formatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = pattern
        return formatter
    }

    func string(from date: Date) -> String { formatter.string(from: date) }
    func date(from string: String) -> Date? { formatter.date(from: String(string.prefix(pattern.count))) }
}
