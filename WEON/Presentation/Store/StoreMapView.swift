//
//  StoreMapView.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import SwiftUI

struct StoreMapView: View {
    let store: StoreDetail

    var body: some View {
        NaverMapView(store: store.coordinate, storeName: store.name)
            .ignoresSafeArea(edges: .bottom)
            .safeAreaInset(edge: .bottom) {
                HStack(spacing: Spacing.m) {
                    StoreThumbnail(kind: store.kind, size: 48)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(store.name)
                            .font(.seed(16, weight: .bold, relativeTo: .headline))
                        Text(store.shortAddress)
                            .font(.seed(13, relativeTo: .footnote))
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                        Text("내 위치에서 \(store.distanceKm.formattedDistance)")
                            .font(.seed(12, weight: .bold, relativeTo: .caption))
                            .foregroundStyle(Color.brandText)
                    }
                    Spacer(minLength: 0)
                }
                .padding(Spacing.l)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: Radius.l, style: .continuous))
                .padding(Spacing.l)
            }
            .navigationTitle("가게 위치")
            .navigationBarTitleDisplayMode(.inline)
    }
}
