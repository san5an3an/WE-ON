//
//  CommonComponents.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import ImageIO
import SwiftUI

struct SectionHeader<Trailing: View>: View {
    let title: String
    var subtitle: String?
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.seed(20, weight: .bold, relativeTo: .title3))
                if let subtitle {
                    Text(subtitle)
                        .font(.seed(13, relativeTo: .footnote))
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            trailing
        }
    }
}

extension SectionHeader where Trailing == EmptyView {
    init(title: String, subtitle: String? = nil) {
        self.init(title: title, subtitle: subtitle) { EmptyView() }
    }
}

struct LoginRequiredView: View {
    @Environment(SessionStore.self) private var session
    let message: String

    var body: some View {
        VStack(spacing: Spacing.l) {
            Image("WEONLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 96)
                .accessibilityHidden(true)
            VStack(spacing: Spacing.s) {
                Text("로그인이 필요해요")
                    .font(.seed(17, weight: .bold, relativeTo: .headline))
                Text(message)
                    .font(.seed(14, relativeTo: .subheadline))
                    .foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.center)
            Button("로그인하기") { session.requireLogin() }
                .buttonStyle(.primary)
                .frame(width: 220)
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct LoadingOverlay: ViewModifier {
    let isLoading: Bool

    func body(content: Content) -> some View {
        content
            .overlay {
                if isLoading {
                    ZStack {
                        Color.black.opacity(0.08).ignoresSafeArea()
                        ProgressView()
                            .controlSize(.large)
                            .padding(Spacing.xl)
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: Radius.m))
                    }
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: isLoading)
    }
}

struct ErrorAlert: ViewModifier {
    @Binding var error: WEONError?

    func body(content: Content) -> some View {
        content.alert(
            "알림",
            isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } }),
            presenting: error
        ) { _ in
            Button("확인", role: .cancel) {}
        } message: { error in
            Text(error.errorDescription ?? "")
        }
    }
}

extension View {
    func loadingOverlay(_ isLoading: Bool) -> some View {
        modifier(LoadingOverlay(isLoading: isLoading))
    }

    func errorAlert(_ error: Binding<WEONError?>) -> some View {
        modifier(ErrorAlert(error: error))
    }
}

struct FormField<Field: View>: View {
    let title: String
    var message: String?
    var isFocused = false
    var text: Binding<String>?
    @ViewBuilder var field: Field

    private var borderColor: Color {
        if message != nil { return .red.opacity(0.7) }
        return isFocused ? .brandText : .clear
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: Spacing.s) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.seed(12, weight: .bold, relativeTo: .caption))
                        .foregroundStyle(isFocused ? Color.brandText : Color.secondary)
                    field
                        .font(.seed(17, relativeTo: .body))
                }
                if let text, isFocused, !text.wrappedValue.isEmpty {
                    Button {
                        text.wrappedValue = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(title) 지우기")
                }
            }
            .padding(.horizontal, Spacing.l)
            .padding(.vertical, Spacing.m)
            // 포커스 전에는 채운 박스, 포커스 후에는 흰 박스와 테두리 표시
            .background(isFocused ? Color.cardSurface : Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: Radius.m, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: Radius.m, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: 1.5)
            }
            .animation(.easeOut(duration: 0.15), value: isFocused)
            if let message {
                Text(message)
                    .font(.seed(12, relativeTo: .caption))
                    .foregroundStyle(.red)
                    .padding(.horizontal, Spacing.xs)
            }
        }
    }
}

struct DataImage: View {
    let data: Data

    var body: some View {
        if let image = Self.cgImage(from: data) {
            Image(decorative: image, scale: 1)
                .resizable()
                .scaledToFill()
        } else {
            Color.hairline
        }
    }

    // UIKit 없이 ImageIO 로 이미지 데이터 디코딩
    static func cgImage(from data: Data) -> CGImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: 1280
        ]
        return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
    }
}
