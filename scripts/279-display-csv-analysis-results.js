// CSVファイルの分析結果を詳細表示
async function displayCsvAnalysisResults() {
  try {
    console.log("📊 CSVファイルの詳細分析結果を表示中...")
    console.log("=".repeat(60))

    // CSVファイルを取得
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
          pass: values[4]?.replace(/"/g, ""),
          tel: values[5]?.replace(/"/g, ""),
          referrer: values[6]?.replace(/"/g, "") || null,
          investment: values[11]?.replace(/"/g, ""),
          startDate: values[13]?.replace(/"/g, ""),
        }
        csvData.push(user)
      }
    }

    console.log(`📊 CSVデータ総数: ${csvData.length}人`)

    // 重要ユーザーの詳細確認
    console.log("\n🎯 重要ユーザーの詳細確認:")
    const importantUsers = ["klmiklmi0204", "kazukazu2", "yatchan003", "yatchan002", "bighand1011", "Mira"]

    const corrections = []
    importantUsers.forEach((userId) => {
      const csvUser = csvData.find((user) => user.id === userId)
      if (csvUser) {
        corrections.push({
          user_id: userId,
          name: csvUser.name,
          correct_referrer: csvUser.referrer,
          email: csvUser.email,
          proxy_email: csvUser.proxyEmail,
        })

        console.log({
          user_id: userId,
          name: csvUser.name,
          correct_referrer: csvUser.referrer || "なし",
          email: csvUser.email,
          proxy_email: csvUser.proxyEmail,
          action: csvUser.referrer ? `紹介者を ${csvUser.referrer} に設定` : "紹介者を削除",
        })
      } else {
        console.log({
          user_id: userId,
          status: "❌ CSVに見つかりません",
        })
      }
    })

    // ルートユーザーの確認
    console.log("\n🌳 ルートユーザー（紹介者なし）:")
    const rootUsers = csvData.filter((user) => !user.referrer)
    rootUsers.forEach((user) => {
      console.log({
        user_id: user.id,
        name: user.name,
        email: user.email,
        proxy_email: user.proxyEmail,
        status: "🌳 ルートユーザー",
      })
    })

    console.log(`\n📊 ルートユーザー数: ${rootUsers.length}人`)

    // 1125Ritsukoが紹介したユーザーの詳細
    console.log("\n👤 1125Ritsukoが紹介したユーザーの詳細:")
    const ritsukoReferrals = csvData.filter((user) => user.referrer === "1125Ritsuko")
    console.log(`  1125Ritsukoの正しい紹介数: ${ritsukoReferrals.length}人`)

    console.log("  1125Ritsukoが紹介したユーザー（最初の15人）:")
    ritsukoReferrals.slice(0, 15).forEach((user, index) => {
      console.log({
        no: index + 1,
        user_id: user.id,
        name: user.name,
        email: user.email,
        proxy_email: user.proxyEmail,
        email_type: user.proxyEmail?.includes("@shogun-trade.com") ? "📧 代理メール" : "📧 実メール",
      })
    })

    if (ritsukoReferrals.length > 15) {
      console.log(`... 他 ${ritsukoReferrals.length - 15}人`)
    }

    // 間違って1125Ritsukoが紹介者になっているユーザー
    console.log("\n❌ 間違って1125Ritsukoが紹介者になっているユーザー:")
    const wrongRitsukoUsers = ["kazukazu2", "yatchan003", "yatchan002"]
    wrongRitsukoUsers.forEach((userId) => {
      const csvUser = csvData.find((user) => user.id === userId)
      if (csvUser) {
        console.log({
          user_id: userId,
          name: csvUser.name,
          wrong_referrer: "1125Ritsuko（現在のDB）",
          correct_referrer: csvUser.referrer || "なし",
          action: csvUser.referrer ? `紹介者を ${csvUser.referrer} に修正` : "紹介者を削除",
          priority: "🔴 緊急修正が必要",
        })
      }
    })

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
        referrer_email: referrerUser?.email || "不明",
      })
    })

    // 代理メール統計
    console.log("\n📧 代理メール統計:")
    const proxyEmails = csvData.filter((user) => user.proxyEmail && user.proxyEmail.includes("@shogun-trade.com"))
    console.log(`  代理メール使用者: ${proxyEmails.length}人`)

    // 修正が必要なユーザーのSQLスクリプト生成
    console.log("\n📝 修正SQLスクリプトの生成:")
    console.log("-- 重要ユーザーの紹介者修正SQL")
    corrections.forEach((correction) => {
      if (correction.correct_referrer) {
        console.log(`-- ${correction.user_id} (${correction.name}) の紹介者を ${correction.correct_referrer} に設定`)
        console.log(
          `UPDATE users SET referrer_id = (SELECT id FROM users WHERE user_id = '${correction.correct_referrer}'), updated_at = NOW() WHERE user_id = '${correction.user_id}';`,
        )
      } else {
        console.log(`-- ${correction.user_id} (${correction.name}) の紹介者を削除`)
        console.log(`UPDATE users SET referrer_id = NULL, updated_at = NOW() WHERE user_id = '${correction.user_id}';`)
      }
    })

    // サマリー
    console.log("\n" + "=".repeat(60))
    console.log("📊 分析結果サマリー:")
    console.log(`  CSVユーザー数: ${csvData.length}人`)
    console.log(`  ルートユーザー数: ${rootUsers.length}人`)
    console.log(`  1125Ritsukoの正しい紹介数: ${ritsukoReferrals.length}人`)
    console.log(`  代理メール使用者: ${proxyEmails.length}人`)
    console.log(`  修正が必要な重要ユーザー: ${corrections.length}人`)

    console.log("\n🎯 次に必要なアクション:")
    console.log("1. 🔴 重要ユーザーの紹介者を正しく修正")
    console.log("2. 📊 修正後のシステム健全性確認")
    console.log("3. 🧪 全ユーザーの段階的修正計画")
    console.log("4. ✅ 最終検証と確認")

    return {
      csvData,
      corrections,
      ritsukoReferrals: ritsukoReferrals.length,
      rootUsers: rootUsers.length,
      proxyEmails: proxyEmails.length,
    }
  } catch (error) {
    console.error("❌ CSV分析結果表示中にエラーが発生しました:", error)
    throw error
  }
}

// 実行
displayCsvAnalysisResults()
  .then((result) => {
    console.log("\n✅ CSV分析結果表示完了")
    console.log(`📊 修正対象: ${result.corrections.length}人`)
  })
  .catch((error) => {
    console.error("❌ CSV分析結果表示エラー:", error)
  })
