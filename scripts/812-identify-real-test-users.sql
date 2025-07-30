-- テストユーザーの正確な識別

SELECT '=== IDENTIFYING REAL TEST USERS ===' as section;

-- 1. 明確なテストユーザーパターン
SELECT 'Clear test user patterns:' as info;

-- パターン1: 大文字小文字の組み合わせで重複するメール
SELECT 'Duplicate emails with case variations:' as pattern1;
SELECT 
    LOWER(email) as email_lowercase,
    COUNT(*) as count,
    STRING_AGG(email || ' (' || name || ')', ', ' ORDER BY email) as variations
FROM users
WHERE email LIKE '%@shogun-trade.com%' OR email LIKE '%@shogun-trade.co%'
GROUP BY LOWER(email)
HAVING COUNT(*) > 1
ORDER BY count DESC;

-- パターン2: 単一文字のメールアドレス
SELECT 'Single letter emails:' as pattern2;
SELECT id, name, email, created_at, phone
FROM users
WHERE email ~ '^[a-zA-Z0-9]{1,3}@shogun-trade\.com$'
ORDER BY email;

-- パターン3: phone = '000-0000-0000'のユーザー
SELECT 'Users with phone 000-0000-0000:' as pattern3;
SELECT id, name, email, created_at
FROM users
WHERE phone = '000-0000-0000'
ORDER BY created_at;

-- パターン4: 名前が「ユーザー」で始まる
SELECT 'Users with name starting with ユーザー:' as pattern4;
SELECT id, name, email, created_at
FROM users
WHERE name LIKE 'ユーザー%'
ORDER BY name;

-- パターン5: 2025/6/26 04:20:09に一括作成されたユーザー
SELECT 'Users created at 2025-06-26 04:20:09:' as pattern5;
SELECT COUNT(*) as count, created_at
FROM users
WHERE created_at = '2025-06-26 04:20:09.784831+00'
GROUP BY created_at;

-- パターン6: referrer_idがNULLで、単純なuser_idパターン
SELECT 'Simple user_id patterns with null referrer:' as pattern6;
SELECT id, name, email, user_id
FROM users
WHERE referrer_id IS NULL
  AND user_id ~ '^[a-zA-Z]+user$|^[a-zA-Z]+[0-9]+$'
  AND email LIKE '%@shogun-trade.com%'
ORDER BY user_id;

SELECT '=== ANALYSIS COMPLETE ===' as status;