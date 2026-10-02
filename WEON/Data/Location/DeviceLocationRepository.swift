//
//  DeviceLocationRepository.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import CoreLocation
import Foundation

// 기기 위치 조회와 Kakao 주소 변환 담당
@MainActor
final class DeviceLocationRepository: NSObject, LocationRepository, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    // 위치 권한 응답을 기다리는 요청 목록 보관
    private var authorizationWaiters: [CheckedContinuation<Void, Never>] = []

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    // 위치 권한 요청 후 허용 여부 확인
    func isAuthorized() async -> Bool {
        await requestAuthorizationIfNeeded()
        return [.authorizedWhenInUse, .authorizedAlways].contains(manager.authorizationStatus)
    }

    // 최근 5분 안의 위치가 있으면 재사용하고 없으면 새 위치 요청
    func currentCoordinate() async -> Coordinate? {
        guard await isAuthorized() else { return nil }
        if let location = manager.location, location.timestamp.timeIntervalSinceNow > -300 {
            return Coordinate(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        }
        return await firstLiveCoordinate()
    }

    // 좌표를 Kakao API 로 주소 문자열로 변환
    func address(of coordinate: Coordinate) async throws -> String? {
        var request = URLRequest(url: kakaoURL(for: coordinate), timeoutInterval: 10)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("KakaoAK \(AppConfiguration.kakaoAPIKey)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw WEONError.server }
        return try JSONDecoder().decode(KakaoAddressResponseDTO.self, from: data).firstAddress
    }

    // 권한 상태가 바뀌면 기다리던 요청 재개
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.resumeAuthorizationWaiters()
        }
    }

    // 권한을 아직 묻지 않았을 때만 권한 요청
    private func requestAuthorizationIfNeeded() async {
        guard manager.authorizationStatus == .notDetermined else { return }
        await withCheckedContinuation { continuation in
            authorizationWaiters.append(continuation)
            manager.requestWhenInUseAuthorization()
        }
    }

    // 권한 응답을 기다리던 요청 모두 재개
    private func resumeAuthorizationWaiters() {
        guard manager.authorizationStatus != .notDetermined else { return }
        let waiters = authorizationWaiters
        authorizationWaiters.removeAll()
        waiters.forEach { $0.resume() }
    }

    // 실시간 위치를 최대 5초 동안 기다린 뒤 첫 좌표 반환
    private func firstLiveCoordinate() async -> Coordinate? {
        await withTaskGroup(of: Coordinate?.self) { group in
            group.addTask {
                do {
                    for try await update in CLLocationUpdate.liveUpdates() {
                        if let location = update.location {
                            return Coordinate(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
                        }
                    }
                } catch {
                    return nil
                }
                return nil
            }
            group.addTask {
                try? await Task.sleep(for: .seconds(5))
                return nil
            }
            let first = await group.next() ?? nil
            group.cancelAll()
            return first
        }
    }

    // Kakao 좌표 주소 변환 요청 주소 생성
    private func kakaoURL(for coordinate: Coordinate) -> URL {
        var components = URLComponents(string: "https://dapi.kakao.com/v2/local/geo/coord2address.json")!
        components.queryItems = [
            URLQueryItem(name: "x", value: String(coordinate.longitude)),
            URLQueryItem(name: "y", value: String(coordinate.latitude))
        ]
        return components.url!
    }
}
