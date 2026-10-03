//
//  LottieLoadingView.swift
//  WE-ON
//
//  Created by SAN on 10/3/26.
//

import Lottie
import SwiftUI

// WEON/Resources/Lottie 폴더에 넣는 Lottie JSON 파일 이름 지정
enum LottieAsset: String {
    case weonProgressIndicator = "weonProgressIndicator"

    // 파일이 없으면 nil 반환
    var animation: LottieAnimation? {
        LottieAnimation.named(rawValue, bundle: .main, subdirectory: "Lottie")
    }
}

// 로딩 중 Lottie 애니메이션 표시, JSON 파일이 없으면 기본 회전 표시로 대체
struct LottieLoadingView: View {
    var asset: LottieAsset = .weonProgressIndicator
    var size: CGFloat = 56

    var body: some View {
        Group {
            if let animation = asset.animation {
                LottieView(animation: animation)
                    .playing(loopMode: .loop)
                    .resizable()
            } else {
                ProgressView()
                    .controlSize(size >= 64 ? .large : .regular)
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement()
        .accessibilityLabel("불러오는 중이에요.")
    }
}
