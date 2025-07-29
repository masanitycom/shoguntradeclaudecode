-- 現在の構造に合わせて不足している紹介機能を追加

SELECT '=== 現在の構造確認完了 ===' as step;

-- 不足しているカラムを追加
DO $$
BEGIN
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
END
$$;

-- 既存ユーザーに自分の紹介コードを生成
DO $$
DECLARE
    user_record RECORD;
    counter INTEGER := 1;
    generated_count INTEGER := 0;
BEGIN
    FOR user_record IN 
        SELECT id, name FROM users 
        WHERE my_referral_code IS NULL 
        AND is_admin = false
        ORDER BY created_at
    LOOP
        UPDATE users 
        SET my_referral_code = 'REF' || LPAD(counter::TEXT, 6, '0')
        WHERE id = user_record.id;
        
        counter := counter + 1;
        generated_count := generated_count + 1;
        
        -- 進捗表示（50人ごと）
        IF generated_count % 50 = 0 THEN
            RAISE NOTICE '進捗: % 人に紹介コードを生成', generated_count;
        END IF;
    END LOOP;
    
    RAISE NOTICE '✅ 合計 % 人のユーザーに紹介コードを生成しました', generated_count;
END
$$;

-- 紹介リンクを生成
UPDATE users 
SET referral_link = 'https://shogun-trade.com/register?ref=' || my_referral_code
WHERE referral_link IS NULL 
AND my_referral_code IS NOT NULL;

SELECT '=== 紹介機能追加完了 ===' as result;
