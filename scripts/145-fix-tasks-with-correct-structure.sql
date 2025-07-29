-- =========================================================
-- 正しい構造でtasksテーブルを修正
-- =========================================================
BEGIN;

-- 1. 既存のtasksテーブルに必要なカラムを追加（存在しない場合のみ）
ALTER TABLE public.tasks
  ADD COLUMN IF NOT EXISTS question TEXT;

ALTER TABLE public.tasks
  ADD COLUMN IF NOT EXISTS option1 TEXT;

ALTER TABLE public.tasks
  ADD COLUMN IF NOT EXISTS option2 TEXT;

ALTER TABLE public.tasks
  ADD COLUMN IF NOT EXISTS option3 TEXT;

-- 2. titleカラムが必須の場合、サンプルデータにtitleを含める
-- まず既存データがあるかチェック
DO $$
DECLARE
  task_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO task_count FROM public.tasks;
  
  -- データが0件の場合のみサンプルデータを挿入
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
    ) VALUES 
    (
      'エアドロップタスク1',
      '戦国武将に関する質問です',
      'SURVEY',
      'あなたの好きな戦国武将は？',
      '豊臣秀吉',
      '徳川家康', 
      '織田信長',
      true
    ),
    (
      'エアドロップタスク2',
      'SHOGUN TRADEに関する質問です',
      'SURVEY',
      'SHOGUN TRADEの魅力は？',
      '高い日利',
      'MLMシステム',
      '安全性',
      true
    ),
    (
      'エアドロップタスク3',
      '投資に関する質問です',
      'SURVEY',
      '投資で重要なことは？',
      'リスク管理',
      '分散投資',
      '長期視点',
      true
    );
  END IF;
END
$$;

-- 3. RLS設定
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

-- 4. スキーマキャッシュを即時反映させる（Supabase で自動処理）
NOTIFY pgrst, 'reload schema';

COMMIT;

-- 確認クエリ
SELECT 
  id,
  title,
  question,
  option1,
  option2,
  option3,
  is_active,
  created_at
FROM public.tasks
ORDER BY created_at DESC;
