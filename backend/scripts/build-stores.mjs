// 공공데이터포털에서 아동급식카드 가맹점을 받아 D1 에 하루씩 나눠 넣을 SQL 파일 생성
//
// 사용법
//   DATA_GO_KR_KEY=<일반 인증키> npm run stores:build               API 에서 받아 생성
//   npm run stores:build -- --input data/raw/stores.json             받아 둔 원본으로 생성
//   npm run stores:build -- --input data/raw/stores.json --limit 1000 앞 1000건만 시험 생성
//   --rows-per-file <수>  파일 하나에 담는 가게 수, 기본 30000

import { mkdir, readFile, rm, writeFile } from "node:fs/promises";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { dedupe, toStoreRow, toUpsertSql } from "./store-rows.ts";

// backend 폴더 기준 경로 지정
const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const rawPath = join(root, "data/raw/stores.json");
const outDir = join(root, "data/out");
// 전국아동복지급식정보표준데이터 오픈 API 주소 지정
const apiUrl = "https://api.data.go.kr/openapi/tn_pubr_public_chil_wlfare_mlsv_api";
// 공공데이터포털 요청에 붙이는 이용자 표시 지정
const userAgent = "WE-ON-data-import/1.0 (+https://github.com/san5an3an/WE-ON)";
// 한 번에 받는 건수 지정
const pageSize = 1000;

// --이름 값 형식의 실행 옵션 읽기
function option(name, fallback) {
  const index = process.argv.indexOf(`--${name}`);
  return index === -1 ? fallback : process.argv[index + 1];
}

// API 한 쪽 조회, 일시 오류는 세 번까지 다시 시도
async function fetchPage(key, pageNo) {
  const query = new URLSearchParams({ serviceKey: key, pageNo: String(pageNo), numOfRows: String(pageSize), type: "json" });
  for (let attempt = 1; ; attempt += 1) {
    try {
      const response = await fetch(`${apiUrl}?${query}`, { headers: { "User-Agent": userAgent } });
      const json = await response.json();
      if (json.header?.resultCode !== "00") throw new Error(`API 오류 ${json.header?.resultCode} ${json.header?.resultMsg}`);
      return json.body;
    } catch (error) {
      if (attempt === 4) throw error;
      console.warn(`${pageNo}쪽 다시 시도 (${attempt})`);
      await new Promise((resolve) => setTimeout(resolve, 3000));
    }
  }
}

// API 에서 전체 가맹점을 받아 원본 파일로 저장
async function downloadAll(key) {
  const items = [];
  for (let pageNo = 1; ; pageNo += 1) {
    const body = await fetchPage(key, pageNo);
    const page = body.items?.item ?? [];
    items.push(...page);
    if (pageNo % 25 === 0) console.log(`${items.length} / ${body.totalCount}건 받음`);
    if (page.length === 0 || items.length >= Number(body.totalCount)) break;
  }
  await mkdir(dirname(rawPath), { recursive: true });
  await writeFile(rawPath, JSON.stringify(items));
  return items;
}

// 원본을 변환해 SQL 파일로 나눠 저장
async function main() {
  const input = option("input");
  const limit = Number(option("limit", "0"));
  const rowsPerFile = Number(option("rows-per-file", "30000"));
  let raw;
  if (input) {
    raw = JSON.parse(await readFile(join(root, input), "utf8"));
  } else {
    const key = process.env.DATA_GO_KR_KEY;
    if (!key) throw new Error("DATA_GO_KR_KEY 환경 변수가 없어요. --input 으로 받아 둔 파일을 쓸 수도 있어요.");
    raw = await downloadAll(key);
  }
  if (limit > 0) raw = raw.slice(0, limit);

  const converted = raw.map(toStoreRow);
  const rows = dedupe(converted.filter((row) => row !== null));
  const counts = Object.groupBy(rows, (row) => row.category);

  await rm(outDir, { recursive: true, force: true });
  await mkdir(outDir, { recursive: true });
  const files = [];
  for (let start = 0; start < rows.length; start += rowsPerFile) {
    const file = join(outDir, `stores-${String(files.length + 1).padStart(3, "0")}.sql`);
    await writeFile(file, toUpsertSql(rows.slice(start, start + rowsPerFile)) + "\n");
    files.push(file);
  }

  console.log(`원본 ${raw.length}건 · 제외 ${converted.length - converted.filter(Boolean).length}건 · 중복 합침 ${converted.filter(Boolean).length - rows.length}건`);
  console.log(`넣을 가게 ${rows.length}곳 (음식점 ${counts.restaurant?.length ?? 0} · 편의점 ${counts.convenience?.length ?? 0} · 마트 ${counts.mart?.length ?? 0})`);
  console.log(`SQL 파일 ${files.length}개 → ${outDir}`);
}

await main();
