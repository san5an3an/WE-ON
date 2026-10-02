//
//  AppDependencies.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import Foundation

// 화면에서 쓰는 Repository 묶음 보관, 테스트에서는 Mock 으로 교체
struct AppDependencies: Sendable {
    let auth: any AuthRepository
    let store: any StoreRepository
    let review: any ReviewRepository
    let account: any AccountRepository
    let alarm: any AlarmRepository
    let location: any LocationRepository
    let notification: any NotificationPermissionRepository

    // 화면에서 기본으로 쓰는 실제 서버 연결 구성
    @MainActor static let shared: AppDependencies = .live()

    // 실제 서버와 기기 기능을 쓰는 Repository 생성
    @MainActor
    static func live() -> AppDependencies {
        AppDependencies(
            auth: RemoteAuthRepository(),
            store: RemoteStoreRepository(),
            review: RemoteReviewRepository(),
            account: RemoteAccountRepository(),
            alarm: RemoteAlarmRepository(),
            location: DeviceLocationRepository(),
            notification: DeviceNotificationPermissionRepository()
        )
    }

    // 위치 권한이 없거나 응답이 늦으면 기본 좌표 사용
    func coordinateOrFallback() async -> Coordinate {
        await location.currentCoordinate() ?? .fallback
    }
}
