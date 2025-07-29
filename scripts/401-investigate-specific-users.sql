-- 指定されたユーザーの詳細調査

-- 1. 対象ユーザーの基本情報確認
SELECT 
    '👥 対象ユーザー基本情報' as info,
    u.id as user_uuid,
    u.user_id,
    u.name as ユーザー名,
    u.email,
    u.phone,
    u.is_admin,
    u.created_at as 登録日,
    u.referrer_id,
    ref.name as 紹介者名,
    ref.user_id as 紹介者ID,
    u.my_referral_code as 自分の紹介コード,
    u.usdt_address,
    u.wallet_type
FROM users u
LEFT JOIN users ref ON u.referrer_id = ref.id
WHERE u.user_id IN ('pigret10', 'momochan', 'klmiklmi0204', 'katsuji1')
   OR u.email IN ('c781opigret@gmail.com', 'momokoshimizu0406@gmail.com', 'kimiko.0204.1357@gmail.com', 'jzs01473@gmail.com')
   OR u.name IN ('クリハラチアキ', 'コシミズモモ', 'アラホリキミコ', 'ムロツキカツジ')
ORDER BY u.created_at;

-- 2. NFT保有状況確認
SELECT 
    '🎯 NFT保有状況' as info,
    u.user_id,
    u.name as ユーザー名,
    n.name as NFT名,
    n.price as NFT価格,
    un.current_investment as 現在投資額,
    un.total_earned as 累積報酬,
    un.max_earning as 最大獲得可能額,
    un.is_active as アクティブ状態,
    un.created_at as NFT取得日,
    CASE 
        WHEN un.max_earning > 0 THEN 
            ROUND((un.total_earned / un.max_earning * 100)::numeric, 2)
        ELSE 0 
    END as 進捗パーセント
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
WHERE u.user_id IN ('pigret10', 'momochan', 'klmiklmi0204', 'katsuji1')
   OR u.email IN ('c781opigret@gmail.com', 'momokoshimizu0406@gmail.com', 'kimiko.0204.1357@gmail.com', 'jzs01473@gmail.com')
   OR u.name IN ('クリハラチアキ', 'コシミズモモ', 'アラホリキミコ', 'ムロツキカツジ')
ORDER BY u.user_id, un.created_at;

-- 3. 日利報酬履歴確認
SELECT 
    '💰 日利報酬履歴' as info,
    u.user_id,
    u.name as ユーザー名,
    COUNT(dr.id) as 報酬回数,
    SUM(dr.reward_amount) as 総報酬額,
    AVG(dr.reward_amount) as 平均日利,
    MIN(dr.reward_date) as 最初の報酬日,
    MAX(dr.reward_date) as 最後の報酬日,
    COUNT(CASE WHEN dr.is_claimed = true THEN 1 END) as 申請済み回数,
    COUNT(CASE WHEN dr.is_claimed = false THEN 1 END) as 未申請回数,
    SUM(CASE WHEN dr.is_claimed = false THEN dr.reward_amount ELSE 0 END) as 未申請報酬額
FROM users u
LEFT JOIN user_nfts un ON u.id = un.user_id
LEFT JOIN daily_rewards dr ON un.id = dr.user_nft_id
WHERE u.user_id IN ('pigret10', 'momochan', 'klmiklmi0204', 'katsuji1')
   OR u.email IN ('c781opigret@gmail.com', 'momokoshimizu0406@gmail.com', 'kimiko.0204.1357@gmail.com', 'jzs01473@gmail.com')
   OR u.name IN ('クリハラチアキ', 'コシミズモモ', 'アラホリキミコ', 'ムロツキカツジ')
GROUP BY u.id, u.user_id, u.name
ORDER BY u.user_id;

-- 4. 報酬申請履歴確認
SELECT 
    '📋 報酬申請履歴' as info,
    u.user_id,
    u.name as ユーザー名,
    ra.id as 申請ID,
    ra.reward_amount as 申請額,
    ra.status as ステータス,
    ra.task_answer as タスク回答,
    ra.created_at as 申請日,
    ra.processed_at as 処理日
