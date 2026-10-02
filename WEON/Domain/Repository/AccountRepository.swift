//
//  AccountRepository.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import Foundation

// 가계부 데이터 조회와 저장 규칙 정의
protocol AccountRepository: Sendable {
    // 월별 사용액과 잔액 조회
    func summary(for month: YearMonth) async throws -> AccountSummary
    // 월별 지출 내역 조회
    func expenditures(for month: YearMonth) async throws -> [Expenditure]
    // 지출 추가
    func createExpenditure(_ draft: ExpenditureDraft) async throws
    // 지출 수정
    func updateExpenditure(id: Int, draft: ExpenditureDraft) async throws
    // 지출 삭제
    func deleteExpenditure(id: Int) async throws
    // 이번 달 예산 저장
    func setBudget(_ amount: Int) async throws
}
