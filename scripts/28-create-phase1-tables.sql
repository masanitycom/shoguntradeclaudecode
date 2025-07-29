-- Phase 1で必要な新しいテーブルを作成

-- 支払いアドレステーブル
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

-- NFT購入申請テーブル（既存の場合はスキップ）
CREATE TABLE IF NOT EXISTS nft_purchase_applications (
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

-- エアドロップタスクテーブル（既存の場合はスキップ）
CREATE TABLE IF NOT EXISTS tasks (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    question TEXT NOT NULL,
    option1 TEXT NOT NULL,
    option2 TEXT NOT NULL,
    option3 TEXT NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 報酬申請テーブル（既存の場合はスキップ）
CREATE TABLE IF NOT EXISTS reward_applications (
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

-- サンプルタスクを挿入
INSERT INTO tasks (question, option1, option2, option3, is_active) VALUES
('あなたの好きな戦国武将は？', '豊臣秀吉', '徳川家康', '織田信長', true),
('日本で一番高い山は？', '富士山', '北岳', '奥穂高岳', true),
('SHOGUN TRADEの魅力は？', '高い日利', '安全性', 'コミュニティ', true)
ON CONFLICT DO NOTHING;

-- RLSポリシーを設定
ALTER TABLE payment_addresses ENABLE ROW LEVEL SECURITY;
ALTER TABLE nft_purchase_applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE reward_applications ENABLE ROW LEVEL SECURITY;

-- 支払いアドレス: 全員が読み取り可能
CREATE POLICY "payment_addresses_select" ON payment_addresses FOR SELECT USING (true);

-- NFT購入申請: 自分の申請のみ操作可能
CREATE POLICY "nft_purchase_applications_select" ON nft_purchase_applications FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "nft_purchase_applications_insert" ON nft_purchase_applications FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "nft_purchase_applications_update" ON nft_purchase_applications FOR UPDATE USING (auth.uid() = user_id);

-- タスク: 全員が読み取り可能
CREATE POLICY "tasks_select" ON tasks FOR SELECT USING (true);

-- 報酬申請: 自分の申請のみ操作可能
CREATE POLICY "reward_applications_select" ON reward_applications FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "reward_applications_insert" ON reward_applications FOR INSERT WITH CHECK (auth.uid() = user_id);
