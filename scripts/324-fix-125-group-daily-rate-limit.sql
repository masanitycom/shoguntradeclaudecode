-- 1.25%グループの日利上限を1.3%から1.25%に修正

-- 現在の状態を確認
SELECT 
    id,
    group_name,
    daily_rate_limit,
    daily_rate_limit * 100 as daily_rate_percent,
    description
FROM daily_rate_groups 
WHERE group_name = '1.25%グループ';

-- 1.25%グループの日利上限を修正
UPDATE daily_rate_groups 
SET 
    daily_rate_limit = 0.0125,
    description = '日利上限1.25%のNFTグループ'
WHERE group_name = '1.25%グループ' 
  AND daily_rate_limit = 0.013;

-- 修正後の状態を確認
SELECT 
    id,
    group_name,
    daily_rate_limit,
    daily_rate_limit * 100 as daily_rate_percent,
    description
FROM daily_rate_groups 
WHERE group_name = '1.25%グループ';

-- 1.25%の日利上限を持つNFTを確認
SELECT 
    n.id,
    n.name,
    n.daily_rate_limit,
    n.daily_rate_limit * 100 as daily_rate_percent
FROM nfts n
WHERE n.daily_rate_limit = 0.0125
ORDER BY n.id;

-- 修正完了メッセージ
-- 1.25%グループの日利上限を1.3%から1.25%に修正しました
