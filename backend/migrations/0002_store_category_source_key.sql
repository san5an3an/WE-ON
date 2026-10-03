-- 가게 종류와 공공데이터 원본 식별값 열 추가

-- 음식점, 편의점, 마트 구분 저장, 기존 가게는 음식점으로 간주
ALTER TABLE stores ADD COLUMN category TEXT NOT NULL DEFAULT 'restaurant' CHECK (category IN ('restaurant', 'convenience', 'mart'));
-- 공공데이터를 다시 받을 때 같은 가게를 찾기 위한 원본 식별값 저장
ALTER TABLE stores ADD COLUMN source_key TEXT;
-- 원본 식별값 중복 방지, 다시 받을 때 추가와 갱신 구분에 사용
CREATE UNIQUE INDEX idx_stores_source_key ON stores (source_key);
