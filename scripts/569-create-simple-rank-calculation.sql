-- 実際のテーブル構造に基づく簡単なランク計算

-- 1. 簡単なランク決定関数（実際の構造に基づく）
CREATE OR REPLACE FUNCTION determine_user_rank_simple(p_user_id UUID)
RETURNS TABLE(
    user_id UUID,
    rank_level INTEGER,
    rank_name TEXT,
    nft_investment DECIMAL
) AS $$
DECLARE
    user_nft_investment DECIMAL := 0;
    calculated_rank INTEGER := 0;
    calculated_rank_name TEXT := 'なし';
BEGIN
    -- ユーザーのNFT投資額を計算
    SELECT COALESCE(SUM(un.purchase_price), 0) INTO user_nft_investment
    FROM user_nfts un
    WHERE un.user_id = p_user_id 
    AND un.is_active = true;
    
    -- 簡単なランク決定（NFT投資額のみで判定）
    IF user_nft_investment >= 1000 THEN
        calculated_rank := 1; -- 足軽（最低ランク）
        calculated_rank_name := '足軽';
    ELSE
        calculated_rank := 0;
        calculated_rank_name := 'なし';
    END IF;
    
    RETURN QUERY SELECT 
        p_user_id,
        calculated_rank,
        calculated_rank_name,
        user_nft_investment;
END;
$$ LANGUAGE plpgsql;

-- 2. 全ユーザーのランクを更新（簡単版）
DO $$
DECLARE
    user_record RECORD;
    rank_result RECORD;
    processed_count INTEGER := 0;
BEGIN
    FOR user_record IN 
        SELECT id, name FROM users 
        WHERE name IS NOT NULL 
        ORDER BY name
    LOOP
        -- ランクを計算
        SELECT * INTO rank_result
        FROM determine_user_rank_simple(user_record.id);
        
        -- ユーザーテーブルを更新
        UPDATE users 
        SET current_rank = rank_result.rank_name,
            current_rank_level = rank_result.rank_level,
            updated_at = NOW()
        WHERE id = user_record.id;
        
        processed_count := processed_count + 1;
    END LOOP;
    
    RAISE NOTICE '合計 % 件のユーザーランクを更新完了', processed_count;
END $$;

-- 3. 結果確認
SELECT 
    '📊 ランク更新結果' as info,
    current_rank,
    current_rank_level,
    COUNT(*) as user_count,
    SUM(COALESCE(total_earned, 0)) as total_earnings
FROM users 
WHERE name IS NOT NULL
GROUP BY current_rank, current_rank_level
ORDER BY current_rank_level DESC;

-- 4. 上位ユーザー確認
SELECT 
    '🏆 NFT投資額上位ユーザー' as info,
    u.name,
    u.current_rank,
    COALESCE(SUM(un.purchase_price), 0) as total_investment,
    COALESCE(u.total_earned, 0) as total_earned
FROM users u
LEFT JOIN user_nfts un ON u.id = un.user_id AND un.is_active = true
WHERE u.name IS NOT NULL
GROUP BY u.id, u.name, u.current_rank, u.total_earned
ORDER BY total_investment DESC
LIMIT 10;

SELECT '✅ 簡単なランク計算システム完了' as final_status;
