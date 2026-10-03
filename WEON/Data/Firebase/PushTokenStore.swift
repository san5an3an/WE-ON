//
//  PushTokenStore.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import Foundation

// 푸시 알림용 FCM 토큰을 여러 작업이 안전하게 함께 쓰도록 보관
actor PushTokenStore {
    static let shared = PushTokenStore()

    private(set) var fcmToken: String?

    // FCM 토큰 갱신
    func update(_ token: String?) {
        fcmToken = token
    }
}