FROM users u
LEFT JOIN reward_applications ra ON u.id = ra.user_id
WHERE u.user_id IN ('pigret10', 'momochan', 'klmiklmi0204', 'katsuji1')
   OR u.email IN ('c781opigret@gmail.com', 'momokoshimizu0406@gmail.com', 'kimiko.0204.1357@gmail.com', 'jzs01473@gmail.com')
   OR u.name IN ('クリハラチアキ', 'コシミズモモ', 'アラホリキミコ', 'ムロツキカツジ')
ORDER BY u.user_id, ra.created_at DESC;

-- 5. NFT購入申請履歴確認
SELECT 
    '🛒 NFT購入申請履歴' as info,
    u.user_id,
    u.name as ユーザー名,
    npa.id as 申請ID,
    n.name as NFT名,
    n.price as NFT価格,
    npa.status as ステータス,
    npa.payment_method as 支払い方法,
    npa.transaction_hash as トランザクションハッシュ,
    npa.created_at as 申請日,
    npa.approved_at as 承認日
FROM users u
LEFT JOIN nft_purchase_applications npa ON u.id = npa.user_id
LEFT JOIN nfts n ON npa.nft_id = n.id
WHERE u.user_id IN ('pigret10', 'momochan', 'klmiklmi0204', 'katsuji1')
   OR u.email IN ('c781opigret@gmail.com', 'momokoshimizu0406@gmail.com', 'kimiko.0204.1357@gmail.com', 'jzs01473@gmail.com')
   OR u.name IN ('クリハラチアキ', 'コシミズモモ', 'アラホリキミコ', 'ムロツキカツジ')
ORDER BY u.user_id, npa.created_at DESC;

-- 6. 紹介関係確認
SELECT 
    '🔗 紹介関係確認' as info,
    u.user_id,
    u.name as ユーザー名,
    '紹介した人数: ' || COUNT(referred.id) as 紹介実績,
    STRING_AGG(referred.name || '(' || referred.user_id || ')', ', ') as 紹介したユーザー
FROM users u
LEFT JOIN users referred ON u.id = referred.referrer_id
WHERE u.user_id IN ('pigret10', 'momochan', 'klmiklmi0204', 'katsuji1')
   OR u.email IN ('c781opigret@gmail.com', 'momokoshimizu0406@gmail.com', 'kimiko.0204.1357@gmail.com', 'jzs01473@gmail.com')
   OR u.name IN ('クリハラチアキ', 'コシミズモモ', 'アラホリキミコ', 'ムロツキカツジ')
GROUP BY u.id, u.user_id, u.name
ORDER BY u.user_id;

-- 7. MLMランク確認
SELECT 
    '🏆 MLMランク確認' as info,
    u.user_id,
    u.name as ユーザー名,
    u.current_rank as 現在のランク,
    COALESCE(SUM(un.current_investment), 0) as 総投資額,
    COUNT(un.id) as 保有NFT数
FROM users u
LEFT JOIN user_nfts un ON u.id = un.user_id AND un.is_active = true
WHERE u.user_id IN ('pigret10', 'momochan', 'klmiklmi0204', 'katsuji1')
   OR u.email IN ('c781opigret@gmail.com', 'momokoshimizu0406@gmail.com', 'kimiko.0204.1357@gmail.com', 'jzs01473@gmail.com')
   OR u.name IN ('クリハラチアキ', 'コシミズモモ', 'アラホリキミコ', 'ムロツキカツジ')
GROUP BY u.id, u.user_id, u.name, u.current_rank
ORDER BY u.user_id;

-- 8. 認証情報確認
SELECT 
    '🔐 認証情報確認' as info,
    u.user_id,
    u.name as ユーザー名,
    u.email,
    au.email as 認証テーブルメール,
    au.email_confirmed_at as メール確認日,
    au.last_sign_in_at as 最終ログイン,
    au.created_at as 認証作成日,
    CASE 
        WHEN u.email = au.email THEN '✅ 一致'
        ELSE '❌ 不一致'
    END as メール一致性
