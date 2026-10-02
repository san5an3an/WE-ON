//
//  ReviewImageEncoder.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import Foundation
import ImageIO
import UniformTypeIdentifiers

// 리뷰 사진을 서버 전송용으로 줄이고 Base64 로 변환
enum ReviewImageEncoder {
    // 사진 긴 변의 최대 픽셀 수 지정
    static let maxPixelSize = 1280

    // 원본 사진을 긴 변 기준으로 줄인 PNG 데이터로 변환
    static func downscaledPNG(from data: Data, maxPixelSize: Int = maxPixelSize) -> Data? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
        ]
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { return nil }
        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(output, UTType.png.identifier as CFString, 1, nil) else { return nil }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return output as Data
    }

    // 서버가 받던 64자 줄바꿈 Base64 형식으로 변환
    static func base64String(from data: Data?) -> String? {
        guard let data else { return nil }
        let png = downscaledPNG(from: data) ?? data
        return png.base64EncodedString(options: .lineLength64Characters)
    }
}
