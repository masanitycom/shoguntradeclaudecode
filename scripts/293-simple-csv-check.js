// 🔍 環境変数なしでCSVと比較チェック
const fs = require("fs")

async function simpleCsvCheck() {
  console.log("🔍 CSVとの簡単比較チェック")
  console.log("=" * 60)

  try {
    // CSVファイルを取得
    console.log("1️⃣ CSVファイル取得中...")
    const csvUrl =
      "https://hebbkx1anhila5yf.public.blob.vercel-storage.com/E-NISA%E3%83%AA%E3%82%B9%E3%83%88%20-%20SHOGUN%2BENISA%E7%B4%B9%E4%BB%8B%E8%80%85%E9%A0%86%E3%81%AB%E4%B8%A6%E3%81%B9%E6%9B%BF%E3%81%88-xqLb3E20fjpzRQiUkpfqPjUkP0puIK.csv"

    const response = await fetch(csvUrl)
    if (!response.ok) {
      throw new Error(`CSV取得エラー: ${response.status}`)
    }

    const csvText = await response.text()
    const lines = csvText.split("\n").filter((line) => line.trim())

    console.log(`📊 CSV行数: ${lines.length}行`)

    // CSVデータを解析
    const csvData = []
    for (let i = 1; i < lines.length; i++) {
      if (lines[i].trim()) {
        const values = lines[i].split(",")
        const user = {
          name: values[0]?.replace(/"/g, "").trim(),
          user_id: values[1]?.replace(/"/g, "").trim(),
          referrer: values[6]?.replace(/"/g, "").trim() || null,
        }
        if (user.user_id) {
          csvData.push(user)
        }
      }
    }

    console.log(`📊 有効なCSVユーザー: ${csvData.length}人`)

    // 重要ユーザーの確認
    const importantUsers = [
      "1125Ritsuko",
      "kazukazu2",
      "yatchan002",
      "yatchan003",
      "bighand1011",
      "klmiklmi0204",
      "Mira",
      "OHTAKIYO",
    ]

    console.log("\n2️⃣ 重要ユーザーのCSV情報:")
    importantUsers.forEach((userId) => {
      const csvUser = csvData.find((u) => u.user_id === userId)
      if (csvUser) {
        console.log(`${userId}: ${csvUser.referrer || "なし"}`)
      } else {
        console.log(`${userId}: CSVに存在しない`)
      }
    })

    // 1125Ritsukoの特別確認
    const ritsuko = csvData.find((u) => u.user_id === "1125Ritsuko")
    console.log("\n3️⃣ 1125Ritsukoの詳細:")
    if (ritsuko) {
      console.log({
        user_id: "1125Ritsuko",
        name: ritsuko.name,
        csv_referrer: ritsuko.referrer || "なし",
        expected: "USER0a18",
        status: ritsuko.referrer === "USER0a18" ? "✅ CSV通り" : "❌ CSV不一致",
      })
    } else {
      console.log("❌ 1125RitsukoがCSVに見つかりません")
    }

    // 全CSVユーザーの統計
    const withReferrer = csvData.filter((u) => u.referrer).length
    const withoutReferrer = csvData.filter((u) => !u.referrer).length

    console.log("\n4️⃣ CSV統計:")
    console.log(`📊 紹介者あり: ${withReferrer}人`)
    console.log(`📊 紹介者なし: ${withoutReferrer}人`)

    // SQLファイルを生成して確認
    const sqlCheck = `
-- 🔍 CSVベース確認SQL
SELECT 
    '1125Ritsuko確認' as check_type,
    u.user_id,
    u.name,
    COALESCE(r.user_id, 'なし') as current_referrer,
    '${ritsuko?.referrer || "なし"}' as csv_referrer,
    CASE 
        WHEN COALESCE(r.user_id, '') = '${ritsuko?.referrer || ""}' THEN '✅ 一致'
        ELSE '❌ 不一致'
    END as status
FROM users u
LEFT JOIN users r ON u.referrer_id = r.id
WHERE u.user_id = '1125Ritsuko';

-- 重要ユーザー全体確認
SELECT 
    '重要ユーザー確認' as check_type,
    u.user_id,
    u.name,
    COALESCE(r.user_id, 'なし') as current_referrer,
    CASE 
        WHEN u.user_id = '1125Ritsuko' THEN '${csvData.find((u) => u.user_id === "1125Ritsuko")?.referrer || "なし"}'
        WHEN u.user_id = 'kazukazu2' THEN '${csvData.find((u) => u.user_id === "kazukazu2")?.referrer || "なし"}'
        WHEN u.user_id = 'yatchan002' THEN '${csvData.find((u) => u.user_id === "yatchan002")?.referrer || "なし"}'
        WHEN u.user_id = 'yatchan003' THEN '${csvData.find((u) => u.user_id === "yatchan003")?.referrer || "なし"}'
        WHEN u.user_id = 'bighand1011' THEN '${csvData.find((u) => u.user_id === "bighand1011")?.referrer || "なし"}'
        WHEN u.user_id = 'klmiklmi0204' THEN '${csvData.find((u) => u.user_id === "klmiklmi0204")?.referrer || "なし"}'
        WHEN u.user_id = 'Mira' THEN '${csvData.find((u) => u.user_id === "Mira")?.referrer || "なし"}'
        WHEN u.user_id = 'OHTAKIYO' THEN '${csvData.find((u) => u.user_id === "OHTAKIYO")?.referrer || "なし"}'
        ELSE '不明'
    END as csv_referrer,
    CASE 
        WHEN (u.user_id = '1125Ritsuko' AND COALESCE(r.user_id, '') = '${csvData.find((u) => u.user_id === "1125Ritsuko")?.referrer || ""}') OR
             (u.user_id = 'kazukazu2' AND COALESCE(r.user_id, '') = '${csvData.find((u) => u.user_id === "kazukazu2")?.referrer || ""}') OR
             (u.user_id = 'yatchan002' AND COALESCE(r.user_id, '') = '${csvData.find((u) => u.user_id === "yatchan002")?.referrer || ""}') OR
             (u.user_id = 'yatchan003' AND COALESCE(r.user_id, '') = '${csvData.find((u) => u.user_id === "yatchan003")?.referrer || ""}') OR
             (u.user_id = 'bighand1011' AND COALESCE(r.user_id, '') = '${csvData.find((u) => u.user_id === "bighand1011")?.referrer || ""}') OR
             (u.user_id = 'klmiklmi0204' AND COALESCE(r.user_id, '') = '${csvData.find((u) => u.user_id === "klmiklmi0204")?.referrer || ""}') OR
             (u.user_id = 'Mira' AND COALESCE(r.user_id, '') = '${csvData.find((u) => u.user_id === "Mira")?.referrer || ""}') OR
             (u.user_id = 'OHTAKIYO' AND COALESCE(r.user_id, '') = '${csvData.find((u) => u.user_id === "OHTAKIYO")?.referrer || ""}')
        THEN '✅ CSV一致'
        ELSE '❌ CSV不一致'
    END as status
FROM users u
LEFT JOIN users r ON u.referrer_id = r.id
WHERE u.user_id IN ('1125Ritsuko', 'kazukazu2', 'yatchan002', 'yatchan003', 'bighand1011', 'klmiklmi0204', 'Mira', 'OHTAKIYO')
ORDER BY u.user_id;
        `

    fs.writeFileSync("scripts/294-csv-check.sql", sqlCheck)
    console.log("\n📝 scripts/294-csv-check.sql を生成しました")

    return {
      csvUsers: csvData.length,
      ritsukoReferrer: ritsuko?.referrer || "なし",
      withReferrer,
      withoutReferrer,
    }
  } catch (error) {
    console.error("❌ チェック中にエラー:", error)
    throw error
  }
}

// 実行
simpleCsvCheck()
  .then((result) => {
    console.log(`\n🔍 チェック完了 - CSVユーザー: ${result.csvUsers}人`)
    console.log(`🎯 1125RitsukoのCSV紹介者: ${result.ritsukoReferrer}`)
    console.log(`📊 紹介者あり: ${result.withReferrer}人, なし: ${result.withoutReferrer}人`)
  })
  .catch((error) => {
    console.error("❌ チェックエラー:", error)
  })
