-- PHULIKEユーザーID重複の調査

SELECT '=== PHULIKE USER_ID CONFLICT INVESTIGATION ===' as section;

-- PHULIKEを使用している全ユーザー確認
SELECT 'All users with PHULIKE user_id:' as info;
SELECT 
    id, name, email, user_id, phone, referrer_id,
    created_at, updated_at
FROM users 
WHERE user_id = 'PHULIKE'
ORDER BY created_at;

-- kappystone.516@gmail.com の現在の状況
SELECT 'Current kappystone.516@gmail.com status:' as current_status;
SELECT 
    id, name, email, user_id, phone, referrer_id,
    created_at, updated_at
FROM users 
WHERE email = 'kappystone.516@gmail.com'
ORDER BY created_at;

-- auth.users での確認
SELECT 'Auth users check:' as auth_check;
SELECT 
    id, email, created_at
FROM auth.users 
WHERE email = 'kappystone.516@gmail.com';

-- 解決策：一意のuser_idを生成
SELECT 'CONFLICT RESOLUTION:' as resolution;
SELECT 
    'Issue: PHULIKE user_id already exists' as problem,
    'Solution: Use PHULIKE2 or PHULIKE_NEW for kappystone' as solution1,
    'Alternative: Update existing PHULIKE user if appropriate' as solution2;

-- PHULIKEを参照している他のデータ確認
SELECT 'Referral relationships using PHULIKE:' as referrals;
SELECT 
    id, name, email, user_id
FROM users 
WHERE referrer_id = (SELECT id FROM users WHERE user_id = 'PHULIKE' LIMIT 1);

-- 推奨する新しいuser_id
SELECT 'RECOMMENDED NEW USER_ID FOR KAPPYSTONE:' as recommendation;
SELECT 
    'PHULIKE2' as option1,
    'KAPPYSTONE' as option2,
    'ISHIJIMA' as option3;