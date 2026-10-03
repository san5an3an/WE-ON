//
//  LocationRepository.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import Foundation

// 현재 위치와 주소 조회 규칙 정의
protocol LocationRepository: Sendable {
    // 위치 권한 허용 여부 확인
    func isAuthorized() async -> Bool
    // 현재 위치 좌표 조회
    func currentCoordinate() async -> Coordinate?
    // 좌표를 주소 문자열로 변환
    func address(of coordinate: Coordinate) async throws -> String?
}
