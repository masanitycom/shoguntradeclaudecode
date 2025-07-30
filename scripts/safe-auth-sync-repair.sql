-- 安全なauth.usersとpublic.usersの同期修復
-- 本番環境用: データを壊さずに修正

-- === PHASE 1: バックアップ用テーブル作成 ===
CREATE TABLE IF NOT EXISTS users_backup_20250730 AS 
SELECT * FROM users;

CREATE TABLE IF NOT EXISTS user_nfts_backup_20250730 AS 
SELECT * FROM user_nfts;

-- === PHASE 2: 同期エラーの詳細確認 ===
-- 修正前の状態を記録
SELECT 'BEFORE REPAIR - Auth Users' as status;
SELECT id, email, created_at FROM auth.users 
WHERE email IN ('kappystone.516@gmail.com', 'tokusana371@gmail.com');

SELECT 'BEFORE REPAIR - Public Users' as status;
SELECT id, email, name, user_id FROM users 
WHERE email IN ('kappystone.516@gmail.com', 'phu55papa@gmail.com');

-- === PHASE 3: 修正方針の決定 ===
-- kappystone.516@gmail.com の場合:
-- auth.users ID: 3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c
-- public.users ID: 53b6f22b-5348-4fe2-a969-b522655e8a4a
-- 
-- 修正方針: public.usersのIDをauth.usersに合わせる
-- なぜなら: auth.usersが認証の基準であり、NFTデータは移行可能

-- === PHASE 4: 実際の修正実行（コメントアウト状態で準備） ===
/*
-- ステップ1: kappystone.516@gmail.com の修正
-- 1-1. NFTデータを一時的に別のIDに移動
UPDATE user_nfts 
SET user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c'
WHERE user_id = '53b6f22b-5348-4fe2-a969-b522655e8a4a';

-- 1-2. 古いpublic.usersレコードを削除
DELETE FROM users WHERE id = '53b6f22b-5348-4fe2-a969-b522655e8a4a';

-- 1-3. 正しいIDで新しいpublic.usersレコードを作成
INSERT INTO users (
    id, name, email, user_id, phone, referrer_id, 
    usdt_address, wallet_type, is_admin, created_at, updated_at
) VALUES (
    '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c',
    'イシジマカツヒロ',
    'kappystone.516@gmail.com', 
    'PHULIKE',
    NULL, -- phone は後で設定
    NULL, -- referrer_id は後で設定
    NULL, -- usdt_address は後で設定  
    'その他',
    false,
    NOW(),
    NOW()
);

-- ステップ2: tokusana371@gmail.com の修正
-- 2-1. 存在しないpublic.usersレコードを作成
INSERT INTO users (
    id, name, email, user_id, phone, referrer_id,
    usdt_address, wallet_type, is_admin, created_at, updated_at
) VALUES (
    '359f44c4-507e-4867-b25d-592f98962145',
    '未設定ユーザー', -- 仮の名前
    'tokusana371@gmail.com',
    'tokusana371', -- 仮のuser_id
    NULL,
    NULL,
    NULL,
    'その他',
    false,
    NOW(),
    NOW()
);
*/

-- === PHASE 5: 修正後の検証クエリ ===
-- これらのクエリで修正結果を確認
/*
SELECT 'AFTER REPAIR - Verification' as status;

-- 認証とpublicの一致確認
SELECT 
    au.id as auth_id,
    au.email as auth_email,
    pu.id as public_id, 
    pu.email as public_email,
    pu.name as public_name,
    CASE WHEN au.id = pu.id THEN 'SYNCED' ELSE 'ERROR' END as sync_status
FROM auth.users au
JOIN users pu ON au.email = pu.email
WHERE au.email IN ('kappystone.516@gmail.com', 'tokusana371@gmail.com');

-- NFTデータの整合性確認
SELECT 
    un.user_id,
    u.name,
    u.email,
    n.name as nft_name,
    un.current_investment
FROM user_nfts un
JOIN users u ON un.user_id = u.id  
JOIN nfts n ON un.nft_id = n.id
WHERE u.email IN ('kappystone.516@gmail.com', 'tokusana371@gmail.com');
*/