//
//  ExpenditureFormViewModel.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import Observation

// 지출 입력 화면 상태 관리
@Observable
@MainActor
final class ExpenditureFormViewModel {
    // 입력 중인 지출 내용 보관
    var draft: ExpenditureDraft
    private(set) var isSaving = false
    private(set) var didSave = false
    var error: WEONError?

    // 수정 중인 기존 지출 보관, 새로 추가할 때는 nil 지정
    let editing: Expenditure?
    private let dependencies: AppDependencies

    init(editing: Expenditure?, dependencies: AppDependencies = .shared) {
        self.editing = editing
        self.dependencies = dependencies
        self.draft = editing.map(ExpenditureDraft.init(editing:)) ?? ExpenditureDraft()
    }

    var isEditing: Bool { editing != nil }

    // 저장 버튼 활성화 여부 계산
    var canSubmit: Bool {
        InputValidationUseCase.validateExpenditure(draft) == nil && !isSaving
    }

    // 숫자 이외 문자를 지운 금액 입력값 변환
    func updatePrice(from text: String) {
        let digits = text.filter(\.isNumber)
        draft.price = digits.isEmpty ? nil : Int(digits.prefix(9))
    }

    // 새 지출 추가 또는 기존 지출 수정
    func submit() async {
        isSaving = true
        defer { isSaving = false }
        do {
            if let editing {
                try await dependencies.account.updateExpenditure(id: editing.id, draft: draft)
            } else {
                try await dependencies.account.createExpenditure(draft)
            }
            didSave = true
        } catch {
            self.error = WEONError.wrap(error)
        }
    }
}
