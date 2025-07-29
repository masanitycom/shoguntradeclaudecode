-- 管理画面設定週利と実際データの不整合を修正

-- 1. 現在の問題状況を確認
SELECT 
    '🚨 現在の問題確認' as info,
    u.name as ユーザー名,
    u.user_id,
    n.name as nft名,
    un.current_investment as 投資額,
    un.total_earned as 現在の収益,
    ROUND((un.total_earned / un.current_investment * 100)::numeric, 2) as 現在の収益率パーセント,
    '本来は約11.12%あるべき' as 期待値
FROM users u
JOIN user_nfts un ON u.id = un.user_id
JOIN nfts n ON un.nft_id = n.id
WHERE u.user_id IN ('pigret10', 'momochan', 'klmiklmi0204', 'katsuji1')
ORDER BY u.name;

-- 2. 管理画面設定値を確認
SELECT 
    '📋 管理画面設定値確認' as info,
    gwr.week_start_date as 週開始日,
    drg.group_name,
    gwr.weekly_rate * 100 as 設定週利パーセント,
    gwr.monday_rate * 100 as 月曜,
    gwr.tuesday_rate * 100 as 火曜,
    gwr.wednesday_rate * 100 as 水曜,
    gwr.thursday_rate * 100 as 木曜,
    gwr.friday_rate * 100 as 金曜
FROM group_weekly_rates gwr
JOIN daily_rate_groups drg ON gwr.group_id = drg.id
WHERE gwr.week_start_date >= '2025-02-10'
ORDER BY gwr.week_start_date;

-- 3. 対象ユーザーの現在の日利報酬を確認
SELECT 
    '💰 現在の日利報酬状況' as info,
    u.name as ユーザー名,
    u.user_id,
    COUNT(dr.id) as 報酬回数,
    SUM(dr.reward_amount) as 報酬総額,
    MIN(dr.reward_date) as 最初の報酬日,
    MAX(dr.reward_date) as 最後の報酬日
FROM users u
JOIN user_nfts un ON u.id = un.user_id
LEFT JOIN daily_rewards dr ON un.id = dr.user_nft_id
WHERE u.user_id IN ('pigret10', 'momochan', 'klmiklmi0204', 'katsuji1')
GROUP BY u.name, u.user_id
ORDER BY u.name;

-- 4. 既存の間違った報酬を削除
DELETE FROM daily_rewards 
WHERE user_nft_id IN (
    SELECT un.id 
    FROM user_nfts un 
    JOIN users u ON un.user_id = u.id 
    WHERE u.user_id IN ('pigret10', 'momochan', 'klmiklmi0204', 'katsuji1')
);

-- 5. 正しい報酬を再計算・挿入（管理画面設定値通り）
-- 2/10週（3.12%）
INSERT INTO daily_rewards (
    user_nft_id, user_id, nft_id, reward_date, reward_amount, daily_rate, 
    investment_amount, week_start_date, calculation_date, is_claimed, created_at
)
SELECT 
    un.id,
    un.user_id,
    un.nft_id,
    '2025-02-10'::date,
    un.current_investment * 0.00624, -- 月曜 0.624%
    0.00624,
    un.current_investment,
    '2025-02-10'::date,
    CURRENT_DATE,
    false,
    NOW()
FROM user_nfts un
JOIN users u ON un.user_id = u.id
WHERE u.user_id IN ('pigret10', 'momochan', 'klmiklmi0204', 'katsuji1');

INSERT INTO daily_rewards (
    user_nft_id, user_id, nft_id, reward_date, reward_amount, daily_rate, 
    investment_amount, week_start_date, calculation_date, is_claimed, created_at
)
SELECT 
    un.id,
    un.user_id,
    un.nft_id,
    '2025-02-11'::date,
    un.current_investment * 0.00624, -- 火曜 0.624%
    0.00624,
    un.current_investment,
    '2025-02-10'::date,
    CURRENT_DATE,
    false,
    NOW()
FROM user_nfts un
JOIN users u ON un.user_id = u.id
WHERE u.user_id IN ('pigret10', 'momochan', 'klmiklmi0204', 'katsuji1');

