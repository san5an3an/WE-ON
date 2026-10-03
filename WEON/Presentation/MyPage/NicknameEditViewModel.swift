//
//  NicknameEditViewModel.swift
//  WE-ON
//
//  Created by SAN on 10/3/26.
//

import Observation

// 닉네임 변경 화면 상태 관리
@Observable
@MainActor
final class NicknameEditViewModel {
    // 입력 중인 새 닉네임 보관
    var nickname: String
    private(set) var isSaving = false
    private(set) var didSave = false
    var error: WEONError?

    // 바꾸기 전 닉네임 보관
    private let original: String

    init(current: String) {
        self.nickname = current
        self.original = current
    }

    // 입력칸 아래 안내 문구 지정
    var message: String? {
        nickname.isEmpty ? nil : InputValidationUseCase.validateNickname(nickname)?.errorDescription
    }

    // 규칙에 맞고 기존 닉네임과 다를 때만 저장 버튼 활성화
    var canSave: Bool {
        InputValidationUseCase.validateNickname(nickname) == nil
            && nickname.trimmingCharacters(in: .whitespaces) != original
            && !isSaving
    }

    // 서버에 닉네임 변경 요청
    func save(with session: SessionStore) async {
        isSaving = true
        defer { isSaving = false }
        do {
            try await session.updateNickname(nickname)
            didSave = true
        } catch {
            self.error = WEONError.wrap(error)
        }
    }
}
