const { createClient } = require("@supabase/supabase-js")

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY
const supabase = createClient(supabaseUrl, supabaseKey)

async function analyzeCompleteWeeklyRates() {
  console.log("📊 CSVデータの正確な解析開始...")

  try {
    // 提供されたCSVデータを正確に解析
    const csvRawData = `2週目3週目4週目5週目6週目7週目8週目9週目10週目11週目12週目13週目14週目15週目16週目17週目18週目19週目20週目2025/2/10~142025/2/17~212025/2/24~282025/3/3~72025/3/10~142025/3/17~212025/3/24~282025/3/31~4/42025/4/7~4/112025/4/14~4/182025/4/21~4/252025/5/7~5/92025/5/12~5/162025/5/19~5/232025/5/26~5/302025/6/2~6/62025/6/9~6/132025/6/16~6/202025/6/23~6/27`

    console.log("🔍 提供されたCSVデータ:")
    console.log(csvRawData)

    console.log("\n📋 データ構造分析:")
    console.log(
      "前半: 2週目3週目4週目5週目6週目7週目8週目9週目10週目11週目12週目13週目14週目15週目16週目17週目18週目19週目20週目",
    )
    console.log(
      "後半: 2025/2/10~14 2025/2/17~21 2025/2/24~28 2025/3/3~7 2025/3/10~14 2025/3/17~21 2025/3/24~28 2025/3/31~4/4 2025/4/7~4/11 2025/4/14~4/18 2025/4/21~4/25 2025/5/7~5/9 2025/5/12~5/16 2025/5/19~5/23 2025/5/26~5/30 2025/6/2~6/6 2025/6/9~6/13 2025/6/16~6/20 2025/6/23~6/27",
    )

    console.log("\n❌ 問題点:")
    console.log("1. 週番号と日付範囲が混在している")
    console.log("2. 実際の週利パーセンテージが見当たらない")
    console.log("3. CSVの構造が不明確")

    console.log("\n🤔 推測される構造:")
    console.log("- 前半19項目: 週番号のヘッダー（2週目〜20週目）")
    console.log("- 後半19項目: 対応する日付範囲")
    console.log("- 実際の週利データ（パーセンテージ）が不足している")

    // 日付範囲を解析
    const dateRanges = [
      "2025/2/10~14",
      "2025/2/17~21",
      "2025/2/24~28",
      "2025/3/3~7",
      "2025/3/10~14",
      "2025/3/17~21",
      "2025/3/24~28",
      "2025/3/31~4/4",
      "2025/4/7~4/11",
      "2025/4/14~4/18",
      "2025/4/21~4/25",
      "2025/5/7~5/9",
      "2025/5/12~5/16",
      "2025/5/19~5/23",
      "2025/5/26~5/30",
      "2025/6/2~6/6",
      "2025/6/9~6/13",
      "2025/6/16~6/20",
      "2025/6/23~6/27",
    ]

    console.log("\n📅 日付範囲分析:")
    dateRanges.forEach((range, index) => {
      const weekNumber = index + 2 // 2週目から開始
      console.log(`第${weekNumber}週: ${range}`)
    })

    // 正しい週開始日と比較
    console.log("\n🔍 正しい週開始日との比較:")
    const baseDate = new Date("2025-01-06") // 第1週の月曜日

    for (let week = 2; week <= 20; week++) {
      const correctStart = new Date(baseDate)
      correctStart.setDate(baseDate.getDate() + (week - 1) * 7)

      const csvRange = dateRanges[week - 2] || "不明"
      const correctDate = correctStart.toISOString().split("T")[0]

      console.log(`第${week}週: 正しい開始日=${correctDate}, CSV範囲=${csvRange}`)
    }

    console.log("\n❓ 不足している情報:")
    console.log("1. 各週の実際の週利パーセンテージ")
    console.log("2. NFT別の設定値")
    console.log("3. 完全なCSVファイルの構造")

    console.log("\n💡 推奨アクション:")
    console.log("1. 完全なCSVファイルを確認")
    console.log("2. 週利パーセンテージデータの場所を特定")
    console.log("3. 正しいデータ形式での再提供")

    // 現在のDBデータを確認
    const { data: currentRates, error: currentError } = await supabase
      .from("nft_weekly_rates")
      .select("week_number, COUNT(*)")
      .gte("week_number", 2)
      .group("week_number")
      .order("week_number")

    if (currentError) throw currentError

    console.log("\n📊 現在のDB設定状況:")
    const existingWeeks = currentRates?.map((r) => r.week_number) || []
    console.log(`設定済み週: ${existingWeeks.join(", ")}`)
    console.log(`設定済み週数: ${existingWeeks.length}週`)

    return {
      csvRawData,
      dateRanges,
      existingWeeks,
      needsMoreData: true,
    }
  } catch (error) {
    console.error("❌ 分析エラー:", error)
    throw error
  }
}

// 実行
analyzeCompleteWeeklyRates()
  .then((result) => {
    console.log("\n✅ 分析完了")
    console.log("⚠️ 完全なCSVデータが必要です")
  })
  .catch((error) => {
    console.error("❌ 分析失敗:", error)
  })
