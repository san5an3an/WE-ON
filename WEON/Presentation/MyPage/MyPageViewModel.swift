//
//  MyPageViewModel.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import Observation

// 내 정보 화면 상태 관리
@Observable
@MainActor
final class MyPageViewModel {
  private(set) var summary: AccountSummary = .empty
  private(set) var expenditureCount = 0
  private(set) var isLoading = false
  private(set) var didLoad = false
  
  private let dependencies: AppDependencies
  
  init(dependencies: AppDependencies = .shared) {
    self.dependencies = dependencies
  }
  
  // 프로필 아래 이번 달 사용액, 잔액, 지출 건수 표시용 값 갱신
  func load() async {
      isLoading = true
      defer {
          isLoading = false
          didLoad = true
      }
    async let summary = try? dependencies.account.summary(for: .current)
    async let list = try? dependencies.account.expenditures(for: .current)
    self.summary = await summary ?? .empty
    expenditureCount = await list?.count ?? 0
  }
}
