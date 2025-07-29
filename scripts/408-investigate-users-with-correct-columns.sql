-- 指定ユーザーの詳細調査（実際に存在するカラムのみ使用）

-- 1. 基本情報確認
SELECT 
    '👥 基本情報' as info,
    u.name as ユーザー名,
    u.user_id,
    u.email,
    u.created_at as 登録日,
    ref.name as 紹介者名,
    ref.user_id as 紹介者ID
FROM users u
LEFT JOIN users ref ON u.referrer_id = ref.id
WHERE u.user_id IN ('pigret10', 'momochan', 'klmiklmi0204', 'katsuji1')
   OR u.email IN ('c781opigret@gmail.com', 'momokoshimizu0406@gmail.com', 'kimiko.0204.1357@gmail.com', 'jzs01473@gmail.com')
   OR u.name IN ('クリハラチアキ', 'コシミズモモ', 'アラホリキミコ', 'ムロツキカツジ')
ORDER BY u.name;

-- 2. NFT保有状況（存在するカラムのみ）
SELECT 
    '🎯 NFT保有状況' as info,
    u.name as ユーザー名,
    u.user_id,
    n.name as nft名,
    un.current_investment as 投資額,
    un.total_earned as 累積報酬,
    un.created_at as NFT取得日,
    n.price as nft価格,
    n.daily_rate_limit as 日利上限,
    n.is_special as 特別NFT
FROM users u
JOIN user_nfts un ON u.id = un.user_id
JOIN nfts n ON un.nft_id = n.id
WHERE u.user_id IN ('pigret10', 'momochan', 'klmiklmi0204', 'katsuji1')
   OR u.email IN ('c781opigret@gmail.com', 'momokoshimizu0406@gmail.com', 'kimiko.0204.1357@gmail.com', 'jzs01473@gmail.com')
   OR u.name IN ('クリハラチアキ', 'コシミズモモ', 'アラホリキミコ', 'ムロツキカツジ')
ORDER BY u.name;

-- 3. 日利報酬履歴
SELECT 
    '💰 日利報酬履歴' as info,
    u.name as ユーザー名,
    u.user_id,
    n.name as nft名,
    dr.reward_date as 報酬日,
    dr.reward_amount as 報酬額,
    dr.is_claimed as 申請済み,
    dr.created_at as 作成日時
FROM users u
JOIN user_nfts un ON u.id = un.user_id
JOIN nfts n ON un.nft_id = n.id
JOIN daily_rewards dr ON un.id = dr.user_nft_id
WHERE u.user_id IN ('pigret10', 'momochan', 'klmiklmi0204', 'katsuji1')
   OR u.email IN ('c781opigret@gmail.com', 'momokoshimizu0406@gmail.com', 'kimiko.0204.1357@gmail.com', 'jzs01473@gmail.com')
   OR u.name IN ('クリハラチアキ', 'コシミズモモ', 'アラホリキミコ', 'ムロツキカツジ')
ORDER BY u.name, dr.reward_date DESC
LIMIT 50;

-- 4. 報酬申請履歴（存在するカラムのみ）
SELECT 
    '📋 報酬申請履歴' as info,
    u.name as ユーザー名,
    u.user_id,
    ra.week_start_date as 週開始日,
    ra.total_reward_amount as 申請総額,
    ra.application_type as 申請タイプ,
    ra.fee_rate as 手数料率,
    ra.fee_amount as 手数料額,
    ra.net_amount as 純支払額,
    ra.status as ステータス,
    ra.applied_at as 申請日時,
    ra.processed_at as 処理日時
FROM users u
JOIN reward_applications ra ON u.id = ra.user_id
WHERE u.user_id IN ('pigret10', 'momochan', 'klmiklmi0204', 'katsuji1')
   OR u.email IN ('c781opigret@gmail.com', 'momokoshimizu0406@gmail.com', 'kimiko.0204.1357@gmail.com', 'jzs01473@gmail.com')
   OR u.name IN ('クリハラチアキ', 'コシミズモモ', 'アラホリキミコ', 'ムロツキカツジ')
ORDER BY u.name, ra.applied_at DESC;

-- 5. 管理画面表示形式のサマリー
SELECT 
    '📊 管理画面サマリー' as info,
    u.name as ユーザー名,
    u.user_id,
    u.email,
    ref.user_id as 紹介者ID,
    n.name as nft名,
    un.current_investment as 投資額,
    un.total_earned as 収益,
    TO_CHAR(u.created_at, 'YYYY/MM/DD') as 登録日
FROM users u
LEFT JOIN users ref ON u.referrer_id = ref.id
JOIN user_nfts un ON u.id = un.user_id
JOIN nfts n ON un.nft_id = n.id
WHERE u.user_id IN ('pigret10', 'momochan', 'klmiklmi0204', 'katsuji1')
   OR u.email IN ('c781opigret@gmail.com', 'momokoshimizu0406@gmail.com', 'kimiko.0204.1357@gmail.com', 'jzs01473@gmail.com')
   OR u.name IN ('クリハラチアキ', 'コシミズモモ', 'アラホリキミコ', 'ムロツキカツジ')
ORDER BY u.name;
