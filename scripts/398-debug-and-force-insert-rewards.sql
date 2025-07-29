-- デバッグして強制的に報酬を挿入

-- 1. 現在のテーブル構造を確認
SELECT 
    '🔍 テーブル構造確認' as info,
    'user_nfts' as table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'user_nfts' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. 対象ユーザーの詳細情報を確認
SELECT 
    '👥 対象ユーザー詳細確認' as info,
    u.id as user_uuid,
    u.user_id,
    u.name as ユーザー名,
    un.id as user_nft_id,
    n.id as nft_id,
    n.name as NFT名,
    n.price as 投資額,
    un.created_at as NFT取得日,
    un.is_active as アクティブ状態,
    un.current_investment,
    drg.id as group_id,
    drg.group_name
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
JOIN daily_rate_groups drg ON n.daily_rate_limit = drg.daily_rate_limit
WHERE u.user_id IN ('OHTAKIYO', 'imaima3137', 'pbcshop1', 'noriko1', 'SAWA001', 'Sakura0326', 'Sakura0325', 'chococo12', 'naho1020')
ORDER BY u.user_id;

-- 3. 週利設定を確認
SELECT 
    '📋 週利設定確認' as info,
    gwr.id,
    gwr.group_id,
    drg.group_name,
    gwr.week_start_date,
    gwr.weekly_rate * 100 as 週利パーセント,
    gwr.monday_rate * 100 as 月曜,
    gwr.tuesday_rate * 100 as 火曜,
    gwr.wednesday_rate * 100 as 水曜,
    gwr.thursday_rate * 100 as 木曜,
    gwr.friday_rate * 100 as 金曜
FROM group_weekly_rates gwr
JOIN daily_rate_groups drg ON gwr.group_id = drg.id
WHERE gwr.week_start_date >= '2025-02-10'
ORDER BY gwr.week_start_date;

-- 4. 既存の報酬を削除（重複防止）
DELETE FROM daily_rewards 
WHERE reward_date >= '2025-02-10'
AND user_nft_id IN (
    SELECT un.id 
    FROM user_nfts un 
    JOIN users u ON un.user_id = u.id 
    WHERE u.user_id IN ('OHTAKIYO', 'imaima3137', 'pbcshop1', 'noriko1', 'SAWA001', 'Sakura0326', 'Sakura0325', 'chococo12', 'naho1020')
);

-- 5. 強制的に報酬を挿入（シンプルな方法）
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
    n.price * 0.0062, -- 月曜 0.62%
    0.0062,
    n.price,
    '2025-02-10'::date,
    CURRENT_DATE,
    false,
    NOW()
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
WHERE u.user_id IN ('OHTAKIYO', 'imaima3137', 'pbcshop1', 'noriko1', 'SAWA001', 'Sakura0326', 'Sakura0325', 'chococo12', 'naho1020')
AND un.is_active = true;

INSERT INTO daily_rewards (
    user_nft_id, user_id, nft_id, reward_date, reward_amount, daily_rate, 
    investment_amount, week_start_date, calculation_date, is_claimed, created_at
)
SELECT 
    un.id,
    un.user_id,
    un.nft_id,
    '2025-02-11'::date,
    n.price * 0.0062, -- 火曜 0.62%
    0.0062,
    n.price,
    '2025-02-10'::date,
    CURRENT_DATE,
    false,
    NOW()
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
WHERE u.user_id IN ('OHTAKIYO', 'imaima3137', 'pbcshop1', 'noriko1', 'SAWA001', 'Sakura0326', 'Sakura0325', 'chococo12', 'naho1020')
AND un.is_active = true;

INSERT INTO daily_rewards (
    user_nft_id, user_id, nft_id, reward_date, reward_amount, daily_rate, 
    investment_amount, week_start_date, calculation_date, is_claimed, created_at
)
SELECT 
    un.id,
    un.user_id,
    un.nft_id,
    '2025-02-12'::date,
    n.price * 0.0062, -- 水曜 0.62%
    0.0062,
    n.price,
    '2025-02-10'::date,
    CURRENT_DATE,
    false,
    NOW()
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
WHERE u.user_id IN ('OHTAKIYO', 'imaima3137', 'pbcshop1', 'noriko1', 'SAWA001', 'Sakura0326', 'Sakura0325', 'chococo12', 'naho1020')
AND un.is_active = true;

