// 공공데이터 가맹점 한 건을 stores 테이블 행으로 바꾸고 SQL 로 만드는 순수 함수 모음

// 전국아동복지급식정보표준데이터 API 응답 한 건 중 쓰는 필드 보관
export interface RawStore {
  mrhstNm: string;
  mrhstCode: string;
  signguCode: string;
  rdnmadr: string;
  lnmadr: string;
  latitude: string;
  longitude: string;
  phoneNumber: string;
  referenceDate: string;
}

// stores 테이블에 넣을 가게 한 행 보관
export interface StoreRow {
  name: string;
  category: "restaurant" | "convenience" | "mart";
  roadAddress: string;
  lotAddress: string;
  lat: number;
  lng: number;
  phone: string | null;
  sourceKey: string;
  referenceDate: string;
}

// 아동급식카드 가맹점 표시값 지정
const mealCardStoreType = 1;
// 원본 데이터 출처 표시값 지정
const sourceName = "data.go.kr/15034530";
// 한 INSERT 문에 담는 행 수 지정, D1 의 SQL 문 길이 제한 안쪽으로 유지
const rowsPerStatement = 100;

// 가맹점유형코드를 가게 종류로 변환, 지자체마다 1 과 01 처럼 다르게 적어 둔 값을 함께 처리
const categoryByCode: Record<string, StoreRow["category"]> = {
  "1": "restaurant",
  "2": "mart",
  "3": "convenience",
};

// 연속 공백을 하나로 줄이고 앞뒤 공백 제거
function clean(value: string | undefined): string {
  return (value ?? "").replace(/\s+/g, " ").trim();
}

// 000-0000 처럼 자리만 채운 전화번호는 없는 번호로 처리
function cleanPhone(value: string | undefined): string | null {
  const phone = clean(value);
  return phone === "" || /^[0-]+$/.test(phone.replace(/^\d{2,3}-/, "")) ? null : phone;
}

// 원본 한 건을 가게 행으로 변환, 종류를 모르거나 국내 좌표가 아니면 null 반환
export function toStoreRow(raw: RawStore): StoreRow | null {
  const category = categoryByCode[clean(raw.mrhstCode).replace(/^0+/, "")];
  const lat = Number(raw.latitude);
  const lng = Number(raw.longitude);
  const name = clean(raw.mrhstNm);
  const lotAddress = clean(raw.lnmadr);
  const roadAddress = clean(raw.rdnmadr) || lotAddress;
  if (!category || name === "" || roadAddress === "") return null;
  if (!(lat >= 33 && lat <= 39 && lng >= 124 && lng <= 132)) return null;
  return {
    name,
    category,
    roadAddress,
    lotAddress,
    lat,
    lng,
    phone: cleanPhone(raw.phoneNumber),
    sourceKey: `${clean(raw.signguCode)}|${name}|${roadAddress}`,
    referenceDate: clean(raw.referenceDate),
  };
}

// 같은 원본 식별값이 여러 번 나오면 기준일이 가장 최근인 한 건만 남김
export function dedupe(rows: StoreRow[]): StoreRow[] {
  const latest = new Map<string, StoreRow>();
  for (const row of rows) {
    const current = latest.get(row.sourceKey);
    if (!current || row.referenceDate > current.referenceDate) latest.set(row.sourceKey, row);
  }
  return [...latest.values()];
}

// SQL 문자열 값으로 변환, 작은따옴표는 두 번 적어 감쌈
function sqlText(value: string | null): string {
  return value === null ? "NULL" : `'${value.replace(/'/g, "''")}'`;
}

// 가게 행 묶음을 upsert SQL 로 변환, 이미 있는 가게는 id 를 유지한 채 내용만 갱신
export function toUpsertSql(rows: StoreRow[]): string {
  const statements: string[] = [];
  for (let start = 0; start < rows.length; start += rowsPerStatement) {
    const values = rows.slice(start, start + rowsPerStatement).map((row) =>
      `(${sqlText(row.name)}, ${mealCardStoreType}, ${sqlText(row.category)}, ${sqlText(row.roadAddress)}, ${sqlText(row.lotAddress)}, ${row.lat}, ${row.lng}, ${sqlText(row.phone)}, ${sqlText(sourceName)}, ${sqlText(row.sourceKey)})`,
    );
    statements.push(
      `INSERT INTO stores (name, store_type, category, road_address, lot_address, lat, lng, phone, source, source_key) VALUES\n${values.join(",\n")}\n` +
        "ON CONFLICT (source_key) DO UPDATE SET name = excluded.name, category = excluded.category, road_address = excluded.road_address, " +
        "lot_address = excluded.lot_address, lat = excluded.lat, lng = excluded.lng, phone = excluded.phone, source = excluded.source;",
    );
  }
  return statements.join("\n");
}
