//
//  AccountViewModel.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import Observation

// 가계부 화면 상태 관리
@Observable
@MainActor
final class AccountViewModel {
    // 지금 보고 있는 연월 보관
    private(set) var month: YearMonth = .current
    private(set) var summary: AccountSummary = .empty
    // 날짜별로 묶은 지출 내역 보관
    private(set) var groups: [ExpenditureDayGroup] = []
    private(set) var isLoading = false
    private(set) var didLoad = false
    var error: WEONError?

    private let dependencies: AppDependencies

    init(dependencies: AppDependencies = .shared) {
        self.dependencies = dependencies
    }

    // 이번 달보다 미래로는 이동하지 않도록 다음 달 버튼 활성화 여부 계산
    var canMoveForward: Bool { month < .current }

    // 연월을 바꾼 뒤 가계부 다시 조회
    func moveMonth(by offset: Int) async {
        let target = month.adding(months: offset)
        guard target <= .current else { return }
        month = target
        await load()
    }

    // 요약과 지출 내역을 동시에 조회
    func load() async {
        defer { didLoad = true }
        let month = self.month
        async let summary = try? dependencies.account.summary(for: month)
        async let list = try? dependencies.account.expenditures(for: month)
        self.summary = await summary ?? .empty
        groups = ExpenditureGroupingUseCase.groupByDay(await list ?? [])
    }

    // 지출 삭제 후 목록 갱신
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
