const { createClient } = require("@supabase/supabase-js")

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY
const supabase = createClient(supabaseUrl, supabaseKey)

async function analyzeCompleteCSVData() {
  console.log("📊 CSVファイルの実際の内容を確認...")

  try {
    // CSVファイルを直接取得
    const csvUrl =
      "https://hebbkx1anhila5yf.public.blob.vercel-storage.com/%E9%80%B1%E5%88%A9%E8%A8%AD%E5%AE%9A%20-%20%E3%82%B7%E3%83%BC%E3%83%881%20%282%29-xf6S0JEO7KgGA19O5Vcfpp3R12B5GC.csv"
    const response = await fetch(csvUrl)
    const csvText = await response.text()

    console.log("📄 CSVファイル取得完了")
    console.log("ファイルサイズ:", csvText.length, "文字")

    // CSVを解析
    const lines = csvText.trim().split("\n")
    const headers = lines[0].split(",").map((h) => h.trim().replace(/"/g, ""))

    console.log("\n📋 実際のCSVヘッダー:")
    headers.forEach((header, index) => {
      console.log(`${index + 1}. "${header}"`)
    })

    // データ行を解析
    const dataRows = lines.slice(1)
    console.log(`\n📊 データ行数: ${dataRows.length}行`)

    // 最初の数行を詳細表示
    console.log("\n🔍 実際のCSVデータ（最初の3行）:")
    dataRows.slice(0, 3).forEach((line, index) => {
      const values = line.split(",").map((v) => v.trim().replace(/"/g, ""))
      console.log(`行${index + 1}: NFT="${values[0]}"`)

      // 各週のデータを表示
      for (let i = 1; i < Math.min(values.length, 10); i++) {
        const weekNum = i + 1
        console.log(`  第${weekNum}週: "${values[i]}"`)
      }

      // 20週目の値（日付範囲が入っている可能性）
      if (values.length > 19) {
        console.log(`  第20週: "${values[19]}"`)
      }
    })

    // 20週目の列から日付パターンを抽出
    const datePattern = dataRows[0]?.split(",")[19]?.trim().replace(/"/g, "")
    console.log(`\n📅 第20週の値: "${datePattern}"`)

    // 日付パターンから基準日を逆算
    if (datePattern && datePattern.includes("2025/6/23")) {
      console.log("✅ 日付パターン確認: 2025/6/23~6/27")
      console.log("📐 基準日を逆算中...")

      // 第20週が2025/6/23から始まる場合の第1週を計算
      const week20Start = new Date("2025-06-23")
      const week1Start = new Date(week20Start)
      week1Start.setDate(week20Start.getDate() - (20 - 1) * 7)

      console.log(`📅 計算された第1週開始日: ${week1Start.toISOString().split("T")[0]}`)
      console.log(
        `📅 計算された第2週開始日: ${new Date(week1Start.getTime() + 7 * 24 * 60 * 60 * 1000).toISOString().split("T")[0]}`,
      )
    }

    // 正しい基準日で週利データを解析
    const correctBaseDate = new Date("2025-02-10") // 第1週の月曜日

    const weeklyRatesData = []

    dataRows.forEach((line, rowIndex) => {
      const values = line.split(",").map((v) => v.trim().replace(/"/g, ""))
      const nftName = values[0]

      if (!nftName || nftName === "") return

      console.log(`\n🎯 NFT: ${nftName}`)

      // 2週目から19週目までの週利を処理
      for (let weekIndex = 1; weekIndex <= 18; weekIndex++) {
        const weekNumber = weekIndex + 1 // 2週目から開始
        const rateValue = values[weekIndex]

        let weeklyRate = 0
        if (rateValue && rateValue !== "" && !isNaN(Number.parseFloat(rateValue))) {
          weeklyRate = Number.parseFloat(rateValue)
        }

        // 正しい週開始日を計算
        const weekStartDate = new Date(correctBaseDate)
        weekStartDate.setDate(correctBaseDate.getDate() + (weekNumber - 1) * 7)

        const weekEndDate = new Date(weekStartDate)
        weekEndDate.setDate(weekStartDate.getDate() + 4)

        const dateRange = `${weekStartDate.toLocaleDateString("ja-JP", { month: "numeric", day: "numeric" })}～${weekEndDate.toLocaleDateString("ja-JP", { month: "numeric", day: "numeric" })}`

        weeklyRatesData.push({
          nft_name: nftName,
          week_number: weekNumber,
          weekly_rate: weeklyRate,
          week_start_date: weekStartDate.toISOString().split("T")[0],
          week_end_date: weekEndDate.toISOString().split("T")[0],
          date_range: dateRange,
        })

        if (weeklyRate > 0) {
          console.log(`  第${weekNumber}週 (${dateRange}): ${weeklyRate}%`)
        } else if (weekNumber <= 5) {
          console.log(`  第${weekNumber}週 (${dateRange}): 0% (開始前)`)
        }
      }
    })

    console.log(`\n📈 解析完了: ${weeklyRatesData.length}件のデータ`)

    // 週別統計（正しい日付で）
    const weekStats = {}
    weeklyRatesData.forEach((item) => {
      if (!weekStats[item.week_number]) {
        weekStats[item.week_number] = {
          week_number: item.week_number,
          date_range: item.date_range,
          total_nfts: 0,
          active_nfts: 0,
          total_rate: 0,
          max_rate: 0,
        }
      }

      weekStats[item.week_number].total_nfts++
      if (item.weekly_rate > 0) {
        weekStats[item.week_number].active_nfts++
        weekStats[item.week_number].total_rate += item.weekly_rate
        weekStats[item.week_number].max_rate = Math.max(weekStats[item.week_number].max_rate, item.weekly_rate)
      }
    })

    console.log("\n📊 正しい日付での週別統計:")
    Object.values(weekStats).forEach((stats) => {
      const avgRate = stats.active_nfts > 0 ? (stats.total_rate / stats.active_nfts).toFixed(2) : 0
      console.log(`第${stats.week_number}週 (${stats.date_range}):`)
      console.log(`  NFT数: ${stats.total_nfts}, 有効: ${stats.active_nfts}`)
      console.log(`  平均週利: ${avgRate}%, 最大: ${stats.max_rate}%`)
    })

    return {
      success: true,
      totalRecords: weeklyRatesData.length,
      weekStats: Object.values(weekStats),
      correctBaseDate: correctBaseDate.toISOString().split("T")[0],
      sampleData: weeklyRatesData.slice(0, 10),
    }
  } catch (error) {
    console.error("❌ 分析エラー:", error)
    throw error
  }
}

// 実行
analyzeCompleteCSVData()
  .then((result) => {
    console.log("\n✅ 分析完了")
    console.log(`📊 総レコード数: ${result.totalRecords}`)
    console.log(`📅 正しい基準日: ${result.correctBaseDate}`)
    console.log("🔧 管理画面の日付計算を修正してください")
  })
  .catch((error) => {
    console.error("❌ 分析失敗:", error)
  })