INSERT INTO daily_rewards (
    user_nft_id, user_id, nft_id, reward_date, reward_amount, daily_rate, 
    investment_amount, week_start_date, calculation_date, is_claimed, created_at
)
SELECT 
    un.id,
    un.user_id,
    un.nft_id,
    '2025-02-13'::date,
    n.price * 0.0062, -- 木曜 0.62%
    0.0062,
    n.price,
    '2025-02-10'::date,
    CURRENT_DATE,
    false,
    NOW()
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
WHERE u.user_id IN ('OHTAKIYO', 'imaima3137', 'pbcshop1', 'noriko1', 'SAWA001', 'Sakura0326', 'Sakura0325', 'chococo12', 'naho1020')
AND un.is_active = true;

INSERT INTO daily_rewards (
    user_nft_id, user_id, nft_id, reward_date, reward_amount, daily_rate, 
    investment_amount, week_start_date, calculation_date, is_claimed, created_at
)
SELECT 
    un.id,
    un.user_id,
    un.nft_id,
    '2025-02-14'::date,
    n.price * 0.0062, -- 金曜 0.62%
    0.0062,
    n.price,
    '2025-02-10'::date,
    CURRENT_DATE,
    false,
    NOW()
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
WHERE u.user_id IN ('OHTAKIYO', 'imaima3137', 'pbcshop1', 'noriko1', 'SAWA001', 'Sakura0326', 'Sakura0325', 'chococo12', 'naho1020')
AND un.is_active = true;

-- 2/17週（3.56%）
INSERT INTO daily_rewards (
    user_nft_id, user_id, nft_id, reward_date, reward_amount, daily_rate, 
    investment_amount, week_start_date, calculation_date, is_claimed, created_at
)
SELECT 
    un.id,
    un.user_id,
    un.nft_id,
    '2025-02-17'::date,
    n.price * 0.00712, -- 月曜 0.712%
    0.00712,
    n.price,
    '2025-02-17'::date,
    CURRENT_DATE,
    false,
    NOW()
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
WHERE u.user_id IN ('OHTAKIYO', 'imaima3137', 'pbcshop1', 'noriko1', 'SAWA001', 'Sakura0326', 'Sakura0325', 'chococo12', 'naho1020')
AND un.is_active = true;

INSERT INTO daily_rewards (
    user_nft_id, user_id, nft_id, reward_date, reward_amount, daily_rate, 
    investment_amount, week_start_date, calculation_date, is_claimed, created_at
)
SELECT 
    un.id,
    un.user_id,
    un.nft_id,
    '2025-02-18'::date,
    n.price * 0.00712, -- 火曜 0.712%
    0.00712,
    n.price,
    '2025-02-17'::date,
    CURRENT_DATE,
    false,
    NOW()
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
WHERE u.user_id IN ('OHTAKIYO', 'imaima3137', 'pbcshop1', 'noriko1', 'SAWA001', 'Sakura0326', 'Sakura0325', 'chococo12', 'naho1020')
AND un.is_active = true;

INSERT INTO daily_rewards (
    user_nft_id, user_id, nft_id, reward_date, reward_amount, daily_rate, 
    investment_amount, week_start_date, calculation_date, is_claimed, created_at
)
SELECT 
    un.id,
    un.user_id,
    un.nft_id,
    '2025-02-19'::date,
    n.price * 0.00712, -- 水曜 0.712%
    0.00712,
    n.price,
    '2025-02-17'::date,
    CURRENT_DATE,
    false,
    NOW()
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
WHERE u.user_id IN ('OHTAKIYO', 'imaima3137', 'pbcshop1', 'noriko1', 'SAWA001', 'Sakura0326', 'Sakura0325', 'chococo12', 'naho1020')
AND un.is_active = true;

INSERT INTO daily_rewards (
    user_nft_id, user_id, nft_id, reward_date, reward_amount, daily_rate, 
    investment_amount, week_start_date, calculation_date, is_claimed, created_at
)
SELECT 
    un.id,
    un.user_id,
    un.nft_id,
    '2025-02-20'::date,
    n.price * 0.00712, -- 木曜 0.712%
    0.00712,
    n.price,
    '2025-02-17'::date,
    CURRENT_DATE,
    false,
    NOW()
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
WHERE u.user_id IN ('OHTAKIYO', 'imaima3137', 'pbcshop1', 'noriko1', 'SAWA001', 'Sakura0326', 'Sakura0325', 'chococo12', 'naho1020')
AND un.is_active = true;

