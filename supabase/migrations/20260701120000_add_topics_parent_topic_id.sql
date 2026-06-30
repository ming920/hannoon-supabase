-- topics 계층(서브토픽) 분류 기능용 컬럼.
-- hannoon-ai의 토픽 분류기(subtopics_enabled 모드)가 의존한다:
--   src/db/topics.py (INSERT_TOPIC_SQL), src/db/topic_causes.py (roots_only / parent_topic_id 스코프),
--   src/topic_classifier/pipeline.py (_assign_hierarchical).
-- 원본: hannoon-ai/migrations/0001_topics_parent_topic_id.sql 를 Supabase 마이그레이션으로 포팅한 것.
--
-- 의미:
--   parent_topic_id IS NULL → 최상위 토픽
--   parent_topic_id = <id>  → 해당 부모 아래 서브토픽(leaf); events.topic_id는 leaf만 참조
-- 기존 토픽은 모두 parent_topic_id NULL(최상위)로 남아 평면 동작과 호환된다.

ALTER TABLE "public"."topics"
  ADD COLUMN IF NOT EXISTS parent_topic_id bigint;

-- 자기참조 FK. 부모 삭제 시 서브토픽은 최상위로 승격(SET NULL)한다.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'topics_parent_topic_id_fkey'
  ) THEN
    ALTER TABLE "public"."topics"
      ADD CONSTRAINT topics_parent_topic_id_fkey
      FOREIGN KEY (parent_topic_id)
      REFERENCES "public"."topics"(id)
      ON DELETE SET NULL;
  END IF;
END $$;

-- 부모 스코프 후보 검색(WHERE parent_topic_id = ? / IS NULL)용 인덱스.
CREATE INDEX IF NOT EXISTS idx_topics_parent_topic_id
  ON "public"."topics"(parent_topic_id);
