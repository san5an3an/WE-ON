//
//  ReviewRepository.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import Foundation

// 리뷰 조회와 작성 규칙 정의
protocol ReviewRepository: Sendable {
    // 가게의 최근 리뷰 조회
    func recentReviews(storeId: Int) async throws -> [Review]
    // 가게의 리뷰 전체 조회
    func reviews(storeId: Int) async throws -> [Review]
    // 리뷰 작성 처리
    func createReview(storeId: Int, draft: ReviewDraft) async throws
    // 리뷰 수정
    func updateReview(id: Int, draft: ReviewDraft) async throws
    // 리뷰 삭제
    func deleteReview(id: Int) async throws
}
