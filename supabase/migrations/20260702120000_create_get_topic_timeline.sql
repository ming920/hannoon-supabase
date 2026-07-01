-- =============================================================
-- get_topic_timeline: 부모 토픽의 서브토픽별 이벤트 스윔레인 조회
-- =============================================================
-- 토픽 상세 화면의 "시간 × 서브토픽" 스윔레인 렌더링을 위해
-- 부모 토픽 id를 받아 직접 자식(leaf) 서브토픽들의 이벤트를
-- 레인별로 묶어 반환한다.
--
-- 반환 구조:
--   { topic, time_range, subtopics: [ { id, title, order, is_self, has_more, events } ] }
--
-- B1 방어: DB가 leaf-only 이벤트를 강제하지 않으므로, 부모 topic_id에
-- 직접 연결된 이벤트가 있으면 마지막 레인(is_self=true, title='(직접)')으로 포함한다.
-- leaf 토픽(자식 없음)이 직접 호출된 경우도 이 경로로 처리된다.
-- =============================================================

CREATE OR REPLACE FUNCTION public.get_topic_timeline(
  p_topic_id   bigint,
  p_lane_limit int DEFAULT 50
)
RETURNS json
LANGUAGE plpgsql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $$
DECLARE
  v_topic_row       record;             -- topics 행 (id, title, category)
  v_is_parent       boolean;            -- 직접 자식 1개 이상 존재 여부
  v_lane_order      int   := 0;         -- subtopics 배열 순서 카운터
  v_lanes           jsonb := '[]'::jsonb; -- 누적 레인 배열
  v_sub             record;             -- 서브토픽 루프 변수
  v_events_json     json;               -- 레인별 이벤트 배열
  v_event_count     int;                -- 레인 전체 이벤트 수 (has_more 판단)
  v_has_more        boolean;
  v_direct_count    int;                -- 부모 직접 이벤트 수 (B1 방어용)
  v_direct_events   json;
  v_direct_has_more boolean;
  v_time_min        timestamp;          -- 전체 이벤트 created_at 최솟값
  v_time_max        timestamp;          -- 전체 이벤트 created_at 최댓값
BEGIN

  -- ── 1. 토픽 존재 확인 ──────────────────────────────────────
  SELECT id, title, category
  INTO v_topic_row
  FROM public.topics
  WHERE id = p_topic_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION '존재하지 않는 토픽입니다';
  END IF;

  -- ── 2. is_parent 판정 (직접 자식 1개 이상이면 true) ────────
  SELECT EXISTS (
    SELECT 1 FROM public.topics WHERE parent_topic_id = p_topic_id
  ) INTO v_is_parent;

  -- ── 3. 직접 자식(leaf) 서브토픽별 레인 구성 ────────────────
  -- 각 자식 leaf 마다 events를 created_at ASC 정렬, 최대 p_lane_limit 개 반환.
  -- 빈 레인(이벤트 0개)도 반드시 포함한다.
  FOR v_sub IN
    SELECT id, title
    FROM public.topics
    WHERE parent_topic_id = p_topic_id
    ORDER BY id
  LOOP
    -- 전체 이벤트 수 확인 (p_lane_limit 초과 시 has_more = true)
    SELECT COUNT(*)
    INTO v_event_count
    FROM public.events
    WHERE topic_id = v_sub.id;

    v_has_more := v_event_count > p_lane_limit;

    -- 이벤트 목록 (created_at ASC, 최대 p_lane_limit 개)
    SELECT array_to_json(array_agg(row_to_json(e)))
    INTO v_events_json
    FROM (
      SELECT
        ev.id,
        ev.title,
        ev.summary,
        ev.category,
        ev.created_at,
        ev.event_image_url,
        ev.prev_event_id,
        ev.next_event_id
      FROM public.events ev
      WHERE ev.topic_id = v_sub.id
      ORDER BY ev.created_at ASC
      LIMIT p_lane_limit
    ) e;

    -- 레인 객체를 배열에 추가 (이벤트가 없으면 events = [])
    v_lanes := v_lanes || jsonb_build_array(
      jsonb_build_object(
        'id',       v_sub.id,
        'title',    v_sub.title,
        'order',    v_lane_order,
        'is_self',  false,
        'has_more', v_has_more,
        'events',   COALESCE(v_events_json::jsonb, '[]'::jsonb)
      )
    );

    v_lane_order := v_lane_order + 1;
  END LOOP;

  -- ── 4. B1 방어: 부모 직접 이벤트 처리 ─────────────────────
  -- events.topic_id = p_topic_id 인 직접 이벤트가 있으면
  -- 마지막 레인으로 추가 (is_self=true, title='(직접)').
  SELECT COUNT(*)
  INTO v_direct_count
  FROM public.events
  WHERE topic_id = p_topic_id;

  IF v_direct_count > 0 THEN
    v_direct_has_more := v_direct_count > p_lane_limit;

    SELECT array_to_json(array_agg(row_to_json(e)))
    INTO v_direct_events
    FROM (
      SELECT
        ev.id,
        ev.title,
        ev.summary,
        ev.category,
        ev.created_at,
        ev.event_image_url,
        ev.prev_event_id,
        ev.next_event_id
      FROM public.events ev
      WHERE ev.topic_id = p_topic_id
      ORDER BY ev.created_at ASC
      LIMIT p_lane_limit
    ) e;

    v_lanes := v_lanes || jsonb_build_array(
      jsonb_build_object(
        'id',       p_topic_id,
        'title',    '(직접)',
        'order',    v_lane_order,
        'is_self',  true,
        'has_more', v_direct_has_more,
        'events',   COALESCE(v_direct_events::jsonb, '[]'::jsonb)
      )
    );
  END IF;

  -- ── 5. time_range 계산 ─────────────────────────────────────
  -- 서브토픽 이벤트 및 부모 직접 이벤트 전체(p_lane_limit 미적용)의
  -- created_at min/max를 구해 타임라인 축 기준을 일관되게 한다.
  -- 이벤트가 하나도 없으면 둘 다 null 반환.
  SELECT
    MIN(ev.created_at),
    MAX(ev.created_at)
  INTO v_time_min, v_time_max
  FROM public.events ev
  WHERE ev.topic_id IN (
    SELECT id FROM public.topics WHERE parent_topic_id = p_topic_id
    UNION ALL
    SELECT p_topic_id
  );

  -- ── 6. 최종 JSON 반환 ──────────────────────────────────────
  RETURN json_build_object(
    'topic', json_build_object(
      'id',        v_topic_row.id,
      'title',     v_topic_row.title,
      'category',  v_topic_row.category,
      'is_parent', v_is_parent
    ),
    'time_range', json_build_object(
      'min', v_time_min,
      'max', v_time_max
    ),
    'subtopics', COALESCE(v_lanes::json, '[]'::json)
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_topic_timeline(bigint, int) TO anon;
GRANT EXECUTE ON FUNCTION public.get_topic_timeline(bigint, int) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_topic_timeline(bigint, int) TO service_role;
