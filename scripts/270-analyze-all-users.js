import { createClient } from "@supabase/supabase-js"

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY

if (!supabaseUrl || !supabaseServiceKey) {
  throw new Error("Missing Supabase environment variables")
}

const supabase = createClient(supabaseUrl, supabaseServiceKey)

async function analyzeAllUsers() {
  console.log("🔍 全ユーザーの分析を開始します...")
  console.log("=".repeat(60))

  try {
    // 1. CSVファイルを取得して分析
    console.log("📥 CSVファイルを取得中...")
    const csvUrl =
      "https://hebbkx1anhila5yf.public.blob.vercel-storage.com/E-NISA%E3%83%AA%E3%82%B9%E3%83%88%20-%20SHOGUN%2BENISA%E7%B4%B9%E4%BB%8B%E8%80%85%E9%A0%86%E3%81%AB%E4%B8%A6%E3%81%B9%E6%9B%BF%E3%81%88-xqLb3E20fjpzRQiUkpfqPjUkP0puIK.csv"

    const response = await fetch(csvUrl)
    if (!response.ok) {
      throw new Error(`CSVファイル取得失敗: ${response.status}`)
    }

    const csvText = await response.text()
    console.log("✅ CSVファイル取得成功")

    // CSVをパース（簡単な実装）
    const lines = csvText.split("\n")
    const headers = lines[0].split(",").map((h) => h.trim().replace(/"/g, ""))

    console.log("📋 CSVヘッダー:")
    headers.forEach((header, index) => {
      console.log(`  ${index}: ${header}`)
    })

    const csvData = []
    for (let i = 1; i < lines.length; i++) {
      if (lines[i].trim()) {
        const values = lines[i].split(",").map((v) => v.trim().replace(/"/g, ""))
        const row = {}
        headers.forEach((header, index) => {
          row[header] = values[index] || null
        })
        csvData.push(row)
      }
    }

    console.log(`📊 CSVデータ: ${csvData.length}行`)

    // 2. 紹介関係の分析
    console.log("\n🔍 紹介関係の分析:")

    const referrerStats = {}
    const rootUsers = []
    const usersWithReferrer = []

    csvData.forEach((row) => {
      const userId = row.id
      const referrer = row.referrer

      if (!referrer || referrer === "NULL" || referrer === "") {
        rootUsers.push({
          user_id: userId,
          name: row.name,
          email: row["メールアドレス"],
          proxy_email: row["代理のメアド"],
        })
      } else {
        usersWithReferrer.push({
          user_id: userId,
          name: row.name,
          email: row["メールアドレス"],
          proxy_email: row["代理のメアド"],
          referrer: referrer,
        })

        referrerStats[referrer] = (referrerStats[referrer] || 0) + 1
      }
    })

    console.log(`  ルートユーザー（紹介者なし）: ${rootUsers.length}人`)
    console.log(`  紹介者ありユーザー: ${usersWithReferrer.length}人`)

    console.log("\n👤 ルートユーザー一覧:")
    rootUsers.forEach((user) => {
      console.log(`  ${user.user_id} (${user.name}) - ${user.email}`)
    })

    console.log("\n📈 紹介者ランキング（上位10位）:")
    Object.entries(referrerStats)
      .sort(([, a], [, b]) => b - a)
      .slice(0, 10)
      .forEach(([referrer, count]) => {
        console.log(`  ${referrer}: ${count}人`)
      })

    // 3. 現在のDBと比較
    console.log("\n🔄 現在のDBとの比較:")

    const { data: dbUsers, error: dbError } = await supabase.from("users").select(`
        user_id,
        name,
        email,
        referrer_id
      `)

    if (dbError) {
      console.error("❌ DB取得エラー:", dbError)
      return
    }

    console.log(`  DB内ユーザー数: ${dbUsers.length}人`)

    // 紹介者IDをuser_idに変換するマップを作成
    const idToUserIdMap = {}
    for (const user of dbUsers) {
      if (user.referrer_id) {
        const { data: referrer } = await supabase.from("users").select("user_id").eq("id", user.referrer_id).single()

        if (referrer) {
          idToUserIdMap[user.user_id] = referrer.user_id
        }
      }
    }

    // 差異を確認
    const differences = []
    const csvUserMap = {}

    csvData.forEach((row) => {
      csvUserMap[row.id] = row.referrer
    })

    dbUsers.forEach((dbUser) => {
      const csvReferrer = csvUserMap[dbUser.user_id]
      const dbReferrer = idToUserIdMap[dbUser.user_id]

      const csvRef = csvReferrer || null
      const dbRef = dbReferrer || null

      if (csvRef !== dbRef) {
        differences.push({
          user_id: dbUser.user_id,
          name: dbUser.name,
          csv_referrer: csvRef,
          db_referrer: dbRef,
          status: csvRef ? (dbRef ? "DIFFERENT" : "MISSING_IN_DB") : "SHOULD_BE_NULL",
        })
      }
    })

    console.log(`\n❌ 差異のあるユーザー: ${differences.length}人`)

    if (differences.length > 0) {
      console.log("\n📋 修正が必要なユーザー（最初の20人）:")
      differences.slice(0, 20).forEach((diff) => {
        console.log({
          user_id: diff.user_id,
          name: diff.name,
          csv_referrer: diff.csv_referrer || "なし",
          db_referrer: diff.db_referrer || "なし",
          status: diff.status,
        })
      })

      if (differences.length > 20) {
        console.log(`  ... 他 ${differences.length - 20}人`)
      }
    }

    // 4. 特に重要なユーザーの確認
    console.log("\n🎯 重要ユーザーの確認:")
    const importantUsers = ["bighand1011", "klmiklmi0204", "Mira", "USER0a18", "OHTAKIYO", "1125Ritsuko"]

    importantUsers.forEach((userId) => {
      const csvUser = csvData.find((row) => row.id === userId)
      const dbUser = dbUsers.find((user) => user.user_id === userId)

      if (csvUser && dbUser) {
        const csvReferrer = csvUser.referrer || "なし"
        const dbReferrer = idToUserIdMap[userId] || "なし"

        console.log({
          user_id: userId,
          name: csvUser.name,
          csv_referrer: csvReferrer,
          db_referrer: dbReferrer,
          status: csvReferrer === dbReferrer ? "✅ 正しい" : "❌ 修正必要",
        })
      }
    })

    // 5. 代理メールアドレスの分析
    console.log("\n📧 代理メールアドレスの分析:")
    const proxyEmailUsers = csvData.filter(
      (row) => row["代理のメアド"] && row["代理のメアド"].includes("@shogun-trade.com"),
    )

    console.log(`  代理メール使用者: ${proxyEmailUsers.length}人`)

    const proxyReferrerStats = {}
    proxyEmailUsers.forEach((user) => {
      if (user.referrer) {
        proxyReferrerStats[user.referrer] = (proxyReferrerStats[user.referrer] || 0) + 1
      }
    })

    console.log("  代理メール紹介者ランキング:")
    Object.entries(proxyReferrerStats)
      .sort(([, a], [, b]) => b - a)
      .slice(0, 5)
      .forEach(([referrer, count]) => {
        console.log(`    ${referrer}: ${count}人`)
      })

    // 6. 緊急修正が必要なユーザーの特定
    console.log("\n🚨 緊急修正が必要なユーザー:")
    const urgentFixes = differences.filter((diff) => ["bighand1011", "klmiklmi0204", "Mira"].includes(diff.user_id))

    if (urgentFixes.length > 0) {
      console.log("  以下のユーザーは今日の修正で紹介者が削除されました:")
      urgentFixes.forEach((fix) => {
        console.log({
          user_id: fix.user_id,
          name: fix.name,
          should_have_referrer: fix.csv_referrer,
          current_referrer: fix.db_referrer,
        })
      })
    }

    // 7. CSVにないDBユーザーの確認
    console.log("\n🔍 CSVにないDBユーザー:")
    const dbOnlyUsers = dbUsers.filter((dbUser) => !csvData.find((csvRow) => csvRow.id === dbUser.user_id))

    console.log(`  CSVにないユーザー: ${dbOnlyUsers.length}人`)
    if (dbOnlyUsers.length > 0) {
      console.log("  最初の10人:")
      dbOnlyUsers.slice(0, 10).forEach((user) => {
        console.log({
          user_id: user.user_id,
          name: user.name,
          email: user.email,
        })
      })
    }

    console.log("\n" + "=".repeat(60))
    console.log("📊 分析結果サマリー:")
    console.log(`  CSVユーザー数: ${csvData.length}人`)
    console.log(`  DBユーザー数: ${dbUsers.length}人`)
    console.log(`  ルートユーザー: ${rootUsers.length}人`)
    console.log(`  修正が必要: ${differences.length}人`)
    console.log(`  代理メール使用: ${proxyEmailUsers.length}人`)
    console.log(`  CSVにないDBユーザー: ${dbOnlyUsers.length}人`)

    if (differences.length > 0) {
      console.log("\n⚠️ 次のステップ:")
      console.log("  1. 緊急修正が必要なユーザーの修正")
      console.log("  2. その他の差異の確認と修正")
      console.log("  3. 修正結果の検証")
      console.log("  4. システム健全性の最終確認")
    } else {
      console.log("\n✅ すべてのユーザーの紹介関係が正しく設定されています")
    }
  } catch (error) {
    console.error("❌ 分析中にエラーが発生しました:", error)
  }
}

// 実行
analyzeAllUsers()
  .then(() => {
    console.log("\n✅ 全ユーザー分析完了")
  })
  .catch((error) => {
    console.error("❌ 全ユーザー分析エラー:", error)
  })
