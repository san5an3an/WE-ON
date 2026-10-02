import { Hono } from "hono";
import { requireUser } from "../auth";
import { ApiError, type AppContext } from "../types";
import { requireInt, requireString, type Body } from "../validation";

// 리뷰 API 경로 등록
export const reviewRoutes = new Hono<AppContext>();

// D1 한 행 크기 제한(2MB) 안에 들도록 사진 Base64 길이 제한
const maxImageLength = 1_500_000;
// 리뷰 본문 최소 글자 수 지정
const minBodyLength = 10;

// 리뷰와 작성자, 가게 이름을 합친 조회 결과 한 행 보관
interface ReviewRow {
  id: number;
  user_id: number;
  nickname: string;
  store_id: number;
  store_name: string;
  date: string;
  body: string;
  rating: number;
  image: string | null;
}

// 사진 Base64 값 확인, 없으면 null 반환
function readImage(body: Body): string | null {
  const image = body.reviewImage;
  if (image === null || image === undefined || image === "") return null;
  if (typeof image !== "string") throw new ApiError(400, "reviewImage 값이 올바르지 않습니다.");
  if (image.length > maxImageLength) throw new ApiError(413, "사진 용량이 너무 큽니다.");
  return image;
}

// 리뷰 본문 글자 수 확인
function readReviewBody(body: Body): string {
  const text = requireString(body, "body");
  if (text.trim().length < minBodyLength) {
    throw new ApiError(400, "리뷰는 10글자 이상 입력해 주세요.");
  }
  return text;
}

// 본인 리뷰인지 확인
async function requireOwnReview(db: D1Database, reviewId: number, userId: number) {
  const review = await db.prepare("SELECT user_id FROM reviews WHERE id = ?").bind(reviewId).first<{ user_id: number }>();
  if (!review) throw new ApiError(404, "리뷰를 찾을 수 없습니다.");
  if (review.user_id !== userId) throw new ApiError(403, "본인 리뷰만 수정하거나 삭제할 수 있습니다.");
}

// 가게 리뷰 최신순 조회, page 와 display 가 있으면 나눠서 조회
reviewRoutes.get("/review/:storeId{[0-9]+}", async (c) => {
  const storeId = Number(c.req.param("storeId"));
  const page = Number(c.req.query("page") ?? "0");
  const display = Number(c.req.query("display") ?? "0");
  const paged = Number.isInteger(page) && Number.isInteger(display) && page > 0 && display > 0;
  const result = await c.env.DB.prepare(
    `SELECT reviews.*, users.nickname, stores.name AS store_name
     FROM reviews
     JOIN users ON users.id = reviews.user_id
     JOIN stores ON stores.id = reviews.store_id
     WHERE reviews.store_id = ?
     ORDER BY reviews.id DESC
     LIMIT ? OFFSET ?`,
  )
    .bind(storeId, paged ? display : -1, paged ? (page - 1) * display : 0)
    .all<ReviewRow>();
  return c.json(
    result.results.map((row) => ({
      userId: row.user_id,
      userName: row.nickname,
      reviewId: row.id,
      storeId: row.store_id,
      storeName: row.store_name,
      date: row.date,
      body: row.body,
      rating: row.rating,
      reviewImage: row.image,
    })),
  );
});

// 리뷰 작성
reviewRoutes.post("/review/create", async (c) => {
  const body = await c.req.json<Body>();
  const user = await requireUser(c, body);
  const storeId = requireInt(body, "storeId", { min: 1 });
  const store = await c.env.DB.prepare("SELECT id FROM stores WHERE id = ?").bind(storeId).first();
  if (!store) throw new ApiError(404, "가게를 찾을 수 없습니다.");
  await c.env.DB.prepare("INSERT INTO reviews (user_id, store_id, date, body, rating, image) VALUES (?, ?, ?, ?, ?, ?)")
    .bind(user.id, storeId, requireString(body, "date"), readReviewBody(body), requireInt(body, "rating", { min: 1, max: 5 }), readImage(body))
    .run();
  return c.body(null, 200);
});

// 본인 리뷰 수정
reviewRoutes.post("/review/update", async (c) => {
  const body = await c.req.json<Body>();
  const user = await requireUser(c, body);
  const reviewId = requireInt(body, "reviewId", { min: 1 });
  await requireOwnReview(c.env.DB, reviewId, user.id);
  await c.env.DB.prepare("UPDATE reviews SET date = ?, body = ?, rating = ?, image = ? WHERE id = ?")
    .bind(requireString(body, "date"), readReviewBody(body), requireInt(body, "rating", { min: 1, max: 5 }), readImage(body), reviewId)
    .run();
  return c.body(null, 200);
});

// 본인 리뷰 삭제
reviewRoutes.post("/review/delete", async (c) => {
  const body = await c.req.json<Body>();
  const user = await requireUser(c, body);
  const reviewId = requireInt(body, "reviewId", { min: 1 });
  await requireOwnReview(c.env.DB, reviewId, user.id);
  await c.env.DB.prepare("DELETE FROM reviews WHERE id = ?").bind(reviewId).run();
  return c.body(null, 200);
});
