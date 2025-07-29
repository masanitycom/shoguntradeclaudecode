-- 不正なウォレットアドレスをクリア
UPDATE users 
SET usdt_address = NULL 
WHERE usdt_address = '0ｘ51654654655165151dfsdf4as54a45a6';

-- 修正したユーザーを確認
SELECT 
  name,
  user_id,
  usdt_address,
  wallet_type
FROM users 
WHERE user_id = 'test005';
