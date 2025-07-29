-- テーブル構造の修正

-- daily_rewardsテーブルにupdated_atカラムを追加（存在しない場合）
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'daily_rewards' 
        AND column_name = 'updated_at'
    ) THEN
        ALTER TABLE daily_rewards ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
        RAISE NOTICE 'daily_rewardsテーブルにupdated_atカラムを追加しました';
    END IF;
END $$;

-- user_nftsテーブルのupdated_atトリガーを作成
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- user_nftsテーブルのトリガーを作成
DROP TRIGGER IF EXISTS update_user_nfts_updated_at ON user_nfts;
CREATE TRIGGER update_user_nfts_updated_at
    BEFORE UPDATE ON user_nfts
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- daily_rewardsテーブルのトリガーを作成
DROP TRIGGER IF EXISTS update_daily_rewards_updated_at ON daily_rewards;
CREATE TRIGGER update_daily_rewards_updated_at
    BEFORE UPDATE ON daily_rewards
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

RAISE NOTICE 'テーブル構造の修正が完了しました';
