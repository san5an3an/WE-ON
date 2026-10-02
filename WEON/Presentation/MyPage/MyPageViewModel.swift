//
//  MyPageViewModel.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import Observation

@Observable
@MainActor
final class MyPageViewModel {
    private(set) var summary: AccountSummary = .empty
    private(set) var expenditureCount = 0

    private let dependencies: AppDependencies

    init(dependencies: AppDependencies = .shared) {
        self.dependencies = dependencies
    }

    // 프로필 아래 이번 달 사용액, 잔액, 지출 건수 표시용 값 갱신
    func load() async {
        async let summary = try? dependencies.account.summary(for: .current)
        async let list = try? dependencies.account.expenditures(for: .current)
        self.summary = await summary ?? .empty
        expenditureCount = await list?.count ?? 0
    }
}
