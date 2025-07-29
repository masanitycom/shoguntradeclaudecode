-- 既存のNFTで運用開始日が未設定または不正なものを修正

-- 既存のoperation_start_dateの状況を確認
SELECT 
    COUNT(*) as total_nfts,
    COUNT(operation_start_date) as with_operation_date,
    COUNT(*) - COUNT(operation_start_date) as missing_operation_date
FROM user_nfts 
WHERE is_active = true;

-- 運用開始日が未設定のNFTを表示
SELECT 
    un.id,
    u.name as user_name,
    u.user_id,
    n.name as nft_name,
    un.purchase_date,
    un.operation_start_date,
    calculate_operation_start_date(un.purchase_date) as calculated_start_date
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
WHERE un.is_active = true 
  AND (un.operation_start_date IS NULL 
       OR un.purchase_date IS NOT NULL 
       AND un.operation_start_date != calculate_operation_start_date(un.purchase_date))
ORDER BY un.purchase_date DESC;

-- 運用開始日を自動計算して更新
UPDATE user_nfts 
SET operation_start_date = calculate_operation_start_date(purchase_date)
WHERE is_active = true 
  AND purchase_date IS NOT NULL 
  AND (operation_start_date IS NULL 
       OR operation_start_date != calculate_operation_start_date(purchase_date));

-- 更新結果を確認
SELECT 
    COUNT(*) as total_active_nfts,
    COUNT(operation_start_date) as with_operation_date,
    COUNT(*) - COUNT(operation_start_date) as still_missing
FROM user_nfts 
WHERE is_active = true;

-- 更新後の運用開始日一覧（確認用）
SELECT 
    u.name as user_name,
    u.user_id,
    n.name as nft_name,
    un.purchase_date,
    un.operation_start_date,
    CASE 
        WHEN un.operation_start_date > CURRENT_DATE THEN '待機中'
        ELSE '運用中'
    END as status
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
WHERE un.is_active = true 
  AND un.operation_start_date IS NOT NULL
ORDER BY un.operation_start_date DESC
LIMIT 20;