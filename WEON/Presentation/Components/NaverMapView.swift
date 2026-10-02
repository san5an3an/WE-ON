//
//  NaverMapView.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

@preconcurrency import NMapsMap
import SwiftUI

// 네이버 지도 SDK 가 UIView 만 제공해 UIViewRepresentable 로 연결
struct NaverMapView: UIViewRepresentable {
    let store: Coordinate
    var storeName: String?
    var isInteractive = true
    var showsMyLocation = true

    func makeUIView(context: Context) -> NMFNaverMapView {
        let mapView = NMFNaverMapView(frame: .zero)
        mapView.showLocationButton = isInteractive && showsMyLocation
        mapView.showZoomControls = false
        mapView.showCompass = false
        mapView.showScaleBar = false
        mapView.mapView.isScrollGestureEnabled = isInteractive
        mapView.mapView.isZoomGestureEnabled = isInteractive
        mapView.mapView.isRotateGestureEnabled = false
        mapView.mapView.isTiltGestureEnabled = false
        mapView.mapView.zoomLevel = isInteractive ? 16 : 15
        if showsMyLocation {
            mapView.mapView.positionMode = .normal
        }

        let marker = NMFMarker(position: NMGLatLng(lat: store.latitude, lng: store.longitude))
        marker.iconImage = NMF_MARKER_IMAGE_BLACK
        marker.iconTintColor = UIColor(Color.brand)
        marker.captionText = storeName ?? ""
        marker.mapView = mapView.mapView
        context.coordinator.marker = marker

        mapView.mapView.moveCamera(NMFCameraUpdate(scrollTo: NMGLatLng(lat: store.latitude, lng: store.longitude)))
        return mapView
    }

    func updateUIView(_ uiView: NMFNaverMapView, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator {
        var marker: NMFMarker?
    }
}
