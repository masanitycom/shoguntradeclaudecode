-- 運用開始日を正しい月曜日に修正（日本時間対応）

-- 1. 修正前の状況確認（日本時間）
SELECT 
    'Before Fix (JST)' as status,
    COUNT(*) as total_nfts,
    COUNT(CASE WHEN EXTRACT(DOW FROM operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo') = 1 THEN 1 END) as monday_starts_jst,
    COUNT(CASE WHEN EXTRACT(DOW FROM operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo') != 1 THEN 1 END) as non_monday_starts_jst
FROM user_nfts 
WHERE is_active = true;

-- 2. 日本時間で月曜日になるように運用開始日を修正
UPDATE user_nfts 
SET operation_start_date = (
    -- 日本時間で月曜日になるように調整
    CASE 
        WHEN EXTRACT(DOW FROM operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo') = 1 
        THEN operation_start_date -- 既に日本時間で月曜日
        WHEN EXTRACT(DOW FROM operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo') = 0 
        THEN operation_start_date + INTERVAL '1 day' -- 日本時間で日曜日→月曜日
        ELSE operation_start_date - INTERVAL '1 day' * (EXTRACT(DOW FROM operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo') - 1) -- その他→前の月曜日
    END
),
updated_at = NOW()
WHERE is_active = true 
AND EXTRACT(DOW FROM operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo') != 1;

-- 3. 修正後の確認（日本時間）
SELECT 
    'After Fix (JST)' as status,
    COUNT(*) as total_nfts,
    COUNT(CASE WHEN EXTRACT(DOW FROM operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo') = 1 THEN 1 END) as monday_starts_jst,
    COUNT(CASE WHEN EXTRACT(DOW FROM operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo') != 1 THEN 1 END) as non_monday_starts_jst,
    CASE 
        WHEN COUNT(CASE WHEN EXTRACT(DOW FROM operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo') = 1 THEN 1 END) = COUNT(*) 
        THEN '✅ 全て日本時間で月曜日に修正完了'
        ELSE '❌ まだ修正が必要'
    END as result
FROM user_nfts 
WHERE is_active = true;

-- 4. 修正された運用開始日の分布（日本時間）
SELECT 
    operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo' as jst_operation_start,
    TO_CHAR(operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo', 'YYYY-MM-DD (Day)') as jst_formatted_date,
    COUNT(*) as nft_count,
    COUNT(DISTINCT user_id) as user_count
FROM user_nfts 
WHERE is_active = true
GROUP BY operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo'
ORDER BY nft_count DESC, jst_operation_start;
