-- 🔍 CSVに存在するユーザーをCSVの通りに修正
-- 生成日時: 2025-06-29T08:18:28.000Z

-- CSVに存在するユーザーをCSVの通りに正しい紹介者に設定
BEGIN;

-- バックアップ
DROP TABLE IF EXISTS csv_existing_users_backup;
CREATE TABLE csv_existing_users_backup AS
SELECT 
    u.id,
    u.user_id,
    u.name,
    u.referrer_id,
    r.user_id as current_referrer
FROM users u
LEFT JOIN users r ON u.referrer_id = r.id
WHERE u.user_id IN ('242424b', 'atsuko03', 'atsuko04', 'atsuko28', 'Ayanon2', 'Ayanon3', 'FU3111', 'FU9166', 'itsumari0311', 'ko1969', 'kuru39');

-- CSVに存在するユーザーをCSVの通りに修正
-- 242424b (ノグチチヨコ2) -> mitsuaki0320
UPDATE users 
SET referrer_id = (SELECT id FROM users WHERE user_id = 'mitsuaki0320' LIMIT 1),
    updated_at = NOW()
WHERE user_id = '242424b';

-- atsuko03 (コジマアツコ2) -> atsuko28
UPDATE users 
SET referrer_id = (SELECT id FROM users WHERE user_id = 'atsuko28' LIMIT 1),
    updated_at = NOW()
WHERE user_id = 'atsuko03';

-- atsuko04 (コジマアツコ3) -> atsuko28
UPDATE users 
SET referrer_id = (SELECT id FROM users WHERE user_id = 'atsuko28' LIMIT 1),
    updated_at = NOW()
WHERE user_id = 'atsuko04';

-- atsuko28 (コジマアツコ4) -> USER0a18
UPDATE users 
SET referrer_id = (SELECT id FROM users WHERE user_id = 'USER0a18' LIMIT 1),
    updated_at = NOW()
WHERE user_id = 'atsuko28';

-- Ayanon2 (ワタヌキイチロウ) -> mitsuaki0320
UPDATE users 
SET referrer_id = (SELECT id FROM users WHERE user_id = 'mitsuaki0320' LIMIT 1),
    updated_at = NOW()
WHERE user_id = 'Ayanon2';

-- Ayanon3 (ゴトウアヤ) -> Ayanon2
UPDATE users 
SET referrer_id = (SELECT id FROM users WHERE user_id = 'Ayanon2' LIMIT 1),
    updated_at = NOW()
WHERE user_id = 'Ayanon3';

-- FU3111 (シマダフミコ2) -> FU9166
UPDATE users 
SET referrer_id = (SELECT id FROM users WHERE user_id = 'FU9166' LIMIT 1),
    updated_at = NOW()
WHERE user_id = 'FU3111';

-- FU9166 (シマダフミコ4) -> USER0a18
UPDATE users 
SET referrer_id = (SELECT id FROM users WHERE user_id = 'USER0a18' LIMIT 1),
    updated_at = NOW()
WHERE user_id = 'FU9166';

-- itsumari0311 (ミヤモトイツコ2) -> USER0a18
UPDATE users 
SET referrer_id = (SELECT id FROM users WHERE user_id = 'USER0a18' LIMIT 1),
    updated_at = NOW()
WHERE user_id = 'itsumari0311';

-- ko1969 (オジマケンイチ) -> USER0a18
UPDATE users 
SET referrer_id = (SELECT id FROM users WHERE user_id = 'USER0a18' LIMIT 1),
    updated_at = NOW()
WHERE user_id = 'ko1969';

-- kuru39 (ワカミヤミカ) -> USER0a18
UPDATE users 
SET referrer_id = (SELECT id FROM users WHERE user_id = 'USER0a18' LIMIT 1),
    updated_at = NOW()
WHERE user_id = 'kuru39';

-- 修正結果確認
SELECT 
    'CSVに存在するユーザーの修正結果' as check_type,
    u.user_id,
    u.name,
    COALESCE(r.user_id, 'なし') as new_referrer
FROM users u
LEFT JOIN users r ON u.referrer_id = r.id
WHERE u.user_id IN ('242424b', 'atsuko03', 'atsuko04', 'atsuko28', 'Ayanon2', 'Ayanon3', 'FU3111', 'FU9166', 'itsumari0311', 'ko1969', 'kuru39')
ORDER BY u.user_id;

COMMIT;
