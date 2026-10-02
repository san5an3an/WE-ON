//
//  AlarmRepository.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import Foundation

protocol AlarmRepository: Sendable {
    func isSubscribed() async throws -> Bool
    func subscribe() async throws
    func unsubscribe() async throws
}
