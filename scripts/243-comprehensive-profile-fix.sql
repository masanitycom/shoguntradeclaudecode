-- 紹介者がいないユーザーのプロフィール修正（実際のユーザー向け）

-- 1. 現状の詳細確認
SELECT 
  'Current Issues Summary' as check_type,
  COUNT(*) as total_no_referrer_users,
  COUNT(CASE WHEN phone IS NULL OR phone = '' THEN 1 END) as no_phone_users,
  COUNT(CASE WHEN name = SPLIT_PART(email, '@', 1) AND email NOT LIKE '%@shogun-trade.com' THEN 1 END) as real_email_prefix_names
FROM users 
WHERE referrer_id IS NULL 
  AND is_admin = false;

-- 2. 電話番号が空のユーザーにデフォルト値を設定
UPDATE users 
SET phone = '090-0000-0000'
WHERE (phone IS NULL OR phone = '') 
  AND referrer_id IS NULL 
  AND is_admin = false;

-- 3. 実際のメールアドレスを持つユーザーで名前がメールアドレスベースの場合の修正
UPDATE users 
SET name = CASE 
  -- 実際のメールアドレスでメールアドレスベースの名前の場合、適切な名前に変更
  WHEN email NOT LIKE '%@shogun-trade.com' AND name = SPLIT_PART(email, '@', 1) THEN
    CASE 
      WHEN SPLIT_PART(email, '@', 1) = 'tokusana371' THEN 'トクサナ'
      ELSE INITCAP(SPLIT_PART(email, '@', 1)) -- 他は頭文字を大文字に
    END
  ELSE name
END
WHERE referrer_id IS NULL 
  AND is_admin = false
  AND email NOT LIKE '%@shogun-trade.com'
  AND name = SPLIT_PART(email, '@', 1);

-- 4. 紹介者がいないユーザーに管理者を紹介者として設定
-- まず管理者のIDを取得
WITH admin_user AS (
  SELECT id as admin_id 
  FROM users 
  WHERE user_id = 'admin001' 
    AND is_admin = true 
  LIMIT 1
)
UPDATE users 
SET referrer_id = admin_user.admin_id
FROM admin_user
WHERE users.referrer_id IS NULL 
  AND users.is_admin = false
  AND users.user_id != 'admin001';

-- 5. 紹介コードと紹介リンクの整合性確認・修正
UPDATE users 
SET 
  my_referral_code = user_id,
  referral_link = 'https://shogun-trade.vercel.app/register?ref=' || user_id
WHERE referrer_id IS NOT NULL 
  AND is_admin = false
  AND (
    my_referral_code IS NULL OR 
    my_referral_code != user_id OR
    referral_link IS NULL OR
    referral_link != 'https://shogun-trade.vercel.app/register?ref=' || user_id
  );

-- 6. 修正結果の確認
SELECT 
  'Fix Results Summary' as check_type,
  COUNT(*) as total_users,
  COUNT(CASE WHEN referrer_id IS NULL THEN 1 END) as still_no_referrer,
  COUNT(CASE WHEN phone IS NULL OR phone = '' THEN 1 END) as still_no_phone,
  COUNT(CASE WHEN my_referral_code IS NULL THEN 1 END) as no_referral_code,
  COUNT(CASE WHEN referral_link IS NULL THEN 1 END) as no_referral_link
FROM users 
WHERE is_admin = false;

-- 7. 特定の問題ユーザーの確認
SELECT 
  'Specific Users After Fix' as check_type,
  user_id,
  name,
  email,
  phone,
  referrer_id,
  my_referral_code,
  referral_link,
  CASE WHEN referrer_id IS NOT NULL THEN 'Has Referrer' ELSE 'No Referrer' END as referrer_status
FROM users 
WHERE user_id IN ('Tomo115', '0619mmmk', 'mook0214', 'USER001', 'USER002', 'tokusana371')
ORDER BY user_id;

-- 8. 紹介者として設定された管理者の確認
SELECT 
  'Admin as Referrer Check' as check_type,
  r.name as referrer_name,
  r.user_id as referrer_user_id,
  COUNT(u.id) as referred_users_count
FROM users u
JOIN users r ON u.referrer_id = r.id
WHERE r.is_admin = true
GROUP BY r.id, r.name, r.user_id;
