//
//  AccountRepository.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import Foundation

protocol AccountRepository: Sendable {
    func summary(for month: YearMonth) async throws -> AccountSummary
    func expenditures(for month: YearMonth) async throws -> [Expenditure]
    func createExpenditure(_ draft: ExpenditureDraft) async throws
    func updateExpenditure(id: Int, draft: ExpenditureDraft) async throws
    func deleteExpenditure(id: Int) async throws
    func setBudget(_ amount: Int) async throws
}
