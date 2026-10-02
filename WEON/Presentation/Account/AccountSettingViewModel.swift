//
//  AccountSettingViewModel.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import Observation

// 가계부 설정 화면 상태 관리
@Observable
@MainActor
final class AccountSettingViewModel {
    // 입력 중인 예산 금액 보관
    var budget: Int?
    private(set) var isAlarmOn = false
    private(set) var isLoading = false
    // 알림 권한이 꺼져 있어 설정 앱 안내가 필요한지 여부 보관
    var needsNotificationPermission = false
    // 저장 완료 안내 문구 보관
    var message: String?
    var error: WEONError?

    private let dependencies: AppDependencies

    init(dependencies: AppDependencies = .shared) {
        self.dependencies = dependencies
    }

    // 예산 저장 버튼 활성화 여부 계산
    var canSaveBudget: Bool { (budget ?? -1) >= 0 && !isLoading }

    // 알림 등록 상태와 현재 예산 조회
    func load() async {
        isAlarmOn = (try? await dependencies.alarm.isSubscribed()) ?? false
        if budget == nil, let summary = try? await dependencies.account.summary(for: .current), summary.budget > 0 {
            budget = summary.budget
        }
    }

    // 숫자만 남겨 예산 입력값 변환
    func updateBudget(from text: String) {
        let digits = text.filter(\.isNumber)
        budget = digits.isEmpty ? nil : Int(digits.prefix(9))
    }

    // 이번 달 예산 저장
    func saveBudget() async {
        guard let budget else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            try await dependencies.account.setBudget(budget)
            message = "이번 달 예산을 \(budget.wonText)으로 저장했어요."
        } catch {
            self.error = WEONError.wrap(error)
        }
    }

    // 지출 알림 등록 또는 해제 후 실제 상태 다시 조회
    func setAlarm(_ isOn: Bool) async {
        // 켤 때만 알림 권한을 묻고, 거절되면 서버 등록 없이 설정 앱 안내 표시
        if isOn, !(await dependencies.notification.requestAuthorization()) {
            isAlarmOn = false
            needsNotificationPermission = true
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            if isOn {
                try await dependencies.alarm.subscribe()
            } else {
                try await dependencies.alarm.unsubscribe()
            }
        } catch {
            self.error = WEONError.wrap(error)
        }
        isAlarmOn = (try? await dependencies.alarm.isSubscribed()) ?? isOn
    }
}
