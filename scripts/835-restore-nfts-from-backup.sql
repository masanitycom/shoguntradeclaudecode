-- バックアップからNFTを復元

SELECT '=== バックアップからNFT復元 ===' as section;

-- 1. バックアップ内のNFTデータ確認
SELECT 'バックアップ内のNFTデータ:' as info;
SELECT 
    u.name,
    u.email,
    n.name as nft_name,
    un.purchase_date,
    un.operation_start_date,
    un.total_earned,
    un.is_active
FROM user_nfts_emergency_backup_20250730 un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
WHERE u.name IN (
    'サカイユカ3', 'ヤタガワタクミ', 'イシザキイヅミ002', 'オジマケンイチ',
    'シマダフミコ2', 'コジマアツコ4', 'コジマアツコ3', 'サカイユカ2',
    'コジマアツコ2', 'ワタヌキイチロウ', 'ハギワラサナエ', 'シマダフミコ3',
    'ヤナギダカツミ2', 'イノセアキコ', 'カタオカマキ', 'アイタノリコ２',
    'オジマタカオ', 'ソメヤトモコ', 'ソウマユウゴ2', 'シマダフミコ4',
    'ノグチチヨコ2', 'イノセミツアキ'
)
ORDER BY u.name;

-- 2. 現在のNFTテーブルと比較
SELECT '現在消失しているNFT:' as missing_nfts;
SELECT 
    u.name,
    u.email,
    'NFTなし（要復元）' as current_status
FROM users u
WHERE u.name IN (
    'サカイユカ3', 'ヤタガワタクミ', 'イシザキイヅミ002', 'オジマケンイチ',
    'シマダフミコ2', 'コジマアツコ4', 'コジマアツコ3', 'サカイユカ2',
    'コジマアツコ2', 'ワタヌキイチロウ', 'ハギワラサナエ', 'シマダフミコ3',
    'ヤナギダカツミ2', 'イノセアキコ', 'カタオカマキ', 'アイタノリコ２',
    'オジマタカオ', 'ソメヤトモコ', 'ソウマユウゴ2', 'シマダフミコ4',
    'ノグチチヨコ2', 'イノセミツアキ'
)
AND NOT EXISTS (
    SELECT 1 FROM user_nfts un 
    WHERE un.user_id = u.id AND un.is_active = true
);

-- 3. NFT復元SQL
SELECT 'NFT復元実行:' as restoration;
INSERT INTO user_nfts (
    id,
    user_id,
    nft_id,
    purchase_date,
    operation_start_date,
    is_active,
    total_earned,
    created_at,
    updated_at
)
SELECT 
    backup.id,
    backup.user_id,
    backup.nft_id,
    backup.purchase_date,
    backup.operation_start_date,
    backup.is_active,
    backup.total_earned,
    backup.created_at,
    NOW() as updated_at
FROM user_nfts_emergency_backup_20250730 backup
JOIN users u ON backup.user_id = u.id
WHERE u.name IN (
    'サカイユカ3', 'ヤタガワタクミ', 'イシザキイヅミ002', 'オジマケンイチ',
    'シマダフミコ2', 'コジマアツコ4', 'コジマアツコ3', 'サカイユカ2',
    'コジマアツコ2', 'ワタヌキイチロウ', 'ハギワラサナエ', 'シマダフミコ3',
    'ヤナギダカツミ2', 'イノセアキコ', 'カタオカマキ', 'アイタノリコ２',
    'オジマタカオ', 'ソメヤトモコ', 'ソウマユウゴ2', 'シマダフミコ4',
    'ノグチチヨコ2', 'イノセミツアキ'
)
AND NOT EXISTS (
    SELECT 1 FROM user_nfts existing 
    WHERE existing.user_id = backup.user_id 
    AND existing.nft_id = backup.nft_id
)
ON CONFLICT (id) DO NOTHING;

-- 4. 復元結果確認
SELECT '復元後のNFT状況:' as after_restoration;
SELECT 
    u.name,
    u.email,
    n.name as nft_name,
    un.purchase_date,
    un.operation_start_date,
    un.total_earned,
    'NFT復元完了' as status
FROM users u
JOIN user_nfts un ON u.id = un.user_id
JOIN nfts n ON un.nft_id = n.id
WHERE u.name IN (
    'サカイユカ3', 'ヤタガワタクミ', 'イシザキイヅミ002', 'オジマケンイチ',
    'シマダフミコ2', 'コジマアツコ4', 'コジマアツコ3', 'サカイユカ2',
    'コジマアツコ2', 'ワタヌキイチロウ', 'ハギワラサナエ', 'シマダフミコ3',
    'ヤナギダカツミ2', 'イノセアキコ', 'カタオカマキ', 'アイタノリコ２',
    'オジマタカオ', 'ソメヤトモコ', 'ソウマユウゴ2', 'シマダフミコ4',
    'ノグチチヨコ2', 'イノセミツアキ'
)
AND un.is_active = true
ORDER BY u.name;

SELECT '=== NFT復元完了 ===' as status;