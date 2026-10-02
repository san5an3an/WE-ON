import { Hono } from "hono";
import { requireUser } from "../auth";
import { ApiError, type AppContext } from "../types";
import { currentYearMonth, requireDay, requireInt, requireString, requireYearMonth, type Body } from "../validation";

// 가계부 API 경로 등록
export const accountRoutes = new Hono<AppContext>();

// expenditures 테이블 한 행 보관
interface ExpenditureRow {
  id: number;
  user_id: number;
  restaurant: string;
  price: number;
  date: string;
  body: string;
}

// 지출 추가와 수정 요청 값 확인
function readExpenditure(body: Body) {
  return {
    restaurant: requireString(body, "restaurant").trim(),
    price: requireInt(body, "price", { min: 0, max: 100_000_000 }),
    date: requireDay(body, "date"),
    memo: requireString(body, "body", { allowEmpty: true }),
  };
}

// 본인 지출인지 확인
async function requireOwnExpenditure(db: D1Database, accountId: number, userId: number) {
  const row = await db.prepare("SELECT user_id FROM expenditures WHERE id = ?").bind(accountId).first<{ user_id: number }>();
  if (!row) throw new ApiError(404, "지출 내역을 찾을 수 없습니다.");
  if (row.user_id !== userId) throw new ApiError(403, "본인 지출 내역만 수정하거나 삭제할 수 있습니다.");
}

// 월별 사용액과 잔액 계산
accountRoutes.post("/account", async (c) => {
  const body = await c.req.json<Body>();
  const user = await requireUser(c, body);
  const yearMonth = requireYearMonth(body, "yearMonth");
  const used = await c.env.DB.prepare("SELECT SUM(price) AS total FROM expenditures WHERE user_id = ? AND date LIKE ?")
    .bind(user.id, `${yearMonth}-%`)
    .first<{ total: number | null }>();
  const budget = await c.env.DB.prepare("SELECT amount FROM budgets WHERE user_id = ? AND year_month = ?")
    .bind(user.id, yearMonth)
    .first<{ amount: number }>();
  const charge = Number(used?.total ?? 0);
  const amount = Number(budget?.amount ?? 0);
  // 예산이 없으면 잔액을 음수로 두어 앱에서 예산 미설정으로 표시
  return c.json({ charge, balance: amount - charge });
});

// 월별 지출 내역 조회, 최근 날짜부터 정렬
accountRoutes.post("/account/list", async (c) => {
  const body = await c.req.json<Body>();
  const user = await requireUser(c, body);
  const yearMonth = requireYearMonth(body, "yearMonth");
  const result = await c.env.DB.prepare("SELECT * FROM expenditures WHERE user_id = ? AND date LIKE ? ORDER BY date DESC, id DESC")
    .bind(user.id, `${yearMonth}-%`)
    .all<ExpenditureRow>();
  return c.json(
    result.results.map((row) => ({
      userId: row.user_id,
      accountId: row.id,
      restaurant: row.restaurant,
      price: row.price,
      date: row.date,
      body: row.body,
    })),
  );
});

// 지출 추가
accountRoutes.post("/account/create", async (c) => {
  const body = await c.req.json<Body>();
  const user = await requireUser(c, body);
  const item = readExpenditure(body);
  await c.env.DB.prepare("INSERT INTO expenditures (user_id, restaurant, price, date, body) VALUES (?, ?, ?, ?, ?)")
    .bind(user.id, item.restaurant, item.price, item.date, item.memo)
    .run();
  return c.body(null, 200);
});

// 본인 지출 수정
accountRoutes.post("/account/update", async (c) => {
  const body = await c.req.json<Body>();
  const user = await requireUser(c, body);
  const accountId = requireInt(body, "accountId", { min: 1 });
  await requireOwnExpenditure(c.env.DB, accountId, user.id);
  const item = readExpenditure(body);
  await c.env.DB.prepare("UPDATE expenditures SET restaurant = ?, price = ?, date = ?, body = ? WHERE id = ?")
    .bind(item.restaurant, item.price, item.date, item.memo, accountId)
    .run();
  return c.body(null, 200);
});

// 본인 지출 삭제
accountRoutes.post("/account/delete", async (c) => {
  const body = await c.req.json<Body>();
  const user = await requireUser(c, body);
  const accountId = requireInt(body, "accountId", { min: 1 });
  await requireOwnExpenditure(c.env.DB, accountId, user.id);
  await c.env.DB.prepare("DELETE FROM expenditures WHERE id = ?").bind(accountId).run();
  return c.body(null, 200);
});

// 이번 달 예산 저장, 이미 있으면 덮어쓰기 처리
accountRoutes.post("/account/setting", async (c) => {
  const body = await c.req.json<Body>();
  const user = await requireUser(c, body);
  const amount = requireInt(body, "amount", { min: 0, max: 100_000_000 });
  await c.env.DB.prepare(
    "INSERT INTO budgets (user_id, year_month, amount) VALUES (?, ?, ?) ON CONFLICT (user_id, year_month) DO UPDATE SET amount = excluded.amount",
  )
    .bind(user.id, currentYearMonth(), amount)
    .run();
  return c.body(null, 200);
});
