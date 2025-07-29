// 🚀 外部計算システム - TypeScript版

interface NFTData {
  user_id: string
  user_nft_id: number
  purchase_price: number
  daily_rate_limit: number
  nft_name: string
  group_name: string
}

interface WeeklyRate {
  group_id: string
  group_name: string
  monday_rate: number
  tuesday_rate: number
  wednesday_rate: number
  thursday_rate: number
  friday_rate: number
}

interface CalculationResult {
  user_id: string
  user_nft_id: number
  reward_amount: number
  calculation_date: string
}

export class ExternalCalculator {
  private supabase: any

  constructor(supabaseClient: any) {
    this.supabase = supabaseClient
  }

  // 🚀 メイン計算関数 - PostgreSQLの外で実行
  async calculateDailyRewards(targetDate: Date): Promise<CalculationResult[]> {
    try {
      console.log(`🔄 外部計算開始: ${targetDate.toISOString().split("T")[0]}`)

      // 1. NFTデータを取得
      const { data: nftData, error: nftError } = await this.supabase.from("calculation_data_export").select("*")

      if (nftError) {
        console.error("NFTデータ取得エラー:", nftError)
        throw nftError
      }

      console.log(`📊 NFTデータ取得: ${nftData?.length || 0}件`)

      // 2. 週利データを取得
      const weekStart = this.getWeekStart(targetDate)
      const { data: weeklyRates, error: rateError } = await this.supabase
        .from("group_weekly_rates")
        .select(`
          *,
          daily_rate_groups!inner(group_name)
        `)
        .eq("week_start_date", weekStart.toISOString().split("T")[0])

      if (rateError) {
        console.error("週利データ取得エラー:", rateError)
        throw rateError
      }

      console.log(`📈 週利データ取得: ${weeklyRates?.length || 0}件`)

      // 3. JavaScript/TypeScriptで高速計算
      const results: CalculationResult[] = []
      const dayOfWeek = targetDate.getDay() // 0=日曜, 1=月曜...

      // 平日のみ処理
      if (dayOfWeek === 0 || dayOfWeek === 6) {
        console.log("⏭️ 土日のためスキップ")
        return results
      }

      if (!nftData || nftData.length === 0) {
        console.log("⚠️ NFTデータが見つかりません")
        return results
      }

      for (const nft of nftData) {
        const groupRate = weeklyRates?.find((rate) => rate.daily_rate_groups?.group_name === nft.group_name)

        if (!groupRate) {
          console.log(`⚠️ グループレートが見つかりません: ${nft.group_name}`)
          continue
        }

        // 曜日別レート取得
        const dailyRate = this.getDailyRate(groupRate, dayOfWeek)
        if (dailyRate === 0) continue

        // 報酬計算
        let rewardAmount = nft.purchase_price * dailyRate

        // 上限チェック
        if (rewardAmount > nft.daily_rate_limit) {
          rewardAmount = nft.daily_rate_limit
        }

        if (rewardAmount > 0) {
          results.push({
            user_id: nft.user_id,
            user_nft_id: nft.user_nft_id,
            reward_amount: Math.round(rewardAmount * 100) / 100, // 小数点2桁
            calculation_date: targetDate.toISOString().split("T")[0],
          })
        }
      }

      console.log(`✅ 計算完了: ${results.length}件の報酬`)
      return results
    } catch (error) {
      console.error("❌ 外部計算エラー:", error)
      throw error
    }
  }

  // 🚀 計算結果をデータベースに高速インポート
  async importResults(results: CalculationResult[]): Promise<void> {
    try {
      console.log(`📥 結果インポート開始: ${results.length}件`)

      if (results.length === 0) {
        console.log("⚠️ インポートするデータがありません")
        return
      }

      // daily_rewardsテーブルに直接インサート
      const { error } = await this.supabase.from("daily_rewards").upsert(
        results.map((r) => ({
          user_nft_id: r.user_nft_id,
          reward_amount: r.reward_amount,
          reward_date: r.calculation_date,
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString(),
        })),
        {
          onConflict: "user_nft_id,reward_date",
          ignoreDuplicates: false,
        },
      )

      if (error) {
        console.error("インポートエラー:", error)
        throw error
      }

      console.log("✅ インポート完了")
    } catch (error) {
      console.error("❌ インポートエラー:", error)
      throw error
    }
  }

  // ヘルパー関数群
  private getWeekStart(date: Date): Date {
    const weekStart = new Date(date)
    const dayOfWeek = weekStart.getDay()
    const daysToMonday = dayOfWeek === 0 ? 6 : dayOfWeek - 1
    weekStart.setDate(weekStart.getDate() - daysToMonday)
    return weekStart
  }

  private getDailyRate(weeklyRate: any, dayOfWeek: number): number {
    switch (dayOfWeek) {
      case 1:
        return weeklyRate.monday_rate || 0
      case 2:
        return weeklyRate.tuesday_rate || 0
      case 3:
        return weeklyRate.wednesday_rate || 0
      case 4:
        return weeklyRate.thursday_rate || 0
      case 5:
        return weeklyRate.friday_rate || 0
      default:
        return 0
    }
  }
}

// 🚀 使用例
export async function runDailyCalculation(supabaseClient: any, targetDate?: Date) {
  const calculator = new ExternalCalculator(supabaseClient)
  const date = targetDate || new Date()

  try {
    const results = await calculator.calculateDailyRewards(date)
    await calculator.importResults(results)

    return {
      success: true,
      message: `${results.length}件の報酬を計算・インポートしました`,
      processed_count: results.length,
      total_amount: results.reduce((sum, r) => sum + r.reward_amount, 0),
    }
  } catch (error) {
    console.error("計算エラー:", error)
    return {
      success: false,
      message: `計算エラー: ${error}`,
      processed_count: 0,
      total_amount: 0,
    }
  }
}
