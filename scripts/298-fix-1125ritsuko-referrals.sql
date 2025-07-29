-- 🔥 1125Ritsukoの紹介数を0にする修正SQL
-- 26人のユーザーを正しい紹介者に変更

BEGIN;

-- バックアップテーブル作成
DROP TABLE IF EXISTS ritsuko_fix_backup;
CREATE TABLE ritsuko_fix_backup AS
SELECT 
    u.id,
    u.user_id,
    u.name,
    u.referrer_id,
    r.user_id as current_referrer_user_id
FROM users u
LEFT JOIN users r ON u.referrer_id = r.id
WHERE u.referrer_id = (SELECT id FROM users WHERE user_id = '1125Ritsuko');

-- 修正前の状態確認
SELECT 
    '修正前の1125Ritsuko紹介数' as status,
    COUNT(*) as count
FROM users
WHERE referrer_id = (SELECT id FROM users WHERE user_id = '1125Ritsuko');

-- CSVに存在するユーザーの修正（正しい紹介者が判明しているもの）
-- 242424b (ノグチチヨコ2) -> USER0a18
UPDATE users 
SET referrer_id = (SELECT id FROM users WHERE user_id = 'USER0a18' LIMIT 1),
    updated_at = NOW()
WHERE user_id = '242424b' 
  AND referrer_id = (SELECT id FROM users WHERE user_id = '1125Ritsuko');

-- atsuko03 (コジマアツコ2) -> USER0a18
UPDATE users 
SET referrer_id = (SELECT id FROM users WHERE user_id = 'USER0a18' LIMIT 1),
    updated_at = NOW()
WHERE user_id = 'atsuko03' 
  AND referrer_id = (SELECT id FROM users WHERE user_id = '1125Ritsuko');

-- atsuko04 (コジマアツコ3) -> USER0a18
UPDATE users 
SET referrer_id = (SELECT id FROM users WHERE user_id = 'USER0a18' LIMIT 1),
    updated_at = NOW()
WHERE user_id = 'atsuko04' 
  AND referrer_id = (SELECT id FROM users WHERE user_id = '1125Ritsuko');

-- atsuko28 (コジマアツコ4) -> USER0a18
UPDATE users 
SET referrer_id = (SELECT id FROM users WHERE user_id = 'USER0a18' LIMIT 1),
    updated_at = NOW()
WHERE user_id = 'atsuko28' 
  AND referrer_id = (SELECT id FROM users WHERE user_id = '1125Ritsuko');

-- Ayanon2 (ワタヌキイチロウ) -> USER0a18
UPDATE users 
SET referrer_id = (SELECT id FROM users WHERE user_id = 'USER0a18' LIMIT 1),
    updated_at = NOW()
WHERE user_id = 'Ayanon2' 
  AND referrer_id = (SELECT id FROM users WHERE user_id = '1125Ritsuko');

-- Ayanon3 (ゴトウアヤ) -> USER0a18
UPDATE users 
SET referrer_id = (SELECT id FROM users WHERE user_id = 'USER0a18' LIMIT 1),
    updated_at = NOW()
WHERE user_id = 'Ayanon3' 
  AND referrer_id = (SELECT id FROM users WHERE user_id = '1125Ritsuko');

-- FU3111 (シマダフミコ2) -> USER0a18
UPDATE users 
SET referrer_id = (SELECT id FROM users WHERE user_id = 'USER0a18' LIMIT 1),
    updated_at = NOW()
WHERE user_id = 'FU3111' 
  AND referrer_id = (SELECT id FROM users WHERE user_id = '1125Ritsuko');

-- FU9166 (シマダフミコ4) -> USER0a18
UPDATE users 
SET referrer_id = (SELECT id FROM users WHERE user_id = 'USER0a18' LIMIT 1),
    updated_at = NOW()
WHERE user_id = 'FU9166' 
  AND referrer_id = (SELECT id FROM users WHERE user_id = '1125Ritsuko');

-- itsumari0311 (ミヤモトイツコ2) -> USER0a18
UPDATE users 
SET referrer_id = (SELECT id FROM users WHERE user_id = 'USER0a18' LIMIT 1),
    updated_at = NOW()
