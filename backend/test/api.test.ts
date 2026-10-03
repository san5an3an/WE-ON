import { env } from "cloudflare:test";
import { beforeEach, describe, expect, it } from "vitest";
import { createApp } from "../src/app";
import { ApiError, type TokenVerifier } from "../src/types";

// 테스트용 토큰은 "uid|email|verified" 형식으로 해석
const fakeVerifier: TokenVerifier = async (token) => {
  const [uid, email, verified] = token.split("|");
  if (!uid || !email) throw new ApiError(401, "유효하지 않은 로그인 토큰입니다.");
  return { uid, email, emailVerified: verified === "1" };
};

// 가짜 토큰 검증을 쓰는 테스트용 앱 생성
const app = createApp(fakeVerifier);
// 테스트 기준 위치 지정
const here = { curLat: 37.66, curLogt: 126.8 };
const alice = "uid-alice|alice@weon.app|1";
const bob = "uid-bob|bob@weon.app|1";

// 테스트용 앱에 JSON 요청을 보내고 응답 해석
async function call(method: "GET" | "POST", path: string, body?: unknown) {
  const response = await app.request(
    path,
    { method, headers: { "Content-Type": "application/json" }, body: body === undefined ? undefined : JSON.stringify(body) },
    env,
  );
  const text = await response.text();
  return { status: response.status, json: text ? JSON.parse(text) : null };
}

// 회원가입 요청 전송
async function signUp(token: string, email: string) {
  return call("POST", "/login/signUp", { firebaseToken: token, email });
}

beforeEach(async () => {
  await env.DB.batch([
    env.DB.prepare("DELETE FROM reviews"),
    env.DB.prepare("DELETE FROM expenditures"),
    env.DB.prepare("DELETE FROM budgets"),
    env.DB.prepare("DELETE FROM alarms"),
    env.DB.prepare("DELETE FROM users"),
    env.DB.prepare("DELETE FROM stores"),
    env.DB.prepare(
      `INSERT INTO stores (id, name, store_type, road_address, lot_address, lat, lng, benefit_name, benefit_target, source) VALUES
       (1, '행복 분식', 1, '경기도 고양시 일산동구 중앙로 1 (장항동)', '장항동 1', 37.661, 126.801, NULL, NULL, 'test'),
       (2, '선한 국밥', 0, '경기도 고양시 일산동구 중앙로 2', '장항동 2', 37.665, 126.805, '국밥 무료', '결식아동', 'test'),
       (3, '함께 식당', 2, '서울특별시 중구 세종대로 110', '태평로1가 31', 37.5665, 126.978, '식사 무료', '아동급식카드 소지 아동', 'test'),
       (4, '부산 세종식당', 1, '부산광역시 부산진구 중앙대로 1', '부전동 1', 35.1796, 129.0756, NULL, NULL, 'test')`,
    ),
  ]);
});

describe("회원", () => {
  it("가입 후 인증된 계정은 로그인 정보를 받는다", async () => {
    expect((await signUp("uid-alice|alice@weon.app|0", "alice@weon.app")).status).toBe(200);
    const login = await call("POST", "/login", { firebaseToken: alice });
    expect(login.status).toBe(200);
    expect(login.json).toMatchObject({ email: "alice@weon.app", userName: "alice" });
    expect(typeof login.json.userId).toBe("number");
  });

  it("이메일 인증 전에는 로그인할 수 없다", async () => {
    await signUp("uid-alice|alice@weon.app|0", "alice@weon.app");
    const login = await call("POST", "/login", { firebaseToken: "uid-alice|alice@weon.app|0" });
    expect(login.status).toBe(403);
    expect(login.json.ErrorMessage).toBeTypeOf("string");
  });

  it("가입하지 않은 계정과 중복 가입은 거절한다", async () => {
    expect((await call("POST", "/login", { firebaseToken: alice })).status).toBe(404);
    await signUp(alice, "alice@weon.app");
    expect((await signUp(alice, "alice@weon.app")).status).toBe(400);
  });

  it("가입 때 보낸 닉네임을 저장하고 내 정보에서 바꿀 수 있다", async () => {
    await call("POST", "/login/signUp", { firebaseToken: alice, email: "alice@weon.app", nickname: "  위온이  " });
    expect((await call("POST", "/login", { firebaseToken: alice })).json.userName).toBe("위온이");
    const changed = await call("POST", "/myPage/nickname", { firebaseToken: alice, nickname: "새이름" });
    expect(changed.status).toBe(200);
    expect(changed.json).toMatchObject({ email: "alice@weon.app", userName: "새이름" });
    expect((await call("POST", "/login", { firebaseToken: alice })).json.userName).toBe("새이름");
  });

  it("닉네임 길이가 맞지 않으면 400 을 돌려준다", async () => {
    expect((await call("POST", "/login/signUp", { firebaseToken: alice, email: "alice@weon.app", nickname: "a" })).status).toBe(400);
    await signUp(alice, "alice@weon.app");
    expect((await call("POST", "/myPage/nickname", { firebaseToken: alice, nickname: "열세글자를넘는아주긴닉네임" })).status).toBe(400);
    expect((await call("POST", "/myPage/nickname", { firebaseToken: bob, nickname: "가입안함" })).status).toBe(404);
  });

  it("토큰이 없으면 401 을 돌려준다", async () => {
    expect((await call("POST", "/login", {})).status).toBe(401);
  });

  it("탈퇴하면 리뷰와 가계부도 함께 지운다", async () => {
    await signUp(alice, "alice@weon.app");
    await call("POST", "/review/create", { firebaseToken: alice, storeId: 1, date: "2026-10-03 12:00:00", body: "정말 맛있고 친절했어요", rating: 5, reviewImage: null });
    await call("POST", "/account/create", { firebaseToken: alice, restaurant: "행복 분식", price: 6000, date: "2026-10-03", body: "" });
    expect((await call("POST", "/myPage/delete", { firebaseToken: alice })).status).toBe(200);
    const counts = await env.DB.prepare("SELECT (SELECT COUNT(*) FROM users) AS u, (SELECT COUNT(*) FROM reviews) AS r, (SELECT COUNT(*) FROM expenditures) AS e").first();
    expect(counts).toEqual({ u: 0, r: 0, e: 0 });
  });
});

