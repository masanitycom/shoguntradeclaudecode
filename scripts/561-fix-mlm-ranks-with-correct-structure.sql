-- mlm_ranksテーブルを実際の構造に合わせて修正

-- 1. 既存データをクリア
DELETE FROM mlm_ranks;

-- 2. 実際の構造に合わせてMLMランクデータを挿入（存在するカラムのみ使用）
INSERT INTO mlm_ranks (
    rank_level,
    rank_name,
    required_nft_value,
    distribution_rate,
    bonus_rate,
    created_at
) VALUES 
(0, 'なし', 0, 0.0000, 0.0000, NOW()),
(1, '足軽', 1000, 0.4500, 0.4500, NOW()),
(2, '武将', 1000, 0.2500, 0.2500, NOW()),
(3, '代官', 1000, 0.1000, 0.1000, NOW()),
(4, '奉行', 1000, 0.0600, 0.0600, NOW()),
(5, '老中', 1000, 0.0500, 0.0500, NOW()),
(6, '大老', 1000, 0.0400, 0.0400, NOW()),
(7, '大名', 1000, 0.0300, 0.0300, NOW()),
(8, '将軍', 1000, 0.0200, 0.0200, NOW());

-- 3. 結果確認
SELECT 
    '✅ MLMランク設定完了' as status,
    rank_level,
    rank_name,
    required_nft_value,
    distribution_rate * 100 as distribution_percent,
    bonus_rate * 100 as bonus_percent
FROM mlm_ranks 
ORDER BY rank_level;

SELECT '✅ MLMランクテーブル修正完了' as final_status;
