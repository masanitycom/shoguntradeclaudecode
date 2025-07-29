-- 手動設定データの復元（テーブル構造に基づく修正版）

-- 1. テーブル構造に基づいた安全な復元処理
DO $$
DECLARE
    backup_record RECORD;
    restore_count INTEGER := 0;
BEGIN
    -- バックアップから最新の手動設定を復元
    FOR backup_record IN 
        SELECT DISTINCT ON (week_start_date) 
            week_start_date,
            backup_timestamp
        FROM group_weekly_rates_backup
        WHERE backup_reason LIKE '%Manual%' OR backup_reason LIKE '%手動%'
        ORDER BY week_start_date, backup_timestamp DESC
    LOOP
        -- 現在のデータを一時的にバックアップ
        INSERT INTO group_weekly_rates_backup (
            week_start_date,
            daily_rate_group,
            weekly_rate,
            monday_rate,
            tuesday_rate,
            wednesday_rate,
            thursday_rate,
            friday_rate,
            distribution_method,
            backup_timestamp,
            backup_reason
        )
        SELECT 
            week_start_date,
            daily_rate_group,
            weekly_rate,
            monday_rate,
            tuesday_rate,
            wednesday_rate,
            thursday_rate,
            friday_rate,
            distribution_method,
            NOW()::TEXT,
            'Before manual restore - ' || NOW()::TEXT
        FROM group_weekly_rates
        WHERE week_start_date = backup_record.week_start_date;

        -- 現在のデータを削除
        DELETE FROM group_weekly_rates 
        WHERE week_start_date = backup_record.week_start_date;

        -- バックアップから復元
        INSERT INTO group_weekly_rates (
            week_start_date,
            daily_rate_group,
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
            week_start_date,
            daily_rate_group,
            weekly_rate,
            monday_rate,
            tuesday_rate,
            wednesday_rate,
            thursday_rate,
            friday_rate,
            distribution_method,
            NOW(),
            NOW()
        FROM group_weekly_rates_backup
        WHERE week_start_date = backup_record.week_start_date
        AND backup_timestamp = backup_record.backup_timestamp;

        restore_count := restore_count + 1;
        
        RAISE NOTICE 'Restored manual settings for week: %', backup_record.week_start_date;
    END LOOP;

    RAISE NOTICE 'Manual settings restoration completed. Restored % weeks.', restore_count;
END;
$$;

SELECT 'Manual settings restoration completed' as status;
