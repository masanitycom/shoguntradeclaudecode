// CSVデータに基づく修正結果の検証

const { createClient } = require("@supabase/supabase-js")

// Supabaseクライアントの初期化
const supabase = createClient(process.env.NEXT_PUBLIC_SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY)

async function verifyCsvCorrections() {
  console.log("🔍 CSVデータに基づく修正結果を検証中...\n")

  try {
    // 1. 重要ユーザーの現在の紹介関係を確認
    console.log("=== 重要ユーザーの現在の紹介関係 ===")
    const { data: importantUsers, error: importantError } = await supabase
      .from("users")
      .select(`
        user_id,
        name,
        email,
        referrer:referrer_id(user_id, name),
        created_at,
        updated_at
      `)
      .in("user_id", ["OHTAKIYO", "1125Ritsuko", "USER0a18", "bighand1011", "Mira", "klmiklmi0204"])
      .order("user_id")

    if (importantError) {
      console.error("❌ 重要ユーザー取得エラー:", importantError)
      return
    }

    // CSVに基づく正しい紹介関係
    const correctReferrals = {
      OHTAKIYO: "klmiklmi0204",
      "1125Ritsuko": "USER0a18",
      USER0a18: null,
      bighand1011: null,
      Mira: null,
      klmiklmi0204: null,
    }

    importantUsers.forEach((user) => {
      const expectedReferrer = correctReferrals[user.user_id]
      const actualReferrer = user.referrer?.user_id || null
      const isCorrect = expectedReferrer === actualReferrer

      console.log(`${user.user_id} (${user.name})`)
      console.log(`  期待値: ${expectedReferrer || "なし"}`)
      console.log(`  実際値: ${actualReferrer || "なし"}`)
      console.log(`  状態: ${isCorrect ? "✅ 正しい" : "❌ 間違い"}`)
      console.log(`  メール: ${user.email}`)
      console.log(`  更新日: ${new Date(user.updated_at).toLocaleString("ja-JP")}`)
      console.log()
    })

    // 2. 修正が必要なユーザーの特定
    const incorrectUsers = importantUsers.filter((user) => {
      const expectedReferrer = correctReferrals[user.user_id]
      const actualReferrer = user.referrer?.user_id || null
      return expectedReferrer !== actualReferrer
    })

    if (incorrectUsers.length > 0) {
      console.log("=== 修正が必要なユーザー ===")
      incorrectUsers.forEach((user) => {
        const expectedReferrer = correctReferrals[user.user_id]
        const actualReferrer = user.referrer?.user_id || null
        console.log(`❌ ${user.user_id}: ${actualReferrer || "なし"} → ${expectedReferrer || "なし"}`)
      })
      console.log()
    } else {
      console.log("✅ 全ての重要ユーザーの紹介関係が正しく設定されています\n")
    }

    // 3. 1125Ritsukoの紹介したユーザー統計
    console.log("=== 1125Ritsukoの紹介統計 ===")
    const ritsukoUser = importantUsers.find((u) => u.user_id === "1125Ritsuko")
    if (ritsukoUser) {
      const { data: ritsukoReferrals, error: referralError } = await supabase
        .from("users")
        .select("user_id, name, email, created_at")
        .eq("referrer_id", ritsukoUser.id)
        .eq("is_admin", false)
        .order("created_at", { ascending: false })

      if (!referralError && ritsukoReferrals) {
        const proxyEmailCount = ritsukoReferrals.filter((u) => u.email.includes("@shogun-trade.com")).length
        const realEmailCount = ritsukoReferrals.length - proxyEmailCount

        console.log(`総紹介者数: ${ritsukoReferrals.length}`)
        console.log(`代理メール: ${proxyEmailCount}`)
        console.log(`実メール: ${realEmailCount}`)
        console.log()

        if (ritsukoReferrals.length > 0) {
          console.log("最近の紹介者（最新5人）:")
          ritsukoReferrals.slice(0, 5).forEach((user) => {
            const emailType = user.email.includes("@shogun-trade.com") ? "📧代理" : "✉️実"
            console.log(`  ${user.user_id} (${user.name}) ${emailType}`)
          })
          console.log()
        }
      }
    }

    // 4. システム全体の健全性確認
    console.log("=== システム健全性確認 ===")
    const { data: systemHealth, error: healthError } = await supabase.rpc("get_system_health_stats")

    if (!healthError && systemHealth) {
      console.log(`総ユーザー数: ${systemHealth.total_users}`)
      console.log(`紹介者ありユーザー: ${systemHealth.users_with_referrer}`)
      console.log(`紹介者率: ${systemHealth.referrer_percentage}%`)
      console.log(`代理メールユーザー: ${systemHealth.proxy_email_users}`)
      console.log(`無効な紹介者: ${systemHealth.invalid_referrers}`)
      console.log(`自己参照: ${systemHealth.self_references}`)
    }

    // 5. 最近の変更ログ確認
    console.log("\n=== 最近の変更ログ ===")
    const { data: changeLogs, error: logError } = await supabase
      .from("referral_change_log")
      .select("*")
      .eq("changed_by", "CSV_DATA_CORRECTION")
      .gte("changed_at", new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString())
      .order("changed_at", { ascending: false })

    if (!logError && changeLogs && changeLogs.length > 0) {
      console.log(`過去24時間の変更: ${changeLogs.length}件`)
      changeLogs.forEach((log) => {
        console.log(`${log.user_code}: ${log.old_referrer_code || "なし"} → ${log.new_referrer_code || "なし"}`)
        console.log(`  理由: ${log.change_reason}`)
        console.log(`  日時: ${new Date(log.changed_at).toLocaleString("ja-JP")}`)
        console.log()
      })
    } else {
      console.log("過去24時間の変更ログはありません")
    }

    // 6. 検証結果サマリー
    console.log("=== 検証結果サマリー ===")
    const correctCount = importantUsers.length - incorrectUsers.length
    console.log(`✅ 正しい紹介関係: ${correctCount}/${importantUsers.length}`)
    console.log(`❌ 修正が必要: ${incorrectUsers.length}/${importantUsers.length}`)

    if (incorrectUsers.length === 0) {
      console.log("\n🎉 全ての重要ユーザーの紹介関係が正しく修正されました！")
    } else {
      console.log("\n⚠️ まだ修正が必要なユーザーがあります。修正スクリプトを実行してください。")
    }
  } catch (error) {
    console.error("❌ 検証中にエラーが発生しました:", error)
  }
}

// システム健全性統計を取得するSQL関数（存在しない場合は作成）
async function createHealthStatsFunction() {
  const { error } = await supabase.rpc("create_health_stats_function")
  if (error && !error.message.includes("already exists")) {
    console.error("健全性統計関数の作成エラー:", error)
  }
}

// 実行
createHealthStatsFunction().then(() => {
  verifyCsvCorrections()
    .then(() => {
      console.log("\n✅ 検証完了")
    })
    .catch((error) => {
      console.error("❌ 検証エラー:", error)
    })
})
