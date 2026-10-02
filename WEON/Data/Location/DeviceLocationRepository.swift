//
//  DeviceLocationRepository.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import CoreLocation
import Foundation

@MainActor
final class DeviceLocationRepository: NSObject, LocationRepository, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var authorizationWaiters: [CheckedContinuation<Void, Never>] = []

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func isAuthorized() async -> Bool {
        await requestAuthorizationIfNeeded()
        return [.authorizedWhenInUse, .authorizedAlways].contains(manager.authorizationStatus)
    }

    func currentCoordinate() async -> Coordinate? {
        guard await isAuthorized() else { return nil }
        if let location = manager.location, location.timestamp.timeIntervalSinceNow > -300 {
            return Coordinate(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        }
        return await firstLiveCoordinate()
    }

    func address(of coordinate: Coordinate) async throws -> String? {
        var request = URLRequest(url: kakaoURL(for: coordinate), timeoutInterval: 10)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("KakaoAK \(AppConfiguration.kakaoAPIKey)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw WEONError.server }
        return try JSONDecoder().decode(KakaoAddressResponseDTO.self, from: data).firstAddress
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.resumeAuthorizationWaiters()
        }
    }

    private func requestAuthorizationIfNeeded() async {
        guard manager.authorizationStatus == .notDetermined else { return }
        await withCheckedContinuation { continuation in
            authorizationWaiters.append(continuation)
            manager.requestWhenInUseAuthorization()
        }
    }

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

    private func kakaoURL(for coordinate: Coordinate) -> URL {
        var components = URLComponents(string: "https://dapi.kakao.com/v2/local/geo/coord2address.json")!
        components.queryItems = [
            URLQueryItem(name: "x", value: String(coordinate.longitude)),
            URLQueryItem(name: "y", value: String(coordinate.latitude))
        ]
        return components.url!
    }
}
