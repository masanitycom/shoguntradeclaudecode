"use client"

import { useState, useEffect } from "react"
import { Card, CardContent } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { Loader2, LogOut, Users, Coins, FileText, TrendingUp, Settings, BarChart } from "lucide-react"
import { createClient } from "@/lib/supabase/supabaseBrowserClient"
import { useRouter } from "next/navigation"

interface AdminStats {
  total_users: number
  active_nfts: number
  pending_applications: number
  total_rewards: number
}

export default function AdminPage() {
  const [loading, setLoading] = useState(true)
  const [stats, setStats] = useState<AdminStats | null>(null)
  const [user, setUser] = useState<any>(null)
  const router = useRouter()
  const supabase = createClient()

  useEffect(() => {
    checkAuth()
  }, [])

  const checkAuth = async () => {
    try {
      const {
        data: { user: authUser },
      } = await supabase.auth.getUser()

      if (!authUser) {
        router.push("/login")
        return
      }

      const { data: userData } = await supabase.from("users").select("is_admin").eq("id", authUser.id).single()

      if (!userData?.is_admin) {
        router.push("/dashboard")
        return
      }

      setUser(authUser)
      await loadStats()
    } catch (error) {
      console.error("認証エラー:", error)
      router.push("/login")
    } finally {
      setLoading(false)
    }
  }

  const loadStats = async () => {
    try {
      // 新しい統計関数を使用
      const { data: statsData, error } = await supabase.rpc("get_admin_dashboard_stats")

      if (error) {
        console.error("統計データエラー:", error)
        // フォールバック: 個別クエリで取得
        const [usersResult, nftsResult, applicationsResult, rewardsResult] = await Promise.all([
          supabase.from("users").select("id", { count: "exact" }),
          supabase.from("user_nfts").select("id", { count: "exact" }).eq("is_active", true),
          supabase.from("nft_purchase_applications").select("id", { count: "exact" }).eq("status", "pending"),
          supabase.from("daily_rewards").select("reward_amount").eq("is_claimed", false),
        ])

        const totalRewards = rewardsResult.data?.reduce((sum, reward) => sum + Number(reward.reward_amount), 0) || 0

        setStats({
          total_users: usersResult.count || 0,
          active_nfts: nftsResult.count || 0,
          pending_applications: applicationsResult.count || 0,
          total_rewards: totalRewards,
        })
      } else if (statsData && statsData.length > 0) {
        const stat = statsData[0]
        setStats({
          total_users: stat.total_users || 0,
          active_nfts: stat.active_nfts || 0,
          pending_applications: stat.pending_applications || 0,
          total_rewards: Number(stat.total_rewards) || 0,
        })
      }
    } catch (error) {
      console.error("統計データ読み込みエラー:", error)
      // エラー時はゼロで初期化
      setStats({
        total_users: 0,
        active_nfts: 0,
        pending_applications: 0,
        total_rewards: 0,
      })
    }
  }

  const handleLogout = async () => {
    await supabase.auth.signOut()
    router.push("/login")
  }

  const handleRefreshStats = async () => {
    setLoading(true)
    await loadStats()
    setLoading(false)
  }

  if (loading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-red-900 via-black to-red-900 flex items-center justify-center">
        <Loader2 className="h-8 w-8 animate-spin text-white" />
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-red-900 via-black to-red-900">
      {/* ヘッダー */}
      <header className="bg-gray-900/80 border-b border-red-800 px-6 py-4">
        <div className="max-w-7xl mx-auto flex items-center justify-between">
          <div className="flex items-center space-x-4">
            <h1 className="text-2xl font-bold text-white">SHOGUN TRADE</h1>
            <Badge className="bg-red-600 text-white">管理者</Badge>
          </div>
          <div className="flex items-center space-x-4">
            <Button
              onClick={handleRefreshStats}
              variant="outline"
              size="sm"
              className="border-blue-600 text-blue-400 hover:bg-blue-600 hover:text-white bg-gray-800"
            >
              統計更新
            </Button>
            <span className="text-gray-400">{user?.email}</span>
            <Button
              onClick={handleLogout}
              variant="outline"
              size="sm"
              className="border-red-600 text-red-400 hover:bg-red-600 hover:text-white bg-gray-800"
            >
              <LogOut className="h-4 w-4 mr-2" />
              ログアウト
            </Button>
          </div>
        </div>
      </header>

      <main className="max-w-7xl mx-auto p-6">
        {/* 統計情報 */}
        {stats && (
          <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-8">
            <Card className="bg-gray-900/80 border-red-800">
              <CardContent className="p-4">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-gray-400 text-sm">総ユーザー数</p>
                    <p className="text-2xl font-bold text-white">{stats.total_users}</p>
                  </div>
                  <Users className="h-8 w-8 text-blue-400" />
                </div>
              </CardContent>
            </Card>
            <Card className="bg-gray-900/80 border-red-800">
              <CardContent className="p-4">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-gray-400 text-sm">アクティブNFT</p>
                    <p className="text-2xl font-bold text-white">{stats.active_nfts}</p>
                  </div>
                  <Coins className="h-8 w-8 text-green-400" />
                </div>
              </CardContent>
            </Card>
            <Card className="bg-gray-900/80 border-red-800">
              <CardContent className="p-4">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-gray-400 text-sm">保留中申請</p>
                    <p className="text-2xl font-bold text-white">{stats.pending_applications}</p>
                  </div>
                  <FileText className="h-8 w-8 text-yellow-400" />
                </div>
              </CardContent>
            </Card>
            <Card className="bg-gray-900/80 border-red-800">
              <CardContent className="p-4">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-gray-400 text-sm">総報酬額</p>
                    <p className="text-2xl font-bold text-white">${stats.total_rewards.toLocaleString()}</p>
                    {stats.total_rewards === 0 && <p className="text-xs text-green-400 mt-1">✓ クリア済み</p>}
                  </div>
                  <TrendingUp className="h-8 w-8 text-purple-400" />
                </div>
              </CardContent>
            </Card>
          </div>
        )}

        {/* システム状態表示 */}
        <Card className="bg-gray-900/80 border-red-800 mb-8">
          <CardContent className="p-6">
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-white font-semibold text-lg">システム状態</h3>
              <Badge className="bg-green-600 text-white">手動設定モード</Badge>
            </div>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4 text-sm">
              <div>
                <p className="text-gray-400">週利データ</p>
                <p className="text-white">完全クリア済み</p>
              </div>
              <div>
                <p className="text-gray-400">報酬データ</p>
                <p className="text-white">完全クリア済み</p>
              </div>
              <div>
                <p className="text-gray-400">設定モード</p>
                <p className="text-white">手動設定のみ</p>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* 管理機能 */}
        <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
          <Card className="bg-gray-900/80 border-red-800">
            <CardContent className="p-6">
              <div className="flex items-center space-x-4 mb-4">
                <Users className="h-8 w-8 text-blue-400" />
                <div>
                  <h3 className="text-white font-semibold text-lg">ユーザー管理</h3>
                  <p className="text-gray-400 text-sm">ユーザー情報の確認・編集・NFT付与</p>
                </div>
              </div>
              <Button
                onClick={() => router.push("/admin/users")}
                className="w-full bg-blue-600 hover:bg-blue-700 text-white"
              >
                管理画面へ
              </Button>
            </CardContent>
          </Card>

          <Card className="bg-gray-900/80 border-red-800">
            <CardContent className="p-6">
              <div className="flex items-center space-x-4 mb-4">
                <Coins className="h-8 w-8 text-green-400" />
                <div>
                  <h3 className="text-white font-semibold text-lg">NFT管理</h3>
                  <p className="text-gray-400 text-sm">NFT作成・編集・価格設定</p>
                </div>
              </div>
              <Button
                onClick={() => router.push("/admin/nfts")}
                className="w-full bg-green-600 hover:bg-green-700 text-white"
              >
                管理画面へ
              </Button>
            </CardContent>
          </Card>

          <Card className="bg-gray-900/80 border-red-800">
            <CardContent className="p-6">
              <div className="flex items-center space-x-4 mb-4">
                <FileText className="h-8 w-8 text-yellow-400" />
                <div>
                  <h3 className="text-white font-semibold text-lg">申請管理</h3>
                  <p className="text-gray-400 text-sm">NFT購入申請・報酬申請の承認</p>
                </div>
              </div>
              <Button
                onClick={() => router.push("/admin/applications")}
                className="w-full bg-yellow-600 hover:bg-yellow-700 text-white"
              >
                管理画面へ
              </Button>
            </CardContent>
          </Card>

          <Card className="bg-gray-900/80 border-red-800">
            <CardContent className="p-6">
              <div className="flex items-center space-x-4 mb-4">
                <TrendingUp className="h-8 w-8 text-purple-400" />
                <div>
                  <h3 className="text-white font-semibold text-lg">週利管理</h3>
                  <p className="text-gray-400 text-sm">NFT別週利設定・日利計算・報酬分配</p>
                </div>
              </div>
              <Button
                onClick={() => router.push("/admin/weekly-rates")}
                className="w-full bg-purple-600 hover:bg-purple-700 text-white"
              >
                管理画面へ
              </Button>
            </CardContent>
          </Card>

          <Card className="bg-gray-900/80 border-red-800">
            <CardContent className="p-6">
              <div className="flex items-center space-x-4 mb-4">
                <Settings className="h-8 w-8 text-red-400" />
                <div>
                  <h3 className="text-white font-semibold text-lg">タスク管理</h3>
                  <p className="text-gray-400 text-sm">エアドロップタスクの作成・編集</p>
                </div>
              </div>
              <Button
                onClick={() => router.push("/admin/tasks")}
                className="w-full bg-red-600 hover:bg-red-700 text-white"
              >
                管理画面へ
              </Button>
            </CardContent>
          </Card>

          <Card className="bg-gray-900/80 border-red-800">
            <CardContent className="p-6">
              <div className="flex items-center space-x-4 mb-4">
                <BarChart className="h-8 w-8 text-indigo-400" />
                <div>
                  <h3 className="text-white font-semibold text-lg">分析・レポート</h3>
                  <p className="text-gray-400 text-sm">システム分析・レポート生成</p>
                </div>
              </div>
              <Button
                onClick={() => router.push("/admin/analytics")}
                className="w-full bg-indigo-600 hover:bg-indigo-700 text-white"
              >
                管理画面へ
              </Button>
            </CardContent>
          </Card>
        </div>
      </main>
    </div>
  )
}
