//
//  RemoteStoreRepository.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import Foundation

struct RemoteStoreRepository: StoreRepository {
    private let client: APIClient

    init(client: APIClient = APIClient()) {
        self.client = client
    }

    func nearbyStores(around coordinate: Coordinate) async throws -> [StoreSummary] {
        let response: [SimpleStoreDTO] = try await client.send(Endpoint(path: "/restaurant/findByCur", method: .post, body: LocationRequestDTO(coordinate)))
        return response.map { $0.toEntity() }
    }

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

    func storeDetail(id: Int, around coordinate: Coordinate) async throws -> StoreDetail {
        let response: StoreDTO = try await client.send(Endpoint(path: "/restaurant/\(id)", method: .post, body: LocationRequestDTO(coordinate)))
        return response.toEntity()
    }
}
