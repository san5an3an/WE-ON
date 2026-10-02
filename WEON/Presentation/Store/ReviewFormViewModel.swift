//
//  ReviewFormViewModel.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import Foundation
import Observation

@Observable
@MainActor
final class ReviewFormViewModel {
    var draft: ReviewDraft
    private(set) var isSaving = false
    private(set) var didSave = false
    var error: WEONError?

    let storeId: Int
    let storeName: String
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

    var bodyLength: Int {
        draft.body.trimmingCharacters(in: .whitespacesAndNewlines).count
    }

    var canSubmit: Bool {
        InputValidationUseCase.validateReview(draft) == nil && !isSaving
    }

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
