//
//  AccountSettingViewModel.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import Observation

@Observable
@MainActor
final class AccountSettingViewModel {
    var budget: Int?
    private(set) var isAlarmOn = false
    private(set) var isLoading = false
    var message: String?
    var error: WEONError?

    private let dependencies: AppDependencies

    init(dependencies: AppDependencies = .shared) {
        self.dependencies = dependencies
    }

    var canSaveBudget: Bool { (budget ?? -1) >= 0 && !isLoading }

    func load() async {
        isAlarmOn = (try? await dependencies.alarm.isSubscribed()) ?? false
        if budget == nil, let summary = try? await dependencies.account.summary(for: .current), summary.budget > 0 {
            budget = summary.budget
        }
    }

    func updateBudget(from text: String) {
        let digits = text.filter(\.isNumber)
        budget = digits.isEmpty ? nil : Int(digits.prefix(9))
    }

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

    func setAlarm(_ isOn: Bool) async {
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
