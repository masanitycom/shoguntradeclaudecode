-- グループ別週利設定テーブルとシステムの作成
-- NFTの価格帯別に週利を管理するシステム

DO $$
DECLARE
    table_exists BOOLEAN;
    constraint_exists BOOLEAN;
    function_exists BOOLEAN;
BEGIN
    RAISE NOTICE '🔧 グループ別週利設定システムを構築中...';

    -- 1. daily_rate_groups テーブルの作成
    SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'daily_rate_groups'
    ) INTO table_exists;

    IF NOT table_exists THEN
        RAISE NOTICE '📋 daily_rate_groups テーブルを作成中...';
        CREATE TABLE daily_rate_groups (
            id SERIAL PRIMARY KEY,
            group_name VARCHAR(50) UNIQUE NOT NULL,
            price_threshold DECIMAL(10,2) NOT NULL,
            daily_rate_limit DECIMAL(5,2) NOT NULL,
            description TEXT,
            is_active BOOLEAN DEFAULT true,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
        
        -- RLS (Row Level Security) を有効化
        ALTER TABLE daily_rate_groups ENABLE ROW LEVEL SECURITY;
        
        -- 管理者のみアクセス可能なポリシー
        CREATE POLICY "Admin only access" ON daily_rate_groups
            FOR ALL USING (
                EXISTS (
                    SELECT 1 FROM users 
                    WHERE users.id = auth.uid() 
                    AND users.role = 'admin'
                )
            );

        RAISE NOTICE '✅ daily_rate_groups テーブルを作成しました';
    ELSE
        RAISE NOTICE '✅ daily_rate_groups テーブルは既に存在します';
    END IF;

    -- 2. group_weekly_rates テーブルの作成
    SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'group_weekly_rates'
    ) INTO table_exists;

    IF table_exists THEN
        RAISE NOTICE '⚠️ group_weekly_rates テーブルが既に存在します。削除して再作成します...';
        DROP TABLE group_weekly_rates CASCADE;
    END IF;
    
    -- group_weekly_rates テーブル作成
    CREATE TABLE group_weekly_rates (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        week_start DATE NOT NULL,
        nft_group INTEGER NOT NULL, -- 300, 500, 1000, 1200, 3000, 5000, 10000, 30000, 100000
        weekly_rate DECIMAL(5,2) NOT NULL, -- 週利率 (例: 2.6 = 2.6%)
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        
        -- 制約
        CONSTRAINT group_weekly_rates_week_group_unique UNIQUE (week_start, nft_group),
        CONSTRAINT group_weekly_rates_weekly_rate_check CHECK (weekly_rate >= 0 AND weekly_rate <= 10),
        CONSTRAINT group_weekly_rates_nft_group_check CHECK (nft_group IN (300, 500, 1000, 1200, 3000, 5000, 10000, 30000, 100000))
    );
    
    RAISE NOTICE '✅ group_weekly_rates テーブルを作成しました';
    
    -- インデックス作成
    CREATE INDEX idx_group_weekly_rates_week_start ON group_weekly_rates(week_start);
    CREATE INDEX idx_group_weekly_rates_nft_group ON group_weekly_rates(nft_group);
    CREATE INDEX idx_group_weekly_rates_week_group ON group_weekly_rates(week_start, nft_group);
    
    RAISE NOTICE '✅ インデックスを作成しました';
    
    -- RLS (Row Level Security) 設定
    ALTER TABLE group_weekly_rates ENABLE ROW LEVEL SECURITY;
    
    -- 管理者のみ全アクセス可能
    CREATE POLICY group_weekly_rates_admin_policy ON group_weekly_rates
        FOR ALL
        TO authenticated
        USING (
            EXISTS (
                SELECT 1 FROM users 
                WHERE users.id = auth.uid() 
                AND users.is_admin = true
            )
        );
    
    -- 一般ユーザーは読み取りのみ
    CREATE POLICY group_weekly_rates_read_policy ON group_weekly_rates
        FOR SELECT
        TO authenticated
        USING (true);
    
    RAISE NOTICE '✅ RLSポリシーを設定しました';
    
    -- 3. 基本的なNFTグループデータを挿入
    RAISE NOTICE '📊 基本NFTグループデータを設定中...';
    
    INSERT INTO daily_rate_groups (group_name, price_threshold, daily_rate_limit, description) VALUES
        ('300', 300, 0.5, '$300 NFTグループ'),
        ('500', 500, 0.5, '$500 NFTグループ'),
        ('1000', 1000, 1.0, '$1000 NFTグループ'),
        ('1200', 1200, 1.0, '$1200 NFTグループ'),
        ('3000', 3000, 1.0, '$3000 NFTグループ'),
        ('5000', 5000, 1.0, '$5000 NFTグループ'),
        ('10000', 10000, 1.25, '$10000 NFTグループ'),
        ('30000', 30000, 1.5, '$30000 NFTグループ'),
        ('100000', 100000, 2.0, '$100000 NFTグループ')
    ON CONFLICT (group_name) DO UPDATE SET
        price_threshold = EXCLUDED.price_threshold,
        daily_rate_limit = EXCLUDED.daily_rate_limit,
        description = EXCLUDED.description;

    RAISE NOTICE '✅ NFTグループデータを設定しました';

    -- 4. NFTグループ判定関数の作成
    DROP FUNCTION IF EXISTS get_nft_group(DECIMAL);
    
    CREATE OR REPLACE FUNCTION get_nft_group(nft_price DECIMAL)
    RETURNS INTEGER
    LANGUAGE plpgsql
    IMMUTABLE
    AS $$
    BEGIN
        -- 価格に基づいてNFTグループを決定
        CASE 
            WHEN nft_price <= 300 THEN RETURN 300;
            WHEN nft_price <= 600 THEN RETURN 500;
            WHEN nft_price = 1000 THEN RETURN 1000;
            WHEN nft_price BETWEEN 1100 AND 2100 THEN RETURN 1200;
            WHEN nft_price BETWEEN 3000 AND 8000 THEN RETURN 3000;
            WHEN nft_price = 10000 THEN RETURN 10000;
            WHEN nft_price = 30000 THEN RETURN 30000;
            WHEN nft_price = 50000 THEN RETURN 30000; -- 50000は30000グループに含める
            WHEN nft_price >= 100000 THEN RETURN 100000;
            ELSE RETURN 1000; -- デフォルト
        END CASE;
    END $$;

    RAISE NOTICE '✅ NFTグループ判定関数を作成しました';

    -- 5. 週利取得関数の作成
    DROP FUNCTION IF EXISTS get_weekly_rate(DECIMAL, DATE);
    
    CREATE OR REPLACE FUNCTION get_weekly_rate(nft_price DECIMAL, target_week_start DATE)
    RETURNS DECIMAL
    LANGUAGE plpgsql
    STABLE
    AS $$
    DECLARE
        nft_group INTEGER;
        weekly_rate DECIMAL;
    BEGIN
        -- NFTグループを取得
        nft_group := get_nft_group(nft_price);
        
        -- 指定週の週利を取得
        SELECT gwr.weekly_rate INTO weekly_rate
        FROM group_weekly_rates gwr
        WHERE gwr.nft_group = get_nft_group.nft_group
        AND gwr.week_start = target_week_start;
        
        -- 週利が見つからない場合はデフォルト値を返す
        IF weekly_rate IS NULL THEN
            CASE nft_group
                WHEN 300 THEN weekly_rate := 0.5;
                WHEN 500 THEN weekly_rate := 0.5;
                WHEN 1000 THEN weekly_rate := 1.0;
                WHEN 1200 THEN weekly_rate := 1.0;
                WHEN 3000 THEN weekly_rate := 1.0;
                WHEN 10000 THEN weekly_rate := 1.25;
                WHEN 30000 THEN weekly_rate := 1.5;
                WHEN 100000 THEN weekly_rate := 2.0;
                ELSE weekly_rate := 1.0;
            END CASE;
        END IF;
        
        RETURN weekly_rate;
    END $$;

    RAISE NOTICE '✅ 週利取得関数を作成しました';

    -- 6. サンプル週利データの挿入
    RAISE NOTICE '📊 サンプル週利データを挿入中...';
    
    -- 既存のサンプルデータを削除
    DELETE FROM group_weekly_rates WHERE week_start >= '2024-01-01' AND week_start <= '2024-02-12';
    
    -- サンプルデータを挿入
    INSERT INTO group_weekly_rates (week_start, nft_group, weekly_rate) VALUES
        ('2024-01-01'::DATE, 300, 0.5),
        ('2024-01-01'::DATE, 500, 0.5),
        ('2024-01-01'::DATE, 1000, 1.0),
        ('2024-01-01'::DATE, 1200, 1.0),
        ('2024-01-01'::DATE, 3000, 1.0),
        ('2024-01-01'::DATE, 10000, 1.25),
        ('2024-01-01'::DATE, 30000, 1.5),
        ('2024-01-01'::DATE, 100000, 2.0),
        ('2024-01-08'::DATE, 300, 0.6),
        ('2024-01-08'::DATE, 500, 0.6),
        ('2024-01-08'::DATE, 1000, 1.1),
        ('2024-01-08'::DATE, 1200, 1.1),
        ('2024-01-08'::DATE, 3000, 1.1),
        ('2024-01-08'::DATE, 10000, 1.35),
        ('2024-01-08'::DATE, 30000, 1.6),
        ('2024-01-08'::DATE, 100000, 2.1),
        ('2024-01-15'::DATE, 300, 0.4),
        ('2024-01-15'::DATE, 500, 0.4),
        ('2024-01-15'::DATE, 1000, 0.9),
        ('2024-01-15'::DATE, 1200, 0.9),
        ('2024-01-15'::DATE, 3000, 0.9),
        ('2024-01-15'::DATE, 10000, 1.15),
        ('2024-01-15'::DATE, 30000, 1.4),
        ('2024-01-15'::DATE, 100000, 1.9),
        ('2024-01-22'::DATE, 300, 0.7),
        ('2024-01-22'::DATE, 500, 0.7),
        ('2024-01-22'::DATE, 1000, 1.2),
        ('2024-01-22'::DATE, 1200, 1.2),
        ('2024-01-22'::DATE, 3000, 1.2),
        ('2024-01-22'::DATE, 10000, 1.45),
        ('2024-01-22'::DATE, 30000, 1.7),
        ('2024-01-22'::DATE, 100000, 2.2),
        ('2024-01-29'::DATE, 300, 0.3),
        ('2024-01-29'::DATE, 500, 0.3),
        ('2024-01-29'::DATE, 1000, 0.8),
        ('2024-01-29'::DATE, 1200, 0.8),
        ('2024-01-29'::DATE, 3000, 0.8),
        ('2024-01-29'::DATE, 10000, 1.05),
        ('2024-01-29'::DATE, 30000, 1.3),
        ('2024-01-29'::DATE, 100000, 1.8),
        ('2024-02-05'::DATE, 300, 0.55),
        ('2024-02-05'::DATE, 500, 0.55),
        ('2024-02-05'::DATE, 1000, 1.05),
        ('2024-02-05'::DATE, 1200, 1.05),
        ('2024-02-05'::DATE, 3000, 1.05),
        ('2024-02-05'::DATE, 10000, 1.3),
        ('2024-02-05'::DATE, 30000, 1.55),
        ('2024-02-05'::DATE, 100000, 2.05),
        ('2024-02-12'::DATE, 300, 0.45),
        ('2024-02-12'::DATE, 500, 0.45),
        ('2024-02-12'::DATE, 1000, 0.95),
        ('2024-02-12'::DATE, 1200, 0.95),
        ('2024-02-12'::DATE, 3000, 0.95),
        ('2024-02-12'::DATE, 10000, 1.2),
        ('2024-02-12'::DATE, 30000, 1.45),
        ('2024-02-12'::DATE, 100000, 1.95)
    ON CONFLICT (week_start, nft_group) 
    DO UPDATE SET 
        weekly_rate = EXCLUDED.weekly_rate,
        updated_at = NOW();
    
    RAISE NOTICE '✅ サンプル週利データの挿入が完了しました';

    -- 7. システム状態の確認
    RAISE NOTICE '📋 システム状態確認:';
    
    -- グループ数の確認
    SELECT COUNT(*) INTO constraint_exists FROM daily_rate_groups;
    RAISE NOTICE '- NFTグループ数: %', constraint_exists;
    
    -- 週利データ数の確認
    SELECT COUNT(*) INTO constraint_exists FROM group_weekly_rates;
    RAISE NOTICE '- 週利データ数: %', constraint_exists;

    RAISE NOTICE '✅ グループ別週利設定システムの構築が完了しました';

EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION '❌ グループ別週利設定システム構築中にエラーが発生しました: %', SQLERRM;
END $$;

-- 作成されたテーブルとデータの確認
SELECT 'daily_rate_groups' as table_name, COUNT(*) as record_count FROM daily_rate_groups
UNION ALL
SELECT 'group_weekly_rates' as table_name, COUNT(*) as record_count FROM group_weekly_rates;

-- NFTグループ一覧の表示
SELECT 
    group_name,
    price_threshold,
    daily_rate_limit,
    description
FROM daily_rate_groups 
ORDER BY price_threshold;

-- グループ別週利データを確認
SELECT 
    week_start,
    nft_group,
    weekly_rate
FROM group_weekly_rates
ORDER BY week_start, nft_group;
