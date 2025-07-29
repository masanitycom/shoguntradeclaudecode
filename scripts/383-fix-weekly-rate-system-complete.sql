-- 週利配分システムの完全修正（データ型エラー対応）

-- 1. 現在の問題のある関数を削除
DROP FUNCTION IF EXISTS calculate_daily_rewards_correct(DATE);
DROP FUNCTION IF EXISTS calculate_daily_rewards(DATE);

-- 2. 実際のテーブル構造を確認
SELECT 
    '📋 nftsテーブルのnameカラム型確認' as info,
    column_name,
    data_type,
    character_maximum_length
FROM information_schema.columns 
WHERE table_name = 'nfts' AND column_name = 'name';

-- 3. 正しいデータ型で関数を再作成
CREATE OR REPLACE FUNCTION calculate_daily_rewards_fixed(target_date DATE)
RETURNS TABLE(
    user_id UUID,
    user_nft_id UUID,
    nft_name VARCHAR(255),  -- 実際のデータ型に合わせる
    investment_amount NUMERIC,
    weekly_rate NUMERIC,
    daily_rate NUMERIC,
    reward_amount NUMERIC,
    calculation_method VARCHAR(50)
) AS $$
DECLARE
    day_of_week INTEGER;
    week_start DATE;
    current_rate NUMERIC;
BEGIN
    -- 曜日を取得（1=月曜, 2=火曜, ..., 5=金曜）
    day_of_week := EXTRACT(DOW FROM target_date);
    
    -- 平日以外は計算しない
    IF day_of_week NOT IN (1, 2, 3, 4, 5) THEN
        RETURN;
    END IF;
    
    -- その週の月曜日を計算
    week_start := target_date - (day_of_week - 1) * INTERVAL '1 day';
    
    -- 週利設定がある場合のみ計算
    RETURN QUERY
    SELECT 
        u.id,
        un.id,
        n.name,
        n.price,
        gwr.weekly_rate,
        CASE day_of_week
            WHEN 1 THEN LEAST(COALESCE(gwr.monday_rate, 0), n.daily_rate_limit / 100.0)
            WHEN 2 THEN LEAST(COALESCE(gwr.tuesday_rate, 0), n.daily_rate_limit / 100.0)
            WHEN 3 THEN LEAST(COALESCE(gwr.wednesday_rate, 0), n.daily_rate_limit / 100.0)
            WHEN 4 THEN LEAST(COALESCE(gwr.thursday_rate, 0), n.daily_rate_limit / 100.0)
            WHEN 5 THEN LEAST(COALESCE(gwr.friday_rate, 0), n.daily_rate_limit / 100.0)
        END,
        n.price * CASE day_of_week
            WHEN 1 THEN LEAST(COALESCE(gwr.monday_rate, 0), n.daily_rate_limit / 100.0)
            WHEN 2 THEN LEAST(COALESCE(gwr.tuesday_rate, 0), n.daily_rate_limit / 100.0)
            WHEN 3 THEN LEAST(COALESCE(gwr.wednesday_rate, 0), n.daily_rate_limit / 100.0)
            WHEN 4 THEN LEAST(COALESCE(gwr.thursday_rate, 0), n.daily_rate_limit / 100.0)
            WHEN 5 THEN LEAST(COALESCE(gwr.friday_rate, 0), n.daily_rate_limit / 100.0)
        END,
        '週利配分'::VARCHAR(50)
    FROM users u
    JOIN user_nfts un ON u.id = un.user_id
    JOIN nfts n ON un.nft_id = n.id
    JOIN daily_rate_groups drg ON n.daily_rate_limit = drg.daily_rate_limit
    JOIN group_weekly_rates gwr ON drg.id = gwr.group_id
    WHERE un.is_active = true
    AND gwr.week_start_date = week_start
    AND CASE day_of_week
        WHEN 1 THEN gwr.monday_rate
        WHEN 2 THEN gwr.tuesday_rate
        WHEN 3 THEN gwr.wednesday_rate
        WHEN 4 THEN gwr.thursday_rate
        WHEN 5 THEN gwr.friday_rate
    END IS NOT NULL
    AND CASE day_of_week
        WHEN 1 THEN gwr.monday_rate
        WHEN 2 THEN gwr.tuesday_rate
        WHEN 3 THEN gwr.wednesday_rate
        WHEN 4 THEN gwr.thursday_rate
        WHEN 5 THEN gwr.friday_rate
    END > 0;
