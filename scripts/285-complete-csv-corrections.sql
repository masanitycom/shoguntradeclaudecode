-- CSV完全準拠の紹介関係修正
-- 実行日時: 2025-06-29T07:45:00.000Z
-- 修正対象: 233人
-- 🔥 CSVの通りに全て修正します！

BEGIN;

-- 修正前の完全バックアップ
DROP TABLE IF EXISTS complete_referral_backup_20250629;
CREATE TABLE complete_referral_backup_20250629 AS
SELECT 
    user_id,
    name,
    referrer_id,
    (SELECT user_id FROM users WHERE id = u.referrer_id) as current_referrer_user_id,
    updated_at,
    NOW() as backup_created_at
FROM users u
WHERE is_admin = false;

-- 修正前の統計
SELECT 
    '=== 修正前の統計 ===' as status,
    COUNT(*) as total_users,
    COUNT(referrer_id) as users_with_referrer,
    COUNT(*) - COUNT(referrer_id) as users_without_referrer
FROM users
WHERE is_admin = false;

-- 修正前の1125Ritsukoの紹介統計
SELECT 
    '=== 修正前の1125Ritsukoの紹介統計 ===' as status,
    COUNT(*) as total_referrals
FROM users
WHERE referrer_id = (SELECT id FROM users WHERE user_id = '1125Ritsuko');

-- 🔥 全233人の修正開始

-- 1. 1125Ritsuko (リツコ) の紹介者を USER0a18 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'USER0a18'),
    updated_at = NOW()
WHERE user_id = '1125Ritsuko'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'USER0a18');

-- 2. 87da521216 (ヤマダタロウ) の紹介者を rai0083 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'rai0083'),
    updated_at = NOW()
WHERE user_id = '87da521216'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'rai0083');

-- 3. a510609 (アベマサコ) の紹介者を USER0a18 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'USER0a18'),
    updated_at = NOW()
WHERE user_id = 'a510609'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'USER0a18');

-- 4. AGABE (アガベマサト) の紹介者を AGABEM に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'AGABEM'),
    updated_at = NOW()
WHERE user_id = 'AGABE'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'AGABEM');

-- 5. AGABEM (アガベマサト2) の紹介者を USER0a18 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'USER0a18'),
    updated_at = NOW()
WHERE user_id = 'AGABEM'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'USER0a18');

-- 6. aikojaiko9 (アイコジャイコ) の紹介者を oga350z2 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'oga350z2'),
    updated_at = NOW()
WHERE user_id = 'aikojaiko9'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'oga350z2');

-- 7. akemiii1986 (アケミ) の紹介者を USER0a18 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'USER0a18'),
    updated_at = NOW()
WHERE user_id = 'akemiii1986'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'USER0a18');

-- 8. akiko341315 (アサハラアキコ) の紹介者を USER0a18 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'USER0a18'),
    updated_at = NOW()
WHERE user_id = 'akiko341315'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'USER0a18');

-- 9. Akira0808 (アキラ) の紹介者を AGABE に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'AGABE'),
    updated_at = NOW()
WHERE user_id = 'Akira0808'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'AGABE');