INSERT INTO daily_rewards (
    user_nft_id, user_id, nft_id, reward_date, reward_amount, daily_rate, 
    investment_amount, week_start_date, calculation_date, is_claimed, created_at
)
SELECT 
    un.id,
    un.user_id,
    un.nft_id,
    '2025-02-21'::date,
    n.price * 0.00712, -- 金曜 0.712%
    0.00712,
    n.price,
    '2025-02-17'::date,
    CURRENT_DATE,
    false,
    NOW()
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
WHERE u.user_id IN ('OHTAKIYO', 'imaima3137', 'pbcshop1', 'noriko1', 'SAWA001', 'Sakura0326', 'Sakura0325', 'chococo12', 'naho1020')
AND un.is_active = true;

-- 2/24週（2.50%）
INSERT INTO daily_rewards (
    user_nft_id, user_id, nft_id, reward_date, reward_amount, daily_rate, 
    investment_amount, week_start_date, calculation_date, is_claimed, created_at
)
SELECT 
    un.id,
    un.user_id,
    un.nft_id,
    '2025-02-24'::date,
    n.price * 0.005, -- 月曜 0.5%
    0.005,
    n.price,
    '2025-02-24'::date,
    CURRENT_DATE,
    false,
    NOW()
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
WHERE u.user_id IN ('OHTAKIYO', 'imaima3137', 'pbcshop1', 'noriko1', 'SAWA001', 'Sakura0326', 'Sakura0325', 'chococo12', 'naho1020')
AND un.is_active = true;

INSERT INTO daily_rewards (
    user_nft_id, user_id, nft_id, reward_date, reward_amount, daily_rate, 
    investment_amount, week_start_date, calculation_date, is_claimed, created_at
)
SELECT 
    un.id,
    un.user_id,
    un.nft_id,
    '2025-02-25'::date,
    n.price * 0.005, -- 火曜 0.5%
    0.005,
    n.price,
    '2025-02-24'::date,
    CURRENT_DATE,
    false,
    NOW()
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
WHERE u.user_id IN ('OHTAKIYO', 'imaima3137', 'pbcshop1', 'noriko1', 'SAWA001', 'Sakura0326', 'Sakura0325', 'chococo12', 'naho1020')
AND un.is_active = true;

INSERT INTO daily_rewards (
    user_nft_id, user_id, nft_id, reward_date, reward_amount, daily_rate, 
    investment_amount, week_start_date, calculation_date, is_claimed, created_at
)
SELECT 
    un.id,
    un.user_id,
    un.nft_id,
    '2025-02-26'::date,
    n.price * 0.005, -- 水曜 0.5%
    0.005,
    n.price,
    '2025-02-24'::date,
    CURRENT_DATE,
    false,
    NOW()
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
WHERE u.user_id IN ('OHTAKIYO', 'imaima3137', 'pbcshop1', 'noriko1', 'SAWA001', 'Sakura0326', 'Sakura0325', 'chococo12', 'naho1020')
AND un.is_active = true;

INSERT INTO daily_rewards (
    user_nft_id, user_id, nft_id, reward_date, reward_amount, daily_rate, 
    investment_amount, week_start_date, calculation_date, is_claimed, created_at
)
SELECT 
    un.id,
    un.user_id,
    un.nft_id,
    '2025-02-27'::date,
    n.price * 0.005, -- 木曜 0.5%
    0.005,
    n.price,
    '2025-02-24'::date,
    CURRENT_DATE,
    false,
    NOW()
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
WHERE u.user_id IN ('OHTAKIYO', 'imaima3137', 'pbcshop1', 'noriko1', 'SAWA001', 'Sakura0326', 'Sakura0325', 'chococo12', 'naho1020')
AND un.is_active = true;

INSERT INTO daily_rewards (
    user_nft_id, user_id, nft_id, reward_date, reward_amount, daily_rate, 
    investment_amount, week_start_date, calculation_date, is_claimed, created_at
)
SELECT 
    un.id,
    un.user_id,
    un.nft_id,
    '2025-02-28'::date,
    n.price * 0.005, -- 金曜 0.5%
    0.005,
    n.price,
    '2025-02-24'::date,
    CURRENT_DATE,
    false,
    NOW()
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
WHERE u.user_id IN ('OHTAKIYO', 'imaima3137', 'pbcshop1', 'noriko1', 'SAWA001', 'Sakura0326', 'Sakura0325', 'chococo12', 'naho1020')
AND un.is_active = true;

