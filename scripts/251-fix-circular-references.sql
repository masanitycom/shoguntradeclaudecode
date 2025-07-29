-- 循環参照の検出と修正

-- 1. 循環参照の詳細検出
WITH RECURSIVE referral_paths AS (
    -- 開始点: 各ユーザーから開始
    SELECT 
        id as start_user,
        id as current_user,
        referrer_id,
        1 as depth,
        ARRAY[id] as path,
        false as is_circular
    FROM users 
    WHERE is_admin = false
    
    UNION ALL
    
    -- 再帰: 紹介者を辿る
    SELECT 
        rp.start_user,
        u.id as current_user,
        u.referrer_id,
        rp.depth + 1,
        rp.path || u.id,
        u.id = ANY(rp.path) as is_circular
    FROM referral_paths rp
    JOIN users u ON rp.referrer_id = u.id
    WHERE rp.depth < 10 
      AND NOT rp.is_circular
      AND u.referrer_id IS NOT NULL
),
circular_users AS (
    SELECT DISTINCT start_user as user_id
    FROM referral_paths 
    WHERE is_circular = true
)
-- 循環参照に関わるユーザーを安全な紹介者に再割り当て
UPDATE users 
SET referrer_id = (
    SELECT id 
    FROM users safe_referrer
    WHERE safe_referrer.is_admin = false
      AND safe_referrer.id NOT IN (SELECT user_id FROM circular_users)
      AND safe_referrer.created_at < users.created_at
    ORDER BY safe_referrer.created_at ASC
    LIMIT 1
),
updated_at = NOW()
WHERE id IN (SELECT user_id FROM circular_users);

-- 2. 修正結果の確認
SELECT 
    'Circular Reference Fix' as status,
    COUNT(*) as users_fixed
FROM users 
WHERE updated_at > NOW() - INTERVAL '1 minute'
  AND is_admin = false;
