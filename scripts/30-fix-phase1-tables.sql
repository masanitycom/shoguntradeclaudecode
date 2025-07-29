-- 【安全】既存データを一切変更しない新テーブル追加SQL

-- 1. 支払いアドレステーブル（完全に新規）
CREATE TABLE IF NOT EXISTS payment_addresses (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    payment_method VARCHAR(50) NOT NULL,
    address TEXT NOT NULL,
    qr_code_url TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- デフォルトのUSDT BEP20アドレスを挿入
INSERT INTO payment_addresses (payment_method, address, is_active) 
VALUES ('USDT_BEP20', '0x1234567890123456789012345678901234567890', true)
ON CONFLICT DO NOTHING;

-- 2. 日本の祝日カレンダーテーブル（完全に新規）
CREATE TABLE IF NOT EXISTS holidays_jp (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    holiday_date DATE NOT NULL UNIQUE,
    holiday_name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2024-2025年の主要祝日を挿入
INSERT INTO holidays_jp (holiday_date, holiday_name) VALUES
('2024-01-01', '元日'),
('2024-01-08', '成人の日'),
('2024-02-11', '建国記念の日'),
('2024-02-23', '天皇誕生日'),
('2024-03-20', '春分の日'),
('2024-04-29', '昭和の日'),
('2024-05-03', '憲法記念日'),
('2024-05-04', 'みどりの日'),
('2024-05-05', 'こどもの日'),
('2024-07-15', '海の日'),
('2024-08-11', '山の日'),
('2024-09-16', '敬老の日'),
('2024-09-22', '秋分の日'),
('2024-10-14', 'スポーツの日'),
('2024-11-03', '文化の日'),
('2024-11-23', '勤労感謝の日'),
('2025-01-01', '元日'),
('2025-01-13', '成人の日'),
('2025-02-11', '建国記念の日'),
('2025-02-23', '天皇誕生日'),
('2025-03-20', '春分の日'),
('2025-04-29', '昭和の日'),
('2025-05-03', '憲法記念日'),
('2025-05-04', 'みどりの日'),
('2025-05-05', 'こどもの日'),
('2025-07-21', '海の日'),
('2025-08-11', '山の日'),
('2025-09-15', '敬老の日'),
('2025-09-23', '秋分の日'),
('2025-10-13', 'スポーツの日'),
('2025-11-03', '文化の日'),
('2025-11-23', '勤労感謝の日')
ON CONFLICT (holiday_date) DO NOTHING;

-- 3. 週間利益管理テーブル（完全に新規）
CREATE TABLE IF NOT EXISTS weekly_profits (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    week_start_date DATE NOT NULL UNIQUE,
    total_profit DECIMAL(15,2) NOT NULL,
    tenka_bonus_pool DECIMAL(15,2) GENERATED ALWAYS AS (total_profit * 0.20) STORED,
    input_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. tasksテーブル（存在しない場合のみ作成）
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'tasks' AND table_schema = 'public') THEN
        CREATE TABLE tasks (
            id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
            question TEXT NOT NULL,
            option1 TEXT NOT NULL,
            option2 TEXT NOT NULL,
            option3 TEXT NOT NULL,
            is_active BOOLEAN DEFAULT true,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
        
        -- サンプルタスクを挿入
        INSERT INTO tasks (question, option1, option2, option3, is_active) VALUES
        ('あなたの好きな戦国武将は？', '豊臣秀吉', '徳川家康', '織田信長', true),
        ('日本で一番高い山は？', '富士山', '北岳', '奥穂高岳', true),
        ('SHOGUN TRADEの魅力は？', '高い日利', '安全性', 'コミュニティ', true);
        
        RAISE NOTICE 'tasksテーブルを新規作成しました';
    ELSE
        RAISE NOTICE 'tasksテーブルは既に存在します - スキップ';
    END IF;
END
$$;

-- 5. nft_purchase_applicationsテーブル（存在しない場合のみ作成）
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'nft_purchase_applications' AND table_schema = 'public') THEN
        CREATE TABLE nft_purchase_applications (
            id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
            user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
            nft_id UUID NOT NULL REFERENCES nfts(id) ON DELETE CASCADE,
            requested_price DECIMAL(10,2) NOT NULL,
            payment_method VARCHAR(50) NOT NULL DEFAULT 'USDT_BEP20',
            payment_proof_url TEXT,
            status VARCHAR(50) NOT NULL DEFAULT 'PENDING',
            admin_notes TEXT,
            approved_at TIMESTAMP WITH TIME ZONE,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
        
        RAISE NOTICE 'nft_purchase_applicationsテーブルを新規作成しました';
    ELSE
        RAISE NOTICE 'nft_purchase_applicationsテーブルは既に存在します - スキップ';
    END IF;
END
$$;

-- 6. reward_applicationsテーブル（存在しない場合のみ作成）
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'reward_applications' AND table_schema = 'public') THEN
        CREATE TABLE reward_applications (
            id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
            user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
            week_start_date DATE NOT NULL,
            total_reward_amount DECIMAL(10,2) NOT NULL,
            application_type VARCHAR(50) NOT NULL DEFAULT 'AIRDROP_TASK',
            task_id UUID REFERENCES tasks(id),
            task_answers JSONB,
            status VARCHAR(50) NOT NULL DEFAULT 'PENDING',
            approved_at TIMESTAMP WITH TIME ZONE,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
        
        RAISE NOTICE 'reward_applicationsテーブルを新規作成しました';
    ELSE
        RAISE NOTICE 'reward_applicationsテーブルは既に存在します - スキップ';
    END IF;
END
$$;

-- 7. RLSポリシーを設定
ALTER TABLE payment_addresses ENABLE ROW LEVEL SECURITY;
ALTER TABLE holidays_jp ENABLE ROW LEVEL SECURITY;
ALTER TABLE weekly_profits ENABLE ROW LEVEL SECURITY;

-- 支払いアドレス: 全員が読み取り可能
DROP POLICY IF EXISTS "payment_addresses_select" ON payment_addresses;
CREATE POLICY "payment_addresses_select" ON payment_addresses FOR SELECT USING (true);

-- 祝日: 全員が読み取り可能
DROP POLICY IF EXISTS "holidays_jp_select" ON holidays_jp;
CREATE POLICY "holidays_jp_select" ON holidays_jp FOR SELECT USING (true);

-- 週間利益: 管理者のみ操作可能
DROP POLICY IF EXISTS "weekly_profits_admin_all" ON weekly_profits;
CREATE POLICY "weekly_profits_admin_all" ON weekly_profits FOR ALL USING (
    EXISTS (
        SELECT 1 FROM users 
        WHERE users.id = auth.uid() 
        AND users.is_admin = true
    )
);

-- 8. 既存テーブルのRLSポリシーも設定
DO $$
BEGIN
    -- tasksテーブルのRLS
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'tasks' AND table_schema = 'public') THEN
        ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
        DROP POLICY IF EXISTS "tasks_select" ON tasks;
        CREATE POLICY "tasks_select" ON tasks FOR SELECT USING (true);
        
        -- 管理者のみ編集可能
        DROP POLICY IF EXISTS "tasks_admin_all" ON tasks;
        CREATE POLICY "tasks_admin_all" ON tasks FOR ALL USING (
            EXISTS (
                SELECT 1 FROM users 
                WHERE users.id = auth.uid() 
                AND users.is_admin = true
            )
        );
    END IF;
    
    -- nft_purchase_applicationsテーブルのRLS
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'nft_purchase_applications' AND table_schema = 'public') THEN
        ALTER TABLE nft_purchase_applications ENABLE ROW LEVEL SECURITY;
        DROP POLICY IF EXISTS "nft_purchase_applications_select" ON nft_purchase_applications;
        DROP POLICY IF EXISTS "nft_purchase_applications_insert" ON nft_purchase_applications;
        DROP POLICY IF EXISTS "nft_purchase_applications_update" ON nft_purchase_applications;
        DROP POLICY IF EXISTS "nft_purchase_applications_admin_all" ON nft_purchase_applications;
        
        CREATE POLICY "nft_purchase_applications_select" ON nft_purchase_applications FOR SELECT USING (auth.uid() = user_id);
        CREATE POLICY "nft_purchase_applications_insert" ON nft_purchase_applications FOR INSERT WITH CHECK (auth.uid() = user_id);
        CREATE POLICY "nft_purchase_applications_update" ON nft_purchase_applications FOR UPDATE USING (auth.uid() = user_id);
        
        -- 管理者は全て見れる
        CREATE POLICY "nft_purchase_applications_admin_all" ON nft_purchase_applications FOR ALL USING (
            EXISTS (
                SELECT 1 FROM users 
                WHERE users.id = auth.uid() 
                AND users.is_admin = true
            )
        );
    END IF;
    
    -- reward_applicationsテーブルのRLS
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'reward_applications' AND table_schema = 'public') THEN
        ALTER TABLE reward_applications ENABLE ROW LEVEL SECURITY;
        DROP POLICY IF EXISTS "reward_applications_select" ON reward_applications;
        DROP POLICY IF EXISTS "reward_applications_insert" ON reward_applications;
        DROP POLICY IF EXISTS "reward_applications_admin_all" ON reward_applications;
        
        CREATE POLICY "reward_applications_select" ON reward_applications FOR SELECT USING (auth.uid() = user_id);
        CREATE POLICY "reward_applications_insert" ON reward_applications FOR INSERT WITH CHECK (auth.uid() = user_id);
        
        -- 管理者は全て見れる
        CREATE POLICY "reward_applications_admin_all" ON reward_applications FOR ALL USING (
            EXISTS (
                SELECT 1 FROM users 
                WHERE users.id = auth.uid() 
                AND users.is_admin = true
            )
        );
    END IF;
END
$$;

-- 完了メッセージ
SELECT 'Phase 1テーブル作成が完了しました！既存データは一切変更されていません。' AS result;
