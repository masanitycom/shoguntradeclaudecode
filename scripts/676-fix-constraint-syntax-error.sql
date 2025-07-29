-- 制約作成の構文エラー修正

-- 1. 既存の制約を確認
SELECT 
    constraint_name, 
    constraint_type,
    table_name
FROM information_schema.table_constraints 
WHERE table_name = 'daily_rate_groups';

-- 2. 制約が存在しない場合のみ作成（PostgreSQL互換）
DO $$
BEGIN
    -- UNIQUE制約が存在するかチェック
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_name = 'daily_rate_groups' 
        AND constraint_type = 'UNIQUE'
        AND constraint_name LIKE '%daily_rate_limit%'
    ) THEN
        -- 制約を作成
        ALTER TABLE daily_rate_groups 
        ADD CONSTRAINT daily_rate_groups_daily_rate_limit_key 
        UNIQUE (daily_rate_limit);
        
        RAISE NOTICE 'UNIQUE制約を作成しました';
    ELSE
        RAISE NOTICE 'UNIQUE制約は既に存在します';
    END IF;
END $$;

-- 3. 制約作成後の確認
SELECT 
    constraint_name, 
    constraint_type
FROM information_schema.table_constraints 
WHERE table_name = 'daily_rate_groups';
