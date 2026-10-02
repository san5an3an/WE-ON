import { Hono } from "hono";
import { verifyFirebaseToken } from "./auth";
import { accountRoutes } from "./routes/account";
import { alarmRoutes } from "./routes/alarm";
import { reviewRoutes } from "./routes/review";
import { storeRoutes } from "./routes/store";
import { userRoutes } from "./routes/user";
import { ApiError, type AppContext, type TokenVerifier } from "./types";

// 토큰 검증 방식을 주입받아 앱 생성
export function createApp(verifyToken: TokenVerifier = verifyFirebaseToken) {
  const app = new Hono<AppContext>();

  app.use(async (c, next) => {
    c.set("verifyToken", verifyToken);
    await next();
  });

  app.get("/", (c) => c.json({ service: "we-on-server", status: "ok" }));

  app.route("/", userRoutes);
  app.route("/", storeRoutes);
  app.route("/", reviewRoutes);
  app.route("/", accountRoutes);
  app.route("/", alarmRoutes);

  // 앱이 읽는 { ErrorMessage } 형식으로 에러 응답 변환
  app.onError((error, c) => {
    if (error instanceof ApiError) {
      return c.json({ ErrorMessage: error.message }, error.status);
    }
    if (error instanceof SyntaxError) {
      return c.json({ ErrorMessage: "요청 본문이 올바른 JSON 이 아닙니다." }, 400);
    }
    console.error(error);
    return c.json({ ErrorMessage: "서버에서 오류가 발생했습니다." }, 500);
  });

  app.notFound((c) => c.json({ ErrorMessage: "요청한 주소를 찾을 수 없습니다." }, 404));

  return app;
}
