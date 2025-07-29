-- 🔍 CSVに存在しないユーザーの確認と修正
-- 生成日時: 2025-06-29T08:18:28.000Z

-- CSVに存在しないユーザー一覧
/*
1. MAU1204 (シマダフミコ3)
2. mitsuaki0320 (イノセミツアキ)
3. mook0214 (ハギワラサナエ)
4. NYAN (サトウチヨコ)
5. USER037 (S)
6. USER038 (X)
7. USER039 (A4)
8. USER040 (A2)
9. USER041 (A6)
10. USER042 (T)
11. USER043 (A5)
12. USER044 (A8)
13. USER045 (A1)
14. USER046 (L)
15. USER047 (A7)
*/

-- これらのユーザーはCSVに存在しないため、USER0a18に統一します
BEGIN;

-- バックアップ
DROP TABLE IF EXISTS csv_missing_users_backup;
CREATE TABLE csv_missing_users_backup AS
SELECT 
    u.id,
    u.user_id,
    u.name,
    u.referrer_id,
    r.user_id as current_referrer
FROM users u
LEFT JOIN users r ON u.referrer_id = r.id
WHERE u.user_id IN ('MAU1204', 'mitsuaki0320', 'mook0214', 'NYAN', 'USER037', 'USER038', 'USER039', 'USER040', 'USER041', 'USER042', 'USER043', 'USER044', 'USER045', 'USER046', 'USER047');

-- CSVに存在しないユーザーをUSER0a18に統一
-- MAU1204 (シマダフミコ3) -> USER0a18
UPDATE users 
SET referrer_id = (SELECT id FROM users WHERE user_id = 'USER0a18' LIMIT 1),
    updated_at = NOW()
WHERE user_id = 'MAU1204';

-- mitsuaki0320 (イノセミツアキ) -> USER0a18
UPDATE users 
SET referrer_id = (SELECT id FROM users WHERE user_id = 'USER0a18' LIMIT 1),
    updated_at = NOW()
WHERE user_id = 'mitsuaki0320';

-- mook0214 (ハギワラサナエ) -> USER0a18
UPDATE users 
SET referrer_id = (SELECT id FROM users WHERE user_id = 'USER0a18' LIMIT 1),
    updated_at = NOW()
WHERE user_id = 'mook0214';

-- NYAN (サトウチヨコ) -> USER0a18
UPDATE users 
SET referrer_id = (SELECT id FROM users WHERE user_id = 'USER0a18' LIMIT 1),
    updated_at = NOW()
WHERE user_id = 'NYAN';

-- USER037 (S) -> USER0a18
UPDATE users 
SET referrer_id = (SELECT id FROM users WHERE user_id = 'USER0a18' LIMIT 1),
    updated_at = NOW()
WHERE user_id = 'USER037';

-- USER038 (X) -> USER0a18
UPDATE users 
SET referrer_id = (SELECT id FROM users WHERE user_id = 'USER0a18' LIMIT 1),
    updated_at = NOW()
WHERE user_id = 'USER038';

-- USER039 (A4) -> USER0a18
UPDATE users 
SET referrer_id = (SELECT id FROM users WHERE user_id = 'USER0a18' LIMIT 1),
    updated_at = NOW()
WHERE user_id = 'USER039';

-- USER040 (A2) -> USER0a18
UPDATE users 
SET referrer_id = (SELECT id FROM users WHERE user_id = 'USER0a18' LIMIT 1),
    updated_at = NOW()
WHERE user_id = 'USER040';

-- USER041 (A6) -> USER0a18
UPDATE users 
SET referrer_id = (SELECT id FROM users WHERE user_id = 'USER0a18' LIMIT 1),
    updated_at = NOW()
WHERE user_id = 'USER041';

-- USER042 (T) -> USER0a18
UPDATE users 
SET referrer_id = (SELECT id FROM users WHERE user_id = 'USER0a18' LIMIT 1),
    updated_at = NOW()
WHERE user_id = 'USER042';

-- USER043 (A5) -> USER0a18
UPDATE users 
SET referrer_id = (SELECT id FROM users WHERE user_id = 'USER0a18' LIMIT 1),
    updated_at = NOW()
WHERE user_id = 'USER043';

-- USER044 (A8) -> USER0a18
UPDATE users 
SET referrer_id = (SELECT id FROM users WHERE user_id = 'USER0a18' LIMIT 1),
    updated_at = NOW()
WHERE user_id = 'USER044';

-- USER045 (A1) -> USER0a18
UPDATE users 
SET referrer_id = (SELECT id FROM users WHERE user_id = 'USER0a18' LIMIT 1),
    updated_at = NOW()
WHERE user_id = 'USER045';

-- USER046 (L) -> USER0a18
UPDATE users 
SET referrer_id = (SELECT id FROM users WHERE user_id = 'USER0a18' LIMIT 1),
    updated_at = NOW()
WHERE user_id = 'USER046';

-- USER047 (A7) -> USER0a18
UPDATE users 
SET referrer_id = (SELECT id FROM users WHERE user_id = 'USER0a18' LIMIT 1),
    updated_at = NOW()
WHERE user_id = 'USER047';

-- 修正結果確認
SELECT 
    'CSVに存在しないユーザーの修正結果' as check_type,
    u.user_id,
    u.name,
    COALESCE(r.user_id, 'なし') as new_referrer
FROM users u
LEFT JOIN users r ON u.referrer_id = r.id
WHERE u.user_id IN ('MAU1204', 'mitsuaki0320', 'mook0214', 'NYAN', 'USER037', 'USER038', 'USER039', 'USER040', 'USER041', 'USER042', 'USER043', 'USER044', 'USER045', 'USER046', 'USER047')
ORDER BY u.user_id;

COMMIT;
