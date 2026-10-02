//
//  AccountViewModel.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import Observation

@Observable
@MainActor
final class AccountViewModel {
    private(set) var month: YearMonth = .current
    private(set) var summary: AccountSummary = .empty
    private(set) var groups: [ExpenditureDayGroup] = []
    private(set) var isLoading = false
    private(set) var didLoad = false
    var error: WEONError?

    private let dependencies: AppDependencies

    init(dependencies: AppDependencies = .shared) {
        self.dependencies = dependencies
    }

    var canMoveForward: Bool { month < .current }

    func moveMonth(by offset: Int) async {
        let target = month.adding(months: offset)
        guard target <= .current else { return }
        month = target
        await load()
    }

    func load() async {
        defer { didLoad = true }
        let month = self.month
        async let summary = try? dependencies.account.summary(for: month)
        async let list = try? dependencies.account.expenditures(for: month)
        self.summary = await summary ?? .empty
        groups = ExpenditureGroupingUseCase.groupByDay(await list ?? [])
    }

    func delete(_ expenditure: Expenditure) async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await dependencies.account.deleteExpenditure(id: expenditure.id)
            await load()
        } catch {
            self.error = WEONError.wrap(error)
        }
    }
}
