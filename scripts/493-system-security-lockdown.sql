-- 🔒 システムセキュリティロックダウン

-- 1. 緊急停止フラグテーブル作成
CREATE TABLE IF NOT EXISTS system_emergency_flags (
    flag_name TEXT PRIMARY KEY,
    is_active BOOLEAN DEFAULT FALSE,
    reason TEXT,
    created_by TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. 緊急停止フラグを設定
INSERT INTO system_emergency_flags (flag_name, is_active, reason, created_by)
VALUES 
    ('CALCULATION_EMERGENCY_STOP', TRUE, '週利設定なしで不正計算実行のため緊急停止', 'system_admin')
ON CONFLICT (flag_name) 
DO UPDATE SET 
    is_active = TRUE,
    reason = '週利設定なしで不正計算実行のため緊急停止',
    updated_at = NOW();

-- 3. 危険な計算関数を安全化（既存関数を置き換え）
CREATE OR REPLACE FUNCTION calculate_daily_rewards_for_date(target_date DATE)
RETURNS TABLE(
    user_id UUID,
    nft_id UUID,
    reward_amount NUMERIC,
    calculation_details JSONB
) 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- 🚨 緊急停止チェック
    IF EXISTS (
        SELECT 1 FROM system_emergency_flags 
        WHERE flag_name = 'CALCULATION_EMERGENCY_STOP' AND is_active = TRUE
    ) THEN
        RAISE EXCEPTION '🚨 緊急停止: 計算機能は管理者により停止されています';
    END IF;
    
    -- 週利設定必須チェック
    IF NOT EXISTS (
        SELECT 1 FROM group_weekly_rates 
        WHERE week_start_date <= target_date 
        AND week_start_date + INTERVAL '6 days' >= target_date
    ) THEN
        RAISE EXCEPTION '🚨 エラー: 対象日(%s)の週利設定が存在しません', target_date;
    END IF;
    
    -- 平日チェック
    IF EXTRACT(DOW FROM target_date) IN (0, 6) THEN
        RAISE EXCEPTION '🚨 エラー: 土日は計算対象外です (%s)', target_date;
    END IF;
    
    RAISE NOTICE '✅ 安全チェック通過: %s の計算を開始', target_date;
    
    -- 実際の計算処理は後で実装
    RETURN;
END;
$$;

-- 4. 管理者用緊急解除関数
CREATE OR REPLACE FUNCTION emergency_unlock_calculations(admin_password TEXT)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- 簡易パスワードチェック（本番では強化必要）
    IF admin_password != 'SHOGUN_EMERGENCY_2025' THEN
        RAISE EXCEPTION '🚨 認証失敗: 管理者パスワードが正しくありません';
    END IF;
    
    UPDATE system_emergency_flags 
    SET 
        is_active = FALSE,
        reason = reason || ' [管理者により解除]',
        updated_at = NOW()
    WHERE flag_name = 'CALCULATION_EMERGENCY_STOP';
    
    RETURN '✅ 緊急停止を解除しました。計算機能が利用可能です。';
END;
$$;

-- 5. システム状態確認
SELECT 
    '🔒 セキュリティ状態' as section,
    flag_name,
    is_active,
    reason,
    created_at
FROM system_emergency_flags;
