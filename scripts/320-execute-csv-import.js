const { createClient } = require("@supabase/supabase-js")

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY
const supabase = createClient(supabaseUrl, supabaseKey)

async function executeCSVImport() {
  console.log("📋 CSVデータに基づく正しい日付でのインポート準備...")

  try {
    // 正しい基準日（第1週の月曜日）
    const correctBaseDate = new Date("2025-02-10")

    console.log(`📅 基準日: ${correctBaseDate.toISOString().split("T")[0]}`)

    // 第2週の確認
    const week2Start = new Date(correctBaseDate)
    week2Start.setDate(correctBaseDate.getDate() + 7)
    console.log(`📅 第2週開始日: ${week2Start.toISOString().split("T")[0]} (${week2Start.toLocaleDateString("ja-JP")})`)

    // CSVから抽出した実際の週利データ
    const csvWeeklyRates = [
      { week: 2, rate: 0 }, // 2025/2/17~21
      { week: 3, rate: 0 }, // 2025/2/24~28
      { week: 4, rate: 0 }, // 2025/3/3~7
      { week: 5, rate: 0 }, // 2025/3/10~14
      { week: 6, rate: 0 }, // 2025/3/17~21
      { week: 7, rate: 0 }, // 2025/3/24~28
      { week: 8, rate: 0 }, // 2025/3/31~4/4
      { week: 9, rate: 0 }, // 2025/4/7~11
      { week: 10, rate: 1.46 }, // 2025/4/14~18
      { week: 11, rate: 1.37 }, // 2025/4/21~25
      { week: 12, rate: 1.51 }, // 2025/4/28~5/2
      { week: 13, rate: 0.85 }, // 2025/5/5~9
      { week: 14, rate: 1.49 }, // 2025/5/12~16
      { week: 15, rate: 1.89 }, // 2025/5/19~23
      { week: 16, rate: 1.76 }, // 2025/5/26~30
      { week: 17, rate: 2.02 }, // 2025/6/2~6
      { week: 18, rate: 2.23 }, // 2025/6/9~13
      { week: 19, rate: 1.17 }, // 2025/6/16~20
    ]

    // 日付範囲の計算関数
    const getWeekDates = (weekNumber) => {
      const weekStart = new Date(correctBaseDate)
      weekStart.setDate(correctBaseDate.getDate() + (weekNumber - 1) * 7)

      const weekEnd = new Date(weekStart)
      weekEnd.setDate(weekStart.getDate() + 4)

      return {
        start: weekStart.toISOString().split("T")[0],
        end: weekEnd.toISOString().split("T")[0],
        range: `${weekStart.toLocaleDateString("ja-JP", { month: "numeric", day: "numeric" })}～${weekEnd.toLocaleDateString("ja-JP", { month: "numeric", day: "numeric" })}`,
      }
    }

    // 各週の正しい日付を確認
    console.log("\n📅 正しい日付範囲:")
    csvWeeklyRates.forEach((item) => {
      const dates = getWeekDates(item.week)
      const status = item.rate > 0 ? "🟢" : "⚪"
      console.log(`${status} 第${item.week}週 (${dates.range}): ${item.rate}%`)
    })

    // アクティブなNFTを取得
    const { data: nfts, error: nftError } = await supabase.from("nfts").select("id, name").eq("is_active", true)

    if (nftError) throw nftError

    console.log(`\n📦 対象NFT数: ${nfts.length}個`)

    // ランダム配分関数
    const distributeRandomly = (weeklyRate) => {
      if (weeklyRate === 0) {
        return { monday: 0, tuesday: 0, wednesday: 0, thursday: 0, friday: 0 }
      }

      const activeDays = Math.floor(Math.random() * 5) + 1
      const rates = [0, 0, 0, 0, 0]

      const selectedDays = []
      while (selectedDays.length < activeDays) {
        const day = Math.floor(Math.random() * 5)
        if (!selectedDays.includes(day)) {
          selectedDays.push(day)
        }
      }

      let remaining = weeklyRate
      selectedDays.forEach((dayIndex, i) => {
        if (i === selectedDays.length - 1) {
          rates[dayIndex] = remaining
        } else {
          const rate = remaining * (0.1 + Math.random() * 0.7)
          rates[dayIndex] = Math.round(rate * 100) / 100
          remaining -= rates[dayIndex]
        }
      })

      return {
        monday: rates[0],
        tuesday: rates[1],
        wednesday: rates[2],
        thursday: rates[3],
        friday: rates[4],
      }
    }

    console.log("\n📊 インポート予定データ:")
    let totalRecords = 0

    for (const weekData of csvWeeklyRates) {
      const dates = getWeekDates(weekData.week)
      console.log(`第${weekData.week}週 (${dates.range}): ${weekData.rate}% - ${nfts.length}件のレコード`)
      totalRecords += nfts.length
    }

    console.log(`\n📋 総レコード数: ${totalRecords}件`)
    console.log("\n⚠️  実際のインポートは管理画面から手動で行ってください:")
    console.log("1. /admin/weekly-rates にアクセス")
    console.log("2. 各週の週利を手動入力")
    console.log("3. 日利配分は自動生成されます")

    // 現在の設定状況を確認
    const { data: existingRates } = await supabase
      .from("nft_weekly_rates")
      .select("week_number, COUNT(*)")
      .gte("week_number", 2)
      .lte("week_number", 19)

    if (existingRates && existingRates.length > 0) {
      console.log("\n📋 現在の設定状況:")
      const existingWeeks = existingRates.map((r) => r.week_number)
      console.log(`設定済み週: ${existingWeeks.join(", ")}`)
    }

    return {
      csvData: csvWeeklyRates,
      nftCount: nfts.length,
      totalRecords,
      correctBaseDate: correctBaseDate.toISOString().split("T")[0],
      message: "正しい日付での手動入力用データ準備完了",
    }
  } catch (error) {
    console.error("❌ エラー:", error)
    throw error
  }
}

// 実行
executeCSVImport()
  .then((result) => {
    console.log("\n✅ 準備完了")
    console.log(`📅 正しい基準日: ${result.correctBaseDate}`)
    console.log("👉 管理画面の日付計算を修正してから手動入力を開始してください")
  })
  .catch((error) => {
    console.error("❌ 失敗:", error)
  })
