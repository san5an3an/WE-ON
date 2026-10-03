//
//  ReviewFormViewModel.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import Foundation
import Observation

// 리뷰 입력 화면 상태 관리
@Observable
@MainActor
final class ReviewFormViewModel {
    var draft: ReviewDraft
    private(set) var isSaving = false
    private(set) var didSave = false
    var error: WEONError?

    let storeId: Int
    let storeName: String
    // 수정 중인 기존 리뷰 보관, 새로 작성할 때는 nil 지정
    let editing: Review?
    private let dependencies: AppDependencies

    init(storeId: Int, storeName: String, editing: Review?, dependencies: AppDependencies = .shared) {
        self.storeId = storeId
        self.storeName = storeName
        self.editing = editing
        self.dependencies = dependencies
        self.draft = editing.map(ReviewDraft.init(editing:)) ?? ReviewDraft()
    }

    var isEditing: Bool { editing != nil }

    // 앞뒤 공백을 뺀 본문 글자 수 계산
    var bodyLength: Int {
        draft.body.trimmingCharacters(in: .whitespacesAndNewlines).count
    }

    // 등록 버튼 활성화 여부 계산
    var canSubmit: Bool {
        InputValidationUseCase.validateReview(draft) == nil && !isSaving
    }

    // 새 리뷰 작성 또는 기존 리뷰 수정
    func submit() async {
        isSaving = true
        defer { isSaving = false }
        do {
            if let editing {
                try await dependencies.review.updateReview(id: editing.id, draft: draft)
            } else {
                try await dependencies.review.createReview(storeId: storeId, draft: draft)
            }
            didSave = true
        } catch {
            self.error = WEONError.wrap(error)
        }
    }
}
