//
//  ResponseDTO.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import Foundation

// 서버 에러 응답, 키 이름은 서버 형식 그대로 유지
struct ErrorResponseDTO: Decodable {
    let ErrorMessage: String
}

// 로그인 응답 해석
struct LoginResponseDTO: Decodable {
    let userId: Int
    let email: String
    let userName: String

    // 화면에서 쓰는 사용자 정보로 변환
    func toEntity() -> UserProfile {
        UserProfile(id: userId, email: email, nickname: userName)
    }
}

// 가게 목록 한 칸 응답 해석
struct SimpleStoreDTO: Decodable {
    let storeId: Int
    let storeName: String
    let storeType: Int
    let curDist: Double
    let totalRating: Double

    // 화면에서 쓰는 가게 요약으로 변환
    func toEntity() -> StoreSummary {
        StoreSummary(id: storeId, name: storeName, kind: StoreKind(storeType: storeType), distanceKm: curDist, rating: totalRating)
    }
}

// 가게 상세 응답, refine 접두 필드는 공공데이터 원본 이름 유지
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

    // 화면에서 쓰는 가게 상세로 변환
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

// 리뷰 응답 해석
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

    // Base64 사진을 이미지 데이터로 바꾸며 리뷰로 변환
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

// 지출 내역 응답 해석
struct ExpenditureDTO: Decodable {
    let userId: Int
    let accountId: Int
    let restaurant: String
    let price: Int
    let date: String
    let body: String

    // 날짜 문자열을 Date 로 바꾸며 지출로 변환
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

// 월별 가계부 요약 응답 해석, charge 는 사용액 표시
struct AccountSummaryDTO: Decodable {
    let balance: Int
    let charge: Int

    // 사용액과 잔액으로 변환
    func toEntity() -> AccountSummary {
        AccountSummary(used: charge, balance: balance)
    }
}

// 지출 알림 등록 여부 응답 해석
struct AlarmStateDTO: Decodable {
    let exist: Bool
}

// Kakao 좌표 주소 변환 응답 해석
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

// 서버와 주고받는 날짜 문자열 형식 지정
enum APIDateFormat {
    case day
    case dateTime

    private var pattern: String {
        switch self {
        case .day: "yyyy-MM-dd"
        case .dateTime: "yyyy-MM-dd HH:mm:ss"
        }
    }

    // 서울 시간대 기준 DateFormatter 생성
    private var formatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = pattern
        return formatter
    }

    // Date 를 서버 형식 문자열로 변환
    func string(from date: Date) -> String { formatter.string(from: date) }
    // 서버 형식 문자열을 Date 로 변환
    func date(from string: String) -> Date? { formatter.date(from: String(string.prefix(pattern.count))) }
}
