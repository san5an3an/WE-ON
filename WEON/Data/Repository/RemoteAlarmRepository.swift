//
//  RemoteAlarmRepository.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import Foundation

// 지출 알림 API 호출 담당
struct RemoteAlarmRepository: AlarmRepository {
    private let firebase: FirebaseAuthClient
    private let client: APIClient
    private let tokenStore: PushTokenStore

    init(firebase: FirebaseAuthClient = FirebaseAuthClient(), client: APIClient = APIClient(), tokenStore: PushTokenStore = .shared) {
        self.firebase = firebase
        self.client = client
        self.tokenStore = tokenStore
    }

    // 지출 알림 등록 여부 조회
    func isSubscribed() async throws -> Bool {
        let token = try await firebase.idToken()
        let response: AlarmStateDTO = try await client.send(Endpoint(path: "/alarm", method: .post, body: TokenRequestDTO(firebaseToken: token)))
        return response.exist
    }

    // 이 기기로 지출 알림 등록
    func subscribe() async throws {
        try await client.send(Endpoint(path: "/alarm/add", method: .post, body: try await alarmBody()))
    }

    // 지출 알림 해제
    func unsubscribe() async throws {
        try await client.send(Endpoint(path: "/alarm/delete", method: .post, body: try await alarmBody()))
    }

    // 로그인 토큰과 FCM 토큰을 담은 요청 Body 생성
    private func alarmBody() async throws -> AlarmRequestDTO {
        let token = try await firebase.idToken()
        return AlarmRequestDTO(firebaseToken: token, FCMToken: await tokenStore.fcmToken ?? "")
    }
}
