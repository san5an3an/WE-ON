//
//  ReviewRepository.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import Foundation

protocol ReviewRepository: Sendable {
    func recentReviews(storeId: Int) async throws -> [Review]
    func reviews(storeId: Int) async throws -> [Review]
    func createReview(storeId: Int, draft: ReviewDraft) async throws
    func updateReview(id: Int, draft: ReviewDraft) async throws
    func deleteReview(id: Int) async throws
}
