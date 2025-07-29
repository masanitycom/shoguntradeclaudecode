const { createClient } = require("@supabase/supabase-js")

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY

if (!supabaseUrl || !supabaseServiceKey) {
  console.error("❌ Supabase環境変数が設定されていません")
  process.exit(1)
}

const supabase = createClient(supabaseUrl, supabaseServiceKey)

async function verifyCsvCorrections() {
  console.log("🔍 CSV修正結果の検証を開始...")
  console.log("=" * 60)

  try {
    // CSVファイルを再取得
    console.log("📥 CSVファイルを再取得中...")
    const csvUrl =
      "https://hebbkx1anhila5yf.public.blob.vercel-storage.com/SHOGUN%2BENISA%E7%B4%B9%E4%BB%8B%E8%80%85%E9%A0%86%E3%81%AB%E4%B8%A6%E3%81%B9%E6%9B%BF%E3%81%88%20-%20%E3%82%B7%E3%83%BC%E3%83%882-3sEEqgz48qctjxfbOBP51UPTybAwSP.csv"

    const response = await fetch(csvUrl)
    const csvText = await response.text()

    const lines = csvText.split("\n").filter((line) => line.trim())
    const csvUsers = []
    for (let i = 1; i < lines.length; i++) {
      const values = lines[i].split(",")
      if (values.length >= 4) {
        csvUsers.push({
          name: values[0]?.trim(),
          user_id: values[1]?.trim(),
          tel: values[2]?.trim(),
          referrer: values[3]?.trim() || null,
        })
      }
    }

    console.log(`✅ CSV再取得完了: ${csvUsers.length}人\n`)

    // データベースから修正後の状態を取得
    console.log("📥 修正後のデータベース状態を取得中...")
    const { data: dbUsers, error: dbError } = await supabase
      .from("users")
      .select(`
        user_id,
        name,
        referrer_id,
        referrer:referrer_id(user_id, name)
      `)
      .eq("is_admin", false)
      .order("user_id")

    if (dbError) {
      console.error("❌ データベース取得エラー:", dbError)
      return
    }

    console.log(`✅ データベース取得完了: ${dbUsers.length}人\n`)

    // CSVとデータベースを再比較
    console.log("🔍 修正結果の検証...")
    console.log("=" * 60)

    const csvUserMap = new Map()
    csvUsers.forEach((user) => {
      if (user.user_id) {
        csvUserMap.set(user.user_id, user)
      }
    })

    let correctCount = 0
    let stillWrongCount = 0
    const stillWrong = []

    dbUsers.forEach((dbUser) => {
      const csvUser = csvUserMap.get(dbUser.user_id)

      if (csvUser) {
        const currentReferrer = dbUser.referrer?.user_id || null
        const correctReferrer = csvUser.referrer || null

        if (currentReferrer === correctReferrer) {
          correctCount++
        } else {
          stillWrongCount++
          stillWrong.push({
            user_id: dbUser.user_id,
            name: dbUser.name,
            current_referrer: currentReferrer || "なし",
            correct_referrer: correctReferrer || "なし",
          })
        }
      }
    })

    console.log(`✅ 正しく修正された: ${correctCount}人`)
    console.log(`❌ まだ間違っている: ${stillWrongCount}人\n`)

    if (stillWrong.length > 0) {
      console.log("❌ まだ間違っているユーザー:")
      stillWrong.forEach((user, index) => {
        console.log({
          no: index + 1,
          user_id: user.user_id,
          name: user.name,
          現在の紹介者: user.current_referrer,
          正しい紹介者: user.correct_referrer,
        })
      })
    }

    // 1125Ritsukoの最終確認
    const { data: ritsukoReferrals, error: ritsukoError } = await supabase
      .from("users")
      .select("user_id, name")
      .eq("referrer_id", (await supabase.from("users").select("id").eq("user_id", "1125Ritsuko").single()).data?.id)

    if (!ritsukoError) {
      console.log(`\n🔍 1125Ritsukoの現在の紹介数: ${ritsukoReferrals?.length || 0}人`)
      if (ritsukoReferrals && ritsukoReferrals.length > 0) {
        console.log("❌ 1125Ritsukoがまだ紹介者になっているユーザー:")
        ritsukoReferrals.forEach((user, index) => {
          console.log(`  ${index + 1}. ${user.user_id} (${user.name})`)
        })
      } else {
        console.log("✅ 1125Ritsukoの紹介数は正しく0人になりました")
      }
    }

    // 紹介者ランキング
    const { data: topReferrers, error: topError } = await supabase.rpc("get_top_referrers", { limit_count: 10 })

    if (!topError && topReferrers) {
      console.log("\n📊 修正後の紹介者ランキング（上位10人）:")
      topReferrers.forEach((referrer, index) => {
        console.log({
          rank: index + 1,
          referrer_id: referrer.referrer_id,
          referrer_name: referrer.referrer_name,
          referral_count: referrer.referral_count,
        })
      })
    }

    console.log("\n" + "=" * 60)
    console.log("🎯 検証結果サマリー:")
    console.log(`  📊 CSVユーザー数: ${csvUsers.length}人`)
    console.log(`  📊 データベースユーザー数: ${dbUsers.length}人`)
    console.log(`  ✅ 正しく修正された: ${correctCount}人`)
    console.log(`  ❌ まだ間違っている: ${stillWrongCount}人`)
    console.log(`  📈 修正成功率: ${((correctCount / (correctCount + stillWrongCount)) * 100).toFixed(2)}%`)

    if (stillWrongCount === 0) {
      console.log("\n🎉 全ての紹介関係がCSVの通りに正しく修正されました！")
    } else {
      console.log(`\n⚠️ ${stillWrongCount}人の修正が必要です`)
    }

    return {
      csvUsers: csvUsers.length,
      dbUsers: dbUsers.length,
      correctCount,
      stillWrongCount,
      successRate: ((correctCount / (correctCount + stillWrongCount)) * 100).toFixed(2),
    }
  } catch (error) {
    console.error("❌ 検証中にエラーが発生:", error)
    throw error
  }
}

// 実行
verifyCsvCorrections()
  .then((result) => {
    console.log("\n🔍 CSV修正結果検証完了")
    console.log(`📊 修正成功率: ${result.successRate}%`)
  })
  .catch((error) => {
    console.error("❌ 検証エラー:", error)
  })
