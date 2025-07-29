import { type NextRequest, NextResponse } from "next/server"
import { createClient } from "@/lib/supabase/supabaseBrowserClient"

export async function GET(request: NextRequest) {
  try {
    const supabase = createClient()

    const {
      data: { user },
      error: authError,
    } = await supabase.auth.getUser()

    if (authError || !user) {
      return NextResponse.json({ error: "認証が必要です" }, { status: 401 })
    }

    // ユーザーのランク情報を取得
    const { data: rankData, error: rankError } = await supabase
      .from("user_rank_history")
      .select("*")
      .eq("user_id", user.id)
      .eq("is_current", true)
      .order("created_at", { ascending: false })
      .limit(1)

    if (rankError) {
      console.error("ランク取得エラー:", rankError)
    }

    // ランクデータがない場合のデフォルト値
    const defaultRank = {
      rank_name: "なし",
      rank_level: 0,
      required_points: 1000,
      achieved_points: 0,
      next_rank_name: "足軽",
      remaining_points: 1000,
    }

    if (!rankData || rankData.length === 0) {
      return NextResponse.json(defaultRank)
    }

    const currentRank = rankData[0]

    // 次のランク名を決定
    const getNextRankName = (currentLevel: number) => {
      const ranks = ["なし", "足軽", "武将", "代官", "奉行", "老中", "大老", "大名", "将軍"]
      return ranks[currentLevel + 1] || "最高ランク"
    }

    // 次のランクに必要なポイントを計算
    const getRequiredPoints = (currentLevel: number) => {
      const requirements = [0, 1000, 3000, 5000, 10000, 50000, 100000, 300000, 600000]
      return requirements[currentLevel + 1] || 0
    }

    const requiredPoints = getRequiredPoints(currentRank.rank_level)
    const achievedPoints = Number(currentRank.organization_volume) || 0
    const remainingPoints = Math.max(0, requiredPoints - achievedPoints)

    return NextResponse.json({
      rank_name: currentRank.rank_name || "なし",
      rank_level: currentRank.rank_level || 0,
      required_points: requiredPoints,
      achieved_points: achievedPoints,
      next_rank_name: getNextRankName(currentRank.rank_level || 0),
      remaining_points: remainingPoints,
    })
  } catch (error) {
    console.error("API エラー:", error)
    return NextResponse.json({ error: "サーバーエラーが発生しました" }, { status: 500 })
  }
}
