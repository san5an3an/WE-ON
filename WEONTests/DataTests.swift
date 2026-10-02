//
//  DataTests.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import Foundation
import Testing
@testable import WEON

struct DTOTests {
    @Test func 가게_상세_응답_변환() throws {
        let json = """
        {"storeId":7,"storeName":"나눔 식당","refinezipCd":10200,"refineRoadnmAddr":"경기도 고양시 일산동구 중앙로 1 (장항동)","refineLotnoAddr":"장항동 1","refineWGS84Lat":37.66,"refineWGS84Logt":126.8,"prodName":"짜장면 무료","prodTarget":"결식아동","storeType":2,"curDist":0.8,"totalRating":4.2,"hygieneGrade":""}
        """
        let store = try JSONDecoder().decode(StoreDTO.self, from: Data(json.utf8)).toEntity()
        #expect(store.shortAddress == "경기도 고양시 일산동구 중앙로 1")
        #expect(store.kind == [.mealCard, .goodInfluence])
        #expect(store.coordinate == Coordinate(latitude: 37.66, longitude: 126.8))
    }

    @Test func 가계부_요약은_charge_가_사용액() throws {
        let summary = try JSONDecoder().decode(AccountSummaryDTO.self, from: Data(#"{"balance":7000,"charge":3000}"#.utf8)).toEntity()
        #expect(summary == AccountSummary(used: 3000, balance: 7000))
    }

    @Test func 리뷰_생성_요청은_사진이_없어도_reviewImage_키를_보냄() throws {
        let body = ReviewCreateRequestDTO(firebaseToken: "t", storeId: 1, date: "2026-10-02 12:00:00", body: "본문", rating: 5, reviewImage: nil)
        let object = try JSONSerialization.jsonObject(with: JSONEncoder().encode(body)) as? [String: Any]
        #expect(object?.keys.contains("reviewImage") == true)
        #expect(object?["reviewImage"] is NSNull)
    }

    @Test func 지출_생성_요청은_accountId_를_보내지_않음() throws {
        let body = ExpenditureRequestDTO(token: "t", draft: ExpenditureDraft(storeName: "분식", memo: "점심", price: 6000))
        let object = try JSONSerialization.jsonObject(with: JSONEncoder().encode(body)) as? [String: Any]
        #expect(object?["accountId"] == nil)
        #expect(object?["restaurant"] as? String == "분식")
        #expect((object?["date"] as? String)?.count == 10)
    }

    @Test func 카카오_주소는_지번을_우선() throws {
        let json = #"{"documents":[{"road_address":{"address_name":"도로명"},"address":{"address_name":"지번"}}]}"#
        let response = try JSONDecoder().decode(KakaoAddressResponseDTO.self, from: Data(json.utf8))
        #expect(response.firstAddress == "지번")
    }
}
