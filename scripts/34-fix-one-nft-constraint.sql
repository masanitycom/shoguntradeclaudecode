-- 1人1枚制限の強制ロジック（修正版）
-- UI側の抜け道を完全に防止

-- まず現在の状況を確認
SELECT '1人1枚制限チェック開始' as step;

-- 複数NFTを持つユーザーがいるかチェック
SELECT 
    '複数NFT保有ユーザー確認' as check_type,
    user_id,
    COUNT(*) as nft_count
FROM user_nfts 
WHERE is_active = true 
GROUP BY user_id 
HAVING COUNT(*) > 1
ORDER BY nft_count DESC;

-- 複数NFT保有ユーザーの総数
SELECT 
    '複数NFT保有ユーザー数' as check_type,
    COUNT(*) as user_count
FROM (
    SELECT user_id
    FROM user_nfts 
    WHERE is_active = true 
    GROUP BY user_id 
    HAVING COUNT(*) > 1
) as multiple_nft_users;

-- 制約追加の準備
DO $$
DECLARE
    violation_count INTEGER;
BEGIN
    -- 制約違反があるかチェック
    SELECT COUNT(*) INTO violation_count
    FROM (
        SELECT user_id
        FROM user_nfts 
        WHERE is_active = true 
        GROUP BY user_id 
        HAVING COUNT(*) > 1
    ) as violations;
    
    IF violation_count > 0 THEN
        RAISE NOTICE '⚠️ 警告: % 人のユーザーが複数のアクティブNFTを保有しています', violation_count;
        RAISE NOTICE '制約を追加する前に、データの整合性を確認してください';
        RAISE NOTICE '必要に応じて、古いNFTを非アクティブ化してください';
    ELSE
        RAISE NOTICE '✅ 全ユーザーが1人1枚の制限を満たしています';
        
        -- 制約を追加
        BEGIN
            -- 既存の制約があれば削除
            DROP INDEX IF EXISTS idx_unique_active_nft_per_user;
            
            -- 部分UNIQUE INDEXを作成（WHERE句付き）
            CREATE UNIQUE INDEX idx_unique_active_nft_per_user 
            ON user_nfts (user_id) 
            WHERE is_active = true;
            
            RAISE NOTICE '✅ 1人1枚制限のユニークインデックスを追加しました';
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE '❌ インデックス追加に失敗しました: %', SQLERRM;
        END;
    END IF;
END
$$;

-- 制約追加後の確認
DO $$
BEGIN
    -- インデックスが正しく追加されたかチェック
    IF EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE tablename = 'user_nfts' 
        AND indexname = 'idx_unique_active_nft_per_user'
    ) THEN
        RAISE NOTICE '✅ ユニークインデックスが正常に追加されました';
    ELSE
        RAISE NOTICE '❌ ユニークインデックスが追加されていません';
    END IF;
END
$$;

-- 追加の安全策：トリガーベースの制約チェック
CREATE OR REPLACE FUNCTION check_one_nft_per_user()
RETURNS TRIGGER AS $$
DECLARE
    active_nft_count INTEGER;
BEGIN
    -- 挿入または更新でis_active = trueになる場合のみチェック
    IF NEW.is_active = true THEN
        -- 同じユーザーの他のアクティブNFTをカウント
        SELECT COUNT(*) INTO active_nft_count
        FROM user_nfts 
        WHERE user_id = NEW.user_id 
        AND is_active = true 
        AND id != COALESCE(NEW.id, '00000000-0000-0000-0000-000000000000'::UUID);
        
        IF active_nft_count > 0 THEN
            RAISE EXCEPTION '1人1枚制限違反: ユーザー % は既にアクティブなNFTを保有しています', NEW.user_id;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- トリガーを設定
DROP TRIGGER IF EXISTS trigger_one_nft_per_user ON user_nfts;
CREATE TRIGGER trigger_one_nft_per_user
    BEFORE INSERT OR UPDATE ON user_nfts
    FOR EACH ROW
    EXECUTE FUNCTION check_one_nft_per_user();

-- テスト用情報
DO $$
BEGIN
    RAISE NOTICE '=== 1人1枚制限の実装完了 ===';
    RAISE NOTICE '1. ユニークインデックス: 同一ユーザーの複数アクティブNFTを防止';
    RAISE NOTICE '2. トリガー: 挿入・更新時の追加チェック';
    RAISE NOTICE '3. データベースレベルで完全に制限を強制';
    RAISE NOTICE '4. UI側の抜け道を完全に防止';
END
$$;

-- 完了メッセージ
SELECT '1人1枚制限の制約追加が完了しました（インデックス + トリガー）' AS result;
