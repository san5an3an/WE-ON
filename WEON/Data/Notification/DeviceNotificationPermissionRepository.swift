//
//  DeviceNotificationPermissionRepository.swift
//  WE-ON
//
//  Created by SAN on 10/3/26.
//

import Foundation
import UserNotifications

// 기기 알림 권한 확인과 요청 담당
struct DeviceNotificationPermissionRepository: NotificationPermissionRepository {
    // 이미 정한 권한은 그대로 반환하고, 처음일 때만 권한 요청 창 표시
    func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        switch await center.notificationSettings().authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied:
            return false
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .badge, .sound])) ?? false
        @unknown default:
            return false
        }
    }
}
