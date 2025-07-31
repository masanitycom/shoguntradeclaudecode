-- ハギワラサナエさんの緊急復元

SELECT '=== ハギワラサナエ緊急復元 ===' as section;

-- 1. 正規ユーザーを復元
SELECT '正規ユーザー復元中...' as action;
INSERT INTO users (
    name,
    user_id,
    email,
    phone,
    created_at,
    updated_at,
    is_admin,
    password_changed,
    is_active,
    total_investment,
    total_earned,
    pending_rewards,
    current_rank,
    current_rank_level,
    active_nft_count
) VALUES (
    'ハギワラサナエ',
    'mook0214',
    'tokusana371@gmail.com',  -- 小文字メール（正規）
    '09012345678',
    '2025-06-24 10:08:44.040794+00',  -- 正規の作成日時
    NOW(),
    false,
    false,
    true,
    0.00,
    0.00,
    0.00,
    'なし',
    0,
    0
);

-- 2. 復元確認
SELECT '復元結果確認:' as verification;
SELECT 
    id,
    name,
    user_id,
    email,
    created_at,
    '復元完了' as status
FROM users
WHERE name = 'ハギワラサナエ'
  AND user_id = 'mook0214'
  AND email = 'tokusana371@gmail.com';

-- 3. 参照用ID生成（紹介リンク用）
SELECT '参照用ID生成:' as ref_setup;
UPDATE users 
SET my_referral_code = user_id,
    referral_link = 'https://shogun-trade.vercel.app/register?ref=' || user_id
WHERE name = 'ハギワラサナエ'
  AND user_id = 'mook0214'
  AND email = 'tokusana371@gmail.com';

SELECT '=== ハギワラサナエ復元完了 ===' as status;