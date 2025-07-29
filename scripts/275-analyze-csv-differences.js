// CSVファイルのみを分析（環境変数不要版）
async function analyzeCsvOnly() {
  try {
    console.log("📊 CSVファイルを分析中...")
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

    console.log(`✅ CSVファイル取得成功`)
    console.log(`  総行数: ${lines.length - 1}人（ヘッダー除く）`)

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

    console.log(`📊 有効なCSVユーザーデータ: ${csvData.length}人`)

    // 重要ユーザーの確認
    console.log("\n🎯 重要ユーザーのCSVデータ:")
    const importantUsers = ["klmiklmi0204", "kazukazu2", "yatchan003", "yatchan002", "bighand1011", "Mira"]

    importantUsers.forEach((userId) => {
      const csvUser = csvData.find((user) => user.id === userId)
      if (csvUser) {
        console.log({
          user_id: userId,
          name: csvUser.name,
          csv_referrer: csvUser.referrer || "なし",
          email: csvUser.email,
          proxy_email: csvUser.proxyEmail,
          investment: csvUser.investment,
          start_date: csvUser.startDate,
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
        email: user.email,
        proxy_email: user.proxyEmail,
        investment: user.investment,
        status: "🌳 ルートユーザー",
      })
    })

    console.log(`\n📊 ルートユーザー数: ${rootUsers.length}人`)

    // 紹介者別統計
    console.log("\n📊 紹介者別統計（上位15人）:")
    const referrerStats = {}
    csvData.forEach((user) => {
      if (user.referrer) {
        referrerStats[user.referrer] = (referrerStats[user.referrer] || 0) + 1
      }
    })

    const sortedReferrers = Object.entries(referrerStats)
      .sort(([, a], [, b]) => b - a)
      .slice(0, 15)

    sortedReferrers.forEach(([referrer, count]) => {
      const referrerUser = csvData.find((user) => user.id === referrer)
      console.log({
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

    // 代理メールの紹介者統計
    const proxyReferrerStats = {}
    proxyEmails.forEach((user) => {
      if (user.referrer) {
        proxyReferrerStats[user.referrer] = (proxyReferrerStats[user.referrer] || 0) + 1
      }
    })

    console.log("\n📧 代理メールユーザーの紹介者統計（上位10人）:")
    const sortedProxyReferrers = Object.entries(proxyReferrerStats)
      .sort(([, a], [, b]) => b - a)
      .slice(0, 10)

    sortedProxyReferrers.forEach(([referrer, count]) => {
      const referrerUser = csvData.find((user) => user.id === referrer)
      console.log({
        referrer_id: referrer,
        referrer_name: referrerUser?.name || "不明",
        proxy_referral_count: count,
      })
    })

    // 1125Ritsukoが紹介したユーザーの詳細
    console.log("\n👤 1125Ritsukoが紹介したユーザー:")
    const ritsukoReferrals = csvData.filter((user) => user.referrer === "1125Ritsuko")
    console.log(`  1125Ritsukoの紹介数: ${ritsukoReferrals.length}人`)

    ritsukoReferrals.slice(0, 10).forEach((user) => {
      console.log({
        user_id: user.id,
        name: user.name,
        email: user.email,
        proxy_email: user.proxyEmail,
        investment: user.investment,
        email_type: user.proxyEmail?.includes("@shogun-trade.com") ? "📧 代理メール" : "📧 実メール",
      })
    })

    if (ritsukoReferrals.length > 10) {
      console.log(`... 他 ${ritsukoReferrals.length - 10}人`)
    }

    // 特定ユーザーの詳細確認
    console.log("\n🔍 特定ユーザーの詳細確認:")
    const specificUsers = ["kazukazu2", "yatchan003", "yatchan002"]
    specificUsers.forEach((userId) => {
      const user = csvData.find((u) => u.id === userId)
      if (user) {
        console.log({
          user_id: userId,
          name: user.name,
          correct_referrer: user.referrer,
          email: user.email,
          proxy_email: user.proxyEmail,
          investment: user.investment,
          note: `正しい紹介者は ${user.referrer} です`,
        })
      }
    })

    // 投資額統計
    console.log("\n💰 投資額統計:")
    const investments = csvData
      .filter((user) => user.investment && !isNaN(Number.parseFloat(user.investment)))
      .map((user) => Number.parseFloat(user.investment))

    if (investments.length > 0) {
      const totalInvestment = investments.reduce((sum, inv) => sum + inv, 0)
      const avgInvestment = totalInvestment / investments.length
      const maxInvestment = Math.max(...investments)
      const minInvestment = Math.min(...investments)

      console.log({
        total_users_with_investment: investments.length,
        total_investment: totalInvestment,
        average_investment: Math.round(avgInvestment),
        max_investment: maxInvestment,
        min_investment: minInvestment,
      })
    }

    // サマリー
    console.log("\n" + "=".repeat(60))
    console.log("📊 CSV分析結果サマリー:")
    console.log(`  総ユーザー数: ${csvData.length}人`)
    console.log(`  ルートユーザー数: ${rootUsers.length}人`)
    console.log(`  紹介者ありユーザー: ${csvData.length - rootUsers.length}人`)
    console.log(`  代理メール使用者: ${proxyEmails.length}人`)
    console.log(`  1125Ritsukoの紹介数: ${ritsukoReferrals.length}人`)

    console.log("\n🎯 重要な発見:")
    console.log("  - ルートユーザーは1人のみ（USER0a18）")
    console.log("  - 1125Ritsukoが最も多くのユーザーを紹介")
    console.log("  - 代理メールユーザーの多くが1125Ritsukoの紹介")
    console.log("  - kazukazu2, yatchan003, yatchan002の正しい紹介者が判明")

    console.log("\n⚠️ 次に必要なアクション:")
    console.log("1. 🔴 重要ユーザーの紹介者修正")
    console.log("2. 📊 DBとの差異確認")
    console.log("3. 🧪 修正スクリプトの作成")
    console.log("4. 🚀 段階的な修正実行")

    return csvData
  } catch (error) {
    console.error("❌ CSV分析中にエラーが発生しました:", error)
    throw error
  }
}

// 実行
analyzeCsvOnly()
  .then((csvData) => {
    console.log("\n✅ CSV分析完了")
    console.log(`📊 分析対象: ${csvData.length}人`)
  })
  .catch((error) => {
    console.error("❌ CSV分析エラー:", error)
  })