describe("가게", () => {
  it("현재 위치 주변 가게를 가까운 순서로 돌려준다", async () => {
    const result = await call("POST", "/restaurant/findByCur", here);
    expect(result.status).toBe(200);
    expect(result.json.map((store: { storeId: number }) => store.storeId)).toEqual([1, 2]);
    expect(result.json[0]).toEqual({ storeId: 1, storeName: "행복 분식", storeType: 1, storeCategory: "restaurant", curDist: expect.any(Number), totalRating: 0 });
    expect(result.json[0].curDist).toBeLessThan(0.2);
  });

  it("현재 위치에서 20km 밖에 있는 가게는 검색하지 않는다", async () => {
    expect((await call("POST", "/restaurant/findByKeyword?keyword=" + encodeURIComponent("세종"), here)).json.map((s: { storeId: number }) => s.storeId)).toEqual([3]);
    const busan = { curLat: 35.18, curLogt: 129.07 };
    expect((await call("POST", "/restaurant/findByKeyword?keyword=" + encodeURIComponent("세종"), busan)).json.map((s: { storeId: number }) => s.storeId)).toEqual([4]);
  });

  it("키워드로 이름과 주소를 검색한다", async () => {
    expect((await call("POST", "/restaurant/findByKeyword?keyword=" + encodeURIComponent("세종대로"), here)).json.map((s: { storeId: number }) => s.storeId)).toEqual([3]);
    expect((await call("POST", "/restaurant/findByKeyword?keyword=" + encodeURIComponent("식"), here)).json).toHaveLength(2);
    expect((await call("POST", "/restaurant/findByKeyword?keyword=" + encodeURIComponent("%"), here)).json).toHaveLength(0);
  });

  it("가게 상세는 원본 앱 응답 필드를 그대로 쓴다", async () => {
    const detail = await call("POST", "/restaurant/2", here);
    expect(detail.json).toMatchObject({
      storeId: 2,
      storeName: "선한 국밥",
      refinezipCd: 0,
      refineRoadnmAddr: "경기도 고양시 일산동구 중앙로 2",
      refineLotnoAddr: "장항동 2",
      refineWGS84Lat: 37.665,
      refineWGS84Logt: 126.805,
      prodName: "국밥 무료",
      prodTarget: "결식아동",
      storeType: 0,
      storeCategory: "restaurant",
      totalRating: 0,
      hygieneGrade: "",
    });
    expect((await call("POST", "/restaurant/999", here)).status).toBe(404);
  });

  it("잘못된 좌표는 400 을 돌려준다", async () => {
    expect((await call("POST", "/restaurant/findByCur", { curLat: "a", curLogt: 1 })).status).toBe(400);
  });
});

