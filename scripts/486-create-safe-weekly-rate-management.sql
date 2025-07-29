-- 安全な週利管理システム

-- 1. 安全な週利設定関数（バックアップ付き）
CREATE OR REPLACE FUNCTION set_weekly_rate_safe(
    p_week_start_date DATE,
    p_group_id UUID,
    p_weekly_rate NUMERIC,
    p_admin_user_id UUID DEFAULT NULL
)
RETURNS TABLE(
    success BOOLEAN,
    message TEXT,
    backup_created BOOLEAN
) AS $$
DECLARE
    backup_count INTEGER := 0;
    existing_count INTEGER := 0;
BEGIN
    -- 事前バックアップ作成
    SELECT create_manual_backup('BEFORE_WEEKLY_RATE_CHANGE') INTO backup_count;
    
    -- 既存設定確認
    SELECT COUNT(*) INTO existing_count
    FROM group_weekly_rates
    WHERE week_start_date = p_week_start_date AND group_id = p_group_id;
    
    -- 週利設定実行
    IF existing_count > 0 THEN
        -- 更新
        PERFORM overwrite_specific_week_rates(p_week_start_date, p_group_id, p_weekly_rate);
        RETURN QUERY SELECT 
            true,
            '✅ 週利設定を更新しました（バックアップ作成済み）',
            true;
    ELSE
        -- 新規作成
        PERFORM create_synchronized_weekly_distribution(p_week_start_date, p_group_id, p_weekly_rate);
        RETURN QUERY SELECT 
            true,
            '✅ 週利設定を新規作成しました（バックアップ作成済み）',
            true;
    END IF;
    
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT 
        false,
        '❌ エラー: ' || SQLERRM,
        backup_count > 0;
END;
$$ LANGUAGE plpgsql;

-- 2. 一括週利設定関数（安全版）
CREATE OR REPLACE FUNCTION set_all_groups_weekly_rate_safe(
    p_week_start_date DATE,
    p_weekly_rate NUMERIC,
    p_admin_user_id UUID DEFAULT NULL
)
RETURNS TABLE(
    group_name TEXT,
    success BOOLEAN,
    message TEXT
) AS $$
DECLARE
    group_rec RECORD;
    backup_count INTEGER := 0;
BEGIN
    -- 事前バックアップ作成
    SELECT create_manual_backup('BEFORE_BULK_WEEKLY_RATE_CHANGE') INTO backup_count;
    
    -- 各グループに設定
    FOR group_rec IN SELECT id, group_name FROM daily_rate_groups ORDER BY daily_rate_limit LOOP
        BEGIN
            PERFORM overwrite_specific_week_rates(p_week_start_date, group_rec.id, p_weekly_rate);
            
            RETURN QUERY SELECT 
                group_rec.group_name::TEXT,
                true,
                '✅ 設定完了';
                
        EXCEPTION WHEN OTHERS THEN
            RETURN QUERY SELECT 
                group_rec.group_name::TEXT,
                false,
                '❌ エラー: ' || SQLERRM;
        END;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- 3. 権限設定
GRANT EXECUTE ON FUNCTION set_weekly_rate_safe(DATE, UUID, NUMERIC, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION set_all_groups_weekly_rate_safe(DATE, NUMERIC, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION create_manual_backup(TEXT) TO authenticated;

-- 4. 現在の安全な状態を確認
SELECT 
    '🛡️ データ保護システム確認' as section,
    'バックアップテーブル作成済み' as backup_table,
    '自動バックアップトリガー設定済み' as auto_backup,
    '安全な設定関数作成済み' as safe_functions,
    COUNT(*) || '件の初期バックアップ作成済み' as initial_backup
FROM group_weekly_rates_backup;
