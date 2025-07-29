-- OHTAKIYOユーザーの紹介情報を確認
SELECT 
  id,
  name,
  user_id,
  email,
  my_referral_code,
  referral_link,
  created_at
FROM users 
WHERE user_id = 'OHTAKIYO' OR name = 'オオタキヨジ';

-- 紹介コードが空の場合は生成
UPDATE users 
SET 
  my_referral_code = CASE 
    WHEN my_referral_code IS NULL OR my_referral_code = '' 
    THEN user_id 
    ELSE my_referral_code 
  END,
  referral_link = CASE 
    WHEN referral_link IS NULL OR referral_link = '' 
    THEN 'https://shogun-trade.com/register?ref=' || user_id
    ELSE referral_link 
  END
WHERE user_id = 'OHTAKIYO';

-- 更新後の確認
SELECT 
  'Updated referral data' as info,
  id,
  name,
  user_id,
  my_referral_code,
  referral_link
FROM users 
WHERE user_id = 'OHTAKIYO';
