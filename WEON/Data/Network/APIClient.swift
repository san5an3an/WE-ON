//
//  APIClient.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import Foundation

// Info.plist 에 들어 있는 서버 주소와 외부 API 키 조회
enum AppConfiguration {
    static var serverURL: URL {
        let value = Bundle.main.object(forInfoDictionaryKey: "SERVER_URL") as? String
        return URL(string: value ?? "") ?? URL(string: "http://127.0.0.1:8080")!
    }

    static var kakaoAPIKey: String {
        (Bundle.main.object(forInfoDictionaryKey: "KAKAO_API_KEY") as? String) ?? ""
    }
}

// 서버 요청 방식 구분
enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
}

// 서버 요청 한 건의 경로, 방식, Query, Body 보관
struct Endpoint: Sendable {
    let path: String
    let method: HTTPMethod
    var queryItems: [URLQueryItem] = []
    var body: (any Encodable & Sendable)?
}

// 서버 요청 전송과 응답 해석 담당
struct APIClient: Sendable {
    private let baseURL: URL
    private let session: URLSession

    init(baseURL: URL = AppConfiguration.serverURL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    // 요청 전송 후 응답 JSON 을 지정한 타입으로 변환
    func send<Response: Decodable>(_ endpoint: Endpoint, as type: Response.Type = Response.self) async throws -> Response {
        let data = try await perform(endpoint)
        do {
            return try JSONDecoder().decode(Response.self, from: data)
        } catch {
            throw WEONError.decoding
        }
    }

    // 응답 본문이 필요 없는 요청 전송
    func send(_ endpoint: Endpoint) async throws {
        _ = try await perform(endpoint)
    }

    // 상태 코드별로 성공 데이터 반환 또는 에러 변환
    private func perform(_ endpoint: Endpoint) async throws -> Data {
        let request = try makeRequest(endpoint)
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw WEONError.network
        }
        guard let status = (response as? HTTPURLResponse)?.statusCode else { throw WEONError.network }
        switch status {
        case 200..<300:
            return data
        case 400..<500:
            let message = try? JSONDecoder().decode(ErrorResponseDTO.self, from: data).ErrorMessage
            throw WEONError.invalidRequest(message)
        default:
            throw WEONError.server
        }
    }

    // Endpoint 를 URLRequest 로 변환
    private func makeRequest(_ endpoint: Endpoint) throws -> URLRequest {
        var components = URLComponents(url: baseURL.appending(path: endpoint.path), resolvingAgainstBaseURL: false)
        if !endpoint.queryItems.isEmpty {
            components?.queryItems = endpoint.queryItems
        }
        guard let url = components?.url else { throw WEONError.invalidRequest(nil) }
        var request = URLRequest(url: url, timeoutInterval: 10)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let body = endpoint.body {
            request.httpBody = try JSONEncoder().encode(body)
        }
        return request
    }
}