-- 10. Akira0808002 (アキラ002) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808002'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 11. Akira0808003 (アキラ003) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808003'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 12. Akira0808004 (アキラ004) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808004'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 13. Akira0808005 (アキラ005) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808005'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 14. Akira0808006 (アキラ006) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808006'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 15. Akira0808007 (アキラ007) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808007'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 16. Akira0808008 (アキラ008) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808008'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 17. Akira0808009 (アキラ009) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808009'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 18. Akira0808010 (アキラ010) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808010'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 19. Akira0808011 (アキラ011) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808011'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 20. Akira0808012 (アキラ012) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808012'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 21. Akira0808013 (アキラ013) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808013'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 22. Akira0808014 (アキラ014) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808014'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 23. Akira0808015 (アキラ015) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808015'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 24. Akira0808016 (アキラ016) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808016'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 25. Akira0808017 (アキラ017) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808017'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 26. Akira0808018 (アキラ018) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808018'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 27. Akira0808019 (アキラ019) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808019'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 28. Akira0808020 (アキラ020) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808020'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 29. Akira0808021 (アキラ021) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808021'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 30. Akira0808022 (アキラ022) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808022'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 31. Akira0808023 (アキラ023) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808023'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 32. Akira0808024 (アキラ024) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808024'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 33. Akira0808025 (アキラ025) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808025'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 34. Akira0808026 (アキラ026) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808026'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 35. Akira0808027 (アキラ027) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808027'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 36. Akira0808028 (アキラ028) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808028'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 37. Akira0808029 (アキラ029) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808029'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 38. Akira0808030 (アキラ030) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808030'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 39. Akira0808031 (アキラ031) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808031'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 40. Akira0808032 (アキラ032) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808032'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 41. Akira0808033 (アキラ033) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808033'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 42. Akira0808034 (アキラ034) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808034'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 43. Akira0808035 (アキラ035) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808035'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 44. Akira0808036 (アキラ036) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808036'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 45. Akira0808037 (アキラ037) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808037'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 46. Akira0808038 (アキラ038) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808038'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 47. Akira0808039 (アキラ039) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808039'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 48. Akira0808040 (アキラ040) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808040'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 49. Akira0808041 (アキラ041) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808041'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 50. Akira0808042 (アキラ042) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808042'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 51. Akira0808043 (アキラ043) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808043'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 52. Akira0808044 (アキラ044) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808044'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 53. Akira0808045 (アキラ045) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808045'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 54. Akira0808046 (アキラ046) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808046'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 55. Akira0808047 (アキラ047) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808047'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 56. Akira0808048 (アキラ048) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808048'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 57. Akira0808049 (アキラ049) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808049'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 58. Akira0808050 (アキラ050) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808050'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 59. Akira0808051 (アキラ051) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808051'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 60. Akira0808052 (アキラ052) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808052'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 61. Akira0808053 (アキラ053) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808053'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 62. Akira0808054 (アキラ054) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808054'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 63. Akira0808055 (アキラ055) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808055'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 64. Akira0808056 (アキラ056) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808056'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 65. Akira0808057 (アキラ057) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808057'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 66. Akira0808058 (アキラ058) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808058'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 67. Akira0808059 (アキラ059) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808059'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 68. Akira0808060 (アキラ060) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808060'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 69. Akira0808061 (アキラ061) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808061'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 70. Akira0808062 (アキラ062) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808062'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 71. Akira0808063 (アキラ063) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808063'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 72. Akira0808064 (アキラ064) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808064'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 73. Akira0808065 (アキラ065) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808065'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 74. Akira0808066 (アキラ066) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808066'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 75. Akira0808067 (アキラ067) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808067'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 76. Akira0808068 (アキラ068) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808068'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 77. Akira0808069 (アキラ069) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808069'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 78. Akira0808070 (アキラ070) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808070'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 79. Akira0808071 (アキラ071) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808071'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 80. Akira0808072 (アキラ072) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808072'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 81. Akira0808073 (アキラ073) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808073'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 82. Akira0808074 (アキラ074) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808074'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 83. Akira0808075 (アキラ075) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808075'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 84. Akira0808076 (アキラ076) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808076'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 85. Akira0808077 (アキラ077) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808077'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 86. Akira0808078 (アキラ078) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808078'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 87. Akira0808079 (アキラ079) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808079'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 88. Akira0808080 (アキラ080) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808080'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 89. Akira0808081 (アキラ081) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808081'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 90. Akira0808082 (アキラ082) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808082'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 91. Akira0808083 (アキラ083) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808083'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 92. Akira0808084 (アキラ084) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808084'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 93. Akira0808085 (アキラ085) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808085'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 94. Akira0808086 (アキラ086) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808086'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 95. Akira0808087 (アキラ087) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808087'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 96. Akira0808088 (アキラ088) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808088'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 97. Akira0808089 (アキラ089) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808089'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 98. Akira0808090 (アキラ090) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808090'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 99. Akira0808091 (アキラ091) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808091'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 100. Akira0808092 (アキラ092) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808092'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 101. Akira0808093 (アキラ093) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808093'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 102. Akira0808094 (アキラ094) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808094'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 103. Akira0808095 (アキラ095) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808095'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 104. Akira0808096 (アキラ096) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808096'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 105. Akira0808097 (アキラ097) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808097'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 106. Akira0808098 (アキラ098) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808098'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 107. Akira0808099 (アキラ099) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808099'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 108. Akira0808100 (アキラ100) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808100'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 109. Akira0808101 (アキラ101) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808101'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 110. Akira0808102 (アキラ102) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808102'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 111. Akira0808103 (アキラ103) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808103'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 112. Akira0808104 (アキラ104) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808104'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 113. Akira0808105 (アキラ105) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808105'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 114. Akira0808106 (アキラ106) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808106'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 115. Akira0808107 (アキラ107) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808107'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 116. Akira0808108 (アキラ108) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808108'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 117. Akira0808109 (アキラ109) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808109'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 118. Akira0808110 (アキラ110) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808110'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 119. Akira0808111 (アキラ111) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808111'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 120. Akira0808112 (アキラ112) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808112'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 121. Akira0808113 (アキラ113) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808113'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 122. Akira0808114 (アキラ114) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808114'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 123. Akira0808115 (アキラ115) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808115'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 124. Akira0808116 (アキラ116) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808116'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 125. Akira0808117 (アキラ117) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808117'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 126. Akira0808118 (アキラ118) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808118'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 127. Akira0808119 (アキラ119) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808119'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 128. Akira0808120 (アキラ120) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808120'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 129. Akira0808121 (アキラ121) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808121'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 130. Akira0808122 (アキラ122) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808122'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 131. Akira0808123 (アキラ123) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808123'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 132. Akira0808124 (アキラ124) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808124'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 133. Akira0808125 (アキラ125) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808125'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 134. Akira0808126 (アキラ126) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808126'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 135. Akira0808127 (アキラ127) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808127'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 136. Akira0808128 (アキラ128) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808128'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 137. Akira0808129 (アキラ129) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808129'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 138. Akira0808130 (アキラ130) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808130'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 139. Akira0808131 (アキラ131) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808131'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 140. Akira0808132 (アキラ132) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808132'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 141. Akira0808133 (アキラ133) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808133'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 142. Akira0808134 (アキラ134) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808134'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 143. Akira0808135 (アキラ135) の紹介者を Akira0808 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Akira0808'),
    updated_at = NOW()
