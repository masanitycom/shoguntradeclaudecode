-- ユーザーテーブルに不足しているカラムを追加

-- 既存のusersテーブル構造を確認
SELECT 'usersテーブル現在の構造' as info;
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'users' AND table_schema = 'public'
ORDER BY ordinal_position;

-- 不足しているカラムを追加
DO $$
BEGIN
    -- ウォレットアドレス
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'users' AND column_name = 'wallet_address'
    ) THEN
        ALTER TABLE users ADD COLUMN wallet_address TEXT;
        RAISE NOTICE '✅ wallet_addressカラムを追加しました';
    END IF;
    
    -- ウォレットタイプ
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'users' AND column_name = 'wallet_type'
    ) THEN
        ALTER TABLE users ADD COLUMN wallet_type VARCHAR(50) DEFAULT 'USDT_BEP20';
        RAISE NOTICE '✅ wallet_typeカラムを追加しました';
    END IF;
    
    -- 自分の紹介コード（招待する側）
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'users' AND column_name = 'my_referral_code'
    ) THEN
        ALTER TABLE users ADD COLUMN my_referral_code VARCHAR(20) UNIQUE;
        RAISE NOTICE '✅ my_referral_codeカラムを追加しました';
    END IF;
    
    -- 紹介リンク
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'users' AND column_name = 'referral_link'
    ) THEN
        ALTER TABLE users ADD COLUMN referral_link TEXT;
        RAISE NOTICE '✅ referral_linkカラムを追加しました';
    END IF;
END
$$;

-- 既存ユーザーに自分の紹介コードを生成
UPDATE users 
SET my_referral_code = 'REF' || LPAD((ROW_NUMBER() OVER (ORDER BY created_at))::TEXT, 6, '0')
WHERE my_referral_code IS NULL;

-- 紹介リンクを生成
UPDATE users 
SET referral_link = 'https://shogun-trade.com/register?ref=' || my_referral_code
WHERE referral_link IS NULL AND my_referral_code IS NOT NULL;

-- 完了メッセージ
SELECT 'ユーザーテーブルの拡張が完了しました' AS result;

-- 更新後の構造確認
SELECT 'usersテーブル更新後の構造' as info;
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'users' AND table_schema = 'public'
ORDER BY ordinal_position;
