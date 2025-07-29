-- ウォレット関連のカラム名を確認
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'users' 
AND column_name LIKE '%wallet%' OR column_name LIKE '%usdt%' OR column_name LIKE '%address%'
ORDER BY column_name;