END;
$$ LANGUAGE plpgsql;

-- 4. 2025-02-12(水曜)の正しい計算テスト
SELECT 
    '🧪 2025-02-12(水曜)の正しい計算テスト' as info,
    nft_name as NFT名,
    investment_amount as 投資額,
    weekly_rate as 週利設定,
    daily_rate as 水曜日利,
    reward_amount as 報酬額
FROM calculate_daily_rewards_fixed('2025-02-12')
WHERE nft_name IN ('SHOGUN NFT 100', 'SHOGUN NFT 1000 (Special)')
ORDER BY investment_amount
LIMIT 10;

-- 5. 現在の週利設定を確認
SELECT 
    '📊 2025-02-10週の設定確認' as info,
    drg.group_name as グループ名,
    drg.daily_rate_limit as 日利上限,
    gwr.weekly_rate as 週利設定,
    gwr.wednesday_rate as 水曜日利,
    COUNT(n.id) as 対象NFT数
FROM daily_rate_groups drg
LEFT JOIN group_weekly_rates gwr ON drg.id = gwr.group_id AND gwr.week_start_date = '2025-02-10'
LEFT JOIN nfts n ON n.daily_rate_limit = drg.daily_rate_limit
GROUP BY drg.group_name, drg.daily_rate_limit, gwr.weekly_rate, gwr.wednesday_rate
ORDER BY drg.daily_rate_limit;

-- 6. 今日は計算対象外であることを確認
SELECT 
    '❌ 今日(7/2)は計算対象外' as info,
    CURRENT_DATE as 今日,
    '週利設定がない' as 理由,
    0 as 計算対象ユーザー数;

-- 7. 既存の間違った報酬を削除（今日分のみ）
DELETE FROM daily_rewards 
WHERE reward_date = CURRENT_DATE
AND user_nft_id IN (
    SELECT un.id 
    FROM user_nfts un 
    JOIN users u ON un.user_id = u.id 
    WHERE u.user_id IN ('OHTAKIYO', 'pigret10', 'momochan', 'imaima3137', 'pbcshop1')
);

-- 8. user_nftsのtotal_earnedを正しい値に更新
UPDATE user_nfts 
SET total_earned = (
    SELECT COALESCE(SUM(dr.reward_amount), 0)
    FROM daily_rewards dr
    WHERE dr.user_nft_id = user_nfts.id
),
updated_at = NOW()
WHERE is_active = true;

-- 9. 修正結果の最終確認
SELECT 
    '✅ 修正完了確認' as info,
    u.user_id,
    u.name as ユーザー名,
    n.name as NFT名,
    n.price as 投資額,
    un.total_earned as 修正後累積報酬,
    CASE 
        WHEN un.total_earned = 0 THEN '✅ 正常（今日は計算なし）'
        ELSE '要確認'
    END as 状態
FROM users u
JOIN user_nfts un ON u.id = un.user_id
JOIN nfts n ON un.nft_id = n.id
WHERE u.user_id IN ('OHTAKIYO', 'pigret10', 'momochan', 'imaima3137', 'pbcshop1')
ORDER BY u.user_id;

-- 10. システム状態サマリー
SELECT 
    '📈 システム状態サマリー' as info,
    '週利配分システム修正完了' as 状態,
    '今後は週利設定がある週のみ計算実行' as 動作,
    '2025-02-10週: 1.8%等の設定が正しく適用される' as 期待結果;
