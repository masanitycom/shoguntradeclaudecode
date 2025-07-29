-- 週ごとの削除機能を作成

-- 1. 週ごとの削除機能（バックアップ付き）
CREATE OR REPLACE FUNCTION admin_delete_weekly_rates_by_week(
    p_week_start_date DATE,
    p_reason TEXT DEFAULT 'Manual deletion'
) RETURNS TABLE(
    success BOOLEAN,
    message TEXT,
    deleted_count INTEGER,
    backup_count INTEGER
) AS $$
DECLARE
    deleted_count INTEGER := 0;
    backup_count INTEGER := 0;
    week_end_date DATE;
BEGIN
    -- 週末日を計算
    week_end_date := p_week_start_date + INTERVAL '6 days';
    
    -- まずバックアップを作成
    INSERT INTO group_weekly_rates_backup (
        original_id,
        group_id,
        week_start_date,
        week_end_date,
        weekly_rate,
        monday_rate,
        tuesday_rate,
        wednesday_rate,
        thursday_rate,
        friday_rate,
        distribution_method,
        backup_reason,
        backup_timestamp
    )
    SELECT 
        gwr.id,
        gwr.group_id,
        gwr.week_start_date,
        gwr.week_end_date,
        gwr.weekly_rate,
        gwr.monday_rate,
        gwr.tuesday_rate,
        gwr.wednesday_rate,
        gwr.thursday_rate,
        gwr.friday_rate,
        gwr.distribution_method,
        'Weekly deletion: ' || p_reason,
        NOW()
    FROM group_weekly_rates gwr
    WHERE gwr.week_start_date = p_week_start_date;
    
    GET DIAGNOSTICS backup_count = ROW_COUNT;
    
    -- 関連する日利報酬データも削除
    DELETE FROM daily_rewards 
    WHERE reward_date >= p_week_start_date 
    AND reward_date <= week_end_date;
    
    -- 週利設定を削除
    DELETE FROM group_weekly_rates 
    WHERE week_start_date = p_week_start_date;
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    IF deleted_count > 0 THEN
        RETURN QUERY SELECT 
            true,
            format('%s週の設定を%s件削除しました（%s件バックアップ済み）', 
                   p_week_start_date::TEXT, deleted_count, backup_count),
            deleted_count,
            backup_count;
    ELSE
        RETURN QUERY SELECT 
            false,
            format('%s週の設定が見つかりませんでした', p_week_start_date::TEXT),
            0,
            0;
    END IF;
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN QUERY SELECT 
            false,
            format('削除エラー: %s', SQLERRM),
            0,
            0;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. 削除前の確認機能
CREATE OR REPLACE FUNCTION check_weekly_rates_for_deletion(
    p_week_start_date DATE
) RETURNS TABLE(
    can_delete BOOLEAN,
    message TEXT,
    weekly_rates_count INTEGER,
    daily_rewards_count INTEGER,
    affected_users INTEGER
) AS $$
DECLARE
    weekly_count INTEGER := 0;
    daily_count INTEGER := 0;
    user_count INTEGER := 0;
    week_end_date DATE;
BEGIN
    week_end_date := p_week_start_date + INTERVAL '6 days';
    
    -- 削除対象の週利設定数を確認
    SELECT COUNT(*) INTO weekly_count
    FROM group_weekly_rates
    WHERE week_start_date = p_week_start_date;
    
    -- 関連する日利報酬数を確認
    SELECT COUNT(*) INTO daily_count
    FROM daily_rewards
    WHERE reward_date >= p_week_start_date 
    AND reward_date <= week_end_date;
    
    -- 影響を受けるユーザー数を確認
    SELECT COUNT(DISTINCT user_id) INTO user_count
    FROM daily_rewards
    WHERE reward_date >= p_week_start_date 
    AND reward_date <= week_end_date;
    
    RETURN QUERY SELECT 
        weekly_count > 0,
        format('週利設定: %s件, 日利報酬: %s件, 影響ユーザー: %s人', 
               weekly_count, daily_count, user_count),
        weekly_count,
        daily_count,
        user_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. バックアップからの復元機能
CREATE OR REPLACE FUNCTION restore_weekly_rates_from_backup(
    p_week_start_date DATE,
    p_backup_timestamp TIMESTAMP WITH TIME ZONE DEFAULT NULL
) RETURNS TABLE(
    success BOOLEAN,
    message TEXT,
    restored_count INTEGER
) AS $$
DECLARE
    restored_count INTEGER := 0;
    backup_timestamp TIMESTAMP WITH TIME ZONE;
BEGIN
    -- バックアップタイムスタンプが指定されていない場合は最新を使用
    IF p_backup_timestamp IS NULL THEN
        SELECT MAX(gwrb.backup_timestamp) INTO backup_timestamp
        FROM group_weekly_rates_backup gwrb
        WHERE gwrb.week_start_date = p_week_start_date;
    ELSE
        backup_timestamp := p_backup_timestamp;
    END IF;
    
    IF backup_timestamp IS NULL THEN
        RETURN QUERY SELECT 
            false,
            format('%s週のバックアップが見つかりませんでした', p_week_start_date::TEXT),
            0;
        RETURN;
    END IF;
    
    -- 既存の設定を削除
    DELETE FROM group_weekly_rates 
    WHERE week_start_date = p_week_start_date;
    
    -- バックアップから復元
    INSERT INTO group_weekly_rates (
        id,
        group_id,
        week_start_date,
        week_end_date,
        weekly_rate,
        monday_rate,
        tuesday_rate,
        wednesday_rate,
        thursday_rate,
        friday_rate,
        distribution_method,
        created_at,
        updated_at
    )
    SELECT 
        gen_random_uuid(),
        gwrb.group_id,
        gwrb.week_start_date,
        gwrb.week_end_date,
        gwrb.weekly_rate,
        gwrb.monday_rate,
        gwrb.tuesday_rate,
        gwrb.wednesday_rate,
        gwrb.thursday_rate,
        gwrb.friday_rate,
        gwrb.distribution_method,
        NOW(),
        NOW()
    FROM group_weekly_rates_backup gwrb
    WHERE gwrb.week_start_date = p_week_start_date
    AND gwrb.backup_timestamp = backup_timestamp;
    
    GET DIAGNOSTICS restored_count = ROW_COUNT;
    
    IF restored_count > 0 THEN
        RETURN QUERY SELECT 
            true,
            format('%s週の設定を%s件復元しました', p_week_start_date::TEXT, restored_count),
            restored_count;
    ELSE
        RETURN QUERY SELECT 
            false,
            format('%s週の復元に失敗しました', p_week_start_date::TEXT),
            0;
    END IF;
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN QUERY SELECT 
            false,
            format('復元エラー: %s', SQLERRM),
            0;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. 権限設定
GRANT EXECUTE ON FUNCTION admin_delete_weekly_rates_by_week(DATE, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION check_weekly_rates_for_deletion(DATE) TO authenticated;
GRANT EXECUTE ON FUNCTION restore_weekly_rates_from_backup(DATE, TIMESTAMP WITH TIME ZONE) TO authenticated;

-- 完了メッセージ
SELECT 'Created weekly deletion functions' as status;
