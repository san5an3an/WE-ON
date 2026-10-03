// 위도와 경도 좌표 보관
export interface Coordinate {
  lat: number;
  lng: number;
}

// 지구 반지름 지정
const earthRadiusKm = 6371;

// 두 좌표 사이 거리를 km 단위로 계산
export function distanceKm(a: Coordinate, b: Coordinate): number {
  const toRad = (deg: number) => (deg * Math.PI) / 180;
  const dLat = toRad(b.lat - a.lat);
  const dLng = toRad(b.lng - a.lng);
  const h = Math.sin(dLat / 2) ** 2 + Math.cos(toRad(a.lat)) * Math.cos(toRad(b.lat)) * Math.sin(dLng / 2) ** 2;
  return 2 * earthRadiusKm * Math.asin(Math.min(1, Math.sqrt(h)));
}

// 반경 안의 좌표를 SQL 범위 조건으로 거르기 위한 위경도 경계 계산
export function boundingBox(center: Coordinate, radiusKm: number) {
  const latDelta = radiusKm / 111.32;
  const lngDelta = radiusKm / (111.32 * Math.max(Math.cos((center.lat * Math.PI) / 180), 0.01));
  return {
    minLat: center.lat - latDelta,
    maxLat: center.lat + latDelta,
    minLng: center.lng - lngDelta,
    maxLng: center.lng + lngDelta,
  };
}

// 거리를 m 단위까지만 남기도록 반올림
export function roundKm(value: number): number {
  return Math.round(value * 1000) / 1000;
}
