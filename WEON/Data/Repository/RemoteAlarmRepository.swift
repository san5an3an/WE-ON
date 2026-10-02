//
//  RemoteAlarmRepository.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import Foundation

struct RemoteAlarmRepository: AlarmRepository {
    private let firebase: FirebaseAuthClient
    private let client: APIClient
    private let tokenStore: PushTokenStore

    init(firebase: FirebaseAuthClient = FirebaseAuthClient(), client: APIClient = APIClient(), tokenStore: PushTokenStore = .shared) {
        self.firebase = firebase
        self.client = client
        self.tokenStore = tokenStore
    }

    func isSubscribed() async throws -> Bool {
        let token = try await firebase.idToken()
        let response: AlarmStateDTO = try await client.send(Endpoint(path: "/alarm", method: .post, body: TokenRequestDTO(firebaseToken: token)))
        return response.exist
    }

    func subscribe() async throws {
        try await client.send(Endpoint(path: "/alarm/add", method: .post, body: try await alarmBody()))
    }

    func unsubscribe() async throws {
        try await client.send(Endpoint(path: "/alarm/delete", method: .post, body: try await alarmBody()))
    }

    private func alarmBody() async throws -> AlarmRequestDTO {
        let token = try await firebase.idToken()
        return AlarmRequestDTO(firebaseToken: token, FCMToken: await tokenStore.fcmToken ?? "")
    }
}
