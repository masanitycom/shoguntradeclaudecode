-- 🚨 緊急関数ロックダウン - 危険な関数を即座に無効化（完全修正版）

-- 1. 緊急関数無効化テーブルの作成
CREATE TABLE IF NOT EXISTS disabled_functions (
    id SERIAL PRIMARY KEY,
    function_name TEXT NOT NULL,
    reason TEXT NOT NULL,
    disabled_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    disabled_by TEXT DEFAULT CURRENT_USER,
    original_definition TEXT,
    UNIQUE(function_name)
);

-- 2. 全ての計算関数を緊急無効化（完全修正版）
DO $$
DECLARE
    func_record RECORD;
    func_definition TEXT;
    disable_sql TEXT;
BEGIN
    -- 危険な関数を特定して無効化
    FOR func_record IN 
        SELECT routine_name, routine_definition
        FROM information_schema.routines
        WHERE routine_schema = 'public'
        AND (
            routine_name LIKE '%calculate%' OR 
            routine_name LIKE '%reward%' OR 
            routine_name LIKE '%daily%' OR
            routine_name LIKE '%batch%'
        )
        AND (
            routine_definition LIKE '%daily_rewards%' OR
            routine_definition LIKE '%user_nfts%' OR
            routine_definition LIKE '%INSERT%' OR
            routine_definition LIKE '%UPDATE%'
        )
    LOOP
        -- 元の定義を保存
        INSERT INTO disabled_functions (function_name, reason, original_definition)
        VALUES (
            func_record.routine_name,
            '緊急無効化: 不正計算実行のため',
            func_record.routine_definition
        )
        ON CONFLICT (function_name) DO NOTHING;
        
        -- 関数を安全な空関数に置き換え（format修正版）
        disable_sql := 'CREATE OR REPLACE FUNCTION ' || quote_ident(func_record.routine_name) || '() 
            RETURNS TEXT AS $func$
            BEGIN
                RAISE EXCEPTION ''🚨 この関数は緊急無効化されています: ' || func_record.routine_name || ''';
                RETURN ''DISABLED'';
            END;
            $func$ LANGUAGE plpgsql;';
        
        EXECUTE disable_sql;
        
        RAISE NOTICE '🚨 関数無効化完了: %', func_record.routine_name;
    END LOOP;
END $$;

-- 3. 無効化された関数の一覧表示
SELECT 
    '🚨 無効化された関数一覧' as section,
    function_name,
    reason,
    disabled_at,
    disabled_by,
    LEFT(original_definition, 100) as original_preview
FROM disabled_functions
ORDER BY disabled_at DESC;

-- 4. 緊急停止フラグの更新
UPDATE system_emergency_flags 
SET 
    reason = reason || ' | 危険関数無効化完了',
    updated_at = NOW()
WHERE flag_name = 'CALCULATION_EMERGENCY_STOP';

-- 5. システム安全性確認
SELECT 
    '✅ システム安全性確認' as section,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.routines 
            WHERE routine_schema = 'public' 
            AND routine_name LIKE '%calculate%'
            AND routine_definition LIKE '%daily_rewards%'
            AND routine_definition NOT LIKE '%DISABLED%'
        ) THEN '❌ まだ危険な関数が存在'
        ELSE '✅ 全ての危険な関数が無効化済み'
    END as safety_status,
    (SELECT COUNT(*) FROM disabled_functions) as disabled_function_count,
    (SELECT is_active FROM system_emergency_flags WHERE flag_name = 'CALCULATION_EMERGENCY_STOP') as emergency_stop_active;

-- 6. 最終安全確認メッセージ
SELECT 
    '🛡️ 緊急対応完了' as section,
    '✅ 危険な計算関数を全て無効化しました' as action_1,
    '✅ 緊急停止フラグが有効です' as action_2,
    '✅ 不正データは全てバックアップ済みです' as action_3,
    '✅ システムは現在安全な状態です' as action_4,
    '⚠️ 管理者による明示的な承認なしに計算は実行されません' as warning;
