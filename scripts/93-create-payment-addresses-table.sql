-- 支払いアドレステーブルの作成
CREATE TABLE IF NOT EXISTS payment_addresses (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  payment_method VARCHAR(50) NOT NULL,
  address TEXT NOT NULL,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- デフォルトのUSDT BEP-20アドレスを挿入（まだアドレスが設定されていない場合）
INSERT INTO payment_addresses (payment_method, address, is_active)
SELECT 'USDT_BEP20', 'アドレス未設定', true
WHERE NOT EXISTS (
  SELECT 1 FROM payment_addresses WHERE payment_method = 'USDT_BEP20'
);

-- RLSポリシーを設定
ALTER TABLE payment_addresses ENABLE ROW LEVEL SECURITY;

-- 管理者のみ編集可能
CREATE POLICY "管理者のみ支払いアドレス編集可能" ON payment_addresses
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.is_admin = true
    )
  );

-- 全ユーザーが閲覧可能
CREATE POLICY "全ユーザー支払いアドレス閲覧可能" ON payment_addresses
  FOR SELECT USING (true);

SELECT '=== 支払いアドレステーブル作成完了 ===' as result;