WHERE user_id = 'itsumari0311' 
  AND referrer_id = (SELECT id FROM users WHERE user_id = '1125Ritsuko');

-- ko1969 (オジマケンイチ) -> USER0a18
UPDATE users 
SET referrer_id = (SELECT id FROM users WHERE user_id = 'USER0a18' LIMIT 1),
    updated_at = NOW()
WHERE user_id = 'ko1969' 
  AND referrer_id = (SELECT id FROM users WHERE user_id = '1125Ritsuko');

-- kuru39 (ワカミヤミカ) -> USER0a18
UPDATE users 
SET referrer_id = (SELECT id FROM users WHERE user_id = 'USER0a18' LIMIT 1),
    updated_at = NOW()
WHERE user_id = 'kuru39' 
  AND referrer_id = (SELECT id FROM users WHERE user_id = '1125Ritsuko');

-- MAU1204 (シマダフミコ3) -> USER0a18
UPDATE users 
SET referrer_id = (SELECT id FROM users WHERE user_id = 'USER0a18' LIMIT 1),
    updated_at = NOW()
WHERE user_id = 'MAU1204' 
  AND referrer_id = (SELECT id FROM users WHERE user_id = '1125Ritsuko');

-- mitsuaki0320 (イノセミツアキ) -> USER0a18
UPDATE users 
SET referrer_id = (SELECT id FROM users WHERE user_id = 'USER0a18' LIMIT 1),
    updated_at = NOW()
WHERE user_id = 'mitsuaki0320' 
  AND referrer_id = (SELECT id FROM users WHERE user_id = '1125Ritsuko');

-- mook0214 (ハギワラサナエ) -> USER0a18
UPDATE users 
SET referrer_id = (SELECT id FROM users WHERE user_id = 'USER0a18' LIMIT 1),
    updated_at = NOW()
WHERE user_id = 'mook0214' 
  AND referrer_id = (SELECT id FROM users WHERE user_id = '1125Ritsuko');

-- NYAN (サトウチヨコ) -> USER0a18
UPDATE users 
SET referrer_id = (SELECT id FROM users WHERE user_id = 'USER0a18' LIMIT 1),
    updated_at = NOW()
WHERE user_id = 'NYAN' 
  AND referrer_id = (SELECT id FROM users WHERE user_id = '1125Ritsuko');

-- CSVに存在しないUSERシリーズ（テストユーザー）をUSER0a18に統一
-- USER037 (S) -> USER0a18
UPDATE users 
SET referrer_id = (SELECT id FROM users WHERE user_id = 'USER0a18' LIMIT 1),
    updated_at = NOW()
WHERE user_id = 'USER037' 
  AND referrer_id = (SELECT id FROM users WHERE user_id = '1125Ritsuko');

-- USER038 (X) -> USER0a18
UPDATE users 
SET referrer_id = (SELECT id FROM users WHERE user_id = 'USER0a18' LIMIT 1),
    updated_at = NOW()
WHERE user_id = 'USER038' 
  AND referrer_id = (SELECT id FROM users WHERE user_id = '1125Ritsuko');

-- USER039 (A4) -> USER0a18
UPDATE users 
SET referrer_id = (SELECT id FROM users WHERE user_id = 'USER0a18' LIMIT 1),
    updated_at = NOW()
WHERE user_id = 'USER039' 
  AND referrer_id = (SELECT id FROM users WHERE user_id = '1125Ritsuko');

-- USER040 (A2) -> USER0a18
UPDATE users 
SET referrer_id = (SELECT id FROM users WHERE user_id = 'USER0a18' LIMIT 1),
    updated_at = NOW()
WHERE user_id = 'USER040' 
  AND referrer_id = (SELECT id FROM users WHERE user_id = '1125Ritsuko');

-- USER041 (A6) -> USER0a18
UPDATE users 
SET referrer_id = (SELECT id FROM users WHERE user_id = 'USER0a18' LIMIT 1),
    updated_at = NOW()
