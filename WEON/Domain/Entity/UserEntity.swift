//
//  UserEntity.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import Foundation

// 로그인한 사용자 정보 보관
struct UserProfile: Hashable, Sendable {
    let id: Int
    let email: String
    let nickname: String
}
