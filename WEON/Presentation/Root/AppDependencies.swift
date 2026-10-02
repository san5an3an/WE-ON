//
//  AppDependencies.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import Foundation

struct AppDependencies: Sendable {
    let auth: any AuthRepository
    let store: any StoreRepository
    let review: any ReviewRepository
    let account: any AccountRepository
    let alarm: any AlarmRepository
    let location: any LocationRepository

    // 화면에서 기본으로 쓰는 실제 서버 연결 구성
    @MainActor static let shared: AppDependencies = .live()

    @MainActor
    static func live() -> AppDependencies {
        AppDependencies(
            auth: RemoteAuthRepository(),
            store: RemoteStoreRepository(),
            review: RemoteReviewRepository(),
            account: RemoteAccountRepository(),
            alarm: RemoteAlarmRepository(),
            location: DeviceLocationRepository()
        )
    }

    // 위치 권한이 없거나 응답이 늦으면 기본 좌표 사용
    func coordinateOrFallback() async -> Coordinate {
        await location.currentCoordinate() ?? .fallback
    }
}
