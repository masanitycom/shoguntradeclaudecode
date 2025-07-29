-- 🚨 緊急システム修復 - 全関数クリーンアップ

-- 既存の問題関数を全て削除
DROP FUNCTION IF EXISTS get_user_reward_summary(uuid);
DROP FUNCTION IF EXISTS force_daily_calculation();
DROP FUNCTION IF EXISTS get_system_status();
DROP FUNCTION IF EXISTS get_weekly_rates_with_groups();
DROP FUNCTION IF EXISTS set_group_weekly_rate(DATE, TEXT, NUMERIC);
DROP FUNCTION IF EXISTS admin_create_backup(DATE);
DROP FUNCTION IF EXISTS admin_delete_weekly_rates(DATE);
DROP FUNCTION IF EXISTS admin_restore_from_backup(DATE, TIMESTAMP);
DROP FUNCTION IF EXISTS get_backup_list();

-- 緊急診断関数
CREATE OR REPLACE FUNCTION emergency_system_diagnosis()
RETURNS TABLE(
    check_name TEXT,
    status TEXT,
    count_value BIGINT,
    details TEXT
) AS $$
BEGIN
    -- ユーザー数チェック
    RETURN QUERY
    SELECT 
        'total_users'::TEXT,
        'INFO'::TEXT,
        COUNT(*)::BIGINT,
        'アクティブユーザー数'::TEXT
    FROM users 
    WHERE created_at IS NOT NULL;
    
    -- NFT数チェック
    RETURN QUERY
    SELECT 
        'total_nfts'::TEXT,
        'INFO'::TEXT,
        COUNT(*)::BIGINT,
        '総NFT数'::TEXT
    FROM nfts;
    
    -- ユーザーNFT数チェック
    RETURN QUERY
    SELECT 
        'user_nfts'::TEXT,
        'INFO'::TEXT,
        COUNT(*)::BIGINT,
        'ユーザー保有NFT数'::TEXT
    FROM user_nfts;
    
    -- 週利設定チェック
    RETURN QUERY
    SELECT 
        'weekly_rates'::TEXT,
        'INFO'::TEXT,
        COUNT(*)::BIGINT,
        '設定済み週利数'::TEXT
    FROM group_weekly_rates;
    
    -- 日利報酬チェック
    RETURN QUERY
    SELECT 
        'daily_rewards'::TEXT,
        'INFO'::TEXT,
        COUNT(*)::BIGINT,
        '日利報酬レコード数'::TEXT
    FROM daily_rewards;
    
    -- テーブル存在チェック
    RETURN QUERY
    SELECT 
        'table_check'::TEXT,
        'INFO'::TEXT,
        COUNT(*)::BIGINT,
        '主要テーブル数'::TEXT
    FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name IN ('users', 'nfts', 'user_nfts', 'group_weekly_rates', 'daily_rewards');
    
END;
$$ LANGUAGE plpgsql;

-- 緊急データ確認
CREATE OR REPLACE FUNCTION check_february_10_data()
RETURNS TABLE(
    data_type TEXT,
    found BOOLEAN,
    count_value BIGINT,
    sample_data TEXT
) AS $$
BEGIN
    -- 2025-02-10の週利設定確認
    RETURN QUERY
    SELECT 
        'february_10_rates'::TEXT,
        EXISTS(SELECT 1 FROM group_weekly_rates WHERE week_start_date = '2025-02-10'),
        COUNT(*)::BIGINT,
        COALESCE(string_agg(group_id::TEXT, ', '), 'なし')::TEXT
    FROM group_weekly_rates 
    WHERE week_start_date = '2025-02-10';
    
    -- グループテーブル確認
    RETURN QUERY
    SELECT 
        'daily_rate_groups'::TEXT,
        EXISTS(SELECT 1 FROM daily_rate_groups),
        COUNT(*)::BIGINT,
        COALESCE(string_agg(group_name, ', '), 'なし')::TEXT
    FROM daily_rate_groups;
    
    -- 最新の週利設定確認
    RETURN QUERY
    SELECT 
        'latest_weekly_rates'::TEXT,
        EXISTS(SELECT 1 FROM group_weekly_rates),
        COUNT(*)::BIGINT,
        COALESCE(MAX(week_start_date)::TEXT, 'なし')::TEXT
    FROM group_weekly_rates;
    
END;
$$ LANGUAGE plpgsql;
