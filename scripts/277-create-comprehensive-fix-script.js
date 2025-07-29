// CSVデータに基づく包括的な修正スクリプトの作成
async function createComprehensiveFix() {
  try {
    console.log("🔧 包括的な修正スクリプトを作成中...")
    console.log("=".repeat(60))

    // CSVファイルを再取得して正確な紹介関係を確認
    const csvUrl =
      "https://hebbkx1anhila5yf.public.blob.vercel-storage.com/E-NISA%E3%83%AA%E3%82%B9%E3%83%88%20-%20SHOGUN%2BENISA%E7%B4%B9%E4%BB%8B%E8%80%85%E9%A0%86%E3%81%AB%E4%B8%A6%E3%81%B9%E6%9B%BF%E3%81%88-xqLb3E20fjpzRQiUkpfqPjUkP0puIK.csv"

    const response = await fetch(csvUrl)
    if (!response.ok) {
      throw new Error(`CSV取得エラー: ${response.status}`)
    }

    const csvText = await response.text()
    const lines = csvText.split("\n")

    // CSVデータを解析
    const csvData = []
    for (let i = 1; i < lines.length; i++) {
      if (lines[i].trim()) {
        const values = lines[i].split(",")
        const user = {
          name: values[0]?.replace(/"/g, ""),
          id: values[1]?.replace(/"/g, ""),
          email: values[2]?.replace(/"/g, ""),
          proxyEmail: values[3]?.replace(/"/g, ""),
          referrer: values[6]?.replace(/"/g, "") || null,
        }
        csvData.push(user)
      }
    }

    console.log(`📊 CSVデータ取得完了: ${csvData.length}人`)

    // 重要ユーザーの正しい紹介関係を特定
    console.log("\n🎯 重要ユーザーの正しい紹介関係:")
    const importantUsers = ["klmiklmi0204", "kazukazu2", "yatchan003", "yatchan002", "bighand1011", "Mira"]

    const corrections = []
    importantUsers.forEach((userId) => {
      const csvUser = csvData.find((user) => user.id === userId)
      if (csvUser) {
        corrections.push({
          user_id: userId,
          name: csvUser.name,
          correct_referrer: csvUser.referrer,
        })
        console.log({
          user_id: userId,
          name: csvUser.name,
          correct_referrer: csvUser.referrer || "なし",
          action: csvUser.referrer ? `紹介者を ${csvUser.referrer} に設定` : "紹介者を削除",
        })
      }
    })

    // 1125Ritsukoが紹介したユーザーの確認
    console.log("\n👤 1125Ritsukoが紹介したユーザーの確認:")
    const ritsukoReferrals = csvData.filter((user) => user.referrer === "1125Ritsuko")
    console.log(`  1125Ritsukoの正しい紹介数: ${ritsukoReferrals.length}人`)

    // 間違って1125Ritsukoが紹介者になっているユーザーを特定
    const wrongRitsukoReferrals = ["kazukazu2", "yatchan003", "yatchan002"]
    console.log("\n❌ 間違って1125Ritsukoが紹介者になっているユーザー:")
    wrongRitsukoReferrals.forEach((userId) => {
      const csvUser = csvData.find((user) => user.id === userId)
      if (csvUser) {
        console.log({
          user_id: userId,
          name: csvUser.name,
          wrong_referrer: "1125Ritsuko",
          correct_referrer: csvUser.referrer,
          action: `紹介者を ${csvUser.referrer} に修正`,
        })
      }
    })

    // SQLスクリプトを生成
    console.log("\n📝 修正SQLスクリプトを生成中...")
    let sqlScript = `-- CSVデータに基づく包括的な紹介関係修正
-- 実行日時: ${new Date().toISOString()}
-- 対象: 重要ユーザーの紹介関係修正

BEGIN;

-- 修正前の状態をバックアップ
DROP TABLE IF EXISTS comprehensive_fix_backup;
CREATE TABLE comprehensive_fix_backup AS
SELECT 
    user_id,
    name,
    email,
    referrer_id,
    (SELECT user_id FROM users WHERE id = u.referrer_id) as referrer_user_id,
    updated_at,
    NOW() as backup_created_at
FROM users u;

-- 重要ユーザーの修正
`

    corrections.forEach((correction) => {
      if (correction.correct_referrer) {
        sqlScript += `
-- ${correction.user_id} (${correction.name}) の紹介者を ${correction.correct_referrer} に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = '${correction.correct_referrer}'),
    updated_at = NOW()
WHERE user_id = '${correction.user_id}';
`
      } else {
        sqlScript += `
-- ${correction.user_id} (${correction.name}) の紹介者を削除
UPDATE users 
SET 
    referrer_id = NULL,
    updated_at = NOW()
WHERE user_id = '${correction.user_id}';
`
      }
    })

    sqlScript += `
COMMIT;

-- 修正結果の確認
SELECT 
    '=== 修正後の状態 ===' as status,
    u.user_id,
    u.name,
    COALESCE((SELECT user_id FROM users WHERE id = u.referrer_id), 'なし') as new_referrer,
    COALESCE((SELECT name FROM users WHERE id = u.referrer_id), 'なし') as new_referrer_name,
    u.updated_at
FROM users u
WHERE u.user_id IN (${importantUsers.map((id) => `'${id}'`).join(", ")})
ORDER BY u.user_id;

-- システム健全性チェック
SELECT 
    '=== システム健全性チェック ===' as status,
    COUNT(*) as total_users,
    COUNT(referrer_id) as users_with_referrer,
    COUNT(*) - COUNT(referrer_id) as users_without_referrer
FROM users;

-- 紹介者なしユーザーの確認
SELECT 
    '=== 紹介者なしユーザー ===' as status,
    user_id,
    name,
    email,
    CASE 
        WHEN user_id = 'admin001' THEN '✅ 管理者（正常）'
        WHEN user_id = 'USER0a18' THEN '✅ ルートユーザー（正常）'
        ELSE '❌ 紹介者が必要'
    END as expected_status
FROM users
WHERE referrer_id IS NULL
ORDER BY user_id;
`

    console.log("\n✅ 修正SQLスクリプト生成完了")
    console.log("📄 スクリプト内容:")
    console.log(sqlScript)

    // 修正計画のサマリー
    console.log("\n📋 修正計画サマリー:")
    console.log(`  修正対象ユーザー: ${corrections.length}人`)
    console.log(`  CSVデータ総数: ${csvData.length}人`)
    console.log(`  1125Ritsukoの正しい紹介数: ${ritsukoReferrals.length}人`)

    console.log("\n🎯 修正内容:")
    corrections.forEach((correction) => {
      console.log(`  ${correction.user_id}: 紹介者を ${correction.correct_referrer || "なし"} に設定`)
    })

    console.log("\n⚠️ 次のステップ:")
    console.log("1. 🔍 修正計画SQLを実行して現在の状態を確認")
    console.log("2. 🧪 生成された修正SQLスクリプトをテスト")
    console.log("3. 🚀 本番環境で修正を実行")
    console.log("4. ✅ 修正結果を検証")

    return {
      csvData,
      corrections,
      sqlScript,
      ritsukoReferrals: ritsukoReferrals.length,
    }
  } catch (error) {
    console.error("❌ 修正スクリプト作成中にエラーが発生しました:", error)
    throw error
  }
}

// 実行
createComprehensiveFix()
  .then((result) => {
    console.log("\n✅ 包括的な修正スクリプト作成完了")
    console.log(`📊 修正対象: ${result.corrections.length}人`)
  })
  .catch((error) => {
    console.error("❌ 修正スクリプト作成エラー:", error)
  })
