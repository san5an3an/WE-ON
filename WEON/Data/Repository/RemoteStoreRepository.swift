//
//  RemoteStoreRepository.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import Foundation

// 가게 API 호출 담당
struct RemoteStoreRepository: StoreRepository {
    private let client: APIClient

    init(client: APIClient = APIClient()) {
        self.client = client
    }

    // 현재 위치 주변 가게 조회
    func nearbyStores(around coordinate: Coordinate) async throws -> [StoreSummary] {
        let response: [SimpleStoreDTO] = try await client.send(Endpoint(path: "/restaurant/findByCur", method: .post, body: LocationRequestDTO(coordinate)))
        return response.map { $0.toEntity() }
    }

    // 가게명이나 주소로 가게 검색 처리
    func searchStores(keyword: String, around coordinate: Coordinate) async throws -> [StoreSummary] {
        let endpoint = Endpoint(
            path: "/restaurant/findByKeyword",
            method: .post,
            queryItems: [URLQueryItem(name: "keyword", value: keyword)],
            body: LocationRequestDTO(coordinate)
        )
        let response: [SimpleStoreDTO] = try await client.send(endpoint)
        return response.map { $0.toEntity() }
    }

    // 가게 상세 정보 조회
    func storeDetail(id: Int, around coordinate: Coordinate) async throws -> StoreDetail {
        let response: StoreDTO = try await client.send(Endpoint(path: "/restaurant/\(id)", method: .post, body: LocationRequestDTO(coordinate)))
        return response.toEntity()
    }
}
