const fs = require("fs")
const { createClient } = require("@supabase/supabase-js")

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY

if (!supabaseUrl || !supabaseServiceKey) {
  console.error("❌ Supabase環境変数が設定されていません")
  process.exit(1)
}

const supabase = createClient(supabaseUrl, supabaseServiceKey)

async function analyzeAllCSVUsers() {
  console.log("🔥 CSV全ユーザーの完全修正分析を開始...")
  console.log("=" * 60)

  try {
    // CSVファイルを取得
    console.log("📥 CSVファイルを取得中...")
    const csvUrl =
      "https://hebbkx1anhila5yf.public.blob.vercel-storage.com/SHOGUN%2BENISA%E7%B4%B9%E4%BB%8B%E8%80%85%E9%A0%86%E3%81%AB%E4%B8%A6%E3%81%B9%E6%9B%BF%E3%81%88%20-%20%E3%82%B7%E3%83%BC%E3%83%882-3sEEqgz48qctjxfbOBP51UPTybAwSP.csv"

    const response = await fetch(csvUrl)
    const csvText = await response.text()

    // CSVをパース
    const lines = csvText.split("\n").filter((line) => line.trim())
    console.log(`📊 CSV総行数: ${lines.length}行`)

    const csvUsers = []
    for (let i = 1; i < lines.length; i++) {
      const values = lines[i].split(",")
      if (values.length >= 4) {
        csvUsers.push({
          name: values[0]?.trim(),
          user_id: values[1]?.trim(),
          tel: values[2]?.trim(),
          referrer: values[3]?.trim() || null,
        })
      }
    }

    console.log(`✅ CSV解析完了: ${csvUsers.length}人`)
    console.log("🎯 CSVの正しい紹介関係に全て修正します！\n")

    // データベースから全ユーザーを取得
    console.log("📥 データベースから全ユーザーを取得中...")
    const { data: dbUsers, error: dbError } = await supabase
      .from("users")
      .select(`
        user_id,
        name,
        referrer_id,
        referrer:referrer_id(user_id, name)
      `)
      .eq("is_admin", false)
      .order("user_id")

    if (dbError) {
      console.error("❌ データベースユーザー取得エラー:", dbError)
      return
    }

    console.log(`✅ データベース取得完了: ${dbUsers.length}人\n`)

    // CSVとデータベースを完全比較
    console.log("🔍 全ユーザーの紹介関係を完全チェック...")
    console.log("=" * 60)

    const csvUserMap = new Map()
    csvUsers.forEach((user) => {
      if (user.user_id) {
        csvUserMap.set(user.user_id, user)
      }
    })

    const corrections = []
    let matchCount = 0
    let mismatchCount = 0

    // 全データベースユーザーをチェック
    dbUsers.forEach((dbUser) => {
      const csvUser = csvUserMap.get(dbUser.user_id)

      if (csvUser) {
        const currentReferrer = dbUser.referrer?.user_id || null
        const correctReferrer = csvUser.referrer || null

        if (currentReferrer !== correctReferrer) {
          mismatchCount++
          corrections.push({
            user_id: dbUser.user_id,
            name: dbUser.name,
            current_referrer: currentReferrer || "なし",
            correct_referrer: correctReferrer || "なし",
            action: correctReferrer ? `紹介者を ${correctReferrer} に変更` : "紹介者を削除",
            csv_name: csvUser.name,
          })
        } else {
          matchCount++
        }
      }
    })

    console.log(`✅ 正しい紹介関係: ${matchCount}人`)
    console.log(`❌ 間違った紹介関係: ${mismatchCount}人`)
    console.log(`🔥 修正が必要: ${corrections.length}人\n`)

    // 間違った紹介関係の詳細表示
    if (corrections.length > 0) {
      console.log("🔥 間違った紹介関係の詳細:")
      console.log("=" * 80)
      corrections.forEach((correction, index) => {
        console.log({
          no: index + 1,
          user_id: correction.user_id,
          name: correction.name,
          現在の紹介者: correction.current_referrer,
          正しい紹介者: correction.correct_referrer,
          action: correction.action,
        })
      })
    }

    // 完全修正SQLスクリプトを生成
    console.log("\n📝 完全修正SQLスクリプトを生成中...")

    let sqlScript = `-- CSV完全準拠の紹介関係修正
-- 実行日時: ${new Date().toISOString()}
-- 修正対象: ${corrections.length}人
-- 🔥 CSVの通りに全て修正します！

BEGIN;

-- 修正前の完全バックアップ
DROP TABLE IF EXISTS complete_referral_backup_${Date.now()};
CREATE TABLE complete_referral_backup_${Date.now()} AS
SELECT 
    user_id,
    name,
    referrer_id,
    (SELECT user_id FROM users WHERE id = u.referrer_id) as current_referrer_user_id,
    updated_at,
    NOW() as backup_created_at
FROM users u
WHERE is_admin = false;

-- 修正前の統計
SELECT 
    '=== 修正前の統計 ===' as status,
    COUNT(*) as total_users,
    COUNT(referrer_id) as users_with_referrer,
    COUNT(*) - COUNT(referrer_id) as users_without_referrer
FROM users
WHERE is_admin = false;

-- 修正前の紹介者別統計（上位20人）
SELECT 
    '=== 修正前の紹介者ランキング ===' as status,
    r.user_id as referrer_id,
    r.name as referrer_name,
    COUNT(*) as referral_count
FROM users u
JOIN users r ON u.referrer_id = r.id
WHERE u.is_admin = false
GROUP BY r.user_id, r.name
ORDER BY COUNT(*) DESC
LIMIT 20;

`

    // 各修正を追加
    corrections.forEach((correction, index) => {
      sqlScript += `
-- ${index + 1}. ${correction.user_id} (${correction.name})
-- 現在: ${correction.current_referrer} → 正しい: ${correction.correct_referrer}
`

      if (correction.correct_referrer !== "なし") {
        sqlScript += `UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = '${correction.correct_referrer}'),
    updated_at = NOW()
WHERE user_id = '${correction.user_id}'
AND EXISTS (SELECT 1 FROM users WHERE user_id = '${correction.correct_referrer}');

-- 修正確認
SELECT 
    '${correction.user_id} 修正確認' as status,
    user_id,
    name,
    (SELECT user_id FROM users WHERE id = referrer_id) as new_referrer
FROM users 
WHERE user_id = '${correction.user_id}';
`
      } else {
        sqlScript += `UPDATE users 
SET 
    referrer_id = NULL,
    updated_at = NOW()
WHERE user_id = '${correction.user_id}';

-- 修正確認
SELECT 
    '${correction.user_id} 修正確認' as status,
    user_id,
    name,
    'なし' as new_referrer
FROM users 
WHERE user_id = '${correction.user_id}';
`
      }
    })

    sqlScript += `
-- 修正後の統計
SELECT 
    '=== 修正後の統計 ===' as status,
    COUNT(*) as total_users,
    COUNT(referrer_id) as users_with_referrer,
    COUNT(*) - COUNT(referrer_id) as users_without_referrer,
    ROUND(COUNT(referrer_id) * 100.0 / COUNT(*), 2) as referrer_percentage
FROM users
WHERE is_admin = false;

-- 修正後の紹介者別統計（上位20人）
SELECT 
    '=== 修正後の紹介者ランキング ===' as status,
    r.user_id as referrer_id,
    r.name as referrer_name,
    COUNT(*) as referral_count
FROM users u
JOIN users r ON u.referrer_id = r.id
WHERE u.is_admin = false
GROUP BY r.user_id, r.name
ORDER BY COUNT(*) DESC
LIMIT 20;

-- 1125Ritsukoの最終確認
SELECT 
    '=== 1125Ritsuko最終確認 ===' as status,
    COUNT(*) as final_referral_count
FROM users
WHERE referrer_id = (SELECT id FROM users WHERE user_id = '1125Ritsuko');

COMMIT;

-- 🎉 CSV完全準拠の修正完了！
SELECT '🎉 CSV完全準拠の修正完了！' as final_status;
`

    // SQLファイルに保存
    fs.writeFileSync("scripts/285-complete-csv-corrections.sql", sqlScript)
    console.log("✅ 完全修正SQLスクリプトを生成: scripts/285-complete-csv-corrections.sql")

    console.log("\n" + "=" * 60)
    console.log("🔥 完全修正分析結果:")
    console.log(`  📊 CSVユーザー数: ${csvUsers.length}人`)
    console.log(`  📊 データベースユーザー数: ${dbUsers.length}人`)
    console.log(`  ✅ 正しい紹介関係: ${matchCount}人`)
    console.log(`  ❌ 間違った紹介関係: ${mismatchCount}人`)
    console.log(`  🔥 修正対象: ${corrections.length}人`)

    console.log("\n🎯 次のステップ:")
    console.log("1. 📊 scripts/285-complete-csv-corrections.sql を実行")
    console.log("2. 🔥 CSVの通りに全ての紹介関係を修正")
    console.log("3. ✅ 修正結果の完全検証")

    return {
      csvUsers: csvUsers.length,
      dbUsers: dbUsers.length,
      matchCount,
      mismatchCount,
      corrections: corrections.length,
    }
  } catch (error) {
    console.error("❌ 分析中にエラーが発生:", error)
    throw error
  }
}

// 実行
analyzeAllCSVUsers()
  .then((result) => {
    console.log("\n🔥 CSV完全修正分析完了")
    console.log(`🎯 修正対象: ${result.corrections}人`)
    console.log("📊 CSVの通りに全て修正します！")
  })
  .catch((error) => {
    console.error("❌ 分析エラー:", error)
  })
