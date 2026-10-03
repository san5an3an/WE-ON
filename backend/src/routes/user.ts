import { Hono } from "hono";
import { identify, requireUser } from "../auth";
import { ApiError, type AppContext, type UserRow } from "../types";
import { requireNickname, requireString, type Body } from "../validation";

// 회원 API 경로 등록
export const userRoutes = new Hono<AppContext>();

// 앱이 쓰는 로그인 응답 형식으로 변환
function toLoginResponse(user: UserRow) {
  return { userId: user.id, email: user.email, userName: user.nickname };
}

// 이메일 앞부분을 기본 닉네임으로 지정
function defaultNickname(email: string): string {
  const local = email.split("@")[0]?.trim();
  return local && local.length > 0 ? local.slice(0, 20) : "이웃";
}

// Firebase 계정으로 서버 회원 생성
userRoutes.post("/login/signUp", async (c) => {
  const body = await c.req.json<Body>();
  const identity = await identify(c, body);
  const email = requireString(body, "email");
  if (identity.email && identity.email.toLowerCase() !== email.toLowerCase()) {
    throw new ApiError(400, "로그인한 계정과 이메일이 다릅니다.");
  }
  const existing = await c.env.DB.prepare("SELECT id FROM users WHERE firebase_uid = ?").bind(identity.uid).first();
  if (existing) {
    throw new ApiError(400, "이미 가입된 사용자입니다.");
  }
  // 닉네임을 보내지 않으면 이메일 앞부분으로 지정
  const nickname = body.nickname === undefined || body.nickname === null || body.nickname === "" ? defaultNickname(email) : requireNickname(body, "nickname");
  await c.env.DB.prepare("INSERT INTO users (firebase_uid, email, nickname) VALUES (?, ?, ?)")
    .bind(identity.uid, email, nickname)
    .run();
  return c.body(null, 200);
});

// 이메일 인증을 마친 회원의 정보 조회
userRoutes.post("/login", async (c) => {
  const body = await c.req.json<Body>();
  const identity = await identify(c, body);
  if (!identity.emailVerified) {
    throw new ApiError(403, "이메일 인증 후 로그인 해주세요.");
  }
  const user = await c.env.DB.prepare("SELECT id, firebase_uid, email, nickname FROM users WHERE firebase_uid = ?")
    .bind(identity.uid)
    .first<UserRow>();
  if (!user) {
    throw new ApiError(404, "가입되지 않은 사용자입니다.");
  }
  return c.json(toLoginResponse(user));
});

// 닉네임 변경 후 바뀐 로그인 정보 반환
userRoutes.post("/myPage/nickname", async (c) => {
  const body = await c.req.json<Body>();
  const user = await requireUser(c, body);
  const nickname = requireNickname(body, "nickname");
  await c.env.DB.prepare("UPDATE users SET nickname = ? WHERE id = ?").bind(nickname, user.id).run();
  return c.json(toLoginResponse({ ...user, nickname }));
});

// 회원과 회원이 남긴 데이터 전체 삭제
userRoutes.post("/myPage/delete", async (c) => {
  const body = await c.req.json<Body>();
  const user = await requireUser(c, body);
  const db = c.env.DB;
  // 참조 데이터를 먼저 지운 뒤 회원 삭제
  await db.batch([
    db.prepare("DELETE FROM reviews WHERE user_id = ?").bind(user.id),
    db.prepare("DELETE FROM expenditures WHERE user_id = ?").bind(user.id),
    db.prepare("DELETE FROM budgets WHERE user_id = ?").bind(user.id),
    db.prepare("DELETE FROM alarms WHERE user_id = ?").bind(user.id),
    db.prepare("DELETE FROM users WHERE id = ?").bind(user.id),
  ]);
  return c.body(null, 200);
});
