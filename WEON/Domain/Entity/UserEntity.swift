//
//  UserEntity.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import Foundation

struct UserProfile: Hashable, Sendable {
    let id: Int
    let email: String
    let nickname: String
}
