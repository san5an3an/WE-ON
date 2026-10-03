//
//  NotificationPermissionRepository.swift
//  WE-ON
//
//  Created by SAN on 10/3/26.
//

import Foundation

// 알림 권한 확인과 요청 규칙 정의
protocol NotificationPermissionRepository: Sendable {
    // 알림 권한을 아직 묻지 않았으면 요청하고 허용 여부 반환
    func requestAuthorization() async -> Bool
}