INSERT INTO daily_rewards (
    user_nft_id, user_id, nft_id, reward_date, reward_amount, daily_rate, 
    investment_amount, week_start_date, calculation_date, is_claimed, created_at
)
SELECT 
    un.id,
    un.user_id,
    un.nft_id,
    '2025-02-12'::date,
    un.current_investment * 0.00624, -- 水曜 0.624%
    0.00624,
    un.current_investment,
    '2025-02-10'::date,
    CURRENT_DATE,
    false,
    NOW()
FROM user_nfts un
JOIN users u ON un.user_id = u.id
WHERE u.user_id IN ('pigret10', 'momochan', 'klmiklmi0204', 'katsuji1');

INSERT INTO daily_rewards (
    user_nft_id, user_id, nft_id, reward_date, reward_amount, daily_rate, 
    investment_amount, week_start_date, calculation_date, is_claimed, created_at
)
SELECT 
    un.id,
    un.user_id,
    un.nft_id,
    '2025-02-13'::date,
    un.current_investment * 0.00624, -- 木曜 0.624%
    0.00624,
    un.current_investment,
    '2025-02-10'::date,
    CURRENT_DATE,
    false,
    NOW()
FROM user_nfts un
JOIN users u ON un.user_id = u.id
WHERE u.user_id IN ('pigret10', 'momochan', 'klmiklmi0204', 'katsuji1');

INSERT INTO daily_rewards (
    user_nft_id, user_id, nft_id, reward_date, reward_amount, daily_rate, 
    investment_amount, week_start_date, calculation_date, is_claimed, created_at
)
SELECT 
    un.id,
    un.user_id,
    un.nft_id,
    '2025-02-14'::date,
    un.current_investment * 0.00624, -- 金曜 0.624%
    0.00624,
    un.current_investment,
    '2025-02-10'::date,
    CURRENT_DATE,
    false,
    NOW()
FROM user_nfts un
JOIN users u ON un.user_id = u.id
WHERE u.user_id IN ('pigret10', 'momochan', 'klmiklmi0204', 'katsuji1');

-- 2/17週（3.56%）の報酬も同様に挿入
INSERT INTO daily_rewards (
    user_nft_id, user_id, nft_id, reward_date, reward_amount, daily_rate, 
    investment_amount, week_start_date, calculation_date, is_claimed, created_at
)
SELECT 
    un.id,
    un.user_id,
    un.nft_id,
    dates.reward_date,
    un.current_investment * 0.00712, -- 0.712%/日
    0.00712,
    un.current_investment,
    '2025-02-17'::date,
    CURRENT_DATE,
    false,
    NOW()
FROM user_nfts un
JOIN users u ON un.user_id = u.id
CROSS JOIN (
    SELECT '2025-02-17'::date as reward_date UNION
    SELECT '2025-02-18'::date UNION
    SELECT '2025-02-19'::date UNION
    SELECT '2025-02-20'::date UNION
    SELECT '2025-02-21'::date
) dates
WHERE u.user_id IN ('pigret10', 'momochan', 'klmiklmi0204', 'katsuji1');

-- 2/24週（2.50%）の報酬
INSERT INTO daily_rewards (
    user_nft_id, user_id, nft_id, reward_date, reward_amount, daily_rate, 
    investment_amount, week_start_date, calculation_date, is_claimed, created_at
)
SELECT 
    un.id,
    un.user_id,
    un.nft_id,
    dates.reward_date,
    un.current_investment * 0.005, -- 0.5%/日
    0.005,
    un.current_investment,
    '2025-02-24'::date,
    CURRENT_DATE,
    false,
    NOW()
FROM user_nfts un
JOIN users u ON un.user_id = u.id
CROSS JOIN (
    SELECT '2025-02-24'::date as reward_date UNION
    SELECT '2025-02-25'::date UNION
    SELECT '2025-02-26'::date UNION
    SELECT '2025-02-27'::date UNION
    SELECT '2025-02-28'::date
) dates
WHERE u.user_id IN ('pigret10', 'momochan', 'klmiklmi0204', 'katsuji1');