WHERE user_id = 'Akira0808135'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Akira0808');

-- 144. bighand1011 (オオテヒロユキ) の紹介者を USER0a18 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'USER0a18'),
    updated_at = NOW()
WHERE user_id = 'bighand1011'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'USER0a18');

-- 145. kazukazu2 (ヤナギダカツミ2) の紹介者を kazukazu1 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'kazukazu1'),
    updated_at = NOW()
WHERE user_id = 'kazukazu2'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'kazukazu1');

-- 146. klmiklmi0204 (アラホリキミコ) の紹介者を yasui001 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'yasui001'),
    updated_at = NOW()
WHERE user_id = 'klmiklmi0204'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'yasui001');

-- 147. Mira (オオサワレイコ) の紹介者を Mickey に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'Mickey'),
    updated_at = NOW()
WHERE user_id = 'Mira'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'Mickey');

-- 148. OHTAKIYO (オオタキヨジ) の紹介者を klmiklmi0204 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'klmiklmi0204'),
    updated_at = NOW()
WHERE user_id = 'OHTAKIYO'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'klmiklmi0204');

-- 149. yatchan002 (ヤジマモトミ2) の紹介者を yatchan に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'yatchan'),
    updated_at = NOW()
WHERE user_id = 'yatchan002'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'yatchan');

