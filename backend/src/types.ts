// Worker 에 연결된 D1 과 환경 변수 정의
export interface Env {
  DB: D1Database;
  FIREBASE_PROJECT_ID: string;
  FCM_SERVICE_ACCOUNT?: string;
}

// 검증을 마친 Firebase 계정 정보 보관
export interface FirebaseIdentity {
  uid: string;
  email: string;
  emailVerified: boolean;
}

// Firebase 토큰 검증 함수 형식 정의, 테스트에서는 가짜 검증으로 교체
export type TokenVerifier = (token: string, env: Env) => Promise<FirebaseIdentity>;

// users 테이블 한 행 보관
export interface UserRow {
  id: number;
  firebase_uid: string;
  email: string;
  nickname: string;
}

// 요청마다 공유하는 값 정의
export interface AppVariables {
  verifyToken: TokenVerifier;
}

// Hono 앱에 쓰는 Bindings 와 Variables 묶음 정의
export interface AppContext {
  Bindings: Env;
  Variables: AppVariables;
}

// 앱이 읽는 상태 코드와 안내 문구를 담은 에러 정의
export class ApiError extends Error {
  constructor(
    readonly status: 400 | 401 | 403 | 404 | 413,
    message: string,
  ) {
    super(message);
  }
}
