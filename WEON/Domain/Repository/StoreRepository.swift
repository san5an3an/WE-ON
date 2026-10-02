//
//  StoreRepository.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import Foundation

protocol StoreRepository: Sendable {
    func nearbyStores(around coordinate: Coordinate) async throws -> [StoreSummary]
    func searchStores(keyword: String, around coordinate: Coordinate) async throws -> [StoreSummary]
    func storeDetail(id: Int, around coordinate: Coordinate) async throws -> StoreDetail
}
