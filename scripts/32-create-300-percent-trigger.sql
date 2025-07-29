-- 300%到達時の即時処理トリガー
-- キャップ超過計算→誤払い防止

-- 300%チェック関数
CREATE OR REPLACE FUNCTION check_300_percent_cap()
RETURNS TRIGGER AS $$
DECLARE
    current_investment DECIMAL(10,2);
    max_earning DECIMAL(10,2);
    current_total_earned DECIMAL(10,2);
BEGIN
    -- user_nftsから投資額と最大収益を取得
    SELECT un.current_investment, un.max_earning, un.total_earned 
    INTO current_investment, max_earning, current_total_earned
    FROM user_nfts un
    WHERE un.id = NEW.user_nft_id;
    
    IF current_investment IS NULL THEN
        RAISE EXCEPTION 'user_nft_id % が見つかりません', NEW.user_nft_id;
    END IF;
    
    -- 今回の報酬を加えた累積報酬を計算
    current_total_earned := current_total_earned + NEW.reward_amount;
    
    -- 300%キャップに達した場合
    IF current_total_earned >= max_earning THEN
        
        -- 今回の報酬額を調整（キャップを超えないように）
        NEW.reward_amount := max_earning - (current_total_earned - NEW.reward_amount);
        
        -- 負の値になる場合は0に設定
        IF NEW.reward_amount < 0 THEN
            NEW.reward_amount := 0;
        END IF;
        
        -- user_nftsの累積報酬を更新
        UPDATE user_nfts 
        SET 
            total_earned = max_earning,
            is_active = false,
            updated_at = NOW()
        WHERE id = NEW.user_nft_id;
        
        -- ログ出力
        RAISE NOTICE 'NFT ID % が300%%キャップ($%)に達しました。NFTを非アクティブ化しました。調整後報酬: $%', 
            NEW.user_nft_id, max_earning, NEW.reward_amount;
    ELSE
        -- キャップに達していない場合、user_nftsの累積報酬を更新
        UPDATE user_nfts 
        SET 
            total_earned = current_total_earned,
            updated_at = NOW()
        WHERE id = NEW.user_nft_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- daily_rewardsテーブルにトリガーを設定（テーブルが存在する場合のみ）
DO $$
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'daily_rewards' AND table_schema = 'public') THEN
        DROP TRIGGER IF EXISTS trigger_300_percent_cap ON daily_rewards;
        CREATE TRIGGER trigger_300_percent_cap
            BEFORE INSERT OR UPDATE ON daily_rewards
            FOR EACH ROW
            EXECUTE FUNCTION check_300_percent_cap();
        RAISE NOTICE '✅ daily_rewardsテーブルに300%%キャップトリガーを設定しました';
    ELSE
        RAISE NOTICE 'ℹ️ daily_rewardsテーブルが存在しないため、トリガーはスキップしました';
    END IF;
END
$$;

-- tenka_bonusesテーブルにもトリガーを設定（テーブルが存在する場合のみ）
DO $$
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'tenka_bonuses' AND table_schema = 'public') THEN
        DROP TRIGGER IF EXISTS trigger_300_percent_cap_tenka ON tenka_bonuses;
        CREATE TRIGGER trigger_300_percent_cap_tenka
            BEFORE INSERT OR UPDATE ON tenka_bonuses
            FOR EACH ROW
            EXECUTE FUNCTION check_300_percent_cap();
        RAISE NOTICE '✅ tenka_bonusesテーブルに300%%キャップトリガーを設定しました';
    ELSE
        RAISE NOTICE 'ℹ️ tenka_bonusesテーブルが存在しないため、トリガーはスキップしました';
    END IF;
END
$$;

-- 完了メッセージ
SELECT '300%キャップ監視トリガーの設定が完了しました' AS result;
