-- topics.parent_topic_id (서브토픽 계층) 회귀 테스트.
-- 컬럼/인덱스 존재와 self-FK 의 ON DELETE SET NULL 동작을 검증한다.
-- 출처 마이그레이션: 20260701120000_add_topics_parent_topic_id.sql

BEGIN;

SELECT plan(5);

SELECT has_column('public', 'topics', 'parent_topic_id',
  'topics.parent_topic_id 컬럼이 존재해야 한다');

SELECT col_is_null('public', 'topics', 'parent_topic_id',
  'topics.parent_topic_id 는 nullable 이어야 한다 (NULL=최상위 토픽)');

SELECT has_index('public', 'topics', 'idx_topics_parent_topic_id',
  'parent_topic_id 스코프 검색용 인덱스가 존재해야 한다');

-- 부모/서브 토픽 시드
INSERT INTO public.topics (category, title, summary)
VALUES ('정치', '_test_parent_topic', '부모 토픽');

INSERT INTO public.topics (category, title, summary, parent_topic_id)
SELECT '정치', '_test_child_topic', '서브 토픽', t.id
FROM public.topics t WHERE t.title = '_test_parent_topic';

SELECT is(
  (SELECT parent_topic_id FROM public.topics WHERE title = '_test_child_topic'),
  (SELECT id FROM public.topics WHERE title = '_test_parent_topic'),
  '서브 토픽의 parent_topic_id 가 부모 id 를 가리켜야 한다'
);

-- 부모 삭제 → 서브 토픽은 최상위로 승격(SET NULL)되어야 하며 삭제되지 않는다.
DELETE FROM public.topics WHERE title = '_test_parent_topic';

SELECT is(
  (SELECT parent_topic_id FROM public.topics WHERE title = '_test_child_topic'),
  NULL::bigint,
  '부모 삭제 시 서브 토픽의 parent_topic_id 는 NULL 로 승격되어야 한다 (ON DELETE SET NULL)'
);

SELECT * FROM finish();

ROLLBACK;
