-- 🔍 1125Ritsukoを紹介者としているユーザーを確認

SELECT 
    '❌ 1125Ritsukoを紹介者としているユーザー' as issue_type,
    u.user_id,
    u.name,
    '1125Ritsuko' as wrong_referrer,
    'これらのユーザーの紹介者を修正する必要がある' as action_needed
FROM users u
WHERE u.referrer_id = (SELECT id FROM users WHERE user_id = '1125Ritsuko')
ORDER BY u.user_id;

-- 1125Ritsukoの詳細確認
SELECT 
    '📊 1125Ritsuko詳細' as info_type,
    u.user_id,
    u.name,
    r.user_id as referrer,
    (SELECT COUNT(*) FROM users WHERE referrer_id = u.id) as referral_count
FROM users u
LEFT JOIN users r ON u.referrer_id = r.id
WHERE u.user_id = '1125Ritsuko';
