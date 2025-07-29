-- =====================================================================
-- OHTAKIYOユーザーの日利計算詳細分析
-- =====================================================================

-- 1. OHTAKIYOユーザーの基本情報を確認
SELECT 
    '👤 OHTAKIYOユーザー基本情報' as status,
    u.id as user_id,
    u.name,
    u.email,
    u.phone,
    u.user_id as display_user_id,
    u.is_active,
    u.created_at
FROM users u
WHERE u.name LIKE '%オオタキヨジ%' 
   OR u.email LIKE '%kiyoji1948%'
   OR u.user_id LIKE '%OHTAKIYO%'
   OR u.phone LIKE '%09012345678%';

-- 2. OHTAKIYOユーザーのNFT保有状況を詳細確認
SELECT 
    '🎯 OHTAKIYO NFT保有詳細' as status,
    un.id as user_nft_id,
    un.user_id,
    un.nft_id,
    n.name as nft_name,
    n.price as nft_price,
    n.daily_rate_limit,
    un.current_investment,
    un.total_earned,
    un.max_earning,
    un.is_active,
    un.operation_start_date,
    un.completion_date,
    ROUND((un.total_earned / un.max_earning * 100)::numeric, 2) as completion_percent
FROM user_nfts un
JOIN nfts n ON un.nft_id = n.id
JOIN users u ON un.user_id = u.id
WHERE u.name LIKE '%オオタキヨジ%' 
   OR u.email LIKE '%kiyoji1948%'
   OR u.user_id LIKE '%OHTAKIYO%'
ORDER BY un.created_at;

-- 3. OHTAKIYOユーザーの日利履歴を確認
SELECT 
    '📈 OHTAKIYO 日利履歴' as status,
    dr.reward_date,
    dr.investment_amount,
    ROUND(dr.daily_rate * 100, 4) as daily_rate_percent,
    dr.reward_amount,
    dr.week_start_date,
    dr.calculation_details,
    dr.is_claimed,
    dr.created_at
FROM daily_rewards dr
JOIN user_nfts un ON dr.user_nft_id = un.id
JOIN users u ON un.user_id = u.id
WHERE u.name LIKE '%オオタキヨジ%' 
   OR u.email LIKE '%kiyoji1948%'
   OR u.user_id LIKE '%OHTAKIYO%'
ORDER BY dr.reward_date DESC
LIMIT 20;

-- 4. SHOGUN NFT 100の詳細情報を確認
SELECT 
    '🏆 SHOGUN NFT 100 詳細' as status,
    n.id as nft_id,
    n.name,
    n.price,
    n.daily_rate_limit,
    n.is_active,
    n.image_url,
    n.description,
    drg.group_name,
    drg.description as group_description
FROM nfts n
JOIN daily_rate_groups drg ON n.daily_rate_limit = drg.daily_rate_limit
WHERE n.name LIKE '%SHOGUN NFT 100%'
   OR n.name LIKE '%100%';

-- 5. 今週のSHOGUN NFT 100グループの週利設定を確認
SELECT 
    '📅 今週の週利設定（1.0%グループ）' as status,
    gwr.week_start_date,
    gwr.week_end_date,
    gwr.weekly_rate,
    gwr.monday_rate,
    gwr.tuesday_rate,
    gwr.wednesday_rate,
    gwr.thursday_rate,
    gwr.friday_rate,
    gwr.distribution_method,
    drg.group_name
FROM group_weekly_rates gwr
JOIN daily_rate_groups drg ON gwr.group_id = drg.id
WHERE drg.daily_rate_limit = 0.01  -- 1.0%グループ
  AND gwr.week_start_date = DATE_TRUNC('week', CURRENT_DATE)::date;

