-- tasksテーブルを完全に再作成

-- 既存のtasksテーブルをドロップ（存在する場合）
DROP TABLE IF EXISTS tasks CASCADE;

-- tasksテーブルを新規作成
CREATE TABLE tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    question TEXT NOT NULL,
    option1 TEXT NOT NULL,
    option2 TEXT NOT NULL,
    option3 TEXT NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLSを有効化
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;

-- 管理者のみアクセス可能なポリシーを作成
CREATE POLICY "Admin can manage tasks" ON tasks
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.is_admin = true
        )
    );

-- サンプルデータを挿入
INSERT INTO tasks (question, option1, option2, option3, is_active) VALUES
('あなたの好きな戦国武将は？', '豊臣秀吉', '徳川家康', '織田信長', true),
('SHOGUN TRADEの魅力は？', '高い日利', '安全性', 'コミュニティ', true),
('投資で最も重要なことは？', 'リスク管理', '情報収集', '長期視点', true),
('NFTの価値を決める要因は？', '希少性', '実用性', 'コミュニティ', true),
('暗号資産投資の基本は？', '分散投資', '長期保有', '情報収集', true);

-- 作成完了メッセージ
SELECT '=== Tasks テーブル作成完了 ===' as message;

-- 最終確認
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'tasks' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- データ確認
SELECT 
    id,
    question,
    option1,
    option2,
    option3,
    is_active,
    created_at
FROM tasks
ORDER BY created_at;
