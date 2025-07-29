-- tasksテーブルに不足しているカラムを追加

-- 既存のカラムをチェックして、不足しているものを追加
DO $$
BEGIN
    -- option1カラムが存在しない場合は追加
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'tasks' 
        AND column_name = 'option1'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE tasks ADD COLUMN option1 TEXT NOT NULL DEFAULT '';
        RAISE NOTICE 'option1カラムを追加しました';
    END IF;

    -- option2カラムが存在しない場合は追加
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'tasks' 
        AND column_name = 'option2'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE tasks ADD COLUMN option2 TEXT NOT NULL DEFAULT '';
        RAISE NOTICE 'option2カラムを追加しました';
    END IF;

    -- option3カラムが存在しない場合は追加
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'tasks' 
        AND column_name = 'option3'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE tasks ADD COLUMN option3 TEXT NOT NULL DEFAULT '';
        RAISE NOTICE 'option3カラムを追加しました';
    END IF;

    -- questionカラムが存在しない場合は追加
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'tasks' 
        AND column_name = 'question'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE tasks ADD COLUMN question TEXT NOT NULL DEFAULT '';
        RAISE NOTICE 'questionカラムを追加しました';
    END IF;

    -- is_activeカラムが存在しない場合は追加
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'tasks' 
        AND column_name = 'is_active'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE tasks ADD COLUMN is_active BOOLEAN NOT NULL DEFAULT true;
        RAISE NOTICE 'is_activeカラムを追加しました';
    END IF;

    -- created_atカラムが存在しない場合は追加
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'tasks' 
        AND column_name = 'created_at'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE tasks ADD COLUMN created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
        RAISE NOTICE 'created_atカラムを追加しました';
    END IF;

    -- updated_atカラムが存在しない場合は追加
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'tasks' 
        AND column_name = 'updated_at'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE tasks ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
        RAISE NOTICE 'updated_atカラムを追加しました';
    END IF;

END $$;

-- デフォルト値を削除（NOT NULL制約は残す）
ALTER TABLE tasks ALTER COLUMN option1 DROP DEFAULT;
ALTER TABLE tasks ALTER COLUMN option2 DROP DEFAULT;
ALTER TABLE tasks ALTER COLUMN option3 DROP DEFAULT;
ALTER TABLE tasks ALTER COLUMN question DROP DEFAULT;

-- サンプルデータを挿入（テーブルが空の場合）
INSERT INTO tasks (question, option1, option2, option3, is_active)
SELECT 
    'あなたの好きな戦国武将は？',
    '豊臣秀吉',
    '徳川家康',
    '織田信長',
    true
WHERE NOT EXISTS (SELECT 1 FROM tasks);

INSERT INTO tasks (question, option1, option2, option3, is_active)
SELECT 
    'SHOGUN TRADEの魅力は？',
    '高い日利',
    '安全性',
    'コミュニティ',
    true
WHERE (SELECT COUNT(*) FROM tasks) = 1;

INSERT INTO tasks (question, option1, option2, option3, is_active)
SELECT 
    '投資で最も重要なことは？',
    'リスク管理',
    '情報収集',
    '長期視点',
    true
WHERE (SELECT COUNT(*) FROM tasks) = 2;

-- 更新完了メッセージ
SELECT '=== Tasks テーブル更新完了 ===' as section;

-- 最終的な構造確認
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'tasks' 
AND table_schema = 'public'
ORDER BY ordinal_position;
