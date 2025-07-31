-- 緊急：実ユーザー保護とNFT復旧

SELECT '=== 緊急：実ユーザー保護 ===' as section;

-- 1. NFTが消失した実ユーザーの確認（2025/6/26登録の実ユーザー）
SELECT 'NFTが消失した実ユーザー:' as critical_users;
SELECT 
    u.id,
    u.name,
    u.user_id,
    u.email,
    u.created_at,
    '要NFT復旧' as action_needed
FROM users u
WHERE u.created_at = '2025-06-26 04:20:09.784831+00'
  AND u.name IN (
    'サカイユカ3', 'ヤタガワタクミ', 'イシザキイヅミ002', 'オジマケンイチ',
    'シマダフミコ2', 'コジマアツコ4', 'コジマアツコ3', 'サカイユカ2',
    'コジマアツコ2', 'ワタヌキイチロウ', 'ハギワラサナエ', 'シマダフミコ3',
    'ヤナギダカツミ2', 'イノセアキコ', 'カタオカマキ', 'アイタノリコ２',
    'オジマタカオ', 'ソメヤトモコ', 'ソウマユウゴ2', 'シマダフミコ4',
    'ノグチチヨコ2', 'イノセミツアキ'
  )
ORDER BY u.name;

-- 2. _authサフィックス問題の確認
SELECT '_authサフィックス問題:' as auth_suffix_issue;
SELECT 
    u.id,
    u.name,
    u.user_id,
    u.email,
    u.created_at,
    CASE 
        WHEN u.name = 'ハギワラサナエ' AND u.user_id = 'mook0214_auth' THEN '削除対象（_auth付き重複）'
        WHEN u.name = 'イシザキイヅミ002' AND u.user_id = 'Zuurin123_auth' THEN '削除対象（_auth付き重複）'
        WHEN u.name = 'ハギワラサナエ' AND u.user_id = 'mook0214' AND u.email = 'Tokusana371@gmail.com' THEN '削除対象（大文字メール重複）'
        WHEN u.name = 'ハギワラサナエ' AND u.user_id = 'mook0214' AND u.email = 'tokusana371@gmail.com' THEN '正規ユーザー（保持）'
        WHEN u.name = 'イシザキイヅミ002' AND u.user_id = 'Zuurin123002' THEN '正規ユーザー（保持）'
        ELSE '要確認'
    END as status
FROM users u
WHERE (u.name = 'ハギワラサナエ' OR u.name = 'イシザキイヅミ002')
ORDER BY u.name, u.created_at;

-- 3. 明確なテストユーザーのみ（ユーザー系とUP系のみ）
SELECT '削除可能な明確なテストユーザー:' as safe_test_users;
SELECT 
    u.id,
    u.name,
    u.email,
    u.user_id,
    u.phone,
    '削除可能' as status
FROM users u
LEFT JOIN user_nfts un ON u.id = un.user_id AND un.is_active = true
WHERE un.user_id IS NULL
  AND u.total_investment = 0
  AND u.total_earned = 0
  AND (
    u.name LIKE 'ユーザー%'
    OR u.name LIKE '%UP'
    OR u.phone = '000-0000-0000'
  )
  AND u.name NOT IN (  -- 実ユーザー除外
    'サカイユカ3', 'ヤタガワタクミ', 'イシザキイヅミ002', 'オジマケンイチ',
    'シマダフミコ2', 'コジマアツコ4', 'コジマアツコ3', 'サカイユカ2',
    'コジマアツコ2', 'ワタヌキイチロウ', 'ハギワラサナエ', 'シマダフミコ3',
    'ヤナギダカツミ2', 'イノセアキコ', 'カタオカマキ', 'アイタノリコ２',
    'オジマタカオ', 'ソメヤトモコ', 'ソウマユウゴ2', 'シマダフミコ4',
    'ノグチチヨコ2', 'イノセミツアキ'
  )
ORDER BY u.created_at;

-- 4. 復旧が必要なアクション
SELECT 'Required Actions:' as actions;
SELECT '1. 実ユーザーのNFT復旧（22人）' as action1
UNION ALL
SELECT '2. _auth付き重複ユーザーの削除' as action2
UNION ALL
SELECT '3. 大文字メール重複ユーザーの削除' as action3
UNION ALL
SELECT '4. 明確なテストユーザーのみ削除' as action4;

SELECT '=== 緊急対応計画完了 ===' as status;