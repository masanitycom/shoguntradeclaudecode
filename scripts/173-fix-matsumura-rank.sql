-- マツムラヒロエさんのMLMランクを正しく修正

-- 1. 現在の状況確認
SELECT 
    u.name,
    u.user_id,
    urh.rank_level,
    urh.rank_name,
    urh.organization_volume,
    urh.is_current
FROM users u
LEFT JOIN user_rank_history urh ON u.id = urh.user_id
WHERE u.user_id = 'm2332h' AND urh.is_current = true;

-- 2. 正しいランクに修正（組織ボリュームが0なので「なし」が正しい）
UPDATE user_rank_history 
SET is_current = false
WHERE user_id = (SELECT id FROM users WHERE user_id = 'm2332h')
  AND is_current = true;

-- 3. 正しいランク履歴を追加
INSERT INTO user_rank_history (
    user_id,
    rank_level,
    rank_name,
    organization_volume,
    max_line_volume,
    other_lines_volume,
    qualified_date,
    is_current,
    created_at,
    updated_at
)
SELECT 
    id,
    0,
    'なし',
    0,
    0,
    0,
    CURRENT_DATE,
    true,
    NOW(),
    NOW()
FROM users 
WHERE user_id = 'm2332h';

-- 4. 修正結果確認
SELECT 
    u.name,
    u.user_id,
    urh.rank_level,
    urh.rank_name,
    urh.organization_volume,
    urh.qualified_date,
    urh.is_current,
    '修正完了: NFT5000ドル保有だが組織ボリューム0のため「なし」ランクが正しい' as status
FROM users u
LEFT JOIN user_rank_history urh ON u.id = urh.user_id
WHERE u.user_id = 'm2332h' AND urh.is_current = true;
