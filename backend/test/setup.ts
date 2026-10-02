import { applyD1Migrations, env } from "cloudflare:test";

// 테스트 시작 전 D1 에 테이블 생성
await applyD1Migrations(env.DB, env.TEST_MIGRATIONS);
