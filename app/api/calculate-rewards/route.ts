// 🚀 Next.js API Route - 外部計算エンドポイント

import { type NextRequest, NextResponse } from "next/server"
import { createClient } from "@/lib/supabase/supabaseBrowserClient"
import { runDailyCalculation } from "@/lib/external-calculator"

export async function POST(request: NextRequest) {
  try {
    const supabase = createClient()

    // 認証チェック
    const {
      data: { user },
      error: authError,
    } = await supabase.auth.getUser()

    if (authError || !user) {
      return NextResponse.json({ error: "認証が必要です" }, { status: 401 })
    }

    // 管理者チェック
    const { data: userData } = await supabase.from("users").select("is_admin").eq("id", user.id).single()

    if (!userData?.is_admin) {
      return NextResponse.json({ error: "管理者権限が必要です" }, { status: 403 })
    }

    // 🚀 外部計算実行
    const body = await request.json()
    const targetDate = body.date ? new Date(body.date) : new Date()

    console.log(`🚀 API経由で日利計算開始: ${targetDate.toISOString()}`)

    const result = await runDailyCalculation(supabase, targetDate)

    return NextResponse.json(result)
  } catch (error) {
    console.error("❌ API計算エラー:", error)
    return NextResponse.json(
      {
        error: "計算処理でエラーが発生しました",
        details: String(error),
      },
      { status: 500 },
    )
  }
}

// GET: 計算状況確認
export async function GET() {
  try {
    const supabase = createClient()

    const { data: stats } = await supabase
      .from("daily_rewards")
      .select("reward_date")
      .order("reward_date", { ascending: false })
      .limit(10)

    return NextResponse.json({
      success: true,
      recent_calculations: stats || [],
      message: "計算履歴を取得しました",
    })
  } catch (error) {
    return NextResponse.json({ error: "履歴取得エラー", details: String(error) }, { status: 500 })
  }
}