-- 6. 今日の計算で期待される報酬額を手動計算
WITH calculation_details AS (
    SELECT 
        u.name as user_name,
        un.current_investment,
        n.daily_rate_limit,
        EXTRACT(DOW FROM CURRENT_DATE) as today_dow,
        CASE EXTRACT(DOW FROM CURRENT_DATE)
            WHEN 1 THEN gwr.monday_rate
            WHEN 2 THEN gwr.tuesday_rate
            WHEN 3 THEN gwr.wednesday_rate
            WHEN 4 THEN gwr.thursday_rate
            WHEN 5 THEN gwr.friday_rate
            ELSE 0
        END as todays_rate,
        CASE EXTRACT(DOW FROM CURRENT_DATE)
            WHEN 0 THEN '日曜日'
            WHEN 1 THEN '月曜日'
            WHEN 2 THEN '火曜日'
            WHEN 3 THEN '水曜日'
            WHEN 4 THEN '木曜日'
            WHEN 5 THEN '金曜日'
            WHEN 6 THEN '土曜日'
        END as day_name
    FROM user_nfts un
    JOIN users u ON un.user_id = u.id
    JOIN nfts n ON un.nft_id = n.id
    JOIN daily_rate_groups drg ON n.daily_rate_limit = drg.daily_rate_limit
    LEFT JOIN group_weekly_rates gwr ON gwr.group_id = drg.id 
        AND gwr.week_start_date = DATE_TRUNC('week', CURRENT_DATE)::date
    WHERE (u.name LIKE '%オオタキヨジ%' 
       OR u.email LIKE '%kiyoji1948%'
       OR u.user_id LIKE '%OHTAKIYO%')
    AND un.is_active = true
)
SELECT 
    '🧮 今日の期待計算' as status,
    cd.user_name,
    cd.current_investment as investment_amount,
    cd.daily_rate_limit as nft_daily_limit,
    cd.day_name,
    ROUND(cd.todays_rate * 100, 4) as todays_rate_percent,
    ROUND(cd.daily_rate_limit * 100, 4) as nft_limit_percent,
    ROUND(LEAST(cd.todays_rate, cd.daily_rate_limit) * 100, 4) as effective_rate_percent,
    cd.current_investment * LEAST(cd.todays_rate, cd.daily_rate_limit) as expected_reward,
    CASE 
        WHEN cd.todays_rate > cd.daily_rate_limit THEN 'NFT上限で制限'
        WHEN cd.todays_rate = 0 THEN '今日は0%設定'
        ELSE '週利設定通り'
    END as rate_status
FROM calculation_details cd;

-- 7. OHTAKIYOユーザーの300%進捗状況を確認
SELECT 
    '📊 300%キャップ進捗' as status,
    un.current_investment,
    un.total_earned,
    un.max_earning,
    ROUND((un.total_earned / un.max_earning * 100)::numeric, 2) as completion_percent,
    un.max_earning - un.total_earned as remaining_earning_capacity,
    CASE 
        WHEN un.total_earned >= un.max_earning THEN 'キャップ到達'
        WHEN un.total_earned >= un.max_earning * 0.9 THEN '90%以上'
        WHEN un.total_earned >= un.max_earning * 0.5 THEN '50%以上'
        ELSE '50%未満'
    END as progress_status
FROM user_nfts un
JOIN users u ON un.user_id = u.id
WHERE (u.name LIKE '%オオタキヨジ%' 
   OR u.email LIKE '%kiyoji1948%'
   OR u.user_id LIKE '%OHTAKIYO%')
AND un.is_active = true;

-- 8. 実際の今日の計算結果を確認
SELECT 
    '💰 今日の実際の計算結果' as status,
    dr.reward_date,
    dr.investment_amount,
    ROUND(dr.daily_rate * 100, 4) as applied_rate_percent,
    dr.reward_amount,
    dr.calculation_details,
    CASE 
        WHEN dr.reward_amount > 0 THEN '報酬支給'
        ELSE '報酬なし'
    END as reward_status
FROM daily_rewards dr
JOIN user_nfts un ON dr.user_nft_id = un.id
JOIN users u ON un.user_id = u.id
WHERE (u.name LIKE '%オオタキヨジ%' 
   OR u.email LIKE '%kiyoji1948%'
   OR u.user_id LIKE '%OHTAKIYO%')
AND dr.reward_date = CURRENT_DATE;

-- 9. 計算ロジックの説明
SELECT 
    '📝 計算ロジック説明' as status,
    '1. 投資額 × 今日の日利 = 基本報酬額' as step1,
    '2. 基本報酬額がNFT日利上限を超える場合は上限適用' as step2,
    '3. 累積収益 + 今日の報酬 が 300%上限を超える場合は残り分のみ支給' as step3,
    '4. 300%到達時にNFTは自動的に非アクティブ化' as step4,
    '5. 土日は計算対象外（平日のみ）' as step5;

-- 10. OHTAKIYOユーザーの総合サマリー
SELECT 
    '📋 OHTAKIYO 総合サマリー' as status,
    COUNT(un.id) as total_nfts,
    COUNT(CASE WHEN un.is_active THEN 1 END) as active_nfts,
    SUM(un.current_investment) as total_investment,
    SUM(un.total_earned) as total_earned,
    SUM(un.max_earning) as total_earning_capacity,
    ROUND(AVG(CASE WHEN un.max_earning > 0 THEN (un.total_earned / un.max_earning * 100) ELSE 0 END), 2) as avg_completion_percent,
    COUNT(CASE WHEN un.total_earned >= un.max_earning THEN 1 END) as completed_nfts
FROM user_nfts un
JOIN users u ON un.user_id = u.id
WHERE u.name LIKE '%オオタキヨジ%' 
   OR u.email LIKE '%kiyoji1948%'
   OR u.user_id LIKE '%OHTAKIYO%';
