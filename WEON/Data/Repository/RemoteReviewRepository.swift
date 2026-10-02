//
//  RemoteReviewRepository.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import Foundation

struct RemoteReviewRepository: ReviewRepository {
    private let firebase: FirebaseAuthClient
    private let client: APIClient

    init(firebase: FirebaseAuthClient = FirebaseAuthClient(), client: APIClient = APIClient()) {
        self.firebase = firebase
        self.client = client
    }

    func recentReviews(storeId: Int) async throws -> [Review] {
        let endpoint = Endpoint(
            path: "/review/\(storeId)",
            method: .get,
            queryItems: [URLQueryItem(name: "page", value: "1"), URLQueryItem(name: "display", value: "3")]
        )
        let response: [ReviewDTO] = try await client.send(endpoint)
        return response.map { $0.toEntity() }
    }

    func reviews(storeId: Int) async throws -> [Review] {
        let response: [ReviewDTO] = try await client.send(Endpoint(path: "/review/\(storeId)", method: .get))
        return response.map { $0.toEntity() }
    }

    func createReview(storeId: Int, draft: ReviewDraft) async throws {
        if let error = InputValidationUseCase.validateReview(draft) { throw error }
        let token = try await firebase.idToken()
        let body = ReviewCreateRequestDTO(
            firebaseToken: token,
            storeId: storeId,
            date: APIDateFormat.dateTime.string(from: .now),
            body: draft.body,
            rating: draft.rating,
            reviewImage: ReviewImageEncoder.base64String(from: draft.imageData)
        )
        try await client.send(Endpoint(path: "/review/create", method: .post, body: body))
    }

    func updateReview(id: Int, draft: ReviewDraft) async throws {
        if let error = InputValidationUseCase.validateReview(draft) { throw error }
        let token = try await firebase.idToken()
        let body = ReviewUpdateRequestDTO(
            firebaseToken: token,
            reviewId: id,
            date: APIDateFormat.day.string(from: .now),
            body: draft.body,
            rating: draft.rating,
            reviewImage: ReviewImageEncoder.base64String(from: draft.imageData)
        )
        try await client.send(Endpoint(path: "/review/update", method: .post, body: body))
    }

    func deleteReview(id: Int) async throws {
        let token = try await firebase.idToken()
        try await client.send(Endpoint(path: "/review/delete", method: .post, body: ReviewDeleteRequestDTO(firebaseToken: token, reviewId: id)))
    }
}
