-- 修正結果の要約確認

SELECT 
    '全ランク修正完了' as status,
    COUNT(*) as total_users,
    SUM(CASE WHEN rank_level = 0 THEN 1 ELSE 0 END) as rank_none,
    SUM(CASE WHEN rank_level = 1 THEN 1 ELSE 0 END) as rank_ashigaru,
    SUM(CASE WHEN rank_level = 2 THEN 1 ELSE 0 END) as rank_bushou,
    SUM(CASE WHEN rank_level = 3 THEN 1 ELSE 0 END) as rank_daikan,
    SUM(CASE WHEN rank_level = 4 THEN 1 ELSE 0 END) as rank_bugyou,
    SUM(CASE WHEN rank_level = 5 THEN 1 ELSE 0 END) as rank_rouchu,
    SUM(CASE WHEN rank_level = 6 THEN 1 ELSE 0 END) as rank_tairou,
    SUM(CASE WHEN rank_level = 7 THEN 1 ELSE 0 END) as rank_daimyou,
    SUM(CASE WHEN rank_level = 8 THEN 1 ELSE 0 END) as rank_shougun
FROM user_rank_history 
WHERE is_current = true;