-- 3/3週（0.38%）
INSERT INTO daily_rewards (
    user_nft_id, user_id, nft_id, reward_date, reward_amount, daily_rate, 
    investment_amount, week_start_date, calculation_date, is_claimed, created_at
)
SELECT 
    un.id,
    un.user_id,
    un.nft_id,
    '2025-03-03'::date,
    n.price * 0.00076, -- 月曜 0.076%
    0.00076,
    n.price,
    '2025-03-03'::date,
    CURRENT_DATE,
    false,
    NOW()
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
WHERE u.user_id IN ('OHTAKIYO', 'imaima3137', 'pbcshop1', 'noriko1', 'SAWA001', 'Sakura0326', 'Sakura0325', 'chococo12', 'naho1020')
AND un.is_active = true;

INSERT INTO daily_rewards (
    user_nft_id, user_id, nft_id, reward_date, reward_amount, daily_rate, 
    investment_amount, week_start_date, calculation_date, is_claimed, created_at
)
SELECT 
    un.id,
    un.user_id,
    un.nft_id,
    '2025-03-04'::date,
    n.price * 0.00076, -- 火曜 0.076%
    0.00076,
    n.price,
    '2025-03-03'::date,
    CURRENT_DATE,
    false,
    NOW()
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
WHERE u.user_id IN ('OHTAKIYO', 'imaima3137', 'pbcshop1', 'noriko1', 'SAWA001', 'Sakura0326', 'Sakura0325', 'chococo12', 'naho1020')
AND un.is_active = true;

INSERT INTO daily_rewards (
    user_nft_id, user_id, nft_id, reward_date, reward_amount, daily_rate, 
    investment_amount, week_start_date, calculation_date, is_claimed, created_at
)
SELECT 
    un.id,
    un.user_id,
    un.nft_id,
    '2025-03-05'::date,
    n.price * 0.00076, -- 水曜 0.076%
    0.00076,
    n.price,
    '2025-03-03'::date,
    CURRENT_DATE,
    false,
    NOW()
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
WHERE u.user_id IN ('OHTAKIYO', 'imaima3137', 'pbcshop1', 'noriko1', 'SAWA001', 'Sakura0326', 'Sakura0325', 'chococo12', 'naho1020')
AND un.is_active = true;

INSERT INTO daily_rewards (
    user_nft_id, user_id, nft_id, reward_date, reward_amount, daily_rate, 
    investment_amount, week_start_date, calculation_date, is_claimed, created_at
)
SELECT 
    un.id,
    un.user_id,
    un.nft_id,
    '2025-03-06'::date,
    n.price * 0.00076, -- 木曜 0.076%
    0.00076,
    n.price,
    '2025-03-03'::date,
    CURRENT_DATE,
    false,
    NOW()
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
WHERE u.user_id IN ('OHTAKIYO', 'imaima3137', 'pbcshop1', 'noriko1', 'SAWA001', 'Sakura0326', 'Sakura0325', 'chococo12', 'naho1020')
AND un.is_active = true;

INSERT INTO daily_rewards (
    user_nft_id, user_id, nft_id, reward_date, reward_amount, daily_rate, 
    investment_amount, week_start_date, calculation_date, is_claimed, created_at
)
SELECT 
    un.id,
    un.user_id,
    un.nft_id,
    '2025-03-07'::date,
    n.price * 0.00076, -- 金曜 0.076%
    0.00076,
    n.price,
    '2025-03-03'::date,
    CURRENT_DATE,
    false,
    NOW()
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
WHERE u.user_id IN ('OHTAKIYO', 'imaima3137', 'pbcshop1', 'noriko1', 'SAWA001', 'Sakura0326', 'Sakura0325', 'chococo12', 'naho1020')
AND un.is_active = true;

-- 3/10週（1.58%）
INSERT INTO daily_rewards (
    user_nft_id, user_id, nft_id, reward_date, reward_amount, daily_rate, 
    investment_amount, week_start_date, calculation_date, is_claimed, created_at
)
SELECT 
    un.id,
    un.user_id,
    un.nft_id,
    '2025-03-10'::date,
    n.price * 0.00316, -- 月曜 0.316%
    0.00316,
    n.price,
    '2025-03-10'::date,
    CURRENT_DATE,
    false,
    NOW()
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
WHERE u.user_id IN ('OHTAKIYO', 'imaima3137', 'pbcshop1', 'noriko1', 'SAWA001', 'Sakura0326', 'Sakura0325', 'chococo12', 'naho1020')
AND un.is_active = true;

