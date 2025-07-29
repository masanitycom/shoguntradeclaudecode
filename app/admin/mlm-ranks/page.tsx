"use client"

import { useEffect, useState } from "react"
import { useRouter } from "next/navigation"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { Crown, Users, TrendingUp, RefreshCw, ArrowLeft } from "lucide-react"
import { createClient } from "@/lib/supabase/supabaseBrowserClient"
import { useToast } from "@/hooks/use-toast"

interface MLMRank {
  id: number
  rank_level: number
  rank_name: string
  required_nft_value: number
  max_organization_volume: number | null
  other_lines_volume: number | null
  bonus_percentage: number
}

interface UserRankData {
  user_id: string
  user_name: string
  user_id_display: string
  rank_level: number
  rank_name: string
  organization_volume: number
  max_line_volume: number
  other_lines_volume: number
  qualified_date: string
}

export default function MLMRanksPage() {
  const [ranks, setRanks] = useState<MLMRank[]>([])
  const [userRanks, setUserRanks] = useState<UserRankData[]>([])
  const [loading, setLoading] = useState(true)
  const [updating, setUpdating] = useState(false)
  const [stats, setStats] = useState({
    totalUsers: 0,
    rankedUsers: 0,
    totalVolume: 0,
  })
  const router = useRouter()
  const supabase = createClient()
  const { toast } = useToast()

  useEffect(() => {
    checkAdminAuth()
    loadData()
  }, [])

  const checkAdminAuth = async () => {
    try {
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
    } catch (error) {
      console.error("管理者認証エラー:", error)
      router.push("/login")
    }
  }

  const loadData = async () => {
    try {
      setLoading(true)

      // MLMランク定義を取得
      const { data: ranksData } = await supabase.from("mlm_ranks").select("*").order("rank_level")

      if (ranksData) {
        setRanks(ranksData)
      }

      // 現在のユーザーランクを取得
      const { data: userRanksData } = await supabase
        .from("user_rank_history")
        .select(`
          user_id,
          rank_level,
          organization_volume,
          max_line_volume,
          other_lines_volume,
          qualified_date,
          users!inner(name, user_id),
          mlm_ranks!inner(rank_name)
        `)
        .eq("is_current", true)
        .order("rank_level", { ascending: false })

      if (userRanksData) {
        const formattedUserRanks = userRanksData.map((item: any) => ({
          user_id: item.user_id,
          user_name: item.users.name,
          user_id_display: item.users.user_id,
          rank_level: item.rank_level,
          rank_name: item.mlm_ranks.rank_name,
          organization_volume: item.organization_volume,
          max_line_volume: item.max_line_volume,
          other_lines_volume: item.other_lines_volume,
          qualified_date: item.qualified_date,
        }))
        setUserRanks(formattedUserRanks)
      }

      // 統計データを計算
      const totalUsers = userRanksData?.length || 0
      const rankedUsers = userRanksData?.filter((u: any) => u.rank_level > 0).length || 0
      const totalVolume = userRanksData?.reduce((sum: number, u: any) => sum + (u.organization_volume || 0), 0) || 0

      setStats({
        totalUsers,
        rankedUsers,
        totalVolume,
      })
    } catch (error) {
      console.error("データ読み込みエラー:", error)
      toast({
        title: "エラー",
        description: "データの読み込みに失敗しました",
        variant: "destructive",
      })
    } finally {
      setLoading(false)
    }
  }

  const updateAllRanks = async () => {
    try {
      setUpdating(true)

      const { data, error } = await supabase.rpc("update_all_user_ranks")

      if (error) {
        throw error
      }

      toast({
        title: "ランク更新完了",
        description: `${data[0]?.updated_users || 0}名のユーザーを更新しました（${data[0]?.rank_changes || 0}名のランクが変更されました）`,
      })

      // データを再読み込み
      await loadData()
    } catch (error) {
      console.error("ランク更新エラー:", error)
      toast({
        title: "エラー",
        description: "ランクの更新に失敗しました",
        variant: "destructive",
      })
    } finally {
      setUpdating(false)
    }
  }

  const getRankColor = (rankLevel: number) => {
    const colors = [
      "bg-gray-500", // なし
      "bg-green-500", // 足軽
      "bg-blue-500", // 武将
      "bg-purple-500", // 代官
      "bg-orange-500", // 奉行
      "bg-red-500", // 老中
      "bg-pink-500", // 大老
      "bg-yellow-500", // 大名
      "bg-gradient-to-r from-yellow-400 to-red-500", // 将軍
    ]
    return colors[rankLevel] || "bg-gray-500"
  }

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-900 flex items-center justify-center">
        <div className="text-white">読み込み中...</div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gray-900">
      {/* ヘッダー */}
      <header className="bg-gray-800 border-b border-red-800 px-6 py-4">
        <div className="max-w-7xl mx-auto flex justify-between items-center">
          <div className="flex items-center space-x-3">
            <Button onClick={() => router.push("/admin")} variant="ghost" className="text-gray-400 hover:text-white">
              <ArrowLeft className="h-4 w-4 mr-2" />
              戻る
            </Button>
            <Crown className="h-8 w-8 text-indigo-500" />
            <div>
              <h1 className="text-2xl font-bold text-white">MLMランク管理</h1>
              <p className="text-gray-400 text-sm">ユーザーランクの管理と更新</p>
            </div>
          </div>
          <Button onClick={updateAllRanks} disabled={updating} className="bg-indigo-600 hover:bg-indigo-700 text-white">
            {updating ? (
              <>
                <RefreshCw className="h-4 w-4 mr-2 animate-spin" />
                更新中...
              </>
            ) : (
              <>
                <RefreshCw className="h-4 w-4 mr-2" />
                全ランク更新
              </>
            )}
          </Button>
        </div>
      </header>

      <main className="max-w-7xl mx-auto p-6">
        {/* 統計カード */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
          <Card className="bg-gray-800 border-gray-700">
            <CardContent className="p-6">
              <div className="flex items-center space-x-3">
                <Users className="h-8 w-8 text-blue-400" />
                <div>
                  <p className="text-gray-400 text-sm">総ユーザー数</p>
                  <p className="text-2xl font-bold text-white">{stats.totalUsers.toLocaleString()}</p>
                </div>
              </div>
            </CardContent>
          </Card>

          <Card className="bg-gray-800 border-gray-700">
            <CardContent className="p-6">
              <div className="flex items-center space-x-3">
                <Crown className="h-8 w-8 text-indigo-400" />
                <div>
                  <p className="text-gray-400 text-sm">ランク保有者</p>
                  <p className="text-2xl font-bold text-white">{stats.rankedUsers.toLocaleString()}</p>
                </div>
              </div>
            </CardContent>
          </Card>

          <Card className="bg-gray-800 border-gray-700">
            <CardContent className="p-6">
              <div className="flex items-center space-x-3">
                <TrendingUp className="h-8 w-8 text-green-400" />
                <div>
                  <p className="text-gray-400 text-sm">総組織ボリューム</p>
                  <p className="text-2xl font-bold text-white">${stats.totalVolume.toLocaleString()}</p>
                </div>
              </div>
            </CardContent>
          </Card>
        </div>

        {/* ランク定義 */}
        <Card className="bg-gray-800 border-gray-700 mb-8">
          <CardHeader>
            <CardTitle className="text-white">ランク定義</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              {ranks.map((rank) => (
                <div key={rank.id} className="bg-gray-700 rounded-lg p-4 border border-gray-600">
                  <div className="flex items-center space-x-3 mb-3">
                    <Badge className={`${getRankColor(rank.rank_level)} text-white`}>Lv.{rank.rank_level}</Badge>
                    <h3 className="text-white font-medium">{rank.rank_name}</h3>
                  </div>
                  <div className="space-y-2 text-sm">
                    <div className="text-gray-300">必要NFT: ${rank.required_nft_value.toLocaleString()}</div>
                    {rank.max_organization_volume && (
                      <div className="text-gray-300">最大系列: ${rank.max_organization_volume.toLocaleString()}</div>
                    )}
                    {rank.other_lines_volume && (
                      <div className="text-gray-300">他系列: ${rank.other_lines_volume.toLocaleString()}</div>
                    )}
                    <div className="text-indigo-400 font-medium">分配率: {rank.bonus_percentage}%</div>
                  </div>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>

        {/* ユーザーランク一覧 */}
        <Card className="bg-gray-800 border-gray-700">
          <CardHeader>
            <CardTitle className="text-white">現在のユーザーランク</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="border-b border-gray-700">
                    <th className="text-left py-3 px-4 text-gray-300">ユーザー</th>
                    <th className="text-left py-3 px-4 text-gray-300">ランク</th>
                    <th className="text-right py-3 px-4 text-gray-300">組織ボリューム</th>
                    <th className="text-right py-3 px-4 text-gray-300">最大系列</th>
                    <th className="text-right py-3 px-4 text-gray-300">他系列</th>
                    <th className="text-left py-3 px-4 text-gray-300">認定日</th>
                  </tr>
                </thead>
                <tbody>
                  {userRanks.map((user) => (
                    <tr key={user.user_id} className="border-b border-gray-700 hover:bg-gray-700">
                      <td className="py-3 px-4">
                        <div>
                          <div className="text-white font-medium">{user.user_name}</div>
                          <div className="text-gray-400 text-sm">{user.user_id_display}</div>
                        </div>
                      </td>
                      <td className="py-3 px-4">
                        <Badge className={`${getRankColor(user.rank_level)} text-white`}>{user.rank_name}</Badge>
                      </td>
                      <td className="py-3 px-4 text-right text-white">${user.organization_volume.toLocaleString()}</td>
                      <td className="py-3 px-4 text-right text-white">${user.max_line_volume.toLocaleString()}</td>
                      <td className="py-3 px-4 text-right text-white">${user.other_lines_volume.toLocaleString()}</td>
                      <td className="py-3 px-4 text-gray-300">
                        {new Date(user.qualified_date).toLocaleDateString("ja-JP")}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
              {userRanks.length === 0 && <div className="text-center py-8 text-gray-400">ランク保有者がいません</div>}
            </div>
          </CardContent>
        </Card>
      </main>
    </div>
  )
}
