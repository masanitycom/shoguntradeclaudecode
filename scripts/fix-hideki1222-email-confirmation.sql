-- hideki1222のメール確認状態を修正

SELECT '=== FIXING HIDEKI1222 EMAIL CONFIRMATION ===' as section;

-- Step 1: monchuck0320@gmail.com のメール確認状態を修正
-- auth.usersテーブルのemail_confirmed_atを現在時刻に設定
UPDATE auth.users 
SET 
    email_confirmed_at = NOW(),
    updated_at = NOW()
WHERE email = 'monchuck0320@gmail.com' 
  AND id = '022ecffe-abdb-44fd-b5b6-430c150d8aab';

-- 修正完了確認
SELECT 'HIDEKI1222 EMAIL CONFIRMATION FIXED!' as status;

-- Step 2: 修正結果の確認
SELECT '=== EMAIL CONFIRMATION VERIFICATION ===' as verification;

-- hideki1222の最終確認
SELECT 'hideki1222 final email status:' as hideki_final;
SELECT 
    au.id as auth_id,
    au.email as auth_email,
    au.email_confirmed_at,
    CASE 
        WHEN au.email_confirmed_at IS NOT NULL THEN 'CONFIRMED ✓'
        ELSE 'UNCONFIRMED ✗'
    END as email_status,
    pu.id as public_id,
    pu.name as public_name,
    pu.user_id as public_user_id,
    (SELECT COUNT(*) FROM user_nfts WHERE user_id = pu.id AND is_active = true) as nft_count,
    (SELECT SUM(current_investment::numeric) FROM user_nfts WHERE user_id = pu.id AND is_active = true) as total_investment
FROM auth.users au
LEFT JOIN users pu ON au.id = pu.id
WHERE au.email = 'monchuck0320@gmail.com';

SELECT 'SUCCESS: hideki1222 can now login successfully!' as success_message;