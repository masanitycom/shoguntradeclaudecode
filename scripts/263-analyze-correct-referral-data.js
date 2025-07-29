// 正しい紹介関係データの分析（メールアドレス重複対応版）

const fs = require("fs")
const csv = require("csv-parser")

async function analyzeCorrectReferralData() {
  console.log("🔍 正しい紹介関係データを分析中...\n")

  const correctData = []

  // CSVファイルを読み込み
  return new Promise((resolve, reject) => {
    fs.createReadStream("./data/correct-referral-data.csv")
      .pipe(csv())
      .on("data", (row) => {
        correctData.push({
          user_id: row.id,
          name: row.name,
          original_email: row["メールアドレス"],
          proxy_email: row["代理のメアド"],
          referrer_id: row.referrer,
          password: row.pass,
          phone: row.tel,
          bo_added: row["BO追加済み"],
          investment: row.investment,
          start_date: row["運用開始日"],
          purchase_date: row["購入日"],
          has_nft: row.NFT,
        })
      })
      .on("end", () => {
        console.log(`📊 CSVデータ読み込み完了: ${correctData.length}件\n`)

        // 1. 基本統計
        console.log("=== 基本統計 ===")
        console.log(`総ユーザー数: ${correctData.length}`)
        console.log(`紹介者あり: ${correctData.filter((u) => u.referrer_id && u.referrer_id !== "").length}`)
        console.log(`紹介者なし: ${correctData.filter((u) => !u.referrer_id || u.referrer_id === "").length}`)

        // メールアドレス重複状況
        const proxyEmailUsers = correctData.filter((u) => u.proxy_email && u.proxy_email.includes("@shogun-trade.com"))
        console.log(`代理メアド使用: ${proxyEmailUsers.length}`)
        console.log()

        // 2. 重要ユーザーの紹介関係
        console.log("=== 重要ユーザーの正しい紹介関係 ===")
        const importantUsers = ["OHTAKIYO", "1125Ritsuko", "USER0a18", "bighand1011", "Mira"]
        importantUsers.forEach((userId) => {
          const user = correctData.find((u) => u.user_id === userId)
          if (user) {
            console.log(`${userId} (${user.name})`)
            console.log(`  紹介者: ${user.referrer_id || "なし"}`)
            console.log(`  本来メール: ${user.original_email}`)
            console.log(`  代理メール: ${user.proxy_email || "なし"}`)
            console.log(`  投資額: ${user.investment}`)
            console.log()
          } else {
            console.log(`${userId} -> CSVに存在しません\n`)
          }
        })

        // 3. 紹介者として多く登場するユーザー
        console.log("=== 主要紹介者（TOP 10） ===")
        const referrerCounts = {}
        correctData.forEach((user) => {
          if (user.referrer_id && user.referrer_id !== "") {
            referrerCounts[user.referrer_id] = (referrerCounts[user.referrer_id] || 0) + 1
          }
        })

        const topReferrers = Object.entries(referrerCounts)
          .sort(([, a], [, b]) => b - a)
          .slice(0, 10)

        topReferrers.forEach(([referrerId, count]) => {
          const referrer = correctData.find((u) => u.user_id === referrerId)
          console.log(`${referrerId} (${referrer?.name || "不明"}): ${count}人`)
        })
        console.log()

        // 4. OHTAKIYOの紹介関係チェーン
        console.log("=== OHTAKIYOの紹介チェーン ===")
        let currentUser = correctData.find((u) => u.user_id === "OHTAKIYO")
        let depth = 0
        const chain = []

        while (currentUser && depth < 10) {
          chain.push({
            user_id: currentUser.user_id,
            name: currentUser.name,
            referrer: currentUser.referrer_id,
            investment: currentUser.investment,
          })
          if (!currentUser.referrer_id || currentUser.referrer_id === "") break
          currentUser = correctData.find((u) => u.user_id === currentUser.referrer_id)
          depth++
        }

        console.log("紹介チェーン:")
        chain.forEach((user, index) => {
          const indent = "  ".repeat(index)
          console.log(`${indent}└─ ${user.user_id} (${user.name}) [投資:${user.investment}]`)
          if (user.referrer) {
            console.log(`${indent}   ↑ 紹介者: ${user.referrer}`)
          }
        })
        console.log()

        // 5. 1125Ritsukoの詳細と紹介したユーザー
        console.log("=== 1125Ritsukoの詳細 ===")
        const ritsuko = correctData.find((u) => u.user_id === "1125Ritsuko")
        if (ritsuko) {
          console.log(`名前: ${ritsuko.name}`)
          console.log(`紹介者: ${ritsuko.referrer_id || "なし"}`)
          console.log(`投資額: ${ritsuko.investment}`)
          console.log(`開始日: ${ritsuko.start_date}`)
          console.log(`本来メール: ${ritsuko.original_email}`)
          console.log(`代理メール: ${ritsuko.proxy_email || "なし"}`)

          // 1125Ritsukoが紹介したユーザー
          const referredUsers = correctData.filter((u) => u.referrer_id === "1125Ritsuko")
          console.log(`紹介したユーザー数: ${referredUsers.length}`)
          if (referredUsers.length > 0) {
            console.log("紹介したユーザー:")
            referredUsers.forEach((user) => {
              console.log(`  - ${user.user_id} (${user.name}) [投資:${user.investment}]`)
            })
          }
        } else {
          console.log("1125RitsukoがCSVに見つかりません")
        }
        console.log()

        // 6. 代理メールアドレス使用者の詳細
        console.log("=== 代理メールアドレス使用者 ===")
        const proxyUsers = correctData.filter((u) => u.proxy_email && u.proxy_email.includes("@shogun-trade.com"))
        console.log(`代理メール使用者: ${proxyUsers.length}人`)

        if (proxyUsers.length > 0) {
          console.log("代理メール使用者一覧（最初の10人）:")
          proxyUsers.slice(0, 10).forEach((user) => {
            console.log(`  ${user.user_id} (${user.name})`)
            console.log(`    本来: ${user.original_email}`)
            console.log(`    代理: ${user.proxy_email}`)
            console.log(`    紹介者: ${user.referrer_id || "なし"}`)
            console.log()
          })
        }

        // 7. 循環参照チェック
        console.log("=== 循環参照チェック ===")
        const visited = new Set()
        const recursionStack = new Set()
        const circularReferences = []

        function hasCycle(userId, path = []) {
          if (recursionStack.has(userId)) {
            circularReferences.push([...path, userId])
            return true
          }
          if (visited.has(userId)) return false

          visited.add(userId)
          recursionStack.add(userId)

          const user = correctData.find((u) => u.user_id === userId)
          if (user && user.referrer_id && user.referrer_id !== "") {
            hasCycle(user.referrer_id, [...path, userId])
          }

          recursionStack.delete(userId)
          return false
        }

        correctData.forEach((user) => {
          if (!visited.has(user.user_id)) {
            hasCycle(user.user_id)
          }
        })

        if (circularReferences.length > 0) {
          console.log("⚠️ 循環参照が検出されました:")
          circularReferences.forEach((cycle) => {
            console.log(`  ${cycle.join(" -> ")}`)
          })
        } else {
          console.log("✅ 循環参照は検出されませんでした")
        }
        console.log()

        // 8. 投資額統計
        console.log("=== 投資額統計 ===")
        const investments = correctData
          .filter((u) => u.investment && !isNaN(Number.parseFloat(u.investment)))
          .map((u) => Number.parseFloat(u.investment))

        if (investments.length > 0) {
          const total = investments.reduce((sum, inv) => sum + inv, 0)
          const average = total / investments.length
          const max = Math.max(...investments)
          const min = Math.min(...investments)

          console.log(`投資者数: ${investments.length}`)
          console.log(`総投資額: $${total.toLocaleString()}`)
          console.log(`平均投資額: $${average.toFixed(2)}`)
          console.log(`最大投資額: $${max.toLocaleString()}`)
          console.log(`最小投資額: $${min.toLocaleString()}`)
        }

        resolve(correctData)
      })
      .on("error", reject)
  })
}

// 実行
analyzeCorrectReferralData()
  .then((data) => {
    console.log("\n✅ 分析完了")
    console.log(`正しいデータ: ${data.length}件のユーザー情報を取得`)
    console.log("📋 次のステップ: 現在のDBとの比較を実行してください")
  })
  .catch((error) => {
    console.error("❌ エラー:", error)
  })