FROM users u
LEFT JOIN auth.users au ON u.id = au.id
WHERE u.user_id IN ('pigret10', 'momochan', 'klmiklmi0204', 'katsuji1')
   OR u.email IN ('c781opigret@gmail.com', 'momokoshimizu0406@gmail.com', 'kimiko.0204.1357@gmail.com', 'jzs01473@gmail.com')
   OR u.name IN ('クリハラチアキ', 'コシミズモモ', 'アラホリキミコ', 'ムロツキカツジ')
ORDER BY u.user_id;

-- 9. 問題点チェック
SELECT 
    '⚠️ 問題点チェック' as info,
    u.user_id,
    u.name as ユーザー名,
    CASE 
        WHEN u.referrer_id IS NULL THEN '❌ 紹介者なし'
        ELSE '✅ 紹介者あり'
    END as 紹介者状況,
    CASE 
        WHEN u.my_referral_code IS NULL OR u.my_referral_code = '' THEN '❌ 紹介コードなし'
        ELSE '✅ 紹介コードあり'
    END as 紹介コード状況,
    CASE 
        WHEN u.usdt_address IS NULL OR u.usdt_address = '' THEN '❌ ウォレットアドレスなし'
        ELSE '✅ ウォレットアドレスあり'
    END as ウォレット状況,
    CASE 
        WHEN NOT EXISTS (SELECT 1 FROM user_nfts un WHERE un.user_id = u.id AND un.is_active = true) THEN '❌ アクティブNFTなし'
        ELSE '✅ アクティブNFTあり'
    END as NFT状況
FROM users u
WHERE u.user_id IN ('pigret10', 'momochan', 'klmiklmi0204', 'katsuji1')
   OR u.email IN ('c781opigret@gmail.com', 'momokoshimizu0406@gmail.com', 'kimiko.0204.1357@gmail.com', 'jzs01473@gmail.com')
   OR u.name IN ('クリハラチアキ', 'コシミズモモ', 'アラホリキミコ', 'ムロツキカツジ')
ORDER BY u.user_id;

-- 10. 最近のアクティビティ確認
SELECT 
    '📅 最近のアクティビティ' as info,
    u.user_id,
    u.name as ユーザー名,
    'daily_rewards' as テーブル,
    COUNT(*) as レコード数,
    MAX(dr.created_at) as 最新日時
FROM users u
LEFT JOIN user_nfts un ON u.id = un.user_id
LEFT JOIN daily_rewards dr ON un.id = dr.user_nft_id
WHERE u.user_id IN ('pigret10', 'momochan', 'klmiklmi0204', 'katsuji1')
   OR u.email IN ('c781opigret@gmail.com', 'momokoshimizu0406@gmail.com', 'kimiko.0204.1357@gmail.com', 'jzs01473@gmail.com')
   OR u.name IN ('クリハラチアキ', 'コシミズモモ', 'アラホリキミコ', 'ムロツキカツジ')
GROUP BY u.id, u.user_id, u.name

UNION ALL

SELECT 
    '📅 最近のアクティビティ' as info,
    u.user_id,
    u.name as ユーザー名,
    'reward_applications' as テーブル,
    COUNT(*) as レコード数,
    MAX(ra.created_at) as 最新日時
FROM users u
LEFT JOIN reward_applications ra ON u.id = ra.user_id
WHERE u.user_id IN ('pigret10', 'momochan', 'klmiklmi0204', 'katsuji1')
   OR u.email IN ('c781opigret@gmail.com', 'momokoshimizu0406@gmail.com', 'kimiko.0204.1357@gmail.com', 'jzs01473@gmail.com')
   OR u.name IN ('クリハラチアキ', 'コシミズモモ', 'アラホリキミコ', 'ムロツキカツジ')
GROUP BY u.id, u.user_id, u.name
ORDER BY user_id, テーブル;
