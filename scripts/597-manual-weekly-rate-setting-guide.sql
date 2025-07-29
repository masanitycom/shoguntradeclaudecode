-- 手動週利設定ガイド

-- グループ別週利設定の説明
SELECT 
    'Group-Based Weekly Rate Setting Guide' as guide_title,
    '各グループごとに異なる週利を設定する必要があります' as description;

-- テンプレート: 週利設定コマンド
SELECT 
    'Template' as template_type,
    'SELECT * FROM set_weekly_rate_manual(''2025-02-10'', 2.6);' as sql_command;

-- 設定テンプレート例
SELECT 
    'Template Example' as template_type,
    'SELECT * FROM set_group_weekly_rate(''2025-02-10'', ''0.5%グループ'', 1.5, ''random'');' as sql_command
UNION ALL
SELECT 
    'Template Example',
    'SELECT * FROM set_group_weekly_rate(''2025-02-10'', ''1.0%グループ'', 2.0, ''random'');'
UNION ALL
SELECT 
    'Template Example',
    'SELECT * FROM set_group_weekly_rate(''2025-02-10'', ''1.25%グループ'', 2.3, ''random'');'
UNION ALL
SELECT 
    'Template Example',
    'SELECT * FROM set_group_weekly_rate(''2025-02-10'', ''1.5%グループ'', 2.6, ''random'');'
UNION ALL
SELECT 
    'Template Example',
    'SELECT * FROM set_group_weekly_rate(''2025-02-10'', ''1.75%グループ'', 2.9, ''random'');'
UNION ALL
SELECT 
    'Template Example',
    'SELECT * FROM set_group_weekly_rate(''2025-02-10'', ''2.0%グループ'', 3.2, ''random'');';

-- 使用例
SELECT 
    'Example Commands' as example_type,
    'Set 2.6% for Feb 10 week' as description,
    'SELECT * FROM set_weekly_rate_manual(''2025-02-10'', 2.6);' as command
UNION ALL
SELECT 
    'Example Commands',
    'Check Feb 10 week settings',
    'SELECT * FROM check_weekly_rate(''2025-02-10'');'
UNION ALL
SELECT 
    'Example Commands',
    'List all configured weeks',
    'SELECT * FROM list_configured_weeks();'
UNION ALL
SELECT 
    'Example Commands',
    'Delete Feb 10 week settings',
    'SELECT * FROM delete_weekly_rate(''2025-02-10'');';

-- 確認用コマンド
SELECT 
    'Check Commands' as command_type,
    'SELECT * FROM check_weekly_rate(''2025-02-10'');' as copy_paste_command
UNION ALL
SELECT 
    'Check Commands',
    'SELECT * FROM list_configured_weeks();';
