-- 不足しているカラムをすべて追加

-- 1. referral_code カラム（誰に紹介されたか）
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'users' AND column_name = 'referral_code'
    ) THEN
        ALTER TABLE users ADD COLUMN referral_code VARCHAR(20);
        RAISE NOTICE '✅ referral_code カラムを追加しました';
    ELSE
        RAISE NOTICE 'ℹ️ referral_code カラムは既に存在します';
    END IF;
END
$$;

-- 2. my_referral_code カラム（自分の紹介コード）
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'users' AND column_name = 'my_referral_code'
    ) THEN
        ALTER TABLE users ADD COLUMN my_referral_code VARCHAR(20) UNIQUE;
        RAISE NOTICE '✅ my_referral_code カラムを追加しました';
    ELSE
        RAISE NOTICE 'ℹ️ my_referral_code カラムは既に存在します';
    END IF;
END
$$;

-- 3. referral_link カラム（自分の紹介リンク）
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'users' AND column_name = 'referral_link'
    ) THEN
        ALTER TABLE users ADD COLUMN referral_link TEXT;
        RAISE NOTICE '✅ referral_link カラムを追加しました';
    ELSE
        RAISE NOTICE 'ℹ️ referral_link カラムは既に存在します';
    END IF;
END
$$;

-- 4. wallet_address カラム
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'users' AND column_name = 'wallet_address'
    ) THEN
        ALTER TABLE users ADD COLUMN wallet_address TEXT;
        RAISE NOTICE '✅ wallet_address カラムを追加しました';
    ELSE
        RAISE NOTICE 'ℹ️ wallet_address カラムは既に存在します';
    END IF;
END
$$;

-- 5. wallet_type カラム
DO $$
BEGIN
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

SELECT '=== カラム追加完了 ===' as result;
