import { importPKCS8, SignJWT } from "jose";
import type { Env } from "./types";

// FCM 전송에 쓰는 Google 서비스 계정 키 정보 보관
interface ServiceAccount {
  project_id: string;
  client_email: string;
  private_key: string;
}

// 매일 보내는 지출 기록 알림 문구 지정
const reminder = {
  title: "오늘 식비를 기록해 보세요",
  body: "WE:ON 가계부에 오늘 지출 내역을 남기면 한 달 예산을 관리하기 쉬워요.",
};

// 서비스 계정 키로 FCM 전송용 OAuth 액세스 토큰 발급
async function accessToken(account: ServiceAccount): Promise<string> {
  const key = await importPKCS8(account.private_key, "RS256");
  const assertion = await new SignJWT({ scope: "https://www.googleapis.com/auth/firebase.messaging" })
    .setProtectedHeader({ alg: "RS256", typ: "JWT" })
    .setIssuer(account.client_email)
    .setAudience("https://oauth2.googleapis.com/token")
    .setIssuedAt()
    .setExpirationTime("1h")
    .sign(key);
  const response = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({ grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer", assertion }),
  });
  if (!response.ok) throw new Error(`token request failed: ${response.status}`);
  return ((await response.json()) as { access_token: string }).access_token;
}

// 알림을 켠 모든 기기에 지출 기록 알림 전송
export async function sendDailyReminder(env: Env): Promise<{ sent: number; removed: number }> {
  if (!env.FCM_SERVICE_ACCOUNT) return { sent: 0, removed: 0 };
  const account = JSON.parse(env.FCM_SERVICE_ACCOUNT) as ServiceAccount;
  const token = await accessToken(account);
  const { results } = await env.DB.prepare("SELECT user_id, fcm_token FROM alarms").all<{ user_id: number; fcm_token: string }>();
  let sent = 0;
  let removed = 0;
  for (const row of results) {
    const response = await fetch(`https://fcm.googleapis.com/v1/projects/${account.project_id}/messages:send`, {
      method: "POST",
      headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json" },
      body: JSON.stringify({ message: { token: row.fcm_token, notification: reminder } }),
    });
    if (response.ok) {
      sent += 1;
    } else if (response.status === 404 || response.status === 400) {
      // 만료되거나 잘못된 기기 토큰 정리
      await env.DB.prepare("DELETE FROM alarms WHERE user_id = ? AND fcm_token = ?").bind(row.user_id, row.fcm_token).run();
      removed += 1;
    }
  }
  return { sent, removed };
}
