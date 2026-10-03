import type { D1Migration } from "@cloudflare/vitest-pool-workers";

// 테스트 환경 변수 타입 정의
declare global {
  namespace Cloudflare {
    interface Env {
      DB: D1Database;
      FIREBASE_PROJECT_ID: string;
      TEST_MIGRATIONS: D1Migration[];
    }
  }
}
