// 新しいCSVファイルを分析して具体的な修正内容を表示
async function showSpecificCorrections() {
  try {
    console.log("📊 新しいCSVファイルを分析中...")
    console.log("=".repeat(60))

    // 新しいCSVファイルを取得
    const csvUrl =
      "https://hebbkx1anhila5yf.public.blob.vercel-storage.com/SHOGUN%2BENISA%E7%B4%B9%E4%BB%8B%E8%80%85%E9%A0%86%E3%81%AB%E4%B8%A6%E3%81%B9%E6%9B%BF%E3%81%88%20-%20%E3%82%B7%E3%83%BC%E3%83%882-3sEEqgz48qctjxfbOBP51UPTybAwSP.csv"

    const response = await fetch(csvUrl)
    if (!response.ok) {
      throw new Error(`CSV取得エラー: ${response.status}`)
    }

    const csvText = await response.text()
    const lines = csvText.split("\n")

    console.log(`✅ 新しいCSVファイル取得成功`)
    console.log(`  総行数: ${lines.length}行`)

    // CSVデータを解析（ヘッダーをスキップ）
    const csvData = []
    for (let i = 1; i < lines.length; i++) {
      if (lines[i].trim()) {
        const values = lines[i].split(",")
        const user = {
          name: values[0]?.replace(/"/g, "").trim(),
          id: values[1]?.replace(/"/g, "").trim(),
          tel: values[2]?.replace(/"/g, "").trim(),
          referrer: values[3]?.replace(/"/g, "").trim() || null,
        }
        if (user.id) {
          // IDが存在する場合のみ追加
          csvData.push(user)
        }
      }
    }

    console.log(`📊 有効なCSVユーザーデータ: ${csvData.length}人`)

    // 重要ユーザーの確認
    console.log("\n🎯 重要ユーザーのCSVデータ:")
    const importantUsers = ["klmiklmi0204", "kazukazu2", "yatchan003", "yatchan002", "bighand1011", "Mira", "OHTAKIYO"]

    const corrections = []
    importantUsers.forEach((userId) => {
      const csvUser = csvData.find((user) => user.id === userId)
      if (csvUser) {
        corrections.push({
          user_id: userId,
          name: csvUser.name,
          correct_referrer: csvUser.referrer,
          tel: csvUser.tel,
        })
        console.log({
          user_id: userId,
          name: csvUser.name,
          correct_referrer: csvUser.referrer || "なし",
          tel: csvUser.tel,
          action: csvUser.referrer ? `紹介者を ${csvUser.referrer} に設定` : "紹介者を削除",
        })
      } else {
        console.log({
          user_id: userId,
          status: "❌ CSVに見つかりません",
        })
      }
    })

    // ルートユーザー（紹介者なし）の確認
    console.log("\n🌳 ルートユーザー（紹介者なし）:")
    const rootUsers = csvData.filter((user) => !user.referrer)
    rootUsers.forEach((user) => {
      console.log({
        user_id: user.id,
        name: user.name,
        tel: user.tel,
        status: "🌳 ルートユーザー",
      })
    })

    console.log(`\n📊 ルートユーザー数: ${rootUsers.length}人`)

    // 紹介者別統計（上位10人）
    console.log("\n📊 紹介者別統計（上位10人）:")
    const referrerStats = {}
    csvData.forEach((user) => {
      if (user.referrer) {
        referrerStats[user.referrer] = (referrerStats[user.referrer] || 0) + 1
      }
    })

    const sortedReferrers = Object.entries(referrerStats)
      .sort(([, a], [, b]) => b - a)
      .slice(0, 10)

    sortedReferrers.forEach(([referrer, count], index) => {
      const referrerUser = csvData.find((user) => user.id === referrer)
      console.log({
        rank: index + 1,
        referrer_id: referrer,
        referrer_name: referrerUser?.name || "不明",
        referral_count: count,
      })
    })

    // 特定の問題ユーザーの確認
    console.log("\n❌ 問題のあるユーザーの確認:")
    const problemUsers = ["kazukazu2", "yatchan003", "yatchan002"]
    problemUsers.forEach((userId) => {
      const csvUser = csvData.find((user) => user.id === userId)
      if (csvUser) {
        console.log({
          user_id: userId,
          name: csvUser.name,
          correct_referrer: csvUser.referrer || "なし",
          current_problem: "現在は1125Ritsukoが紹介者になっている",
          action: csvUser.referrer ? `紹介者を ${csvUser.referrer} に修正` : "紹介者を削除",
          priority: "🔴 緊急修正が必要",
        })
      }
    })

    // 1125Ritsukoが紹介したユーザーの確認
    console.log("\n👤 1125Ritsukoが紹介したユーザー:")
    const ritsukoReferrals = csvData.filter((user) => user.referrer === "1125Ritsuko")
    console.log(`  1125Ritsukoの正しい紹介数: ${ritsukoReferrals.length}人`)

    if (ritsukoReferrals.length > 0) {
      console.log("  1125Ritsukoが紹介したユーザー（最初の10人）:")
      ritsukoReferrals.slice(0, 10).forEach((user, index) => {
        console.log({
          no: index + 1,
          user_id: user.id,
          name: user.name,
          tel: user.tel,
        })
      })

      if (ritsukoReferrals.length > 10) {
        console.log(`... 他 ${ritsukoReferrals.length - 10}人`)
      }
    }

    // 修正SQLスクリプトの生成
    console.log("\n📝 修正SQLスクリプトの生成:")
    let sqlScript = `-- CSVデータに基づく正確な紹介関係修正
-- 実行日時: ${new Date().toISOString()}
-- 対象: ${corrections.length}人の重要ユーザー

BEGIN;

-- 修正前の状態をバックアップ
DROP TABLE IF EXISTS csv_correction_backup;
CREATE TABLE csv_correction_backup AS
SELECT 
    user_id,
    name,
    referrer_id,
    (SELECT user_id FROM users WHERE id = u.referrer_id) as current_referrer_user_id,
    updated_at,
    NOW() as backup_created_at
FROM users u
WHERE user_id IN (${corrections.map((c) => `'${c.user_id}'`).join(", ")});

-- 修正前の状態を表示
SELECT 
    '=== 修正前の状態 ===' as status,
    user_id,
    name,
    current_referrer_user_id as current_referrer,
    updated_at
FROM csv_correction_backup
ORDER BY user_id;

`

    corrections.forEach((correction) => {
      if (correction.correct_referrer) {
        sqlScript += `
-- ${correction.user_id} (${correction.name}) の紹介者を ${correction.correct_referrer} に設定
UPDATE users 
SET 
    referrer_id = (SELECT id FROM users WHERE user_id = '${correction.correct_referrer}'),
    updated_at = NOW()
WHERE user_id = '${correction.user_id}'
AND EXISTS (SELECT 1 FROM users WHERE user_id = '${correction.correct_referrer}');
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
-- 修正後の状態を表示
SELECT 
    '=== 修正後の状態 ===' as status,
    u.user_id,
    u.name,
    COALESCE((SELECT user_id FROM users WHERE id = u.referrer_id), 'なし') as new_referrer,
    COALESCE((SELECT name FROM users WHERE id = u.referrer_id), 'なし') as new_referrer_name,
    u.updated_at
FROM users u
WHERE u.user_id IN (${corrections.map((c) => `'${c.user_id}'`).join(", ")})
ORDER BY u.user_id;

COMMIT;
`

    console.log(sqlScript)

    // サマリー
    console.log("\n" + "=".repeat(60))
    console.log("📊 分析結果サマリー:")
    console.log(`  CSVユーザー数: ${csvData.length}人`)
    console.log(`  ルートユーザー数: ${rootUsers.length}人`)
    console.log(`  修正対象ユーザー: ${corrections.length}人`)
    console.log(`  1125Ritsukoの正しい紹介数: ${ritsukoReferrals.length}人`)

    console.log("\n🎯 修正内容:")
    corrections.forEach((correction) => {
      console.log(
        `  ${correction.user_id} (${correction.name}): 紹介者を ${correction.correct_referrer || "なし"} に設定`,
      )
    })

    console.log("\n⚠️ 次のステップ:")
    console.log("1. 🔍 上記のSQLスクリプトを実行")
    console.log("2. 📊 修正結果の確認")
    console.log("3. ✅ システム健全性の検証")

    return {
      csvData,
      corrections,
      ritsukoReferrals: ritsukoReferrals.length,
      rootUsers: rootUsers.length,
      sqlScript,
    }
  } catch (error) {
    console.error("❌ CSV分析中にエラーが発生しました:", error)
    throw error
  }
}

// 実行
showSpecificCorrections()
  .then((result) => {
    console.log("\n✅ CSV分析完了")
    console.log(`📊 修正対象: ${result.corrections.length}人`)
  })
  .catch((error) => {
    console.error("❌ CSV分析エラー:", error)
  })
