-- =========================================================
-- tasksテーブルに不足しているカラムを安全に追加
-- =========================================================
BEGIN;

-- 1. 必要なカラムを追加（存在しない場合のみ）
ALTER TABLE public.tasks
  ADD COLUMN IF NOT EXISTS question TEXT;

ALTER TABLE public.tasks
  ADD COLUMN IF NOT EXISTS option1 TEXT;

ALTER TABLE public.tasks
  ADD COLUMN IF NOT EXISTS option2 TEXT;

ALTER TABLE public.tasks
  ADD COLUMN IF NOT EXISTS option3 TEXT;

-- 2. RLS設定（既存の場合は上書き）
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admin can manage tasks" ON public.tasks;

CREATE POLICY "Admin can manage tasks" ON public.tasks
  FOR ALL USING (
    EXISTS (
      SELECT 1 
      FROM public.users 
      WHERE users.id = auth.uid() 
        AND users.is_admin = true
    )
  );

-- 3. スキーマキャッシュの更新を促す
NOTIFY pgrst, 'reload schema';

-- 4. サンプルレコード (存在しない場合のみ) を追加
DO $$
DECLARE
  task_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO task_count FROM public.tasks;
  
  IF task_count = 0 THEN
    INSERT INTO public.tasks (
      title,
      description,
      task_type,
      question, 
      option1, 
      option2, 
      option3, 
      is_active
    ) VALUES (
      'エアドロップタスク1',
      '戦国武将に関するアンケート',
      'SURVEY',
      'あなたの好きな戦国武将は？',
      '豊臣秀吉',
      '徳川家康',
      '織田信長',
      true
    );
  END IF;
END
$$;

COMMIT;

-- 5. スキーマキャッシュを即時反映させる（Supabase で自動処理）
SELECT pg_notify('pgrst', 'reload schema');

-- 確認
SELECT 
  id, title, question, option1, option2, option3, is_active, created_at
FROM public.tasks 
ORDER BY created_at DESC;
