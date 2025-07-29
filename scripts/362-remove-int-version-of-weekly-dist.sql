-- ------------------------------------------------------------------
-- 旧 integer 版 create_synchronized_weekly_distribution を削除
-- ------------------------------------------------------------------
DROP FUNCTION IF EXISTS public.create_synchronized_weekly_distribution(
  p_week_start_date date,
  p_group_id        integer,
  p_weekly_rate     numeric
);