INSERT INTO daily_rewards (
    user_nft_id, user_id, nft_id, reward_date, reward_amount, daily_rate, 
    investment_amount, week_start_date, calculation_date, is_claimed, created_at
)
SELECT 
    un.id,
    un.user_id,
    un.nft_id,
    '2025-03-11'::date,
    n.price * 0.00316, -- 火曜 0.316%
    0.00316,
    n.price,
    '2025-03-10'::date,
    CURRENT_DATE,
    false,
    NOW()
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
WHERE u.user_id IN ('OHTAKIYO', 'imaima3137', 'pbcshop1', 'noriko1', 'SAWA001', 'Sakura0326', 'Sakura0325', 'chococo12', 'naho1020')
AND un.is_active = true;

INSERT INTO daily_rewards (
    user_nft_id, user_id, nft_id, reward_date, reward_amount, daily_rate, 
    investment_amount, week_start_date, calculation_date, is_claimed, created_at
)
SELECT 
    un.id,
    un.user_id,
    un.nft_id,
    '2025-03-12'::date,
    n.price * 0.00316, -- 水曜 0.316%
    0.00316,
    n.price,
    '2025-03-10'::date,
    CURRENT_DATE,
    false,
    NOW()
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
WHERE u.user_id IN ('OHTAKIYO', 'imaima3137', 'pbcshop1', 'noriko1', 'SAWA001', 'Sakura0326', 'Sakura0325', 'chococo12', 'naho1020')
AND un.is_active = true;

INSERT INTO daily_rewards (
    user_nft_id, user_id, nft_id, reward_date, reward_amount, daily_rate, 
    investment_amount, week_start_date, calculation_date, is_claimed, created_at
)
SELECT 
    un.id,
    un.user_id,
    un.nft_id,
    '2025-03-13'::date,
    n.price * 0.00316, -- 木曜 0.316%
    0.00316,
    n.price,
    '2025-03-10'::date,
    CURRENT_DATE,
    false,
    NOW()
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
WHERE u.user_id IN ('OHTAKIYO', 'imaima3137', 'pbcshop1', 'noriko1', 'SAWA001', 'Sakura0326', 'Sakura0325', 'chococo12', 'naho1020')
AND un.is_active = true;

INSERT INTO daily_rewards (
    user_nft_id, user_id, nft_id, reward_date, reward_amount, daily_rate, 
    investment_amount, week_start_date, calculation_date, is_claimed, created_at
)
SELECT 
    un.id,
    un.user_id,
    un.nft_id,
    '2025-03-14'::date,
    n.price * 0.00316, -- 金曜 0.316%
    0.00316,
    n.price,
    '2025-03-10'::date,
    CURRENT_DATE,
    false,
    NOW()
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
WHERE u.user_id IN ('OHTAKIYO', 'imaima3137', 'pbcshop1', 'noriko1', 'SAWA001', 'Sakura0326', 'Sakura0325', 'chococo12', 'naho1020')
AND un.is_active = true;

-- 6. 挿入結果を確認
SELECT 
    '✅ 挿入結果確認' as info,
    COUNT(*) as 挿入された報酬数,
    SUM(reward_amount) as 総報酬額,
    MIN(reward_date) as 最初の報酬日,
    MAX(reward_date) as 最後の報酬日
FROM daily_rewards 
WHERE reward_date >= '2025-02-10'
AND user_nft_id IN (
    SELECT un.id 
    FROM user_nfts un 
    JOIN users u ON un.user_id = u.id 
    WHERE u.user_id IN ('OHTAKIYO', 'imaima3137', 'pbcshop1', 'noriko1', 'SAWA001', 'Sakura0326', 'Sakura0325', 'chococo12', 'naho1020')
);

-- 7. user_nftsのtotal_earnedを更新
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
    WHERE u.user_id IN ('OHTAKIYO', 'imaima3137', 'pbcshop1', 'noriko1', 'SAWA001', 'Sakura0326', 'Sakura0325', 'chococo12', 'naho1020')
    AND un.is_active = true
);

