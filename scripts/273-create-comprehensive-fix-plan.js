import { createClient } from "@supabase/supabase-js"

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY

if (!supabaseUrl || !supabaseServiceKey) {
  throw new Error("Missing Supabase environment variables")
}

const supabase = createClient(supabaseUrl, supabaseServiceKey)

async function createComprehensiveFixPlan() {
  console.log("📋 包括的な修正計画を作成します...")
  console.log("=".repeat(60))

  let problemUsers = []
  let todayUpdates = []
  let rootUsers = []
  const csvData = []
  const differences = []

  try {
    // 1. 現在の問題状況を確認
    console.log("🔍 現在の問題状況を確認中...")

    const { data: problemUsersData, error: problemError } = await supabase
      .from("users")
      .select(`
        user_id,
        name,
        email,
        referrer_id,
        updated_at
      `)
      .in("user_id", ["bighand1011", "klmiklmi0204", "Mira"])
      .order("user_id")

    if (problemError) {
      console.error("❌ 問題ユーザー取得エラー:", problemError)
      return
    }

    problemUsers = problemUsersData

    console.log("🚨 緊急修正対象ユーザーの現在の状態:")
    for (const user of problemUsers) {
      let referrerInfo = "なし"
      if (user.referrer_id) {
        const { data: referrer } = await supabase
          .from("users")
          .select("user_id, name")
          .eq("id", user.referrer_id)
          .single()

        if (referrer) {
          referrerInfo = `${referrer.user_id} (${referrer.name})`
        }
      }

      console.log({
        user_id: user.user_id,
        name: user.name,
        current_referrer: referrerInfo,
        last_updated: user.updated_at,
        status: user.referrer_id ? "✅ 紹介者あり" : "❌ 紹介者なし",
      })
    }

    // 2. 今日修正されたユーザーの統計
    console.log("\n📊 今日修正されたユーザーの統計:")
    const { data: todayUpdatesData, error: updateError } = await supabase
      .from("users")
      .select("user_id, name, updated_at", { count: "exact" })
      .gte("updated_at", "2025-06-29T06:00:00Z")
      .order("updated_at", { ascending: false })

    if (updateError) {
      console.error("❌ 今日の更新取得エラー:", updateError)
    } else {
      todayUpdates = todayUpdatesData
      console.log(`  今日修正されたユーザー数: ${todayUpdates.length}人`)

      console.log("  修正されたユーザー一覧（最初の10人）:")
      todayUpdates.slice(0, 10).forEach((user) => {
        console.log(`    ${user.user_id} (${user.name}) - ${user.updated_at}`)
      })
    }

    // 3. 紹介者なしユーザーの確認
    console.log("\n👤 現在の紹介者なしユーザー:")
    const { data: rootUsersData, error: rootError } = await supabase
      .from("users")
      .select("user_id, name, email, created_at")
      .is("referrer_id", null)
      .order("created_at")

    if (rootError) {
      console.error("❌ ルートユーザー取得エラー:", rootError)
    } else {
      rootUsers = rootUsersData
      console.log(`  紹介者なしユーザー数: ${rootUsers.length}人`)
      rootUsers.forEach((user) => {
        const status =
          user.user_id === "admin001"
            ? "✅ 管理者（正常）"
            : user.user_id === "USER0a18"
              ? "✅ ルートユーザー（正常）"
              : "❌ 紹介者が必要"

        console.log({
          user_id: user.user_id,
          name: user.name,
          email: user.email,
          status: status,
        })
      })
    }

    // 4. CSVファイルの分析結果を取得
    console.log("\n📄 CSVファイルの分析結果:")
    try {
      const csvUrl =
        "https://hebbkx1anhila5yf.public.blob.vercel-storage.com/E-NISA%E3%83%AA%E3%82%B9%E3%83%88%20-%20SHOGUN%2BENISA%E7%B4%B9%E4%BB%8B%E8%80%85%E9%A0%86%E3%81%AB%E4%B8%A6%E3%81%B9%E6%9B%BF%E3%81%88-xqLb3E20fjpzRQiUkpfqPjUkP0puIK.csv"

      const response = await fetch(csvUrl)
      if (!response.ok) {
        throw new Error(`CSV取得エラー: ${response.status}`)
      }

      const csvText = await response.text()
      const lines = csvText.split("\n")
      const headers = lines[0].split(",")

      console.log(`  CSVファイル取得成功`)
      console.log(`  総行数: ${lines.length - 1}人（ヘッダー除く）`)
      console.log(`  列数: ${headers.length}`)

      // CSVデータを解析
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

      console.log(`  有効なユーザーデータ: ${csvData.length}人`)

      // ルートユーザー（紹介者なし）の確認
      const csvRootUsers = csvData.filter((user) => !user.referrer || user.referrer === "")
      console.log(`  CSVルートユーザー数: ${csvRootUsers.length}人`)

      csvRootUsers.forEach((user) => {
        console.log(`    ${user.id} (${user.name}) - 紹介者なし`)
      })

      // 重要ユーザーの確認
      const importantUsers = ["bighand1011", "klmiklmi0204", "Mira", "OHTAKIYO", "1125Ritsuko", "USER0a18"]
      console.log("\n🎯 重要ユーザーのCSV情報:")

      importantUsers.forEach((userId) => {
        const csvUser = csvData.find((user) => user.id === userId)
        if (csvUser) {
          console.log({
            user_id: csvUser.id,
            name: csvUser.name,
            csv_referrer: csvUser.referrer || "なし",
            email: csvUser.email,
            proxy_email: csvUser.proxyEmail,
          })
        } else {
          console.log({
            user_id: userId,
            status: "❌ CSVに存在しない",
          })
        }
      })

      // 5. CSVとDBの差異分析
      console.log("\n🔄 CSVとDBの差異分析:")

      const { data: allDbUsersData, error: allDbError } = await supabase
        .from("users")
        .select("user_id, name, referrer_id")

      if (allDbError) {
        console.error("❌ 全ユーザー取得エラー:", allDbError)
        return
      }

      // 紹介者IDをuser_idに変換するマップを作成
      const idToUserIdMap = {}
      for (const user of allDbUsersData) {
        if (user.referrer_id) {
          const { data: referrer } = await supabase.from("users").select("user_id").eq("id", user.referrer_id).single()

          if (referrer) {
            idToUserIdMap[user.user_id] = referrer.user_id
          }
        }
      }

      // 差異を確認
      const csvUserMap = {}

      csvData.forEach((row) => {
        csvUserMap[row.id] = row.referrer
      })

      allDbUsersData.forEach((dbUser) => {
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

      console.log(`  差異のあるユーザー数: ${differences.length}人`)

      if (differences.length > 0) {
        console.log("  差異のあるユーザー（最初の10人）:")
        differences.slice(0, 10).forEach((diff) => {
          console.log({
            user_id: diff.user_id,
            name: diff.name,
            csv_referrer: diff.csv_referrer || "なし",
            db_referrer: diff.db_referrer || "なし",
            status: diff.status,
          })
        })

        if (differences.length > 10) {
          console.log(`    ... 他 ${differences.length - 10}人`)
        }
      }
    } catch (csvError) {
      console.error("❌ CSVファイル分析エラー:", csvError)
    }

    // 6. 修正計画の提案
    console.log("\n📋 修正計画の提案:")
    console.log("=".repeat(40))

    console.log("🎯 Phase 1: 緊急修正（今日削除した紹介関係の復元）")
    console.log("  対象: bighand1011, klmiklmi0204, Mira")
    console.log("  方法: CSVデータに基づく正しい紹介者の設定")
    console.log("  優先度: 🔴 最高")
    console.log("  ステータス: ✅ 実行済み（scripts/274で修正）")

    console.log("\n🎯 Phase 2: 全体的な差異の修正")
    console.log("  対象: CSVとDBで差異のあるすべてのユーザー")
    console.log("  方法: 段階的な修正とテスト")
    console.log("  優先度: 🟡 中")

    console.log("\n🎯 Phase 3: システム健全性の確認")
    console.log("  対象: 全ユーザーの紹介関係")
    console.log("  方法: 循環参照チェック、孤立ユーザーチェック")
    console.log("  優先度: 🟢 低")

    // 7. 次のアクション
    console.log("\n⚠️ 次に必要なアクション:")
    console.log("1. ✅ 緊急修正の実行（scripts/274）")
    console.log("2. 🔄 修正結果の検証")
    console.log("3. 📊 CSVとDBの全体的な差異分析")
    console.log("4. 🎯 段階的な修正計画の策定")
    console.log("5. ✅ システム健全性の最終確認")

    console.log("\n" + "=".repeat(60))
    console.log("📊 現在の状況サマリー:")
    console.log(`  総ユーザー数: ${problemUsers.length + todayUpdates.length + rootUsers.length}人`)
    console.log(`  紹介者なし: ${rootUsers.length}人`)
    console.log(`  今日修正: ${todayUpdates.length}人`)
    console.log(`  緊急修正対象: 3人 (bighand1011, klmiklmi0204, Mira)`)
    console.log(`  CSVとの差異: ${differences.length}人`)
  } catch (error) {
    console.error("❌ 修正計画作成中にエラーが発生しました:", error)
  }
}

// 実行
createComprehensiveFixPlan()
  .then(() => {
    console.log("\n✅ 包括的な修正計画作成完了")
  })
  .catch((error) => {
    console.error("❌ 修正計画作成エラー:", error)
  })
