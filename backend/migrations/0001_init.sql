-- 회원, 가게, 리뷰, 가계부, 알림 테이블 생성

-- Firebase 계정과 연결된 회원 저장
CREATE TABLE users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  firebase_uid TEXT NOT NULL UNIQUE,
  email TEXT NOT NULL,
  nickname TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 아동급식카드 가맹점과 선한 영향력 가게 저장, store_type 은 0 선한 영향력, 1 아동급식카드, 2 둘 다로 구분
CREATE TABLE stores (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  store_type INTEGER NOT NULL,
  zip_code INTEGER NOT NULL DEFAULT 0,
  road_address TEXT NOT NULL DEFAULT '',
  lot_address TEXT NOT NULL DEFAULT '',
  lat REAL NOT NULL,
  lng REAL NOT NULL,
  benefit_name TEXT,
  benefit_target TEXT,
  hygiene_grade TEXT NOT NULL DEFAULT '',
  phone TEXT,
  source TEXT NOT NULL
);
-- 주변 가게 조회를 위한 위경도 Index 생성
CREATE INDEX idx_stores_lat_lng ON stores (lat, lng);

-- 가게 리뷰 저장
CREATE TABLE reviews (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  store_id INTEGER NOT NULL REFERENCES stores (id) ON DELETE CASCADE,
  date TEXT NOT NULL,
  body TEXT NOT NULL,
  rating INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),
  image TEXT
);
-- 가게별 최신 리뷰 조회를 위한 Index 생성
CREATE INDEX idx_reviews_store ON reviews (store_id, id DESC);

-- 가계부 지출 내역 저장
CREATE TABLE expenditures (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  restaurant TEXT NOT NULL,
  price INTEGER NOT NULL CHECK (price >= 0),
  date TEXT NOT NULL,
  body TEXT NOT NULL DEFAULT ''
);
-- 회원별 월간 지출 조회를 위한 Index 생성
CREATE INDEX idx_expenditures_user_date ON expenditures (user_id, date);

-- 회원별 월 예산 저장
CREATE TABLE budgets (
  user_id INTEGER NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  year_month TEXT NOT NULL,
  amount INTEGER NOT NULL CHECK (amount >= 0),
  PRIMARY KEY (user_id, year_month)
);

-- 지출 알림을 받을 기기 FCM 토큰 저장
CREATE TABLE alarms (
  user_id INTEGER NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  fcm_token TEXT NOT NULL,
  PRIMARY KEY (user_id, fcm_token)
);
