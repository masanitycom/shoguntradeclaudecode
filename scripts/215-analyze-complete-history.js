// 完全な週利履歴の詳細分析

console.log("🔍 週利履歴の完全分析を開始...")

// Supabase接続設定
const { createClient } = require("@supabase/supabase-js")

// 環境変数の確認
const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY

if (!supabaseUrl || !supabaseKey) {
  console.error("❌ Supabase環境変数が設定されていません")
  console.log("必要な環境変数:")
  console.log("- NEXT_PUBLIC_SUPABASE_URL")
  console.log("- SUPABASE_SERVICE_ROLE_KEY")
  process.exit(1)
}

const supabase = createClient(supabaseUrl, supabaseKey)

async function analyzeCompleteHistory() {
  try {
    console.log("📊 週利履歴の全体分析...")

    // 1. 全体概要の取得
    const { data: overview, error: overviewError } = await supabase
      .from("nft_weekly_rates")
      .select("week_number, weekly_rate, monday_rate, tuesday_rate, wednesday_rate, thursday_rate, friday_rate")

    if (overviewError) throw overviewError

    console.log(`📈 総履歴数: ${overview.length}件`)

    if (overview.length === 0) {
      console.log("❌ 週利履歴が見つかりません")
      return
    }

    // 2. 週数の範囲
    const weeks = overview.map((item) => item.week_number)
    const minWeek = Math.min(...weeks)
    const maxWeek = Math.max(...weeks)
    const uniqueWeeks = [...new Set(weeks)].sort((a, b) => a - b)

    console.log(`📅 週数範囲: 第${minWeek}週 〜 第${maxWeek}週`)
    console.log(`📊 設定済み週数: ${uniqueWeeks.length}週`)
    console.log(`🗓️ 設定済み週: ${uniqueWeeks.join(", ")}`)

    // 3. 17週以前の分析
    const preWeek17 = overview.filter((item) => item.week_number < 17)
    const week17AndLater = overview.filter((item) => item.week_number >= 17)

    console.log(`\n📋 17週以前の履歴: ${preWeek17.length}件`)
    console.log(`📋 17週以降の履歴: ${week17AndLater.length}件`)

    // 4. 配分パターンの分析
    let equalDistribution = 0
    let unequalDistribution = 0
    let hasZeroDays = 0

    overview.forEach((item) => {
      const rates = [item.monday_rate, item.tuesday_rate, item.wednesday_rate, item.thursday_rate, item.friday_rate]

      // 均等配分の判定（差が0.01%以下）
      const isEqual = rates.every((rate) => Math.abs(rate - rates[0]) < 0.01)
      if (isEqual) {
        equalDistribution++
      } else {
        unequalDistribution++
      }

      // 0%の日があるかチェック
      if (rates.some((rate) => rate === 0)) {
        hasZeroDays++
      }
    })

    console.log(`\n📊 配分パターン分析:`)
    console.log(`✅ 均等配分: ${equalDistribution}件 (${((equalDistribution / overview.length) * 100).toFixed(1)}%)`)
    console.log(
      `🎲 不均等配分: ${unequalDistribution}件 (${((unequalDistribution / overview.length) * 100).toFixed(1)}%)`,
    )
    console.log(`🚫 0%の日を含む: ${hasZeroDays}件 (${((hasZeroDays / overview.length) * 100).toFixed(1)}%)`)

    // 5. 週利の統計
    const weeklyRates = overview.map((item) => item.weekly_rate)
    const avgWeeklyRate = weeklyRates.reduce((sum, rate) => sum + rate, 0) / weeklyRates.length
    const minWeeklyRate = Math.min(...weeklyRates)
    const maxWeeklyRate = Math.max(...weeklyRates)

    console.log(`\n💰 週利統計:`)
    console.log(`📊 平均週利: ${avgWeeklyRate.toFixed(3)}%`)
    console.log(`📉 最小週利: ${minWeeklyRate}%`)
    console.log(`📈 最大週利: ${maxWeeklyRate}%`)

    // 6. 最新の設定例を表示
    const latestWeek = Math.max(...weeks)
    const latestSettings = overview.filter((item) => item.week_number === latestWeek)

    console.log(`\n🔍 第${latestWeek}週の設定例:`)
    latestSettings.slice(0, 3).forEach((item, index) => {
      console.log(
        `${index + 1}. 週利${item.weekly_rate}% → 月${item.monday_rate}%, 火${item.tuesday_rate}%, 水${item.wednesday_rate}%, 木${item.thursday_rate}%, 金${item.friday_rate}%`,
      )
    })

    // 7. NFT別の履歴数
    const { data: nftHistory, error: nftError } = await supabase.from("nft_weekly_rates").select(`
                nft_id,
                nfts!inner(name)
            `)

    if (!nftError && nftHistory) {
      const nftCounts = {}
      nftHistory.forEach((item) => {
        const nftName = item.nfts.name
        nftCounts[nftName] = (nftCounts[nftName] || 0) + 1
      })

      console.log(`\n📋 NFT別履歴数 (上位5件):`)
      Object.entries(nftCounts)
        .sort(([, a], [, b]) => b - a)
        .slice(0, 5)
        .forEach(([name, count]) => {
          console.log(`${name}: ${count}件`)
        })
    }

    console.log("\n✅ 週利履歴分析完了")
  } catch (error) {
    console.error("❌ 分析エラー:", error.message)
  }
}

// 分析実行
analyzeCompleteHistory()
