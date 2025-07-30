"use client"

import { useState, useEffect } from "react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { Progress } from "@/components/ui/progress"
import { Loader2, LogOut, Coins, TrendingUp, Users, Gift, ShoppingCart, History, User, FileText } from "lucide-react"
import { createClient } from "@/lib/supabase/supabaseBrowserClient"
import { useRouter } from "next/navigation"

interface UserNFT {
  id: string
  nft_id: string
  current_investment: number
  total_earned: number
  max_earning: number
  is_active: boolean
  purchase_date: string
  operation_start_date: string
  nfts: {
    name: string
    image_url: string
    daily_rate_limit: number
    price: number
  }
}

interface UserProfile {
  name: string
  email: string
  current_rank: string
  total_investment: number
  total_earned: number
  pending_rewards: number
  referral_code: string
  referral_count: number
}

export default function DashboardPage() {
  const [loading, setLoading] = useState(true)
  const [userNFTs, setUserNFTs] = useState<UserNFT[]>([])
  const [profile, setProfile] = useState<UserProfile | null>(null)
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
        console.log("認証失敗: ユーザーが見つかりません")
        router.push("/login")
        return
      }

      console.log(`🔐 認証成功:`, {
        userId: authUser.id,
        email: authUser.email,
        aud: authUser.aud,
        role: authUser.role,
        created_at: authUser.created_at
      })
      setUser(authUser)

      // NFTデータを先に取得してからプロフィールを計算
      const nftData = await loadUserNFTs(authUser.id)
      await loadProfile(authUser.id, nftData)
    } catch (error) {
      console.error("認証エラー:", error)
      router.push("/login")
    } finally {
      setLoading(false)
    }
  }

  const loadUserNFTs = async (userId: string): Promise<UserNFT[]> => {
    try {
      console.log(`NFT取得開始: ユーザーID = ${userId}`)

      const { data, error } = await supabase
        .from("user_nfts")
        .select(
          `
          id,
          nft_id,
          user_id,
          current_investment,
          total_earned,
          max_earning,
          is_active,
          purchase_date,
          operation_start_date,
          nfts!inner(
            name,
            image_url,
            daily_rate_limit,
            price
          )
        `,
        )
        .eq("user_id", userId)
        .eq("is_active", true)

      if (error) {
        console.error("NFT取得エラー:", error)
        throw error
      }

      console.log(`NFT取得結果:`, {
        count: data?.length || 0,
        userIds: data?.map(nft => nft.user_id) || [],
        nftIds: data?.map(nft => nft.id) || [],
        rawData: data,
      })
      
      // user_idが一致しているかチェック
      const mismatchedData = data?.filter(nft => nft.user_id !== userId) || []
      if (mismatchedData.length > 0) {
        console.error(`🚨 SECURITY ALERT: 異なるユーザーのNFTデータが取得されました!`, {
          expectedUserId: userId,
          mismatchedData: mismatchedData
        })
      }

      // データ型変換とログ出力
      const processedNFTs = (data || []).map((nft) => {
        const processedNFT = {
          ...nft,
          current_investment: Number(nft.current_investment) || 0,
          total_earned: Number(nft.total_earned) || 0,
          max_earning: Number(nft.max_earning) || 0,
          nfts: {
            ...nft.nfts,
            price: Number(nft.nfts.price) || 0,
            daily_rate_limit: Number(nft.nfts.daily_rate_limit) || 0,
          },
        }

        console.log(`NFT処理結果: ${processedNFT.nfts.name}`)
        console.log(`  - 元の価格: "${nft.nfts.price}" (型: ${typeof nft.nfts.price})`)
        console.log(`  - 変換後価格: ${processedNFT.nfts.price} (型: ${typeof processedNFT.nfts.price})`)
        console.log(`  - 投資額: ${processedNFT.current_investment}`)
        console.log(`  - 獲得額: ${processedNFT.total_earned}`)

        return processedNFT
      })

      setUserNFTs(processedNFTs)
      return processedNFTs
    } catch (error) {
      console.error("NFT読み込みエラー:", error)
      setUserNFTs([])
      return []
    }
  }

  const loadProfile = async (userId: string, nftData: UserNFT[]) => {
    try {
      // 新しい統計関数を使用
      const { data: statsData, error: statsError } = await supabase.rpc("get_user_dashboard_stats", {
        p_user_id: userId,
      })

      let totalInvestment = 0
      let totalEarned = 0
      let pendingRewards = 0
      let currentRank = "なし"

      if (statsError || !statsData || statsData.length === 0) {
        console.log("統計関数エラー、フォールバック処理:", statsError)

        // フォールバック: 手動計算
        totalInvestment = nftData.reduce((sum, nft) => sum + nft.nfts.price, 0)
        totalEarned = nftData.reduce((sum, nft) => sum + nft.total_earned, 0)

        // 保留中報酬を個別取得
        const { data: pendingData } = await supabase
          .from("daily_rewards")
          .select("reward_amount")
          .eq("user_id", userId)
          .eq("is_claimed", false)

        pendingRewards = pendingData?.reduce((sum, reward) => sum + Number(reward.reward_amount), 0) || 0

        // 簡易ランク判定
        if (totalInvestment >= 1000) {
          currentRank = "足軽"
        }
      } else {
        const stats = statsData[0]
        totalInvestment = Number(stats.total_investment) || 0
        totalEarned = Number(stats.total_earned) || 0
        pendingRewards = Number(stats.pending_rewards) || 0
        currentRank = stats.current_rank || "なし"
      }

      // ユーザー基本情報を取得
      console.log(`ユーザー基本情報取得: userId = ${userId}`)
      const { data: userData, error: userError } = await supabase.from("users").select("*").eq("id", userId).single()
      
      if (userError) {
        console.error("ユーザー基本情報取得エラー:", userError)
      }
      
      console.log(`取得されたユーザーデータ:`, {
        id: userData?.id,
        name: userData?.name,
        email: userData?.email,
        user_id: userData?.user_id
      })

      console.log(`最終計算結果:`)
      console.log(`  - NFT数: ${nftData.length}`)
      console.log(`  - 総投資額: $${totalInvestment}`)
      console.log(`  - 総獲得額: $${totalEarned}`)
      console.log(`  - 保留中報酬: $${pendingRewards}`)
      console.log(`  - MLMランク: ${currentRank}`)

      setProfile({
        name: userData?.name || "未設定",
        email: userData?.email || "",
        current_rank: currentRank,
        total_investment: totalInvestment,
        total_earned: totalEarned,
        pending_rewards: pendingRewards,
        referral_code: userData?.referral_code || "",
        referral_count: userData?.referral_count || 0,
      })
    } catch (error) {
      console.error("プロフィール読み込みエラー:", error)
    }
  }

  const calculateProgress = (nft: UserNFT) => {
    if (nft.max_earning === 0) return 0
    return Math.min((nft.total_earned / nft.max_earning) * 100, 100)
  }

  const getOperationStatus = (nft: UserNFT) => {
    if (!nft.operation_start_date) {
      return { status: '設定中', color: 'bg-gray-500', description: '運用開始日を設定中です' }
    }
    
    const today = new Date()
    const startDate = new Date(nft.operation_start_date)
    const purchaseDate = new Date(nft.purchase_date)
    
    if (startDate > today) {
      const daysUntilStart = Math.ceil((startDate.getTime() - today.getTime()) / (1000 * 60 * 60 * 24))
      return { 
        status: '待機中', 
        color: 'bg-yellow-500', 
        description: `${startDate.toLocaleDateString('ja-JP')}から運用開始（あと${daysUntilStart}日）`
      }
    } else {
      return { 
        status: '運用中', 
        color: 'bg-green-500', 
        description: `${startDate.toLocaleDateString('ja-JP')}から運用開始済み`
      }
    }
  }

  const handleLogout = async () => {
    await supabase.auth.signOut()
    router.push("/login")
  }

  const handleRefreshData = async () => {
    if (!user) return
    setLoading(true)
    const nftData = await loadUserNFTs(user.id)
    await loadProfile(user.id, nftData)
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
            <Badge className="bg-blue-600 text-white">ユーザー</Badge>
          </div>
          <div className="flex items-center space-x-4">
            <Button
              onClick={handleRefreshData}
              variant="outline"
              size="sm"
              className="border-blue-600 text-blue-400 hover:bg-blue-600 hover:text-white bg-gray-800"
            >
              データ更新
            </Button>
            <span className="text-gray-400">{profile?.name || user?.email}</span>
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
        {/* システム状態表示 */}
        <Card className="bg-gray-900/80 border-red-800 mb-6">
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div className="flex items-center space-x-4">
                <Badge className="bg-green-600 text-white">システム正常</Badge>
                <span className="text-gray-400 text-sm">データクリア済み・手動設定モード</span>
              </div>
              <Button
                onClick={handleRefreshData}
                variant="outline"
                size="sm"
                className="border-green-600 text-green-400 hover:bg-green-600 hover:text-white bg-gray-800"
              >
                最新データ取得
              </Button>
            </div>
          </CardContent>
        </Card>

        {/* プロフィール情報 */}
        {profile && (
          <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-8">
            <Card className="bg-gray-900/80 border-red-800">
              <CardContent className="p-4">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-gray-400 text-sm">総投資額</p>
                    <p className="text-2xl font-bold text-white">${profile.total_investment.toLocaleString()}</p>
                  </div>
                  <Coins className="h-8 w-8 text-yellow-400" />
                </div>
              </CardContent>
            </Card>
            <Card className="bg-gray-900/80 border-red-800">
              <CardContent className="p-4">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-gray-400 text-sm">総獲得額</p>
                    <p className="text-2xl font-bold text-white">${profile.total_earned.toFixed(2)}</p>
                    {profile.total_earned === 0 && <p className="text-xs text-green-400 mt-1">✓ クリア済み</p>}
                  </div>
                  <TrendingUp className="h-8 w-8 text-green-400" />
                </div>
              </CardContent>
            </Card>
            <Card className="bg-gray-900/80 border-red-800">
              <CardContent className="p-4">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-gray-400 text-sm">保留中報酬</p>
                    <p className="text-2xl font-bold text-white">${profile.pending_rewards.toFixed(2)}</p>
                    {profile.pending_rewards === 0 && <p className="text-xs text-green-400 mt-1">✓ クリア済み</p>}
                  </div>
                  <Gift className="h-8 w-8 text-purple-400" />
                </div>
              </CardContent>
            </Card>
            <Card className="bg-gray-900/80 border-red-800">
              <CardContent className="p-4">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-gray-400 text-sm">MLMランク</p>
                    <p className="text-2xl font-bold text-white">{profile.current_rank}</p>
                  </div>
                  <Users className="h-8 w-8 text-blue-400" />
                </div>
              </CardContent>
            </Card>
          </div>
        )}

        {/* 保有NFT */}
        <Card className="bg-gray-900/80 border-red-800 mb-8">
          <CardHeader>
            <CardTitle className="text-white">保有NFT ({userNFTs.length}個)</CardTitle>
          </CardHeader>
          <CardContent>
            {userNFTs.length === 0 ? (
              <div className="text-center py-8">
                <p className="text-gray-400 mb-4">保有NFTがありません</p>
                <p className="text-gray-500 text-sm">NFTを購入して投資を開始しましょう</p>
              </div>
            ) : (
              <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
                {userNFTs.map((nft) => (
                  <Card key={nft.id} className="bg-gray-800/80 border-gray-700">
                    <CardContent className="p-4">
                      <div className="flex items-center space-x-4 mb-4">
                        <img
                          src={nft.nfts.image_url || "/placeholder.svg?height=60&width=60"}
                          alt={nft.nfts.name}
                          className="w-15 h-15 rounded-lg"
                        />
                        <div>
                          <h3 className="text-white font-semibold">{nft.nfts.name}</h3>
                          <p className="text-gray-400 text-sm">
                            日利上限: {(nft.nfts.daily_rate_limit * 100).toFixed(1)}%
                          </p>
                        </div>
                      </div>
                      <div className="space-y-2">
                        <div className="flex justify-between text-sm">
                          <span className="text-gray-400">投資額</span>
                          <span className="text-white">${nft.nfts.price.toLocaleString()}</span>
                        </div>
                        <div className="flex justify-between text-sm">
                          <span className="text-gray-400">購入日</span>
                          <span className="text-white">{new Date(nft.purchase_date).toLocaleDateString('ja-JP')}</span>
                        </div>
                        <div className="flex justify-between text-sm">
                          <span className="text-gray-400">運用開始日</span>
                          <span className="text-white">
                            {nft.operation_start_date ? new Date(nft.operation_start_date).toLocaleDateString('ja-JP') : '設定中'}
                          </span>
                        </div>
                        <div className="flex justify-between text-sm">
                          <span className="text-gray-400">獲得済み</span>
                          <span className="text-green-400">${nft.total_earned.toFixed(2)}</span>
                        </div>
                        <div className="flex justify-between text-sm">
                          <span className="text-gray-400">進捗</span>
                          <span className="text-white">{calculateProgress(nft).toFixed(1)}%</span>
                        </div>
                        <Progress value={calculateProgress(nft)} className="h-2" />
                        
                        {/* 運用ステータス表示 */}
                        <div className="mt-3 pt-3 border-t border-gray-700">
                          <div className="flex items-center justify-between mb-2">
                            <span className="text-gray-400 text-sm">運用状況</span>
                            <Badge className={`${getOperationStatus(nft).color} text-white text-xs`}>
                              {getOperationStatus(nft).status}
                            </Badge>
                          </div>
                          <p className="text-gray-300 text-xs">
                            {getOperationStatus(nft).description}
                          </p>
                        </div>
                      </div>
                    </CardContent>
                  </Card>
                ))}
              </div>
            )}
          </CardContent>
        </Card>

        {/* アクション */}
        <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
          <Card className="bg-gray-900/80 border-red-800">
            <CardContent className="p-6">
              <div className="flex items-center space-x-4 mb-4">
                <ShoppingCart className="h-8 w-8 text-blue-400" />
                <div>
                  <h3 className="text-white font-semibold">NFT購入</h3>
                  <p className="text-gray-400 text-sm">新しいNFTを購入して投資を開始</p>
                </div>
              </div>
              <Button
                onClick={() => router.push("/nft/purchase")}
                className="w-full bg-blue-600 hover:bg-blue-700 text-white"
              >
                NFT購入ページへ
              </Button>
            </CardContent>
          </Card>

          <Card className="bg-gray-900/80 border-red-800">
            <CardContent className="p-6">
              <div className="flex items-center space-x-4 mb-4">
                <Gift className="h-8 w-8 text-purple-400" />
                <div>
                  <h3 className="text-white font-semibold">報酬申請</h3>
                  <p className="text-gray-400 text-sm">エアドロップタスクで報酬を申請</p>
                </div>
              </div>
              <Button
                onClick={() => router.push("/rewards/claim")}
                disabled={!profile || profile.pending_rewards < 50}
                className="w-full bg-purple-600 hover:bg-purple-700 text-white disabled:opacity-50"
              >
                {profile && profile.pending_rewards >= 50 ? "報酬申請へ" : "最低$50必要"}
              </Button>
            </CardContent>
          </Card>

          <Card className="bg-gray-900/80 border-red-800">
            <CardContent className="p-6">
              <div className="flex items-center space-x-4 mb-4">
                <Users className="h-8 w-8 text-green-400" />
                <div>
                  <h3 className="text-white font-semibold">紹介システム</h3>
                  <p className="text-gray-400 text-sm">友達を紹介してボーナスを獲得</p>
                </div>
              </div>
              <Button
                onClick={() => router.push("/referrals")}
                className="w-full bg-green-600 hover:bg-green-700 text-white"
              >
                紹介ページへ
              </Button>
            </CardContent>
          </Card>

          <Card className="bg-gray-900/80 border-red-800">
            <CardContent className="p-6">
              <div className="flex items-center space-x-4 mb-4">
                <History className="h-8 w-8 text-yellow-400" />
                <div>
                  <h3 className="text-white font-semibold">取引履歴</h3>
                  <p className="text-gray-400 text-sm">過去の取引と報酬履歴を確認</p>
                </div>
              </div>
              <Button
                onClick={() => router.push("/history")}
                className="w-full bg-yellow-600 hover:bg-yellow-700 text-white"
              >
                履歴ページへ
              </Button>
            </CardContent>
          </Card>

          <Card className="bg-gray-900/80 border-red-800">
            <CardContent className="p-6">
              <div className="flex items-center space-x-4 mb-4">
                <User className="h-8 w-8 text-red-400" />
                <div>
                  <h3 className="text-white font-semibold">プロフィール</h3>
                  <p className="text-gray-400 text-sm">個人情報とアカウント設定</p>
                </div>
              </div>
              <Button onClick={() => router.push("/profile")} className="w-full bg-red-600 hover:bg-red-700 text-white">
                プロフィールへ
              </Button>
            </CardContent>
          </Card>

          <Card className="bg-gray-900/80 border-red-800">
            <CardContent className="p-6">
              <div className="flex items-center space-x-4 mb-4">
                <FileText className="h-8 w-8 text-indigo-400" />
                <div>
                  <h3 className="text-white font-semibold">日利確認</h3>
                  <p className="text-gray-400 text-sm">現在の日利設定を確認</p>
                </div>
              </div>
              <Button
                onClick={() => router.push("/daily-rates")}
                className="w-full bg-indigo-600 hover:bg-indigo-700 text-white"
              >
                日利ページへ
              </Button>
            </CardContent>
          </Card>
        </div>
      </main>
    </div>
  )
}