-- 3/3週（0.38%）の報酬
INSERT INTO daily_rewards (
    user_nft_id, user_id, nft_id, reward_date, reward_amount, daily_rate, 
    investment_amount, week_start_date, calculation_date, is_claimed, created_at
)
SELECT 
    un.id,
    un.user_id,
    un.nft_id,
    dates.reward_date,
    un.current_investment * 0.00076, -- 0.076%/日
    0.00076,
    un.current_investment,
    '2025-03-03'::date,
    CURRENT_DATE,
    false,
    NOW()
FROM user_nfts un
JOIN users u ON un.user_id = u.id
CROSS JOIN (
    SELECT '2025-03-03'::date as reward_date UNION
    SELECT '2025-03-04'::date UNION
    SELECT '2025-03-05'::date UNION
    SELECT '2025-03-06'::date UNION
    SELECT '2025-03-07'::date
) dates
WHERE u.user_id IN ('pigret10', 'momochan', 'klmiklmi0204', 'katsuji1');

-- 3/10週（1.58%）の報酬
INSERT INTO daily_rewards (
    user_nft_id, user_id, nft_id, reward_date, reward_amount, daily_rate, 
    investment_amount, week_start_date, calculation_date, is_claimed, created_at
)
SELECT 
    un.id,
    un.user_id,
    un.nft_id,
    dates.reward_date,
    un.current_investment * 0.00316, -- 0.316%/日
    0.00316,
    un.current_investment,
    '2025-03-10'::date,
    CURRENT_DATE,
    false,
    NOW()
FROM user_nfts un
JOIN users u ON un.user_id = u.id
CROSS JOIN (
    SELECT '2025-03-10'::date as reward_date UNION
    SELECT '2025-03-11'::date UNION
    SELECT '2025-03-12'::date UNION
    SELECT '2025-03-13'::date UNION
    SELECT '2025-03-14'::date
) dates
WHERE u.user_id IN ('pigret10', 'momochan', 'klmiklmi0204', 'katsuji1');

-- 6. user_nftsのtotal_earnedを正しく更新
UPDATE user_nfts 
SET total_earned = COALESCE((
    SELECT SUM(dr.reward_amount)
    FROM daily_rewards dr 
    WHERE dr.user_nft_id = user_nfts.id
), 0),
updated_at = NOW()
WHERE id IN (
    SELECT un.id 
    FROM user_nfts un 
    JOIN users u ON un.user_id = u.id 
    WHERE u.user_id IN ('pigret10', 'momochan', 'klmiklmi0204', 'katsuji1')
);

-- 7. 修正結果を確認
SELECT 
    '✅ 修正後の結果確認' as info,
    u.name as ユーザー名,
    u.user_id,
    n.name as nft名,
    un.current_investment as 投資額,
    un.total_earned as 修正後収益,
    ROUND((un.total_earned / un.current_investment * 100)::numeric, 4) as 修正後収益率パーセント,
    COUNT(dr.id) as 報酬回数
FROM users u
JOIN user_nfts un ON u.id = un.user_id
JOIN nfts n ON un.nft_id = n.id
LEFT JOIN daily_rewards dr ON un.id = dr.user_nft_id
WHERE u.user_id IN ('pigret10', 'momochan', 'klmiklmi0204', 'katsuji1')
GROUP BY u.name, u.user_id, n.name, un.current_investment, un.total_earned
ORDER BY u.name;

-- 8. 週別詳細確認
SELECT 
    '📊 週別詳細確認' as info,
    u.name as ユーザー名,
    dr.week_start_date as 週開始日,
    SUM(dr.reward_amount) as 週間報酬,
    COUNT(dr.id) as 報酬日数,
    AVG(dr.daily_rate) * 100 as 平均日利パーセント
FROM users u
JOIN user_nfts un ON u.id = un.user_id
JOIN daily_rewards dr ON un.id = dr.user_nft_id
WHERE u.user_id IN ('pigret10', 'momochan', 'klmiklmi0204', 'katsuji1')
GROUP BY u.name, dr.week_start_date
ORDER BY u.name, dr.week_start_date;
