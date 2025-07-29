-- 🛡️ 週利設定保護システム
-- 週利設定が消えないようにする強力な保護機能

-- 1. 週利設定保護テーブルを作成
CREATE TABLE IF NOT EXISTS weekly_rates_protection (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    protection_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    total_settings INTEGER NOT NULL,
    unique_weeks INTEGER NOT NULL,
    earliest_week DATE,
    latest_week DATE,
    protection_hash TEXT NOT NULL,
    created_by UUID,
    notes TEXT
);

-- 2. 現在の週利設定を保護
INSERT INTO weekly_rates_protection (
    total_settings,
    unique_weeks,
    earliest_week,
    latest_week,
    protection_hash,
    notes
)
SELECT 
    COUNT(*),
    COUNT(DISTINCT week_start_date),
    MIN(week_start_date),
    MAX(week_start_date),
    MD5(string_agg(
        gwr.id::text || gwr.week_start_date::text || gwr.weekly_rate::text, 
        '|' ORDER BY gwr.week_start_date, gwr.group_id
    )),
    '復旧後の初期保護'
FROM group_weekly_rates gwr;

-- 3. 週利設定削除防止トリガー
CREATE OR REPLACE FUNCTION prevent_weekly_rates_deletion()
RETURNS TRIGGER AS $$
BEGIN
    -- 管理者以外の削除を防止
    IF current_setting('app.user_role') != 'admin' THEN
        RAISE EXCEPTION '週利設定の削除は管理者のみ可能です';
    END IF;
    
    -- 削除前に自動バックアップを作成
    INSERT INTO weekly_rates_backup (
        backup_reason,
        original_data,
        record_count,
        weeks_covered
    ) VALUES (
        'AUTO_BACKUP_BEFORE_DELETE',
        jsonb_build_object(
            'id', OLD.id,
            'group_id', OLD.group_id,
            'week_start_date', OLD.week_start_date,
            'weekly_rate', OLD.weekly_rate,
            'monday_rate', OLD.monday_rate,
            'tuesday_rate', OLD.tuesday_rate,
            'wednesday_rate', OLD.wednesday_rate,
            'thursday_rate', OLD.thursday_rate,
            'friday_rate', OLD.friday_rate
        ),
        1,
        1
    );
    
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- 4. トリガーを設定
DROP TRIGGER IF EXISTS weekly_rates_protection_trigger ON group_weekly_rates;
CREATE TRIGGER weekly_rates_protection_trigger
    BEFORE DELETE ON group_weekly_rates
    FOR EACH ROW EXECUTE FUNCTION prevent_weekly_rates_deletion();

