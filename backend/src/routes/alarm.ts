import { Hono } from "hono";
import { requireUser } from "../auth";
import type { AppContext } from "../types";
import { requireString, type Body } from "../validation";

// 지출 알림 API 경로 등록
export const alarmRoutes = new Hono<AppContext>();

// 지출 알림 등록 여부 조회
alarmRoutes.post("/alarm", async (c) => {
  const body = await c.req.json<Body>();
  const user = await requireUser(c, body);
  const row = await c.env.DB.prepare("SELECT 1 FROM alarms WHERE user_id = ? LIMIT 1").bind(user.id).first();
  return c.json({ exist: row !== null });
});

// 기기 FCM 토큰으로 지출 알림 등록
alarmRoutes.post("/alarm/add", async (c) => {
  const body = await c.req.json<Body>();
  const user = await requireUser(c, body);
  const token = requireString(body, "FCMToken");
  await c.env.DB.prepare("INSERT OR IGNORE INTO alarms (user_id, fcm_token) VALUES (?, ?)").bind(user.id, token).run();
  return c.body(null, 200);
});

// 지출 알림 해제
alarmRoutes.post("/alarm/delete", async (c) => {
  const body = await c.req.json<Body>();
  const user = await requireUser(c, body);
  // 기기 토큰이 바뀌었을 수 있어 사용자 알림 전체 해제
  await c.env.DB.prepare("DELETE FROM alarms WHERE user_id = ?").bind(user.id).run();
  return c.body(null, 200);
});
