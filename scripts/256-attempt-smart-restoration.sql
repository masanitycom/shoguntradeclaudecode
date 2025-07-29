-- スマート復元: 作成日時ベースの論理的な紹介関係の再構築

-- 1. 論理的な紹介関係の再構築
-- 基本原則: 紹介者は被紹介者より早く登録されている必要がある

-- まず、明らかに正しい関係を特定
WITH logical_referrals AS (
    -- 各ユーザーに対して、そのユーザーより早く登録された適切な紹介者を見つける
    SELECT DISTINCT
        u.id as user_id,
        u.user_id as user_code,
        u.name as user_name,
        u.created_at as user_created,
        -- 最も近い時期に登録された先輩ユーザーを紹介者とする
        (SELECT id 
         FROM users potential_ref 
         WHERE potential_ref.is_admin = false
           AND potential_ref.created_at < u.created_at
           AND potential_ref.id != u.id
         ORDER BY potential_ref.created_at DESC
         LIMIT 1) as suggested_referrer_id
    FROM users u
    WHERE u.is_admin = false
),
referrer_info AS (
    SELECT 
        lr.*,
        ref.user_id as suggested_referrer_code,
        ref.name as suggested_referrer_name,
        ref.created_at as suggested_referrer_created
    FROM logical_referrals lr
    LEFT JOIN users ref ON lr.suggested_referrer_id = ref.id
)
-- 提案される紹介関係を表示（実際の更新前に確認）
SELECT 
    'Suggested Restoration' as check_type,
    user_code,
    user_name,
    user_created,
    suggested_referrer_code,
    suggested_referrer_name,
    suggested_referrer_created,
    CASE 
        WHEN suggested_referrer_id IS NULL THEN 'NO_SUITABLE_REFERRER'
        WHEN user_created <= suggested_referrer_created THEN 'DATE_CONFLICT'
        ELSE 'OK'
    END as status
FROM referrer_info
ORDER BY user_created
LIMIT 50;

-- 2. 特定のケースの確認（1125RitsukoとUSER0a18）
SELECT 
    'Specific Case Check' as check_type,
    'Should 1125Ritsuko have USER0a18 as referrer?' as question,
    ritsuko.user_id as ritsuko_code,
    ritsuko.created_at as ritsuko_created,
    user0a18.user_id as user0a18_code,
    user0a18.created_at as user0a18_created,
    CASE 
        WHEN user0a18.created_at < ritsuko.created_at THEN 'LOGICALLY_POSSIBLE'
        ELSE 'DATE_CONFLICT'
    END as feasibility
FROM users ritsuko
CROSS JOIN users user0a18
WHERE ritsuko.user_id = '1125Ritsuko'
  AND user0a18.user_id = 'USER0a18';
