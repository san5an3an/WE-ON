//
//  StoreRepository.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import Foundation

// 가게 조회 규칙 정의
protocol StoreRepository: Sendable {
    // 현재 위치 주변 가게 조회
    func nearbyStores(around coordinate: Coordinate) async throws -> [StoreSummary]
    // 키워드로 가게 검색 처리
    func searchStores(keyword: String, around coordinate: Coordinate) async throws -> [StoreSummary]
    // 가게 상세 정보 조회
    func storeDetail(id: Int, around coordinate: Coordinate) async throws -> StoreDetail
}
