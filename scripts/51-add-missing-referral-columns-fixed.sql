-- 不足している紹介関連カラムを追加（修正版）

DO $$
BEGIN
    -- referral_code カラム（誰に紹介されたか）
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'users' AND column_name = 'referral_code'
    ) THEN
        ALTER TABLE users ADD COLUMN referral_code VARCHAR(20);
        RAISE NOTICE '✅ referral_code カラムを追加しました';
    ELSE
        RAISE NOTICE 'ℹ️ referral_code カラムは既に存在します';
    END IF;
    
    -- my_referral_code カラム（自分の紹介コード）
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'users' AND column_name = 'my_referral_code'
    ) THEN
        ALTER TABLE users ADD COLUMN my_referral_code VARCHAR(20) UNIQUE;
        RAISE NOTICE '✅ my_referral_code カラムを追加しました';
    ELSE
        RAISE NOTICE 'ℹ️ my_referral_code カラムは既に存在します';
    END IF;
    
    -- referral_link カラム（自分の紹介リンク）
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'users' AND column_name = 'referral_link'
    ) THEN
        ALTER TABLE users ADD COLUMN referral_link TEXT;
        RAISE NOTICE '✅ referral_link カラムを追加しました';
    ELSE
        RAISE NOTICE 'ℹ️ referral_link カラムは既に存在します';
    END IF;
    
    -- wallet_address カラム
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'users' AND column_name = 'wallet_address'
    ) THEN
        ALTER TABLE users ADD COLUMN wallet_address TEXT;
        RAISE NOTICE '✅ wallet_address カラムを追加しました';
    ELSE
        RAISE NOTICE 'ℹ️ wallet_address カラムは既に存在します';
    END IF;
    
    -- wallet_type カラム
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'users' AND column_name = 'wallet_type'
    ) THEN
        ALTER TABLE users ADD COLUMN wallet_type VARCHAR(50) DEFAULT 'USDT_BEP20';
        RAISE NOTICE '✅ wallet_type カラムを追加しました';
    ELSE
        RAISE NOTICE 'ℹ️ wallet_type カラムは既に存在します';
    END IF;
END
$$;

-- 既存ユーザーに自分の紹介コードを生成（ウィンドウ関数を使わない方法）
DO $$
DECLARE
    user_record RECORD;
    counter INTEGER := 1;
BEGIN
    FOR user_record IN 
        SELECT id FROM users 
        WHERE my_referral_code IS NULL AND is_admin = false
        ORDER BY created_at
    LOOP
        UPDATE users 
        SET my_referral_code = 'REF' || LPAD(counter::TEXT, 6, '0')
        WHERE id = user_record.id;
        
        counter := counter + 1;
    END LOOP;
    
    RAISE NOTICE '✅ % 人のユーザーに紹介コードを生成しました', counter - 1;
END
$$;

-- 紹介リンクを生成（まだない場合）
UPDATE users 
SET referral_link = 'https://shogun-trade.com/register?ref=' || my_referral_code
WHERE referral_link IS NULL AND my_referral_code IS NOT NULL;

SELECT 'カラム追加とデータ初期化完了' AS result;

-- 更新後の構造確認
SELECT 'updated_table_structure' as step;

SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'users' 
AND table_schema = 'public'
ORDER BY ordinal_position;
