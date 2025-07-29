// 週利システムの機能確認スクリプト

console.log("🔍 週利システム機能確認開始...")

// Supabaseクライアントの設定
const { createClient } = require("@supabase/supabase-js")

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY

if (!supabaseUrl || !supabaseKey) {
  console.error("❌ Supabase環境変数が設定されていません")
  process.exit(1)
}

const supabase = createClient(supabaseUrl, supabaseKey)

async function verifyWeeklyRatesSystem() {
  try {
    console.log("\n📊 1. 日利上限グループの確認...")

    const { data: groups, error: groupsError } = await supabase
      .from("daily_rate_groups")
      .select(`
        *,
        nfts(id, name)
      `)
      .order("daily_rate_limit")

    if (groupsError) {
      console.error("❌ グループ取得エラー:", groupsError)
      return
    }

    console.log("✅ 日利上限グループ:")
    groups.forEach((group) => {
      const nftCount = group.nfts ? group.nfts.length : 0
      console.log(`  - ${group.group_name}: ${(group.daily_rate_limit * 100).toFixed(1)}% (NFT数: ${nftCount}個)`)
    })

    console.log("\n📈 2. 過去の週利履歴確認...")

    const { data: historyStats, error: historyError } = await supabase
      .from("nft_weekly_rates")
      .select("week_number, nft_id")

    if (historyError) {
      console.error("❌ 履歴取得エラー:", historyError)
      return
    }

    const totalRecords = historyStats.length
    const uniqueWeeks = [...new Set(historyStats.map((h) => h.week_number))].length
    const uniqueNFTs = [...new Set(historyStats.map((h) => h.nft_id))].length

    console.log("✅ 過去の週利履歴:")
    console.log(`  - 総レコード数: ${totalRecords}件`)
    console.log(`  - 設定済み週数: ${uniqueWeeks}週`)
    console.log(`  - 対象NFT数: ${uniqueNFTs}個`)

    console.log("\n⚙️ 3. 現在の週利設定確認...")

    const { data: currentRates, error: currentError } = await supabase
      .from("group_weekly_rates")
      .select(`
        *,
        daily_rate_groups(group_name)
      `)
      .order("week_number", { ascending: false })
      .limit(10)

    if (currentError) {
      console.error("❌ 現在設定取得エラー:", currentError)
      return
    }

    if (currentRates.length === 0) {
      console.log("⚠️ 現在の週利設定がありません")
    } else {
      console.log("✅ 最新の週利設定:")
      currentRates.forEach((rate) => {
        console.log(`  - 第${rate.week_number}週 ${rate.daily_rate_groups.group_name}: ${rate.weekly_rate}%`)
      })
    }

    console.log("\n🎯 4. NFTグループ分類確認...")

    const { data: nftClassification, error: nftError } = await supabase
      .from("nfts")
      .select(`
        name,
        daily_rate_limit,
        group_id,
        daily_rate_groups(group_name)
      `)
      .order("daily_rate_limit")

    if (nftError) {
      console.error("❌ NFT分類取得エラー:", nftError)
      return
    }

    const classified = nftClassification.filter((nft) => nft.group_id)
    const unclassified = nftClassification.filter((nft) => !nft.group_id)

    console.log("✅ NFTグループ分類:")
    console.log(`  - 分類済み: ${classified.length}個`)
    console.log(`  - 未分類: ${unclassified.length}個`)

    if (unclassified.length > 0) {
      console.log("⚠️ 未分類NFT:")
      unclassified.forEach((nft) => {
        console.log(`  - ${nft.name}: ${(nft.daily_rate_limit * 100).toFixed(1)}%`)
      })
    }

    console.log("\n💰 5. 最新の日利報酬確認...")

    const { data: recentRewards, error: rewardsError } = await supabase
      .from("daily_rewards")
      .select("reward_date, reward_amount")
      .gte("reward_date", new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString().split("T")[0])
      .order("reward_date", { ascending: false })

    if (rewardsError) {
      console.error("❌ 報酬取得エラー:", rewardsError)
      return
    }

    const totalRewards = recentRewards.reduce((sum, r) => sum + Number.parseFloat(r.reward_amount), 0)
    const uniqueDates = [...new Set(recentRewards.map((r) => r.reward_date))].length

    console.log("✅ 最近7日間の日利報酬:")
    console.log(`  - 総報酬額: $${totalRewards.toLocaleString()}`)
    console.log(`  - 報酬発生日数: ${uniqueDates}日`)
    console.log(`  - 総報酬件数: ${recentRewards.length}件`)

    console.log("\n🎉 週利システム確認完了！")
    console.log("📋 システム状況サマリー:")
    console.log(`  ✅ 日利上限グループ: ${groups.length}個作成済み`)
    console.log(`  ✅ 過去の週利履歴: ${totalRecords}件保持`)
    console.log(`  ✅ NFT分類: ${classified.length}/${nftClassification.length}個完了`)
    console.log(`  ✅ 最新報酬: $${totalRewards.toLocaleString()} (7日間)`)
  } catch (error) {
    console.error("❌ 確認処理エラー:", error)
  }
}

// 実行
verifyWeeklyRatesSystem()
