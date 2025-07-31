-- 運用開始日の強制設定

SELECT '=== 運用開始日強制設定 ===' as section;

-- 1. 現在のuser_nftsで運用開始日が未設定のレコード確認
SELECT '運用開始日未設定のNFT:' as missing_dates;
SELECT 
    un.id,
    u.name,
    u.user_id,
    n.name as nft_name,
    un.purchase_date,
    un.operation_start_date,
    un.created_at
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
WHERE un.operation_start_date IS NULL
  AND un.is_active = true
ORDER BY un.created_at DESC
LIMIT 10;

-- 2. 購入日から運用開始日を自動計算して更新
SELECT '運用開始日自動計算中...' as calculation;
UPDATE user_nfts 
SET operation_start_date = CASE 
    WHEN EXTRACT(DOW FROM purchase_date) = 0 THEN purchase_date + INTERVAL '1 day'  -- 日曜日なら月曜日
    WHEN EXTRACT(DOW FROM purchase_date) = 6 THEN purchase_date + INTERVAL '2 days' -- 土曜日なら月曜日
    ELSE purchase_date + INTERVAL '1 day' -- 平日なら翌日
END
WHERE operation_start_date IS NULL
  AND is_active = true;

-- 3. 更新結果確認
SELECT '運用開始日更新結果:' as update_result;
SELECT 
    un.id,
    u.name,
    u.user_id,
    n.name as nft_name,
    un.purchase_date,
    un.operation_start_date,
    EXTRACT(DOW FROM un.purchase_date) as purchase_dow,
    EXTRACT(DOW FROM un.operation_start_date) as operation_dow,
    un.updated_at
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
WHERE u.name IN ('サカイユカ2', 'サカイユカ3')
  AND un.is_active = true
ORDER BY un.updated_at DESC;

-- 4. NFT付与フォームで設定される購入日の強制修正
SELECT 'フォーム用の購入日修正:' as form_fix;
UPDATE user_nfts 
SET purchase_date = '2025-01-27 15:00:00+00'::timestamp with time zone,
    operation_start_date = '2025-01-28 15:00:00+00'::timestamp with time zone  -- 月曜日から運用開始
WHERE user_id IN (
    SELECT id FROM users WHERE name IN ('サカイユカ2', 'サカイユカ3')
)
AND is_active = true
AND purchase_date::date >= '2025-02-01';

-- 5. 最終確認
SELECT '最終結果確認:' as final_check;
SELECT 
    u.name,
    u.user_id,
    n.name as nft_name,
    un.purchase_date,
    un.operation_start_date,
    TO_CHAR(un.purchase_date, 'YYYY/MM/DD (Dy)') as purchase_formatted,
    TO_CHAR(un.operation_start_date, 'YYYY/MM/DD (Dy)') as operation_formatted
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
WHERE u.name IN ('サカイユカ2', 'サカイユカ3')
  AND un.is_active = true
ORDER BY u.name;

SELECT '=== 運用開始日設定完了 ===' as status;