WHERE user_id = 'USER041' 
  AND referrer_id = (SELECT id FROM users WHERE user_id = '1125Ritsuko');

-- USER042 (T) -> USER0a18
UPDATE users 
SET referrer_id = (SELECT id FROM users WHERE user_id = 'USER0a18' LIMIT 1),
    updated_at = NOW()
WHERE user_id = 'USER042' 
  AND referrer_id = (SELECT id FROM users WHERE user_id = '1125Ritsuko');

-- USER043 (A5) -> USER0a18
UPDATE users 
SET referrer_id = (SELECT id FROM users WHERE user_id = 'USER0a18' LIMIT 1),
    updated_at = NOW()
WHERE user_id = 'USER043' 
  AND referrer_id = (SELECT id FROM users WHERE user_id = '1125Ritsuko');

-- USER044 (A8) -> USER0a18
UPDATE users 
SET referrer_id = (SELECT id FROM users WHERE user_id = 'USER0a18' LIMIT 1),
    updated_at = NOW()
WHERE user_id = 'USER044' 
  AND referrer_id = (SELECT id FROM users WHERE user_id = '1125Ritsuko');

-- USER045 (A1) -> USER0a18
UPDATE users 
SET referrer_id = (SELECT id FROM users WHERE user_id = 'USER0a18' LIMIT 1),
    updated_at = NOW()
WHERE user_id = 'USER045' 
  AND referrer_id = (SELECT id FROM users WHERE user_id = '1125Ritsuko');

-- USER046 (L) -> USER0a18
UPDATE users 
SET referrer_id = (SELECT id FROM users WHERE user_id = 'USER0a18' LIMIT 1),
    updated_at = NOW()
WHERE user_id = 'USER046' 
  AND referrer_id = (SELECT id FROM users WHERE user_id = '1125Ritsuko');

-- USER047 (A7) -> USER0a18
UPDATE users 
SET referrer_id = (SELECT id FROM users WHERE user_id = 'USER0a18' LIMIT 1),
    updated_at = NOW()
WHERE user_id = 'USER047' 
  AND referrer_id = (SELECT id FROM users WHERE user_id = '1125Ritsuko');

-- 修正後の確認
SELECT 
    '修正後の1125Ritsuko紹介数' as status,
    COUNT(*) as count,
    CASE 
        WHEN COUNT(*) = 0 THEN '✅ 成功（0人）'
        ELSE '❌ まだ' || COUNT(*) || '人残っている'
    END as result
FROM users
WHERE referrer_id = (SELECT id FROM users WHERE user_id = '1125Ritsuko');

-- 修正されたユーザーの確認
SELECT 
    '修正されたユーザー' as check_type,
    u.user_id,
    u.name,
    COALESCE(r.user_id, 'なし') as new_referrer
FROM users u
LEFT JOIN users r ON u.referrer_id = r.id
WHERE u.id IN (SELECT id FROM ritsuko_fix_backup)
ORDER BY u.user_id;

-- 1125Ritsuko自身の状態確認
SELECT 
    '1125Ritsuko自身の状態' as check_type,
    u.user_id,
    u.name,
    COALESCE(r.user_id, 'なし') as referrer,
    (SELECT COUNT(*) FROM users WHERE referrer_id = u.id) as referral_count
FROM users u
LEFT JOIN users r ON u.referrer_id = r.id
WHERE u.user_id = '1125Ritsuko';

-- USER0a18の新しい紹介数確認
SELECT 
    'USER0a18の紹介数' as check_type,
    COUNT(*) as referral_count,
    '1125Ritsukoと修正された26人を含む' as note
FROM users
WHERE referrer_id = (SELECT id FROM users WHERE user_id = 'USER0a18');

COMMIT;

-- 最終成功メッセージ
SELECT 
    CASE 
        WHEN (SELECT COUNT(*) FROM users WHERE referrer_id = (SELECT id FROM users WHERE user_id = '1125Ritsuko')) = 0
        THEN '🎉 完璧！1125Ritsukoの紹介数は0人になりました！'
        ELSE '❌ まだ修正が必要です'
    END as final_result;
