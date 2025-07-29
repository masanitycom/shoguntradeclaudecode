-- 指定ユーザーのNFT保有状況と報酬詳細を取得
-- 管理画面と同様の表示形式で情報を取得

-- 対象ユーザー特定用の共通テーブル式
WITH target_users AS (
    SELECT id, user_id, name, email
    FROM users 
    WHERE user_id IN ('pigret10', 'momochan', 'klmiklmi0204', 'katsuji1')
       OR email IN ('c781opigret@gmail.com', 'momokoshimizu0406@gmail.com', 'kimiko.0204.1357@gmail.com', 'jzs01473@gmail.com')
       OR name IN ('クリハラチアキ', 'コシミズモモ', 'アラホリキミコ', 'ムロツキカツジ')
)

-- 管理画面表示形式でユーザー情報とNFT情報を取得
SELECT 
    '🎯 ユーザーNFT情報' as info,
    u.name as ユーザー名,
    u.user_id,
    u.email,
    ref.user_id as 紹介者ID,
    n.name as nft名,
    un.current_investment as 投資額,
    COALESCE(
        (SELECT SUM(dr.reward_amount) 
         FROM daily_rewards dr 
         WHERE dr.user_nft_id = un.id),
        0
    ) as 累積報酬,
    CASE 
        WHEN un.current_investment > 0 THEN 
            ROUND(
                (COALESCE(
                    (SELECT SUM(dr.reward_amount) 
                     FROM daily_rewards dr 
                     WHERE dr.user_nft_id = un.id),
                    0
                ) / un.current_investment) * 100, 
                4
            )
        ELSE 0
    END as 収益率パーセント,
    (SELECT COUNT(*) FROM daily_rewards dr WHERE dr.user_nft_id = un.id) as 報酬回数,
    un.created_at as 購入日,
    un.status as ステータス,
    n.is_special as 特別NFT,
    n.daily_rate_limit as 日利上限
FROM target_users tu
JOIN users u ON tu.id = u.id
LEFT JOIN users ref ON u.referrer_id = ref.id
JOIN user_nfts un ON u.id = un.user_id
JOIN nfts n ON un.nft_id = n.id
ORDER BY u.name, n.price DESC;

-- 日利報酬履歴を取得
SELECT 
    '💰 日利報酬履歴' as info,
    u.name as ユーザー名,
    u.user_id,
    n.name as nft名,
    dr.reward_date as 報酬日,
    dr.reward_amount as 報酬額,
    dr.is_claimed as 申請済み
FROM target_users tu
JOIN users u ON tu.id = u.id
JOIN user_nfts un ON u.id = un.user_id
JOIN nfts n ON un.nft_id = n.id
JOIN daily_rewards dr ON un.id = dr.user_nft_id
ORDER BY u.name, dr.reward_date DESC
LIMIT 50;

-- 報酬申請履歴を取得
SELECT 
    '📋 報酬申請履歴' as info,
    u.name as ユーザー名,
    u.user_id,
    ra.week_start_date as 週開始日,
    ra.total_reward_amount as 申請総額,
    ra.fee_rate as 手数料率,
    ra.fee_amount as 手数料額,
    ra.net_amount as 純支払額,
    ra.status as ステータス,
    ra.applied_at as 申請日時,
    ra.processed_at as 処理日時
FROM target_users tu
JOIN users u ON tu.id = u.id
JOIN reward_applications ra ON u.id = ra.user_id
ORDER BY u.name, ra.applied_at DESC;

-- 管理画面表示用のサマリー情報
SELECT 
    '📊 管理画面表示用サマリー' as info,
    u.name as ユーザー名,
    u.user_id,
    u.email,
    ref.user_id as 紹介者ID,
    n.name as nft名,
    un.current_investment as 投資額,
    COALESCE(
        (SELECT SUM(dr.reward_amount) 
         FROM daily_rewards dr 
         WHERE dr.user_nft_id = un.id),
        0
    ) as 収益,
    '2025/6/25' as 登録日
FROM target_users tu
JOIN users u ON tu.id = u.id
LEFT JOIN users ref ON u.referrer_id = ref.id
JOIN user_nfts un ON u.id = un.user_id
JOIN nfts n ON un.nft_id = n.id
ORDER BY u.name;
