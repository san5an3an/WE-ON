//
//  AlarmRepository.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import Foundation

// 지출 알림 등록 규칙 정의
protocol AlarmRepository: Sendable {
    // 지출 알림 등록 여부 조회
    func isSubscribed() async throws -> Bool
    // 지출 알림 등록
    func subscribe() async throws
    // 지출 알림 해제
    func unsubscribe() async throws
}
