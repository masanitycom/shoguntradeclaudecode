-- 全ユーザーの紹介コードと紹介リンクを正しく修正

-- 1. 現在の紹介コード状況を確認
SELECT 
  'Before Fix' as status,
  user_id,
  my_referral_code,
  referral_link,
  CASE 
    WHEN my_referral_code = user_id THEN 'Correct'
    ELSE 'Incorrect'
  END as code_status
FROM users 
WHERE user_id IS NOT NULL
ORDER BY created_at
LIMIT 10;

-- 2. 全ユーザーの紹介コードを user_id ベースで修正
UPDATE users 
SET 
  my_referral_code = user_id,
  referral_link = 'https://shogun-trade.vercel.app/register?ref=' || user_id
WHERE user_id IS NOT NULL 
  AND user_id != ''
  AND (my_referral_code != user_id OR referral_link != 'https://shogun-trade.vercel.app/register?ref=' || user_id);

-- 3. 修正後の状況を確認
SELECT 
  'After Fix' as status,
  user_id,
  my_referral_code,
  referral_link,
  CASE 
    WHEN my_referral_code = user_id THEN 'Correct'
    ELSE 'Still Incorrect'
  END as code_status
FROM users 
WHERE user_id IS NOT NULL
ORDER BY created_at
LIMIT 10;

-- 4. 特定ユーザー（kaorin37）の確認
SELECT 
  'kaorin37 Check' as check_type,
  name,
  user_id,
  my_referral_code,
  referral_link,
  email
FROM users 
WHERE user_id = 'kaorin37' OR email = 'kaorin1434@gmail.com';

-- 5. 修正統計
SELECT 
  'Fix Statistics' as check_type,
  COUNT(*) as total_users,
  COUNT(CASE WHEN my_referral_code = user_id THEN 1 END) as correct_codes,
  COUNT(CASE WHEN my_referral_code != user_id THEN 1 END) as incorrect_codes
FROM users 
WHERE user_id IS NOT NULL AND user_id != '';
