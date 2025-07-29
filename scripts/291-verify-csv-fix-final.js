const { createClient } = require("@supabase/supabase-js")

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY

if (!supabaseUrl || !supabaseServiceKey) {
  console.error("❌ Supabase環境変数が設定されていません")
  process.exit(1)
}

const supabase = createClient(supabaseUrl, supabaseServiceKey)

async function verifyCsvFixFinal() {
  console.log("🔍 CSVベース修正の最終検証")
  console.log("=" * 60)

  try {
    // 1. CSVファイル取得
    const csvUrl =
      "https://hebbkx1anhila5yf.public.blob.vercel-storage.com/E-NISA%E3%83%AA%E3%82%B9%E3%83%88%20-%20SHOGUN%2BENISA%E7%B4%B9%E4%BB%8B%E8%80%85%E9%A0%86%E3%81%AB%E4%B8%A6%E3%81%B9%E6%9B%BF%E3%81%88-xqLb3E20fjpzRQiUkpfqPjUkP0puIK.csv"

    const response = await fetch(csvUrl)
    const csvText = await response.text()
    const lines = csvText.split("\n").filter((line) => line.trim())

    const csvData = []
    for (let i = 1; i < lines.length; i++) {
      if (lines[i].trim()) {
        const values = lines[i].split(",")
        const user = {
          user_id: values[1]?.replace(/"/g, "").trim(),
          referrer: values[6]?.replace(/"/g, "").trim() || null,
        }
        if (user.user_id) {
          csvData.push(user)
        }
      }
    }

    console.log(`📊 CSVユーザー数: ${csvData.length}人`)

    // 2. データベース状態取得
    const { data: dbUsers, error } = await supabase
      .from("users")
      .select(`
        user_id,
        name,
        referrer_id,
        referrer:referrer_id(user_id, name)
      `)
      .eq("is_admin", false)

    if (error) {
      throw new Error(`データベース取得エラー: ${error.message}`)
    }

    console.log(`📊 データベースユーザー数: ${dbUsers.length}人`)

    // 3. 比較検証
    const csvMap = new Map()
    csvData.forEach((user) => {
      csvMap.set(user.user_id, user.referrer)
    })

    let correctCount = 0
    let wrongCount = 0
    const wrongUsers = []

    dbUsers.forEach((dbUser) => {
      const csvReferrer = csvMap.get(dbUser.user_id)
      const dbReferrer = dbUser.referrer?.user_id || null

      if (csvReferrer === dbReferrer) {
        correctCount++
      } else {
        wrongCount++
        wrongUsers.push({
          user_id: dbUser.user_id,
          name: dbUser.name,
          db_referrer: dbReferrer || "なし",
          csv_referrer: csvReferrer || "なし",
        })
      }
    })

    // 4. 1125Ritsukoの特別確認
    const ritsuko = dbUsers.find((u) => u.user_id === "1125Ritsuko")
    const ritsukoCSV = csvData.find((u) => u.user_id === "1125Ritsuko")

    console.log("\n🎯 1125Ritsukoの状況:")
    console.log({
      user_id: "1125Ritsuko",
      db_referrer: ritsuko?.referrer?.user_id || "なし",
      csv_referrer: ritsukoCSV?.referrer || "なし",
      status: (ritsuko?.referrer?.user_id || null) === (ritsukoCSV?.referrer || null) ? "✅ 正しい" : "❌ まだ間違い",
    })

    // 5. 結果表示
    console.log("\n" + "=" * 60)
    console.log("🎯 最終検証結果:")
    console.log(`✅ 正しく設定: ${correctCount}人`)
    console.log(`❌ まだ間違い: ${wrongCount}人`)
    console.log(`📈 成功率: ${((correctCount / (correctCount + wrongCount)) * 100).toFixed(2)}%`)

    if (wrongCount === 0) {
      console.log("\n🎉 完璧！全ての紹介関係がCSVの通りに設定されています！")
    } else {
      console.log(`\n⚠️ ${wrongCount}人がまだCSVと一致していません`)

      if (wrongUsers.length <= 10) {
        console.log("\n❌ 間違っているユーザー:")
        wrongUsers.forEach((user, index) => {
          console.log(`${index + 1}. ${user.user_id} (${user.name}): DB=${user.db_referrer} CSV=${user.csv_referrer}`)
        })
      }
    }

    return {
      correctCount,
      wrongCount,
      successRate: ((correctCount / (correctCount + wrongCount)) * 100).toFixed(2),
    }
  } catch (error) {
    console.error("❌ 検証中にエラー:", error)
    throw error
  }
}

// 実行
verifyCsvFixFinal()
  .then((result) => {
    console.log(`\n🔍 最終検証完了 - 成功率: ${result.successRate}%`)
  })
  .catch((error) => {
    console.error("❌ 検証エラー:", error)
  })
