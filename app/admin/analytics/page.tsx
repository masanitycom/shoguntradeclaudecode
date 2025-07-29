"use client"

import { useState, useEffect } from "react"
import { useRouter } from "next/navigation"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { ArrowLeft, Users, DollarSign, TrendingUp, Award } from "lucide-react"
import { createClient } from "@/lib/supabase/supabaseBrowserClient"

interface AnalyticsData {
  totalUsers: number
  totalNFTs: number
  totalRewards: number
  pendingApplications: number
  activeRankHolders: number
  weeklyProfit: number
}

export default function AdminAnalyticsPage() {
  const [analytics, setAnalytics] = useState<AnalyticsData>({
    totalUsers: 0,
    totalNFTs: 0,
    totalRewards: 0,
    pendingApplications: 0,
    activeRankHolders: 0,
    weeklyProfit: 0,
  })
  const [loading, setLoading] = useState(true)
  const router = useRouter()
  const supabase = createClient()

  useEffect(() => {
    checkAdminAuth()
  }, [])

  const checkAdminAuth = async () => {
    const {
      data: { user },
    } = await supabase.auth.getUser()
    if (!user) {
      router.push("/login")
      return
    }

    const { data: userData } = await supabase.from("users").select("is_admin").eq("id", user.id).single()

    if (!userData?.is_admin) {
      router.push("/dashboard")
      return
    }

    loadAnalytics()
  }

  const loadAnalytics = async () => {
    try {
      // 総ユーザー数
      const { count: userCount } = await supabase
        .from("users")
        .select("*", { count: "exact", head: true })
        .eq("is_admin", false)

      // 総NFT数
      const { count: nftCount } = await supabase
        .from("user_nfts")
        .select("*", { count: "exact", head: true })
        .eq("is_active", true)

      // 総報酬額
      const { data: rewardData } = await supabase.from("daily_rewards").select("reward_amount")

      const totalRewards = rewardData?.reduce((sum, reward) => sum + Number(reward.reward_amount), 0) || 0

      // 承認待ち申請数
      const { count: pendingCount } = await supabase
        .from("reward_applications")
        .select("*", { count: "exact", head: true })
        .eq("status", "pending")

      // アクティブランク保有者数
      const { count: rankCount } = await supabase
        .from("user_rank_history")
        .select("*", { count: "exact", head: true })
        .gt("rank_level", 0)

      // 週間利益
      const { data: profitData } = await supabase
        .from("weekly_profits")
        .select("total_profit")
        .order("week_start_date", { ascending: false })
        .limit(1)

      const weeklyProfit = profitData?.[0]?.total_profit || 0

      setAnalytics({
        totalUsers: userCount || 0,
        totalNFTs: nftCount || 0,
        totalRewards,
        pendingApplications: pendingCount || 0,
        activeRankHolders: rankCount || 0,
        weeklyProfit: Number(weeklyProfit),
      })
    } catch (error) {
      console.error("分析データ読み込みエラー:", error)
    } finally {
      setLoading(false)
    }
  }

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-900 flex items-center justify-center">
        <div className="text-white text-xl">読み込み中...</div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gray-900">
      {/* ヘッダー */}
      <header className="bg-gray-800 border-b border-red-800 px-6 py-4">
        <div className="max-w-7xl mx-auto flex justify-between items-center">
          <div className="flex items-center space-x-4">
            <Button onClick={() => router.push("/admin")} variant="ghost" className="text-white hover:bg-white/10">
              <ArrowLeft className="mr-2 h-4 w-4" />
              管理画面に戻る
            </Button>
            <div>
              <h1 className="text-2xl font-bold text-white">分析・統計</h1>
              <p className="text-gray-400 text-sm">システム全体の統計情報</p>
            </div>
          </div>
        </div>
      </header>

      <main className="max-w-7xl mx-auto p-6">
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {/* 総ユーザー数 */}
          <Card className="bg-gray-800 border-gray-700">
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium text-gray-300">総ユーザー数</CardTitle>
              <Users className="h-4 w-4 text-blue-400" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold text-white">{analytics.totalUsers.toLocaleString()}</div>
              <p className="text-xs text-gray-400">登録済みユーザー</p>
            </CardContent>
          </Card>

          {/* 総NFT数 */}
          <Card className="bg-gray-800 border-gray-700">
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium text-gray-300">アクティブNFT数</CardTitle>
              <Award className="h-4 w-4 text-green-400" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold text-white">{analytics.totalNFTs.toLocaleString()}</div>
              <p className="text-xs text-gray-400">運用中のNFT</p>
            </CardContent>
          </Card>

          {/* 総報酬額 */}
          <Card className="bg-gray-800 border-gray-700">
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium text-gray-300">総報酬額</CardTitle>
              <DollarSign className="h-4 w-4 text-yellow-400" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold text-white">${analytics.totalRewards.toLocaleString()}</div>
              <p className="text-xs text-gray-400">累計支払い報酬</p>
            </CardContent>
          </Card>

          {/* 承認待ち申請 */}
          <Card className="bg-gray-800 border-gray-700">
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium text-gray-300">承認待ち申請</CardTitle>
              <TrendingUp className="h-4 w-4 text-orange-400" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold text-white">{analytics.pendingApplications.toLocaleString()}</div>
              <p className="text-xs text-gray-400">処理待ちの申請</p>
            </CardContent>
          </Card>

          {/* ランク保有者数 */}
          <Card className="bg-gray-800 border-gray-700">
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium text-gray-300">ランク保有者</CardTitle>
              <Award className="h-4 w-4 text-purple-400" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold text-white">{analytics.activeRankHolders.toLocaleString()}</div>
              <p className="text-xs text-gray-400">MLMランク保有者</p>
            </CardContent>
          </Card>

          {/* 週間利益 */}
          <Card className="bg-gray-800 border-gray-700">
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium text-gray-300">週間利益</CardTitle>
              <DollarSign className="h-4 w-4 text-green-400" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold text-white">${analytics.weeklyProfit.toLocaleString()}</div>
              <p className="text-xs text-gray-400">最新週の利益</p>
            </CardContent>
          </Card>
        </div>

        {/* 追加の分析カード */}
        <div className="mt-8">
          <Card className="bg-gray-800 border-gray-700">
            <CardHeader>
              <CardTitle className="text-white">システム概要</CardTitle>
            </CardHeader>
            <CardContent className="text-gray-300">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <h3 className="font-semibold text-white mb-2">運用状況</h3>
                  <ul className="space-y-1 text-sm">
                    <li>• 総ユーザー: {analytics.totalUsers}名</li>
                    <li>• アクティブNFT: {analytics.totalNFTs}個</li>
                    <li>• ランク保有者: {analytics.activeRankHolders}名</li>
                  </ul>
                </div>
                <div>
                  <h3 className="font-semibold text-white mb-2">財務状況</h3>
                  <ul className="space-y-1 text-sm">
                    <li>• 累計報酬: ${analytics.totalRewards.toLocaleString()}</li>
                    <li>• 週間利益: ${analytics.weeklyProfit.toLocaleString()}</li>
                    <li>• 承認待ち: {analytics.pendingApplications}件</li>
                  </ul>
                </div>
              </div>
            </CardContent>
          </Card>
        </div>
      </main>
    </div>
  )
}
