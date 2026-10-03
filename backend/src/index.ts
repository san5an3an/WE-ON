import { createApp } from "./app";
import { sendDailyReminder } from "./push";
import type { Env } from "./types";

// 실제 Firebase 토큰 검증을 쓰는 앱 생성
const app = createApp();

// HTTP 요청 처리와 매일 저녁 알림 전송 등록
export default {
  fetch: app.fetch,
  async scheduled(_controller, env, ctx) {
    ctx.waitUntil(sendDailyReminder(env).then((result) => console.log("daily reminder", result)));
  },
} satisfies ExportedHandler<Env>;
