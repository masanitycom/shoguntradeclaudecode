-- RLS・トリガー・権限の完全調査

-- 1. RLS状態確認（修正版）
SELECT 
    '🔒 RLS状態確認' as section,
    schemaname,
    tablename,
    c.relrowsecurity as rls_enabled,
    c.relforcerowsecurity as force_rls
FROM pg_tables t
JOIN pg_class c ON c.relname = t.tablename
WHERE tablename = 'nfts';

-- 2. RLSポリシー確認
SELECT 
    '📋 RLSポリシー詳細' as section,
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE tablename = 'nfts';

-- 3. トリガー詳細確認
SELECT 
    '⚡ トリガー詳細確認' as section,
    tgname as trigger_name,
    tgenabled as enabled,
    tgtype as trigger_type,
    proname as function_name,
    LEFT(prosrc, 200) as function_source_preview
FROM pg_trigger t
JOIN pg_proc p ON t.tgfoid = p.oid
WHERE tgrelid = 'nfts'::regclass
AND tgname NOT LIKE 'RI_%';

-- 4. 現在のユーザー・権限確認
SELECT 
    '👤 現在のユーザー・権限' as section,
    current_user as current_user,
    session_user as session_user,
    current_role as current_role,
    has_table_privilege('nfts', 'UPDATE') as can_update_nfts,
    has_table_privilege('nfts', 'SELECT') as can_select_nfts;

-- 5. テーブル所有者確認
SELECT 
    '🏠 テーブル所有者確認' as section,
    schemaname,
    tablename,
    tableowner
FROM pg_tables
WHERE tablename = 'nfts';

-- 6. テーブル制約確認（PostgreSQL 12+対応）
SELECT 
    '🔗 テーブル制約確認' as section,
    conname as constraint_name,
    contype::text as constraint_type,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint
WHERE conrelid = 'nfts'::regclass;

-- 7. インデックス確認
SELECT 
    '📇 インデックス確認' as section,
    indexname,
    indexdef
FROM pg_indexes
WHERE tablename = 'nfts';

-- 8. 現在のNFT状態確認
SELECT 
    '📊 現在のNFT状態' as section,
    name,
    daily_rate_limit,
    (daily_rate_limit * 100) || '%' as current_rate,
    is_special,
    is_active,
    updated_at
FROM nfts
WHERE name IN ('SHOGUN NFT 100', 'SHOGUN NFT 300', 'SHOGUN NFT 1000 (Special)', 'SHOGUN NFT 30000', 'SHOGUN NFT 100000')
ORDER BY name;
