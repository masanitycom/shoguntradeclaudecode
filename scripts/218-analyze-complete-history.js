import { createClient } from "@supabase/supabase-js"
import dotenv from "dotenv"

// 環境変数を読み込み
dotenv.config({ path: ".env.local" })

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

console.log("🔍 週利システム完全分析開始...\n")

async function analyzeCompleteHistory() {
  try {
    // 1. 週利履歴の全体統計
    console.log("📊 週利履歴全体統計")
    const { data: overallStats, error: statsError } = await supabase
      .from("nft_weekly_rates")
      .select("week_number, weekly_rate, nft_id")

    if (statsError) throw statsError

    const totalRecords = overallStats.length
    const uniqueWeeks = [...new Set(overallStats.map((r) => r.week_number))].length
    const uniqueNFTs = [...new Set(overallStats.map((r) => r.nft_id))].length
    const minWeek = Math.min(...overallStats.map((r) => r.week_number))
    const maxWeek = Math.max(...overallStats.map((r) => r.week_number))

    console.log(`総履歴数: ${totalRecords}件`)
    console.log(`週数範囲: 第${minWeek}週 〜 第${maxWeek}週 (${uniqueWeeks}週間)`)
    console.log(`設定されたNFT数: ${uniqueNFTs}個`)
    console.log("")

    // 2. 17週以前の詳細分析
    console.log("📈 17週以前の詳細分析")
    const preWeek17 = overallStats.filter((r) => r.week_number < 17)
    console.log(`17週以前の履歴数: ${preWeek17.length}件`)

    const preWeek17Weeks = [...new Set(preWeek17.map((r) => r.week_number))].sort((a, b) => a - b)
    console.log(`17週以前の週: ${preWeek17Weeks.join(", ")}`)
    console.log("")

    // 3. 週別の設定数分析
    console.log("📅 週別設定数分析")
    const weeklyStats = {}
    overallStats.forEach((record) => {
      if (!weeklyStats[record.week_number]) {
        weeklyStats[record.week_number] = {
          count: 0,
          rates: [],
        }
      }
      weeklyStats[record.week_number].count++
      weeklyStats[record.week_number].rates.push(record.weekly_rate)
    })

    Object.keys(weeklyStats)
      .sort((a, b) => Number.parseInt(a) - Number.parseInt(b))
      .slice(0, 10) // 最初の10週を表示
      .forEach((week) => {
        const stats = weeklyStats[week]
        const avgRate = (stats.rates.reduce((sum, rate) => sum + rate, 0) / stats.rates.length).toFixed(3)
        console.log(`第${week}週: ${stats.count}件設定, 平均週利${avgRate}%`)
      })
    console.log("")

    // 4. ランダム配分vs均等配分の分析
    console.log("🎲 配分方式分析")
    const { data: distributionData, error: distError } = await supabase
      .from("nft_weekly_rates")
      .select(`
        week_number,
        weekly_rate,
        monday_rate,
        tuesday_rate,
        wednesday_rate,
        thursday_rate,
        friday_rate,
        nfts!inner(name)
      `)
      .order("week_number", { ascending: false })
      .limit(50)

    if (distError) throw distError

    let equalCount = 0
    let randomCount = 0
    let zeroCount = 0

    distributionData.forEach((record) => {
      const rates = [
        record.monday_rate,
        record.tuesday_rate,
        record.wednesday_rate,
        record.thursday_rate,
        record.friday_rate,
      ]

      // 均等配分かチェック
      const isEqual = rates.every((rate) => Math.abs(rate - rates[0]) < 0.01)
      if (isEqual) {
        equalCount++
      } else {
        randomCount++
      }

      // 0%の日があるかチェック
      if (rates.some((rate) => rate === 0)) {
        zeroCount++
      }
    })

    console.log(`最新50件の分析結果:`)
    console.log(`- 均等配分: ${equalCount}件 (${((equalCount / distributionData.length) * 100).toFixed(1)}%)`)
    console.log(`- ランダム配分: ${randomCount}件 (${((randomCount / distributionData.length) * 100).toFixed(1)}%)`)
    console.log(`- 0%の日を含む: ${zeroCount}件 (${((zeroCount / distributionData.length) * 100).toFixed(1)}%)`)
    console.log("")

    // 5. 0%の日の例を表示
    console.log("🔍 0%の日の設定例")
    const zeroExamples = distributionData
      .filter((record) => {
        const rates = [
          record.monday_rate,
          record.tuesday_rate,
          record.wednesday_rate,
          record.thursday_rate,
          record.friday_rate,
        ]
        return rates.some((rate) => rate === 0)
      })
      .slice(0, 5)

    zeroExamples.forEach((record) => {
      const nftName = record.nfts.name
      console.log(`第${record.week_number}週 ${nftName} (週利${record.weekly_rate}%):`)
      console.log(
        `  月${record.monday_rate}% 火${record.tuesday_rate}% 水${record.wednesday_rate}% 木${record.thursday_rate}% 金${record.friday_rate}%`,
      )
    })
    console.log("")

    // 6. NFTグループ分類の確認
    console.log("🏷️ NFTグループ分類確認")
    const { data: nftGroups, error: groupError } = await supabase
      .from("nfts")
      .select(`
        name,
        price,
        daily_rate_limit,
        is_special,
        daily_rate_groups(group_name, daily_rate_limit)
      `)
      .order("price")

    if (groupError) throw groupError

    const groupSummary = {}
    nftGroups.forEach((nft) => {
      const groupName = nft.daily_rate_groups?.group_name || "未分類"
      if (!groupSummary[groupName]) {
        groupSummary[groupName] = []
      }
      groupSummary[groupName].push(nft.name)
    })

    Object.keys(groupSummary).forEach((groupName) => {
      console.log(`${groupName}: ${groupSummary[groupName].length}個`)
      console.log(
        `  ${groupSummary[groupName].slice(0, 3).join(", ")}${groupSummary[groupName].length > 3 ? "..." : ""}`,
      )
    })

    console.log("\n✅ 週利システム完全分析完了!")
  } catch (error) {
    console.error("❌ 分析エラー:", error.message)
  }
}

// 分析実行
analyzeCompleteHistory()
