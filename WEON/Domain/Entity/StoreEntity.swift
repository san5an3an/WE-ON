//
//  StoreEntity.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import Foundation

struct Coordinate: Hashable, Sendable {
    let latitude: Double
    let longitude: Double

    // 위치 권한이 없을 때 쓰는 기본 좌표 지정
    static let fallback = Coordinate(latitude: 37.66, longitude: 126.80)
}

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

enum StoreFilter: CaseIterable, Hashable, Sendable {
    case all
    case mealCard
    case goodInfluence

    var title: String {
        switch self {
        case .all: "전체"
        case .mealCard: "아동급식카드"
        case .goodInfluence: "선한 영향력"
        }
    }

    func matches(_ kind: StoreKind) -> Bool {
        switch self {
        case .all: true
        case .mealCard: kind.contains(.mealCard)
        case .goodInfluence: kind.contains(.goodInfluence)
        }
    }
}

struct StoreSummary: Identifiable, Hashable, Sendable {
    let id: Int
    let name: String
    let kind: StoreKind
    let distanceKm: Double
    let rating: Double
}

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
