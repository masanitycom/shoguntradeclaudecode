const { createClient } = require("@supabase/supabase-js")

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY

if (!supabaseUrl || !supabaseServiceKey) {
  console.error("❌ Supabase環境変数が設定されていません")
  process.exit(1)
}

const supabase = createClient(supabaseUrl, supabaseServiceKey)

async function verifyCorrections() {
  console.log("🔍 CSV修正結果の検証を開始...\n")

  try {
    // 修正されたユーザーの現在の状態を確認
    const { data: correctedUsers, error: correctedError } = await supabase
      .from("users")
      .select(`
        user_id,
        name,
        referrer_id,
        referrer:referrer_id(user_id, name)
      `)
      .in("user_id", ["klmiklmi0204", "kazukazu2", "yatchan003", "yatchan002", "bighand1011", "Mira", "OHTAKIYO"])
      .order("user_id")

    if (correctedError) {
      console.error("❌ 修正されたユーザーの取得エラー:", correctedError)
      return
    }

    console.log("📊 修正されたユーザーの現在の状態:")
    console.log("============================================================")
    correctedUsers.forEach((user) => {
      console.log({
        user_id: user.user_id,
        name: user.name,
        referrer: user.referrer?.user_id || "なし",
        referrer_name: user.referrer?.name || "なし",
      })
    })

    // 期待される修正内容と比較
    const expectedCorrections = {
      klmiklmi0204: "yasui001",
      kazukazu2: "kazukazu1",
      yatchan003: "yatchan",
      yatchan002: "yatchan",
      bighand1011: "USER0a18",
      Mira: "Mickey",
      OHTAKIYO: "klmiklmi0204",
    }

    console.log("\n✅ 修正結果の検証:")
    console.log("============================================================")
    let correctCount = 0
    let totalCount = 0

    correctedUsers.forEach((user) => {
      const expectedReferrer = expectedCorrections[user.user_id]
      const actualReferrer = user.referrer?.user_id
      const isCorrect = actualReferrer === expectedReferrer

      console.log({
        user_id: user.user_id,
        name: user.name,
        expected_referrer: expectedReferrer,
        actual_referrer: actualReferrer || "なし",
        status: isCorrect ? "✅ 正しく修正済み" : "❌ 修正が必要",
        priority: isCorrect ? "正常" : "🔴 要確認",
      })

      if (isCorrect) correctCount++
      totalCount++
    })

    console.log(`\n📊 修正成功率: ${correctCount}/${totalCount} (${Math.round((correctCount / totalCount) * 100)}%)`)

    // 1125Ritsukoの現在の紹介数を確認
    const { data: ritsukoReferrals, error: ritsukoError } = await supabase
      .from("users")
      .select("user_id, name")
      .eq("referrer.user_id", "1125Ritsuko")

    if (!ritsukoError) {
      console.log(`\n📊 1125Ritsukoの現在の紹介数: ${ritsukoReferrals?.length || 0}人`)
      if (ritsukoReferrals && ritsukoReferrals.length > 0) {
        console.log("🔍 1125Ritsukoが紹介したユーザー（最初の10人）:")
        ritsukoReferrals.slice(0, 10).forEach((user) => {
          console.log(`  - ${user.user_id} (${user.name})`)
        })
      }
    }

    // システム全体の健全性チェック
    const { data: systemHealth, error: healthError } = await supabase.rpc("get_system_health_stats")

    if (!healthError && systemHealth) {
      console.log("\n🏥 システム健全性:")
      console.log("============================================================")
      console.log(systemHealth)
    }

    // 紹介者別統計（上位10人）
    const { data: referrerStats, error: statsError } = await supabase
      .from("users")
      .select(`
        referrer_id,
        referrer:referrer_id(user_id, name)
      `)
      .not("referrer_id", "is", null)

    if (!statsError && referrerStats) {
      const referrerCounts = {}
      referrerStats.forEach((user) => {
        if (user.referrer) {
          const key = user.referrer.user_id
          if (!referrerCounts[key]) {
            referrerCounts[key] = {
              user_id: user.referrer.user_id,
              name: user.referrer.name,
              count: 0,
            }
          }
          referrerCounts[key].count++
        }
      })

      const topReferrers = Object.values(referrerCounts)
        .sort((a, b) => b.count - a.count)
        .slice(0, 10)

      console.log("\n🏆 紹介者ランキング（上位10人）:")
      console.log("============================================================")
      topReferrers.forEach((referrer, index) => {
        console.log({
          rank: index + 1,
          user_id: referrer.user_id,
          name: referrer.name,
          referral_count: referrer.count,
        })
      })
    }

    console.log("\n✅ CSV修正結果の検証完了")
  } catch (error) {
    console.error("❌ 検証中にエラーが発生:", error)
  }
}

// 実行
verifyCorrections()
