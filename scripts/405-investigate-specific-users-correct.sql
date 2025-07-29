-- 指定されたユーザーの詳細調査（全テーブル構造確認後の正確版）
-- 実行前に scripts/404-check-all-table-structures.sql を実行して構造を確認すること

-- 対象ユーザー特定用の共通テーブル式
WITH target_users AS (
    SELECT id, user_id, name, email
    FROM users 
    WHERE user_id IN ('pigret10', 'momochan', 'klmiklmi0204', 'katsuji1')
       OR email IN ('c781opigret@gmail.com', 'momokoshimizu0406@gmail.com', 'kimiko.0204.1357@gmail.com', 'jzs01473@gmail.com')
       OR name IN ('クリハラチアキ', 'コシミズモモ', 'アラホリキミコ', 'ムロツキカツジ')
)

-- 1. 対象ユーザーの基本情報確認
SELECT 
    '👥 対象ユーザー基本情報' as info,
    u.id as user_uuid,
    u.user_id,
    u.name as ユーザー名,
    u.email,
    u.phone,
    u.is_admin,
    u.created_at as 登録日,
    u.referrer_id,
    ref.name as 紹介者名,
    ref.user_id as 紹介者ID,
    u.my_referral_code as 自分の紹介コード,
    u.usdt_address,
    u.wallet_type
FROM target_users tu
JOIN users u ON tu.id = u.id
LEFT JOIN users ref ON u.referrer_id = ref.id
ORDER BY u.created_at;
