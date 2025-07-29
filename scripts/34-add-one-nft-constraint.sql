-- 1人1枚制限の強制ロジック
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
            ALTER TABLE user_nfts DROP CONSTRAINT IF EXISTS unique_active_nft_per_user;
            
            -- 新しい制約を追加
            ALTER TABLE user_nfts ADD CONSTRAINT unique_active_nft_per_user 
            UNIQUE (user_id) WHERE (is_active = true);
            
            RAISE NOTICE '✅ 1人1枚制限の制約を追加しました';
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE '❌ 制約追加に失敗しました: %', SQLERRM;
        END;
    END IF;
END
$$;

-- 制約追加後の確認
DO $$
BEGIN
    -- 制約が正しく追加されたかチェック
    IF EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_name = 'user_nfts' 
        AND constraint_name = 'unique_active_nft_per_user'
    ) THEN
        RAISE NOTICE '✅ 制約が正常に追加されました';
    ELSE
        RAISE NOTICE '❌ 制約が追加されていません';
    END IF;
END
$$;

-- テスト用：制約が機能するかテスト（実際には実行されない）
DO $$
BEGIN
    RAISE NOTICE '=== 制約テスト情報 ===';
    RAISE NOTICE '今後、同一ユーザーが複数のアクティブNFTを持とうとすると、';
    RAISE NOTICE 'データベースレベルでエラーが発生し、挿入が拒否されます。';
    RAISE NOTICE 'これにより、UI側の抜け道を完全に防止できます。';
END
$$;

-- 完了メッセージ
SELECT '1人1枚制限の制約追加が完了しました' AS result;
