import { createRemoteJWKSet, jwtVerify } from "jose";
import type { Context } from "hono";
import { ApiError, type AppContext, type Env, type FirebaseIdentity, type UserRow } from "./types";

// Google 이 공개하는 Firebase 서명 키 목록, 자동으로 캐시와 갱신 처리
const firebaseKeys = createRemoteJWKSet(
  new URL("https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com"),
);

// Firebase 공개키로 ID 토큰 서명과 발급 프로젝트 검증
export async function verifyFirebaseToken(token: string, env: Env): Promise<FirebaseIdentity> {
  try {
    const { payload } = await jwtVerify(token, firebaseKeys, {
      issuer: `https://securetoken.google.com/${env.FIREBASE_PROJECT_ID}`,
      audience: env.FIREBASE_PROJECT_ID,
    });
    if (typeof payload.sub !== "string" || payload.sub.length === 0) {
      throw new Error("missing subject");
    }
    return {
      uid: payload.sub,
      email: typeof payload.email === "string" ? payload.email : "",
      emailVerified: payload.email_verified === true,
    };
  } catch {
    throw new ApiError(401, "유효하지 않은 로그인 토큰입니다.");
  }
}

// 요청 Body 에서 Firebase 로그인 토큰 추출
export function readToken(body: Record<string, unknown>): string {
  const token = body.firebaseToken;
  if (typeof token !== "string" || token.length === 0) {
    throw new ApiError(401, "로그인 토큰이 없습니다.");
  }
  return token;
}

// 요청 Body 의 토큰을 검증해 Firebase 계정 정보 조회
export async function identify(c: Context<AppContext>, body: Record<string, unknown>): Promise<FirebaseIdentity> {
  return c.get("verifyToken")(readToken(body), c.env);
}

// 토큰의 Firebase 계정과 연결된 가입 회원 조회
export async function requireUser(c: Context<AppContext>, body: Record<string, unknown>): Promise<UserRow> {
  const identity = await identify(c, body);
  const user = await c.env.DB.prepare("SELECT id, firebase_uid, email, nickname FROM users WHERE firebase_uid = ?")
    .bind(identity.uid)
    .first<UserRow>();
  if (!user) {
    throw new ApiError(404, "가입되지 않은 사용자입니다.");
  }
  return user;
}
