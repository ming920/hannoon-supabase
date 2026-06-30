-- AI 스키마 패리티 가드.
-- hannoon-ai(수집/분류 파이프라인)가 의존하는 Postgres 전용 컬럼이 운영 스키마에 존재하는지
-- DB 측에서 못박는다. hannoon-ai/src/collector/storage.py 의 _validate_postgres_schema /
-- CLASSIFIER_REQUIRED_COLUMNS 와 짝을 이루는 계약으로, 누군가 컬럼을 지우면 CI(supabase test db)가 잡는다.
--
-- ⚠ 동기화 규칙: hannoon-ai 의 CLASSIFIER_REQUIRED_COLUMNS / EXPECTED_VECTOR_DIMENSIONS 를 바꾸면
--   아래 plan() 수와 has_column 목록을 반드시 함께 갱신한다.
--   현재 가드 범위 = AI/Postgres 전용 컬럼 + pgvector 차원(4096). events.id/topic_id/title 등
--   베이스 구조 컬럼은 각 테이블의 생성 마이그레이션·테스트가 담당하므로 여기서는 단언하지 않는다.

BEGIN;

SELECT plan(17);

-- articles: 임베딩/핵심내용 (event_classifier 가 기록)
SELECT has_column('public', 'articles', 'embedding',     'AI 계약: articles.embedding 존재');
SELECT has_column('public', 'articles', 'core_content',  'AI 계약: articles.core_content 존재');

-- events: 분류기 핵심 컬럼
SELECT has_column('public', 'events', 'embedding',       'AI 계약: events.embedding 존재');
SELECT has_column('public', 'events', 'embedding_text',  'AI 계약: events.embedding_text 존재');
SELECT has_column('public', 'events', 'core_content',    'AI 계약: events.core_content 존재');
SELECT has_column('public', 'events', 'reason',          'AI 계약: events.reason 존재');
SELECT has_column('public', 'events', 'prev_event_id',   'AI 계약: events.prev_event_id 존재');
SELECT has_column('public', 'events', 'next_event_id',   'AI 계약: events.next_event_id 존재');
SELECT has_column('public', 'events', 'article_count',   'AI 계약: events.article_count 존재');
SELECT has_column('public', 'events', 'event_image_url', 'AI 계약: events.event_image_url 존재');

-- event_articles / topics / topic_causes
SELECT has_column('public', 'event_articles', 'reason',         'AI 계약: event_articles.reason 존재');
SELECT has_column('public', 'topics', 'parent_topic_id',        'AI 계약: topics.parent_topic_id 존재');
SELECT has_column('public', 'topic_causes', 'cause_text',       'AI 계약: topic_causes.cause_text 존재');
SELECT has_column('public', 'topic_causes', 'cause_embedding',  'AI 계약: topic_causes.cause_embedding 존재');

-- pgvector 차원(4096). pgvector 는 atttypmod 에 차원을 그대로 저장한다.
SELECT is(
  (SELECT a.atttypmod
   FROM pg_attribute a
   JOIN pg_class c ON c.oid = a.attrelid
   JOIN pg_namespace n ON n.oid = c.relnamespace
   WHERE n.nspname = 'public' AND c.relname = 'articles' AND a.attname = 'embedding'),
  4096,
  'AI 계약: articles.embedding 차원은 4096'
);

SELECT is(
  (SELECT a.atttypmod
   FROM pg_attribute a
   JOIN pg_class c ON c.oid = a.attrelid
   JOIN pg_namespace n ON n.oid = c.relnamespace
   WHERE n.nspname = 'public' AND c.relname = 'events' AND a.attname = 'embedding'),
  4096,
  'AI 계약: events.embedding 차원은 4096'
);

SELECT is(
  (SELECT a.atttypmod
   FROM pg_attribute a
   JOIN pg_class c ON c.oid = a.attrelid
   JOIN pg_namespace n ON n.oid = c.relnamespace
   WHERE n.nspname = 'public' AND c.relname = 'topic_causes' AND a.attname = 'cause_embedding'),
  4096,
  'AI 계약: topic_causes.cause_embedding 차원은 4096'
);

SELECT * FROM finish();

ROLLBACK;
