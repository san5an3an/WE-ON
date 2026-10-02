import { Hono } from "hono";
import { boundingBox, distanceKm, roundKm, type Coordinate } from "../geo";
import { ApiError, type AppContext } from "../types";
import { requireNumber, type Body } from "../validation";

// 가게 API 경로 등록
export const storeRoutes = new Hono<AppContext>();

// stores 테이블 조회 결과 한 행 보관
interface StoreRow {
  id: number;
  name: string;
  store_type: number;
  zip_code: number;
  road_address: string;
  lot_address: string;
  lat: number;
  lng: number;
  benefit_name: string | null;
  benefit_target: string | null;
  hygiene_grade: string;
  rating: number | null;
}

// 주변 가게 응답 최대 개수 지정
const nearbyLimit = 50;
// 검색 결과 응답 최대 개수 지정
const searchLimit = 100;
// 리뷰 별점 평균을 함께 조회하는 SQL 조각 지정
const ratingColumn = "(SELECT AVG(rating) FROM reviews WHERE reviews.store_id = stores.id) AS rating";

// 요청 Body 의 현재 위치 좌표 확인
function readCoordinate(body: Body): Coordinate {
  const lat = requireNumber(body, "curLat");
  const lng = requireNumber(body, "curLogt");
  if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
    throw new ApiError(400, "현재 위치 좌표가 올바르지 않습니다.");
  }
  return { lat, lng };
}

// 앱이 쓰는 가게 목록 응답 형식으로 변환
function toSimpleStore(row: StoreRow, distance: number) {
  return {
    storeId: row.id,
    storeName: row.name,
    storeType: row.store_type,
    curDist: roundKm(distance),
    totalRating: Math.round((row.rating ?? 0) * 10) / 10,
  };
}

// 현재 위치에서 가까운 순서로 정렬
function sortByDistance(rows: StoreRow[], from: Coordinate) {
  return rows
    .map((row) => ({ row, distance: distanceKm(from, { lat: row.lat, lng: row.lng }) }))
    .sort((a, b) => a.distance - b.distance);
}

// 반경을 감싸는 위경도 범위 안의 가게 조회
async function storesWithin(db: D1Database, center: Coordinate, radiusKm: number): Promise<StoreRow[]> {
  const box = boundingBox(center, radiusKm);
  const result = await db
    .prepare(`SELECT *, ${ratingColumn} FROM stores WHERE lat BETWEEN ? AND ? AND lng BETWEEN ? AND ? LIMIT 2000`)
    .bind(box.minLat, box.maxLat, box.minLng, box.maxLng)
    .all<StoreRow>();
  return result.results;
}

// 현재 위치 주변 가게 조회
storeRoutes.post("/restaurant/findByCur", async (c) => {
  const center = readCoordinate(await c.req.json<Body>());
  // 가까운 가게가 적으면 반경을 넓혀 다시 조회
  for (const radius of [2, 5, 15]) {
    const rows = sortByDistance(await storesWithin(c.env.DB, center, radius), center).filter((item) => item.distance <= radius);
    if (rows.length >= 10 || radius === 15) {
      return c.json(rows.slice(0, nearbyLimit).map(({ row, distance }) => toSimpleStore(row, distance)));
    }
  }
  return c.json([]);
});

// 가게명과 주소로 가게 검색, 가까운 순서로 정렬
storeRoutes.post("/restaurant/findByKeyword", async (c) => {
  const center = readCoordinate(await c.req.json<Body>());
  const keyword = (c.req.query("keyword") ?? "").trim();
  if (keyword.length === 0) {
    return c.json([]);
  }
  const pattern = `%${keyword.replace(/[\\%_]/g, (ch) => `\\${ch}`)}%`;
  const result = await c.env.DB.prepare(
    `SELECT *, ${ratingColumn} FROM stores
     WHERE name LIKE ?1 ESCAPE '\\' OR road_address LIKE ?1 ESCAPE '\\' OR lot_address LIKE ?1 ESCAPE '\\'
     LIMIT 1000`,
  )
    .bind(pattern)
    .all<StoreRow>();
  const rows = sortByDistance(result.results, center).slice(0, searchLimit);
  return c.json(rows.map(({ row, distance }) => toSimpleStore(row, distance)));
});

// 가게 상세 조회, 응답 필드 이름은 원본 앱 형식 유지
storeRoutes.post("/restaurant/:storeId{[0-9]+}", async (c) => {
  const center = readCoordinate(await c.req.json<Body>());
  const row = await c.env.DB.prepare(`SELECT *, ${ratingColumn} FROM stores WHERE id = ?`)
    .bind(Number(c.req.param("storeId")))
    .first<StoreRow>();
  if (!row) {
    throw new ApiError(404, "가게를 찾을 수 없습니다.");
  }
  return c.json({
    storeId: row.id,
    storeName: row.name,
    refinezipCd: row.zip_code,
    refineRoadnmAddr: row.road_address,
    refineLotnoAddr: row.lot_address,
    refineWGS84Lat: row.lat,
    refineWGS84Logt: row.lng,
    prodName: row.benefit_name,
    prodTarget: row.benefit_target,
    storeType: row.store_type,
    curDist: roundKm(distanceKm(center, { lat: row.lat, lng: row.lng })),
    totalRating: Math.round((row.rating ?? 0) * 10) / 10,
    hygieneGrade: row.hygiene_grade,
  });
});
