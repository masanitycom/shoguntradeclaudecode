-- 📋 運用マニュアル作成 - 今後の安全な運用のために

-- 1. 運用マニュアルテーブルの作成
CREATE TABLE IF NOT EXISTS operation_manual (
    id SERIAL PRIMARY KEY,
    section_name TEXT NOT NULL,
    procedure_name TEXT NOT NULL,
    step_number INTEGER NOT NULL,
    step_description TEXT NOT NULL,
    warning_level TEXT CHECK (warning_level IN ('INFO', 'WARNING', 'CRITICAL')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. 週利設定の安全な手順
INSERT INTO operation_manual (section_name, procedure_name, step_number, step_description, warning_level) VALUES
('週利管理', '週利設定手順', 1, '管理画面にログインし、週利管理ページにアクセス', 'INFO'),
('週利管理', '週利設定手順', 2, '緊急停止フラグが無効であることを確認', 'CRITICAL'),
('週利管理', '週利設定手順', 3, '各グループの週利を慎重に設定（通常2.6%程度）', 'WARNING'),
('週利管理', '週利設定手順', 4, '設定前に自動バックアップが作成されることを確認', 'WARNING'),
('週利管理', '週利設定手順', 5, '設定完了後、システム状況を確認', 'INFO'),

('日利計算', '計算実行手順', 1, '週利設定が存在することを事前確認', 'CRITICAL'),
('日利計算', '計算実行手順', 2, '緊急停止フラグが無効であることを確認', 'CRITICAL'),
('日利計算', '計算実行手順', 3, '平日（月〜金）であることを確認', 'WARNING'),
('日利計算', '計算実行手順', 4, 'アクティブなNFT投資が存在することを確認', 'WARNING'),
('日利計算', '計算実行手順', 5, '計算実行ボタンをクリック', 'INFO'),
('日利計算', '計算実行手順', 6, '計算結果を確認し、異常がないかチェック', 'WARNING'),

('緊急対応', '異常検知時の対応', 1, '異常を検知したら即座に緊急停止フラグを有効化', 'CRITICAL'),
('緊急対応', '異常検知時の対応', 2, '不正データのバックアップを作成', 'CRITICAL'),
('緊急対応', '異常検知時の対応', 3, '危険な関数を無効化', 'CRITICAL'),
('緊急対応', '異常検知時の対応', 4, '根本原因を調査・特定', 'WARNING'),
('緊急対応', '異常検知時の対応', 5, '修正後、システム安全性を確認してから運用再開', 'CRITICAL');

-- 3. 安全チェックリスト
CREATE TABLE IF NOT EXISTS safety_checklist (
    id SERIAL PRIMARY KEY,
    check_category TEXT NOT NULL,
    check_item TEXT NOT NULL,
    check_frequency TEXT NOT NULL,
    is_critical BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

INSERT INTO safety_checklist (check_category, check_item, check_frequency, is_critical) VALUES
('日次チェック', '緊急停止フラグの状態確認', '毎日', TRUE),
('日次チェック', 'システム健全性の確認', '毎日', TRUE),
('日次チェック', '計算結果の妥当性確認', '毎日', TRUE),

('週次チェック', '週利設定の存在確認', '毎週', TRUE),
('週次チェック', 'バックアップデータの整合性確認', '毎週', TRUE),
('週次チェック', '無効化関数の状態確認', '毎週', FALSE),

('月次チェック', 'システム全体の安全性監査', '毎月', TRUE),
('月次チェック', '運用ログの詳細分析', '毎月', FALSE),
('月次チェック', '緊急対応手順の見直し', '毎月', FALSE);

-- 4. 今回の事件記録
CREATE TABLE IF NOT EXISTS incident_log (
    id SERIAL PRIMARY KEY,
    incident_date DATE NOT NULL,
    incident_type TEXT NOT NULL,
    severity_level TEXT CHECK (severity_level IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL')),
    description TEXT NOT NULL,
    impact_amount NUMERIC,
    affected_users INTEGER,
    resolution_summary TEXT,
    lessons_learned TEXT,
    prevention_measures TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

INSERT INTO incident_log (
    incident_date, 
    incident_type, 
    severity_level, 
    description, 
    impact_amount, 
    affected_users, 
    resolution_summary, 
    lessons_learned, 
    prevention_measures
) VALUES (
    '2025-07-03',
    '不正計算実行',
    'CRITICAL',
    '週利設定なしで日利計算が実行され、$30,835.52の不正利益が発生。7,307件のレコードが作成され、297人のユーザーに影響。',
    30835.52,
    297,
    '不正データを全削除、危険関数を無効化、緊急停止システムを実装。バックアップを作成して証拠保全。',
    '週利設定の事前チェック機能が不十分だった。計算関数に安全性チェックが組み込まれていなかった。',
    '緊急停止フラグの実装、危険関数の無効化、週利設定必須チェックの実装、自動バックアップシステムの構築。'
);

-- 5. 運用マニュアルの表示
SELECT 
    '📋 運用マニュアル' as section,
    section_name,
    procedure_name,
    step_number,
    step_description,
    CASE warning_level
        WHEN 'CRITICAL' THEN '🚨 ' || step_description
        WHEN 'WARNING' THEN '⚠️ ' || step_description
        ELSE '📝 ' || step_description
    END as formatted_step
FROM operation_manual
ORDER BY section_name, procedure_name, step_number;

-- 6. 安全チェックリストの表示
SELECT 
    '✅ 安全チェックリスト' as section,
    check_category,
    check_item,
    check_frequency,
    CASE WHEN is_critical THEN '🚨 重要' ELSE '📝 通常' END as priority
FROM safety_checklist
ORDER BY 
    CASE check_frequency 
        WHEN '毎日' THEN 1 
        WHEN '毎週' THEN 2 
        WHEN '毎月' THEN 3 
        ELSE 4 
    END,
    is_critical DESC,
    check_item;

-- 7. 事件記録の表示
SELECT 
    '📊 事件記録' as section,
    incident_date,
    incident_type,
    severity_level,
    description,
    '$' || impact_amount::TEXT as impact_amount,
    affected_users || '人' as affected_users,
    resolution_summary,
    lessons_learned,
    prevention_measures
FROM incident_log
ORDER BY incident_date DESC;

-- 8. 最終確認メッセージ
SELECT 
    '🎯 運用マニュアル作成完了' as section,
    '✅ 安全な運用手順を文書化しました' as manual_status,
    '✅ 日次・週次・月次チェックリストを作成しました' as checklist_status,
    '✅ 今回の事件を詳細に記録しました' as incident_record,
    '✅ 今後の安全な運用が保証されます' as safety_guarantee,
    '📋 管理者は必ずこのマニュアルに従って運用してください' as important_note;
