//
//  ReviewEntity.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import Foundation

// 가게 리뷰 한 건 보관
struct Review: Identifiable, Hashable, Sendable {
    let id: Int
    let userId: Int
    let userName: String
    let storeId: Int
    let storeName: String
    let date: String
    let body: String
    let rating: Int
    let imageData: Data?
}

// 리뷰 작성과 수정 화면의 입력값 보관
struct ReviewDraft: Equatable, Sendable {
    var rating: Int = 5
    var body: String = ""
    var imageData: Data?

    init(rating: Int = 5, body: String = "", imageData: Data? = nil) {
        self.rating = rating
        self.body = body
        self.imageData = imageData
    }

    init(editing review: Review) {
        self.init(rating: review.rating, body: review.body, imageData: review.imageData)
    }
}
