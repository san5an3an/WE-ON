//
//  RemoteAccountRepository.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import Foundation

struct RemoteAccountRepository: AccountRepository {
    private let firebase: FirebaseAuthClient
    private let client: APIClient

    init(firebase: FirebaseAuthClient = FirebaseAuthClient(), client: APIClient = APIClient()) {
        self.firebase = firebase
        self.client = client
    }

    func summary(for month: YearMonth) async throws -> AccountSummary {
        let token = try await firebase.idToken()
        let response: AccountSummaryDTO = try await client.send(Endpoint(path: "/account", method: .post, body: YearMonthRequestDTO(firebaseToken: token, yearMonth: month.apiValue)))
        return response.toEntity()
    }

    func expenditures(for month: YearMonth) async throws -> [Expenditure] {
        let token = try await firebase.idToken()
        let response: [ExpenditureDTO] = try await client.send(Endpoint(path: "/account/list", method: .post, body: YearMonthRequestDTO(firebaseToken: token, yearMonth: month.apiValue)))
        return response.map { $0.toEntity() }
    }

    func createExpenditure(_ draft: ExpenditureDraft) async throws {
        if let error = InputValidationUseCase.validateExpenditure(draft) { throw error }
        let token = try await firebase.idToken()
        try await client.send(Endpoint(path: "/account/create", method: .post, body: ExpenditureRequestDTO(token: token, draft: draft)))
    }

    func updateExpenditure(id: Int, draft: ExpenditureDraft) async throws {
        if let error = InputValidationUseCase.validateExpenditure(draft) { throw error }
        let token = try await firebase.idToken()
        try await client.send(Endpoint(path: "/account/update", method: .post, body: ExpenditureRequestDTO(token: token, accountId: id, draft: draft)))
    }

    func deleteExpenditure(id: Int) async throws {
        let token = try await firebase.idToken()
        try await client.send(Endpoint(path: "/account/delete", method: .post, body: ExpenditureDeleteRequestDTO(firebaseToken: token, accountId: id)))
    }

    func setBudget(_ amount: Int) async throws {
        let token = try await firebase.idToken()
        try await client.send(Endpoint(path: "/account/setting", method: .post, body: BudgetRequestDTO(firebaseToken: token, amount: amount)))
    }
}
