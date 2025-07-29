-- NFT購入申請のエラー修正

-- nft_purchase_applicationsテーブルの構造確認
SELECT 'nft_purchase_applicationsテーブル構造確認' as info;
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'nft_purchase_applications' AND table_schema = 'public'
ORDER BY ordinal_position;

-- payment_addressカラムの制約を修正
DO $$
BEGIN
    -- payment_addressカラムが存在し、NOT NULL制約がある場合は修正
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'nft_purchase_applications' 
        AND column_name = 'payment_address'
        AND is_nullable = 'NO'
    ) THEN
        -- NOT NULL制約を削除してNULL許可に変更
        ALTER TABLE nft_purchase_applications 
        ALTER COLUMN payment_address DROP NOT NULL;
        
        RAISE NOTICE '✅ payment_addressカラムのNOT NULL制約を削除しました';
    ELSIF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'nft_purchase_applications' 
        AND column_name = 'payment_address'
    ) THEN
        RAISE NOTICE 'ℹ️ payment_addressカラムは既にNULL許可です';
    ELSE
        -- カラムが存在しない場合は追加
        ALTER TABLE nft_purchase_applications 
        ADD COLUMN payment_address TEXT;
        
        RAISE NOTICE '✅ payment_addressカラムを追加しました';
    END IF;
END
$$;

-- デフォルトの支払いアドレスを設定する関数
CREATE OR REPLACE FUNCTION get_default_payment_address()
RETURNS TEXT AS $$
DECLARE
    default_address TEXT;
BEGIN
    SELECT address INTO default_address
    FROM payment_addresses 
    WHERE payment_method = 'USDT_BEP20' 
    AND is_active = true 
    LIMIT 1;
    
    RETURN COALESCE(default_address, '0x1234567890123456789012345678901234567890');
END;
$$ LANGUAGE plpgsql;

-- 既存の申請でpayment_addressがNULLの場合はデフォルト値を設定
UPDATE nft_purchase_applications 
SET payment_address = get_default_payment_address()
WHERE payment_address IS NULL;

-- 完了メッセージ
SELECT 'NFT購入申請エラーの修正が完了しました' AS result;
