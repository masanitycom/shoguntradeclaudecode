-- mlm_ranksテーブルを実際の構造に合わせて修正（全必須カラム対応）

-- 1. 既存データをクリア
DELETE FROM mlm_ranks;

-- 2. 実際の構造に合わせてMLMランクデータを挿入（全必須カラムに値を設定）
INSERT INTO mlm_ranks (
    rank_level,
    rank_name,
    required_nft_value,
    required_organization_size,
    max_line_size,
    other_lines_volume,
    distribution_rate,
    bonus_rate,
    bonus_percentage,
    created_at
) VALUES 
(0, 'なし', 0, 0, 0, 0, 0.0000, 0.0000, 0.00, NOW()),
(1, '足軽', 1000, 1000, 0, 0, 0.4500, 0.4500, 45.00, NOW()),
(2, '武将', 1000, 3000, 1500, 1500, 0.2500, 0.2500, 25.00, NOW()),
(3, '代官', 1000, 5000, 2500, 2500, 0.1000, 0.1000, 10.00, NOW()),
(4, '奉行', 1000, 10000, 5000, 5000, 0.0600, 0.0600, 6.00, NOW()),
(5, '老中', 1000, 50000, 25000, 25000, 0.0500, 0.0500, 5.00, NOW()),
(6, '大老', 1000, 100000, 50000, 50000, 0.0400, 0.0400, 4.00, NOW()),
(7, '大名', 1000, 300000, 150000, 150000, 0.0300, 0.0300, 3.00, NOW()),
(8, '将軍', 1000, 600000, 500000, 100000, 0.0200, 0.0200, 2.00, NOW());

-- 3. 結果確認
SELECT 
    '✅ MLMランク設定完了' as status,
    rank_level,
    rank_name,
    required_nft_value,
    required_organization_size,
    max_line_size,
    other_lines_volume,
    distribution_rate * 100 as distribution_percent,
    bonus_rate * 100 as bonus_rate_percent,
    bonus_percentage
FROM mlm_ranks 
ORDER BY rank_level;

SELECT '✅ MLMランクテーブル修正完了（全必須カラム対応）' as final_status;
