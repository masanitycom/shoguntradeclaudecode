-- ユーザーダッシュボードのデータを更新

-- 1. user_nftsテーブルのtotal_earnedを更新
DO $$
DECLARE
    update_count integer := 0;
BEGIN
    -- 2025-02-10の日利をtotal_earnedに加算
    UPDATE user_nfts 
    SET 
        total_earned = total_earned + COALESCE(
            (SELECT SUM(reward_amount) 
             FROM daily_rewards 
             WHERE user_nft_id = user_nfts.id 
             AND reward_date = '2025-02-10'), 
            0
        ),
        updated_at = NOW()
    WHERE id IN (
        SELECT DISTINCT user_nft_id 
        FROM daily_rewards 
        WHERE reward_date = '2025-02-10'
    );
    
    GET DIAGNOSTICS update_count = ROW_COUNT;
    RAISE NOTICE 'user_nftsのtotal_earned更新完了: %件', update_count;
END $$;

-- 2. 更新結果の確認
SELECT 
    '=== 更新後のユーザーデータ確認 ===' as section,
    u.name as user_name,
    COUNT(un.id) as nft_count,
    SUM(un.purchase_price) as total_investment,
    SUM(un.total_earned) as total_earned,
    (SUM(un.total_earned) / SUM(un.purchase_price) * 100)::numeric(5,2) as earned_percentage
FROM user_nfts un
JOIN users u ON un.user_id = u.id
WHERE un.is_active = true
AND (un.operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo')::date = '2025-02-10'
GROUP BY u.id, u.name
ORDER BY total_earned DESC
LIMIT 15;

-- 3. 管理画面用統計データ
SELECT 
    '=== 管理画面統計データ ===' as section,
    COUNT(DISTINCT u.id) as total_users,
    COUNT(un.id) as total_nfts,
    SUM(un.purchase_price) as total_investment,
    SUM(un.total_earned) as total_earned,
    (SELECT COUNT(*) FROM daily_rewards WHERE reward_date = '2025-02-10') as todays_rewards,
    (SELECT SUM(reward_amount) FROM daily_rewards WHERE reward_date = '2025-02-10') as todays_total_amount
FROM user_nfts un
JOIN users u ON un.user_id = u.id
WHERE un.is_active = true;

-- 4. 次回計算予定の確認
SELECT 
    '=== 次回計算予定 ===' as section,
    '2025-02-11'::date as next_calculation_date,
    EXTRACT(DOW FROM '2025-02-11'::date) as day_of_week,
    CASE 
        WHEN EXTRACT(DOW FROM '2025-02-11'::date) IN (0, 6) THEN '土日のため計算なし'
        ELSE '平日のため計算実行'
    END as calculation_status;
