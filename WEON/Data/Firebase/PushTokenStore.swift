//
//  PushTokenStore.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import Foundation

actor PushTokenStore {
    static let shared = PushTokenStore()

    private(set) var fcmToken: String?

    func update(_ token: String?) {
        fcmToken = token
    }
}
