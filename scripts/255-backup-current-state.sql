-- 現在の状態をバックアップしてから復元作業を開始

-- 1. 現在の紹介関係をバックアップテーブルに保存
CREATE TABLE IF NOT EXISTS referral_backup_emergency (
    id SERIAL PRIMARY KEY,
    user_id UUID,
    user_code TEXT,
    user_name TEXT,
    user_email TEXT,
    user_created_at TIMESTAMP WITH TIME ZONE,
    referrer_id UUID,
    referrer_code TEXT,
    referrer_name TEXT,
    referrer_email TEXT,
    backup_timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    backup_reason TEXT
);

-- 現在の状態をバックアップ
INSERT INTO referral_backup_emergency (
    user_id, user_code, user_name, user_email, user_created_at,
    referrer_id, referrer_code, referrer_name, referrer_email,
    backup_reason
)
SELECT 
    u.id, u.user_id, u.name, u.email, u.created_at,
    u.referrer_id, ref.user_id, ref.name, ref.email,
    'Emergency backup before restoration'
FROM users u
LEFT JOIN users ref ON u.referrer_id = ref.id
WHERE u.is_admin = false;

-- 2. バックアップ確認
SELECT 
    'Backup Status' as status,
    COUNT(*) as backed_up_users,
    COUNT(CASE WHEN referrer_id IS NOT NULL THEN 1 END) as users_with_referrer
FROM referral_backup_emergency
WHERE backup_reason = 'Emergency backup before restoration';
