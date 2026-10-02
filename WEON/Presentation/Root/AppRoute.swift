//
//  AppRoute.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import SwiftUI

// 탭 안에서 이동하는 화면 목록 정의
enum AppRoute: Hashable {
    case nearbyStores(StoreFilter)
    case storeDetail(storeId: Int)
    case storeMap(StoreDetail)
    case reviewList(StoreDetail)
    case reviewForm(storeId: Int, storeName: String, editing: Review?)
    case expenditureDetail(Expenditure)
    case accountSetting
}

// 화면 이동 값에 맞는 화면 연결
private struct AppRouteDestinations: ViewModifier {
    func body(content: Content) -> some View {
        content.navigationDestination(for: AppRoute.self) { route in
            switch route {
            case .nearbyStores(let filter):
                NearbyStoresView(initialFilter: filter)
            case .storeDetail(let storeId):
                StoreDetailView(storeId: storeId)
            case .storeMap(let store):
                StoreMapView(store: store)
            case .reviewList(let store):
                ReviewListView(store: store)
            case .reviewForm(let storeId, let storeName, let editing):
                ReviewFormView(storeId: storeId, storeName: storeName, editing: editing)
            case .expenditureDetail(let expenditure):
                ExpenditureDetailView(expenditure: expenditure)
            case .accountSetting:
                AccountSettingView()
            }
        }
    }
}

extension View {
    // 탭마다 화면 이동 연결 적용
    func appRouteDestinations() -> some View {
        modifier(AppRouteDestinations())
    }
}
