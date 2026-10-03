//
//  StoreEntity.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import Foundation

// 위도와 경도 좌표 보관
struct Coordinate: Hashable, Sendable {
    let latitude: Double
    let longitude: Double

    // 위치 권한이 없을 때 쓰는 기본 좌표 지정
    static let fallback = Coordinate(latitude: 37.66, longitude: 126.80)
}

// 아동급식카드 가맹점과 선한 영향력 가게 여부 표시
struct StoreKind: OptionSet, Hashable, Sendable {
    let rawValue: Int

    static let mealCard = StoreKind(rawValue: 1 << 0)
    static let goodInfluence = StoreKind(rawValue: 1 << 1)

    // 서버 storeType 값을 가맹 종류로 변환
    init(storeType: Int) {
        switch storeType {
        case 0: self = .goodInfluence
        case 1: self = .mealCard
        case 2: self = [.mealCard, .goodInfluence]
        default: self = []
        }
    }

    init(rawValue: Int) {
        self.rawValue = rawValue
    }
}

// 가게 목록 필터 종류 구분
enum StoreFilter: CaseIterable, Hashable, Sendable {
    case all
    case mealCard
    case goodInfluence

    // 필터 버튼 문구 지정
    var title: String {
        switch self {
        case .all: "전체"
        case .mealCard: "아동급식카드"
        case .goodInfluence: "선한 영향력"
        }
    }

    // 가게가 이 필터 조건에 맞는지 확인
    func matches(_ kind: StoreKind) -> Bool {
        switch self {
        case .all: true
        case .mealCard: kind.contains(.mealCard)
        case .goodInfluence: kind.contains(.goodInfluence)
        }
    }
}

// 가게 목록에 쓰는 요약 정보 보관
struct StoreSummary: Identifiable, Hashable, Sendable {
    let id: Int
    let name: String
    let kind: StoreKind
    let distanceKm: Double
    let rating: Double
}

// 가게 상세 화면에 쓰는 정보 보관
struct StoreDetail: Identifiable, Hashable, Sendable {
    let id: Int
    let name: String
    let zipCode: Int
    let roadAddress: String
    let lotAddress: String
    let coordinate: Coordinate
    let benefitName: String?
    let benefitTarget: String?
    let kind: StoreKind
    let distanceKm: Double
    let rating: Double
    let hygieneGrade: String

    // 괄호로 붙은 상세 주소를 뺀 도로명 주소 표시
    var shortAddress: String {
        let base = roadAddress.split(separator: "(", maxSplits: 1).first.map(String.init) ?? roadAddress
        return base.trimmingCharacters(in: .whitespaces)
    }
}

extension Double {
    // km 단위 거리를 1km 미만이면 m 단위로 변환
    var formattedDistance: String {
        guard self > 0 else { return "-" }
        if self >= 1 {
            return String(format: "%.1fkm", self)
        }
        return "\(Int(self * 1000))m"
    }
}
