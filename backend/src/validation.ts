import { ApiError } from "./types";

// JSON 요청 Body 형식 정의
export type Body = Record<string, unknown>;

// 문자열 값 확인 후 반환
export function requireString(body: Body, key: string, { allowEmpty = false } = {}): string {
  const value = body[key];
  if (typeof value !== "string" || (!allowEmpty && value.trim().length === 0)) {
    throw new ApiError(400, `${key} 값이 올바르지 않습니다.`);
  }
  return value;
}

// 범위 안의 정수 값 확인 후 반환
export function requireInt(body: Body, key: string, { min = Number.MIN_SAFE_INTEGER, max = Number.MAX_SAFE_INTEGER } = {}): number {
  const value = body[key];
  if (typeof value !== "number" || !Number.isInteger(value) || value < min || value > max) {
    throw new ApiError(400, `${key} 값이 올바르지 않습니다.`);
  }
  return value;
}

// 숫자 값 확인 후 반환
export function requireNumber(body: Body, key: string): number {
  const value = body[key];
  if (typeof value !== "number" || !Number.isFinite(value)) {
    throw new ApiError(400, `${key} 값이 올바르지 않습니다.`);
  }
  return value;
}

// yyyy-MM-dd 형식 날짜 확인 후 반환
export function requireDay(body: Body, key: string): string {
  const value = requireString(body, key);
  if (!/^\d{4}-\d{2}-\d{2}$/.test(value)) {
    throw new ApiError(400, `${key} 는 yyyy-MM-dd 형식이어야 합니다.`);
  }
  return value;
}

// yyyy-MM 형식 연월 확인 후 반환
export function requireYearMonth(body: Body, key: string): string {
  const value = requireString(body, key);
  if (!/^\d{4}-\d{2}$/.test(value)) {
    throw new ApiError(400, `${key} 는 yyyy-MM 형식이어야 합니다.`);
  }
  return value;
}

// 서울 기준 현재 연월을 yyyy-MM 으로 변환
export function currentYearMonth(now = new Date()): string {
  const seoul = new Date(now.getTime() + 9 * 60 * 60 * 1000);
  return seoul.toISOString().slice(0, 7);
}
