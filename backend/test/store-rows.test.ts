import { env } from "cloudflare:test";
import { beforeEach, describe, expect, it } from "vitest";
import { dedupe, toStoreRow, toUpsertSql, type RawStore } from "../scripts/store-rows";

// 공공데이터 API 응답 형식의 가맹점 한 건 생성
function raw(overrides: Partial<RawStore> = {}): RawStore {
  return {
    mrhstNm: "행복 분식",
    mrhstCode: "1 ",
    signguCode: "41285",
    rdnmadr: "경기도 고양시 일산동구 중앙로 1",
    lnmadr: "경기도 고양시 일산동구 장항동 1",
    latitude: "37.661",
    longitude: "126.801",
    phoneNumber: "031-123-4567",
    referenceDate: "2026-03-12",
    ...overrides,
  };
}

// SQL 파일 내용을 문장 단위로 나눠 D1 에 실행
async function runSql(sql: string) {
  await env.DB.batch(sql.split(";\n").filter((part) => part.trim()).map((part) => env.DB.prepare(part)));
}

describe("가맹점 변환", () => {
  it("가맹점유형코드를 가게 종류로 바꾸고 0 이 붙은 코드도 같게 본다", () => {
    expect(toStoreRow(raw({ mrhstCode: "01" }))?.category).toBe("restaurant");
    expect(toStoreRow(raw({ mrhstCode: "2" }))?.category).toBe("mart");
    expect(toStoreRow(raw({ mrhstCode: "03" }))?.category).toBe("convenience");
    expect(toStoreRow(raw({ mrhstCode: "9" }))).toBeNull();
  });

  it("국내 좌표가 아니거나 주소가 없으면 제외한다", () => {
    expect(toStoreRow(raw({ latitude: "0", longitude: "0" }))).toBeNull();
    expect(toStoreRow(raw({ latitude: "" }))).toBeNull();
    expect(toStoreRow(raw({ rdnmadr: "", lnmadr: "" }))).toBeNull();
  });

  it("도로명 주소가 없으면 지번 주소를 쓰고 자리만 채운 전화번호는 비운다", () => {
    const row = toStoreRow(raw({ rdnmadr: " ", phoneNumber: "042-000-0000" }));
    expect(row?.roadAddress).toBe("경기도 고양시 일산동구 장항동 1");
    expect(row?.phone).toBeNull();
    expect(toStoreRow(raw())?.phone).toBe("031-123-4567");
  });

  it("같은 가게가 여러 번 나오면 기준일이 최근인 한 건만 남긴다", () => {
    const rows = [raw({ referenceDate: "2026-01-01", phoneNumber: "031-111-1111" }), raw({ referenceDate: "2026-06-01", phoneNumber: "031-222-2222" })]
      .map(toStoreRow)
      .filter((row) => row !== null);
    expect(dedupe(rows).map((row) => row.phone)).toEqual(["031-222-2222"]);
  });
});

describe("가맹점 upsert SQL", () => {
  beforeEach(async () => {
    await env.DB.batch([env.DB.prepare("DELETE FROM reviews"), env.DB.prepare("DELETE FROM users"), env.DB.prepare("DELETE FROM stores")]);
  });

  it("다시 넣어도 가게 id 와 리뷰를 유지한 채 내용만 갱신한다", async () => {
    const first = toStoreRow(raw({ mrhstNm: "작은 '따옴표' 식당", phoneNumber: "031-111-1111" }))!;
    await runSql(toUpsertSql([first]));
    const store = await env.DB.prepare("SELECT id, name, category, store_type FROM stores").first<{ id: number; name: string; category: string; store_type: number }>();
    expect(store).toMatchObject({ name: "작은 '따옴표' 식당", category: "restaurant", store_type: 1 });

    await env.DB.prepare("INSERT INTO users (firebase_uid, email, nickname) VALUES ('uid', 'a@weon.app', 'a')").run();
    await env.DB.prepare("INSERT INTO reviews (user_id, store_id, date, body, rating) SELECT id, ?, '2026-10-03', '다시 넣어도 남아야 하는 리뷰', 5 FROM users").bind(store!.id).run();

    await runSql(toUpsertSql([{ ...first, phone: "031-222-2222", category: "convenience" }]));
    const after = await env.DB.prepare("SELECT id, phone, category, (SELECT COUNT(*) FROM stores) AS stores, (SELECT COUNT(*) FROM reviews) AS reviews FROM stores").first();
    expect(after).toEqual({ id: store!.id, phone: "031-222-2222", category: "convenience", stores: 1, reviews: 1 });
  });

  it("한 문장에 담는 행 수를 넘으면 여러 문장으로 나눈다", async () => {
    const rows = Array.from({ length: 250 }, (_, index) => toStoreRow(raw({ mrhstNm: `가게 ${index}` }))!);
    const sql = toUpsertSql(rows);
    expect(sql.match(/^INSERT INTO stores/gm)).toHaveLength(3);
    await runSql(sql);
    expect(await env.DB.prepare("SELECT COUNT(*) AS count FROM stores").first("count")).toBe(250);
  });
});