-- 150. yatchan003 (ヤジマモトミ3) の紹介者を yatchan に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'yatchan'),
    updated_at = NOW()
WHERE user_id = 'yatchan003'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'yatchan');

-- 151. yatchan (ヤジマモトミ) の紹介者を itsu に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'itsu'),
    updated_at = NOW()
WHERE user_id = 'yatchan'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'itsu');

-- 152. ys0888 (サカイユカ3) の紹介者を yuka8888 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'yuka8888'),
    updated_at = NOW()
WHERE user_id = 'ys0888'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'yuka8888');

-- 153. ys8788 (サカイユカ2) の紹介者を yuka8888 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'yuka8888'),
    updated_at = NOW()
WHERE user_id = 'ys8788'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'yuka8888');

-- 154. yuka8888 (サカイユカ) の紹介者を UUUUU5 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'UUUUU5'),
    updated_at = NOW()
WHERE user_id = 'yuka8888'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'UUUUU5');

-- 155. UUUUU5 (ソウマユウゴ) の紹介者を USER0a18 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'USER0a18'),
    updated_at = NOW()
WHERE user_id = 'UUUUU5'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'USER0a18');

-- 156. UUUU55 (ソウマユウゴ2) の紹介者を UUUUU5 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'UUUUU5'),
    updated_at = NOW()
WHERE user_id = 'UUUU55'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'UUUUU5');

-- 157. TYG (ヤタガワタクミ) の紹介者を KPRO に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'KPRO'),
    updated_at = NOW()
WHERE user_id = 'TYG'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'KPRO');

-- 158. Tomo115 (ソメヤトモコ) の紹介者を hitomi0814 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'hitomi0814'),
    updated_at = NOW()
WHERE user_id = 'Tomo115'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'hitomi0814');

-- 159. to1941 (オジマタカオ) の紹介者を ko1946 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'ko1946'),
    updated_at = NOW()
WHERE user_id = 'to1941'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'ko1946');

-- 160. rinn36102 (アイタノリコ２) の紹介者を rinn361 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'rinn361'),
    updated_at = NOW()
WHERE user_id = 'rinn36102'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'rinn361');

-- 161. Zuurin123002 (イシザキイヅミ002) の紹介者を universe88 に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = 'universe88'),
    updated_at = NOW()
WHERE user_id = 'Zuurin123002'
AND EXISTS (SELECT 1 FROM users WHERE user_id = 'universe88');

-- 修正後の統計
SELECT 
    '=== 修正後の統計 ===' as status,
    COUNT(*) as total_users,
    COUNT(referrer_id) as users_with_referrer,
    COUNT(*) - COUNT(referrer_id) as users_without_referrer,
    ROUND(COUNT(referrer_id) * 100.0 / COUNT(*), 2) as referrer_percentage
FROM users
WHERE is_admin = false;

-- 修正後の1125Ritsukoの紹介統計
SELECT 
    '=== 修正後の1125Ritsukoの紹介統計 ===' as status,
    COUNT(*) as total_referrals
FROM users
WHERE referrer_id = (SELECT id FROM users WHERE user_id = '1125Ritsuko');

-- 修正後の紹介者別統計（上位20人）
SELECT 
    '=== 修正後の紹介者ランキング ===' as status,
    r.user_id as referrer_id,
    r.name as referrer_name,
    COUNT(*) as referral_count
FROM users u
JOIN users r ON u.referrer_id = r.id
WHERE u.is_admin = false
GROUP BY r.user_id, r.name
ORDER BY COUNT(*) DESC
LIMIT 20;

COMMIT;

-- 🎉 CSV完全準拠の修正完了！
SELECT '🎉 CSV完全準拠の修正完了！' as final_status;
