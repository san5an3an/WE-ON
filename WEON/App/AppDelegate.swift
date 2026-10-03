//
//  AppDelegate.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import FirebaseCore
import FirebaseMessaging
import UIKit
import UserNotifications
import KakaoMapsSDK

// FCM 토큰 발급과 APNs 등록은 UIApplicationDelegate 에서만 받을 수 있어 UIKit 사용
final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    // Firebase 설정 파일이 있을 때만 Firebase 시작과 FCM 토큰 발급용 원격 알림 등록, 알림 권한은 가계부 설정에서 요청
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
      // 카카오맵 appKey가 있을 때에만 mapSDK 시작
      if let key = Bundle.main.object(forInfoDictionaryKey: "KAKAO_NATIVE_APP_KEY") as? String, !key.isEmpty {
        SDKInitializer.InitSDK(appKey: key)
      }
        guard Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil else { return true }
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self
        application.registerForRemoteNotifications()
        return true
    }

    // APNs 기기 토큰을 FCM 에 전달
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        guard FirebaseApp.app() != nil else { return }
        Messaging.messaging().apnsToken = deviceToken
    }

    // 새로 발급된 FCM 토큰 보관
    nonisolated func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        Task {
            await PushTokenStore.shared.update(fcmToken)
        }
    }

    // 앱 사용 중에도 알림 배너 표시
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .badge, .sound]
    }
}