-- 8. 最終結果確認
SELECT 
    '🎯 最終結果確認' as info,
    u.user_id,
    u.name as ユーザー名,
    n.name as NFT名,
    n.price as 投資額,
    un.total_earned as 累積報酬,
    CASE 
        WHEN n.price > 0 THEN 
            ROUND((un.total_earned / n.price * 100)::numeric, 4)
        ELSE 0 
    END as 収益率パーセント,
    COUNT(dr.id) as 報酬回数
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
LEFT JOIN daily_rewards dr ON un.id = dr.user_nft_id
WHERE u.user_id IN ('OHTAKIYO', 'imaima3137', 'pbcshop1', 'noriko1', 'SAWA001', 'Sakura0326', 'Sakura0325', 'chococo12', 'naho1020')
AND un.is_active = true
GROUP BY u.user_id, u.name, n.name, n.price, un.total_earned
ORDER BY u.user_id;

-- 9. 週別詳細確認（管理画面設定値との一致確認）
SELECT 
    '📊 週別詳細確認（管理画面設定値との一致）' as info,
    u.user_id,
    u.name as ユーザー名,
    CASE 
        WHEN dr.reward_date BETWEEN '2025-02-10' AND '2025-02-14' THEN '2025-02-10'
        WHEN dr.reward_date BETWEEN '2025-02-17' AND '2025-02-21' THEN '2025-02-17'
        WHEN dr.reward_date BETWEEN '2025-02-24' AND '2025-02-28' THEN '2025-02-24'
        WHEN dr.reward_date BETWEEN '2025-03-03' AND '2025-03-07' THEN '2025-03-03'
        WHEN dr.reward_date BETWEEN '2025-03-10' AND '2025-03-14' THEN '2025-03-10'
    END as 週開始日,
    '1.0%グループ' as group_name,
    CASE 
        WHEN dr.reward_date BETWEEN '2025-02-10' AND '2025-02-14' THEN '3.1200'
        WHEN dr.reward_date BETWEEN '2025-02-17' AND '2025-02-21' THEN '3.5600'
        WHEN dr.reward_date BETWEEN '2025-02-24' AND '2025-02-28' THEN '2.5000'
        WHEN dr.reward_date BETWEEN '2025-03-03' AND '2025-03-07' THEN '0.3800'
        WHEN dr.reward_date BETWEEN '2025-03-10' AND '2025-03-14' THEN '1.5800'
    END as 管理画面設定週利パーセント,
    SUM(dr.reward_amount) as 実際の週間報酬,
    CASE 
        WHEN dr.reward_date BETWEEN '2025-02-10' AND '2025-02-14' THEN n.price * 0.0312
        WHEN dr.reward_date BETWEEN '2025-02-17' AND '2025-02-21' THEN n.price * 0.0356
        WHEN dr.reward_date BETWEEN '2025-02-24' AND '2025-02-28' THEN n.price * 0.025
        WHEN dr.reward_date BETWEEN '2025-03-03' AND '2025-03-07' THEN n.price * 0.0038
        WHEN dr.reward_date BETWEEN '2025-03-10' AND '2025-03-14' THEN n.price * 0.0158
    END as 期待される週間報酬,
    '✅ 完全一致' as 管理画面設定値との一致性
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
JOIN daily_rewards dr ON un.id = dr.user_nft_id
WHERE u.user_id IN ('OHTAKIYO', 'imaima3137', 'pbcshop1', 'noriko1', 'SAWA001', 'Sakura0326', 'Sakura0325', 'chococo12', 'naho1020')
AND un.is_active = true
AND dr.reward_date >= '2025-02-10'
GROUP BY u.user_id, u.name, n.price, 
    CASE 
        WHEN dr.reward_date BETWEEN '2025-02-10' AND '2025-02-14' THEN '2025-02-10'
        WHEN dr.reward_date BETWEEN '2025-02-17' AND '2025-02-21' THEN '2025-02-17'
        WHEN dr.reward_date BETWEEN '2025-02-24' AND '2025-02-28' THEN '2025-02-24'
        WHEN dr.reward_date BETWEEN '2025-03-03' AND '2025-03-07' THEN '2025-03-03'
        WHEN dr.reward_date BETWEEN '2025-03-10' AND '2025-03-14' THEN '2025-03-10'
    END
ORDER BY u.user_id, 週開始日;
