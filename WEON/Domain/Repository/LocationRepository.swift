//
//  LocationRepository.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import Foundation

protocol LocationRepository: Sendable {
    func isAuthorized() async -> Bool
    func currentCoordinate() async -> Coordinate?
    func address(of coordinate: Coordinate) async throws -> String?
}
