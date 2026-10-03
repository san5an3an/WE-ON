//
//  KakaoMapView.swift
//  WEON
//
//  Created by SAN KANG on 10/4/26.
//

@preconcurrency import KakaoMapsSDK
import SwiftUI

struct KakaoMapView: UIViewRepresentable {
  let store: Coordinate
  var storeName: String?
  var isInteractive = true
  var showsMyLocation = true
  
  func makeUIView(context: Context) -> KMViewContainer {
    let container = KMViewContainer()
    context.coordinator.start(container) // 컨트롤러를 생성 후 엔진 준비
    return container
  }
  
  func updateUIView(_ uiView: KMViewContainer, context: Context) {}
  
  func makeCoordinator() -> Coordinator { Coordinator(parent: self) }
  
  // 화면에서 사라질 때 엔진 정리
  static func dismantleUIView(_ uiView: KMViewContainer, coordinator: Coordinator) {
    coordinator.controller?.pauseEngine()
    coordinator.controller?.resetEngine()
  }
  
  @MainActor
  final class Coordinator: NSObject {
    let parent: KakaoMapView
    var controller: KMController?
    weak var container: KMViewContainer?
    init(parent: KakaoMapView) { self.parent = parent }
    
    func start(_ container: KMViewContainer) {
      self.container = container
      controller = KMController(viewContainer: container) // 지도 엔진 보관
      controller?.delegate = self // 지도 엔진을 Coordinator가 받음
      controller?.prepareEngine() // 지도 엔진 준비
      controller?.activateEngine() // 지도 엔진 시작 -> 준비되면 addViews()가 호출
    }
  }
}

extension KakaoMapView.Coordinator: @preconcurrency MapControllerDelegate {
  func addViews() {
    let posision = MapPoint(longitude: parent.store.longitude, latitude: parent.store.latitude)
    let info = MapviewInfo(viewName: "mapView", defaultPosition: posision, defaultLevel: 10)
    controller?.addView(info)
  }
  func addViewSucceeded(_ viewName: String, viewInfoName: String) {
    if let map = controller?.getView("mapView") as? KakaoMap, let container {
      map.viewRect = container.bounds
      let position = MapPoint(longitude: parent.store.longitude, latitude: parent.store.latitude)
      map.moveCamera(CameraUpdate.make(target: position, mapView: map))
      addStoreMarker(to: map, at: position)
      map.setLogoPosition(origin: GuiAlignment(vAlign: .top, hAlign: .right), position: CGPoint(x: 8, y: 8))
    }
  }
  func containerDidResized(_ size: CGSize) {
    if let map = controller?.getView("mapView") as? KakaoMap {
      map.viewRect = CGRect(origin: .zero, size: size)
    }
  }
  func authenticationFailed(_ errorCode: Int, desc: String) { print(errorCode, desc) }
  // 매장 위치에 아이콘과 매장 이름 마커 표시
  private func addStoreMarker(to map: KakaoMap, at potision: MapPoint) {
    let manager = map.getLabelManager()
    // 스타일 : 아이콘 이미지+하단글자
    let symbol = UIImage(systemName: "mappin.circle.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 28))? .withTintColor(UIColor(Color.red), renderingMode: .alwaysOriginal)
    let icon = PoiIconStyle(symbol: symbol, anchorPoint: CGPoint(x: 0.5, y: 0.5))
    let text = PoiTextStyle(textLineStyles: [PoiTextLineStyle(textStyle: TextStyle(fontSize: 24, fontColor: .black))])
    manager.addPoiStyle(PoiStyle(styleID: "store", styles: [PerLevelPoiStyle(iconStyle: icon, textStyle: text, level: 0)]))
    // 레이어
    let layer = manager.addLabelLayer(option: LabelLayerOptions(layerID: "storeLayer", competitionType: .none, competitionUnit: .symbolFirst, orderType: .rank, zOrder: 10000))
    // 마커+매장이름
    let options = PoiOptions(styleID: "store")
    if let name = parent.storeName {options.addText(PoiText(text: name, styleIndex: 0))}
    let poi = layer?.addPoi(option: options, at: potision)
    // 노출
    poi?.show()
    if !parent.isInteractive {
      for gesture in [GestureType.pan, .zoom, .rotate, .tilt, .doubleTapZoomIn, .oneFingerZoom] {
        map.setGestureEnable(type: gesture, enable: false)
      }
    }
  }
}