describe("리뷰", () => {
  beforeEach(async () => {
    await signUp(alice, "alice@weon.app");
    await signUp(bob, "bob@weon.app");
  });

  it("작성한 리뷰가 최신순으로 보이고 별점 평균에 반영된다", async () => {
    await call("POST", "/review/create", { firebaseToken: alice, storeId: 1, date: "2026-10-01 12:00:00", body: "첫 번째 리뷰입니다 맛있어요", rating: 4, reviewImage: null });
    await call("POST", "/review/create", { firebaseToken: bob, storeId: 1, date: "2026-10-02 12:00:00", body: "두 번째 리뷰입니다 친절해요", rating: 2, reviewImage: "aGVsbG8=" });
    const all = await call("GET", "/review/1");
    expect(all.json.map((review: { userName: string }) => review.userName)).toEqual(["bob", "alice"]);
    expect(all.json[0]).toMatchObject({ storeId: 1, storeName: "행복 분식", rating: 2, reviewImage: "aGVsbG8=" });
    expect((await call("GET", "/review/1?page=1&display=1")).json).toHaveLength(1);
    expect((await call("POST", "/restaurant/1", here)).json.totalRating).toBe(3);
  });

  it("10글자 미만 리뷰와 다른 사람 리뷰 수정은 거절한다", async () => {
    expect((await call("POST", "/review/create", { firebaseToken: alice, storeId: 1, date: "2026-10-01", body: "짧음", rating: 5, reviewImage: null })).status).toBe(400);
    await call("POST", "/review/create", { firebaseToken: alice, storeId: 1, date: "2026-10-01", body: "충분히 긴 리뷰 본문입니다", rating: 5, reviewImage: null });
    const reviewId = (await call("GET", "/review/1")).json[0].reviewId;
    expect((await call("POST", "/review/update", { firebaseToken: bob, reviewId, date: "2026-10-02", body: "남의 리뷰를 고치려는 시도", rating: 1, reviewImage: null })).status).toBe(403);
    expect((await call("POST", "/review/delete", { firebaseToken: bob, reviewId })).status).toBe(403);
    expect((await call("POST", "/review/update", { firebaseToken: alice, reviewId, date: "2026-10-02", body: "수정한 리뷰 본문입니다", rating: 3, reviewImage: null })).status).toBe(200);
    expect((await call("POST", "/review/delete", { firebaseToken: alice, reviewId })).status).toBe(200);
    expect((await call("GET", "/review/1")).json).toHaveLength(0);
  });
});

describe("가계부", () => {
  beforeEach(async () => {
    await signUp(alice, "alice@weon.app");
    await signUp(bob, "bob@weon.app");
  });

  it("월별 지출과 예산 요약을 계산한다", async () => {
    await call("POST", "/account/create", { firebaseToken: alice, restaurant: "행복 분식", price: 6000, date: "2026-10-01", body: "점심" });
    await call("POST", "/account/create", { firebaseToken: alice, restaurant: "선한 국밥", price: 9000, date: "2026-10-03", body: "" });
    await call("POST", "/account/create", { firebaseToken: alice, restaurant: "지난달", price: 1000, date: "2026-09-30", body: "" });
    const list = await call("POST", "/account/list", { firebaseToken: alice, yearMonth: "2026-10" });
    expect(list.json.map((item: { restaurant: string }) => item.restaurant)).toEqual(["선한 국밥", "행복 분식"]);
    expect(list.json[1]).toMatchObject({ price: 6000, date: "2026-10-01", body: "점심" });

    await env.DB.prepare("INSERT INTO budgets (user_id, year_month, amount) SELECT id, '2026-10', 100000 FROM users WHERE email = 'alice@weon.app'").run();
    expect((await call("POST", "/account", { firebaseToken: alice, yearMonth: "2026-10" })).json).toEqual({ charge: 15000, balance: 85000 });
    expect((await call("POST", "/account", { firebaseToken: bob, yearMonth: "2026-10" })).json).toEqual({ charge: 0, balance: 0 });
  });

  it("이번 달 예산을 저장하고 다시 저장하면 덮어쓴다", async () => {
    await call("POST", "/account/setting", { firebaseToken: alice, amount: 50000 });
    await call("POST", "/account/setting", { firebaseToken: alice, amount: 80000 });
    const rows = await env.DB.prepare("SELECT amount FROM budgets").all();
    expect(rows.results).toEqual([{ amount: 80000 }]);
  });

  it("다른 사람 지출은 수정하거나 지울 수 없다", async () => {
    await call("POST", "/account/create", { firebaseToken: alice, restaurant: "행복 분식", price: 6000, date: "2026-10-01", body: "" });
    const accountId = (await call("POST", "/account/list", { firebaseToken: alice, yearMonth: "2026-10" })).json[0].accountId;
    expect((await call("POST", "/account/delete", { firebaseToken: bob, accountId })).status).toBe(403);
    expect((await call("POST", "/account/update", { firebaseToken: alice, accountId, restaurant: "바뀐 가게", price: 7000, date: "2026-10-02", body: "저녁" })).status).toBe(200);
    expect((await call("POST", "/account/list", { firebaseToken: alice, yearMonth: "2026-10" })).json[0]).toMatchObject({ restaurant: "바뀐 가게", price: 7000 });
    expect((await call("POST", "/account/create", { firebaseToken: alice, restaurant: "음수", price: -1, date: "2026-10-01", body: "" })).status).toBe(400);
    expect((await call("POST", "/account/create", { firebaseToken: alice, restaurant: "날짜", price: 1, date: "2026/10/01", body: "" })).status).toBe(400);
  });
});

describe("알림", () => {
  it("알림 등록과 해제 상태를 돌려준다", async () => {
    await signUp(alice, "alice@weon.app");
    expect((await call("POST", "/alarm", { firebaseToken: alice })).json).toEqual({ exist: false });
    await call("POST", "/alarm/add", { firebaseToken: alice, FCMToken: "device-token" });
    expect((await call("POST", "/alarm", { firebaseToken: alice })).json).toEqual({ exist: true });
    await call("POST", "/alarm/delete", { firebaseToken: alice, FCMToken: "device-token" });
    expect((await call("POST", "/alarm", { firebaseToken: alice })).json).toEqual({ exist: false });
  });
});