-- 5. 週利設定整合性チェック関数
CREATE OR REPLACE FUNCTION check_weekly_rates_integrity()
RETURNS TABLE(
    check_type TEXT,
    status TEXT,
    count INTEGER,
    details TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- 基本統計
    RETURN QUERY
    SELECT 
        '📊 基本統計'::TEXT,
        '✅ 正常'::TEXT,
        COUNT(*)::INTEGER,
        format('総設定数: %s, 週数: %s', COUNT(*), COUNT(DISTINCT week_start_date))
    FROM group_weekly_rates;
    
    -- グループ別設定確認
    RETURN QUERY
    SELECT 
        '🎯 グループ別設定'::TEXT,
        CASE WHEN COUNT(*) = 5 THEN '✅ 正常' ELSE '⚠️ 不足' END::TEXT,
        COUNT(*)::INTEGER,
        string_agg(drg.group_name, ', ')
    FROM daily_rate_groups drg
    LEFT JOIN group_weekly_rates gwr ON drg.id = gwr.group_id 
        AND gwr.week_start_date = DATE_TRUNC('week', CURRENT_DATE) + INTERVAL '1 day'
    WHERE gwr.id IS NOT NULL
    GROUP BY (COUNT(*) = 5);
    
    -- 今週の設定確認
    RETURN QUERY
    SELECT 
        '📅 今週の設定'::TEXT,
        CASE WHEN COUNT(*) >= 5 THEN '✅ 正常' ELSE '❌ 不足' END::TEXT,
        COUNT(*)::INTEGER,
        format('今週(%s)の設定数', DATE_TRUNC('week', CURRENT_DATE) + INTERVAL '1 day')
    FROM group_weekly_rates
    WHERE week_start_date = DATE_TRUNC('week', CURRENT_DATE) + INTERVAL '1 day';
    
    -- 日利計算との連動確認
    RETURN QUERY
    SELECT 
        '🔗 日利計算連動'::TEXT,
        CASE WHEN COUNT(*) > 0 THEN '✅ 連動中' ELSE '❌ 未連動' END::TEXT,
        COUNT(*)::INTEGER,
        format('今日の日利計算: %s件', COUNT(*))
    FROM daily_rewards
    WHERE reward_date = CURRENT_DATE;
END;
$$;

-- 6. 安全な週利設定関数（削除防止付き）
CREATE OR REPLACE FUNCTION set_weekly_rates_safe(
    p_week_start_date DATE,
    p_weekly_rate NUMERIC,
    p_admin_user_id UUID DEFAULT NULL
)
RETURNS TABLE(
    group_name TEXT,
    status TEXT,
    weekly_rate NUMERIC,
    backup_created BOOLEAN
)
LANGUAGE plpgsql
AS $$
DECLARE
    group_record RECORD;
    backup_count INTEGER;
    rates RECORD;
BEGIN
    -- 事前バックアップ作成
    SELECT create_manual_backup('BEFORE_SAFE_WEEKLY_RATE_SET') INTO backup_count;
    
    -- 既存設定を確認（削除ではなく更新）
    IF EXISTS (SELECT 1 FROM group_weekly_rates WHERE week_start_date = p_week_start_date) THEN
        -- 更新処理
        FOR group_record IN 
            SELECT id, group_name FROM daily_rate_groups ORDER BY daily_rate_limit
        LOOP
            -- ランダム配分を生成
            SELECT * INTO rates FROM generate_synchronized_weekly_distribution(p_weekly_rate);
            
            UPDATE group_weekly_rates SET
                weekly_rate = p_weekly_rate,
                monday_rate = rates.monday_rate,
                tuesday_rate = rates.tuesday_rate,
                wednesday_rate = rates.wednesday_rate,
                thursday_rate = rates.thursday_rate,
                friday_rate = rates.friday_rate,
                distribution_method = 'SAFE_UPDATE',
                updated_at = NOW()
            WHERE group_id = group_record.id 
            AND week_start_date = p_week_start_date;
            
            RETURN QUERY SELECT 
                group_record.group_name,
                '✅ 更新完了'::TEXT,
                p_weekly_rate,
                true;
        END LOOP;
    ELSE
        -- 新規作成処理
        FOR group_record IN 
            SELECT id, group_name FROM daily_rate_groups ORDER BY daily_rate_limit
        LOOP
            -- ランダム配分を生成
            SELECT * INTO rates FROM generate_synchronized_weekly_distribution(p_weekly_rate);
            
            INSERT INTO group_weekly_rates (
                group_id,
                week_start_date,
                week_end_date,
                week_number,
                weekly_rate,
                monday_rate,
                tuesday_rate,
                wednesday_rate,
                thursday_rate,
                friday_rate,
                distribution_method
            ) VALUES (
                group_record.id,
                p_week_start_date,
                p_week_start_date + INTERVAL '6 days',
                EXTRACT(WEEK FROM p_week_start_date),
                p_weekly_rate,
                rates.monday_rate,
                rates.tuesday_rate,
                rates.wednesday_rate,
                rates.thursday_rate,
                rates.friday_rate,
                'SAFE_CREATE'
            );
            
            RETURN QUERY SELECT 
                group_record.group_name,
                '✅ 新規作成'::TEXT,
                p_weekly_rate,
                true;
        END LOOP;
    END IF;
END;
$$;

-- 7. 権限設定
GRANT EXECUTE ON FUNCTION check_weekly_rates_integrity() TO authenticated;
GRANT EXECUTE ON FUNCTION set_weekly_rates_safe(DATE, NUMERIC, UUID) TO authenticated;

-- 8. 保護システム確認
SELECT 
    '🛡️ 保護システム確認' as info,
    COUNT(*) as protection_records,
    MAX(protection_date) as latest_protection
FROM weekly_rates_protection;

-- 9. 整合性チェック実行
SELECT * FROM check_weekly_rates_integrity();
