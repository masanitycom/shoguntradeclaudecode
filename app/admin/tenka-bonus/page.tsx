"use client"

import { useEffect, useState } from "react"
import { useRouter } from "next/navigation"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Badge } from "@/components/ui/badge"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Gift, ArrowLeft, Calendar, TrendingUp } from "lucide-react"
import { createClient } from "@/lib/supabase/supabaseBrowserClient"
import { useToast } from "@/hooks/use-toast"

interface TenkaDistribution {
  id: string
  week_start_date: string
  week_end_date: string
  total_company_profit: number
  bonus_pool: number
  total_distributed: number
  distribution_date: string
  bonus_rate: number
}

interface UserBonus {
  user_name: string
  user_id_display: string
  rank_name: string
  bonus_percentage: number
  bonus_amount: number
}

const BONUS_RATES = [20, 22, 25, 30]

export default function TenkaBonusPage() {
  const [distributions, setDistributions] = useState<TenkaDistribution[]>([])
  const [selectedDistribution, setSelectedDistribution] = useState<TenkaDistribution | null>(null)
  const [userBonuses, setUserBonuses] = useState<UserBonus[]>([])
  const [loading, setLoading] = useState(true)
  const [processing, setProcessing] = useState(false)
  const [companyProfit, setCompanyProfit] = useState("")
  const [selectedBonusRate, setSelectedBonusRate] = useState<number>(20)
  const [minBonusRate, setMinBonusRate] = useState<number>(20)
  const [weekStart, setWeekStart] = useState("")
  const [weekEnd, setWeekEnd] = useState("")
  const router = useRouter()
  const supabase = createClient()
  const { toast } = useToast()

  useEffect(() => {
    checkAdminAuth()
    loadDistributions()
    loadMinBonusRate()
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

  const loadMinBonusRate = async () => {
    try {
      // 最新の分配記録から最後に使用されたボーナス率を取得
      const { data } = await supabase
        .from("tenka_bonus_distributions")
        .select("bonus_rate")
        .order("created_at", { ascending: false })
        .limit(1)
        .single()

      if (data?.bonus_rate) {
        const lastRate = Number(data.bonus_rate)
        setMinBonusRate(lastRate)
        setSelectedBonusRate(lastRate)
      }
    } catch (error) {
      console.log("最小ボーナス率の読み込み:", error)
      // エラーの場合はデフォルト値を使用
    }
  }

  const loadDistributions = async () => {
    try {
      setLoading(true)

      const { data: distributionsData } = await supabase
        .from("tenka_bonus_distributions")
        .select("*")
        .order("week_start_date", { ascending: false })

      if (distributionsData) {
        setDistributions(distributionsData)
      }
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

  const loadDistributionDetails = async (distribution: TenkaDistribution) => {
    try {
      const { data: bonusData } = await supabase
        .from("user_tenka_bonuses")
        .select(`
          bonus_amount,
          rank_name,
          bonus_percentage,
          users!inner(name, user_id)
        `)
        .eq("distribution_id", distribution.id)
        .order("bonus_amount", { ascending: false })

      if (bonusData) {
        const formattedBonuses = bonusData.map((item: any) => ({
          user_name: item.users.name,
          user_id_display: item.users.user_id,
          rank_name: item.rank_name,
          bonus_percentage: item.bonus_percentage,
          bonus_amount: item.bonus_amount,
        }))
        setUserBonuses(formattedBonuses)
      }

      setSelectedDistribution(distribution)
    } catch (error) {
      console.error("詳細読み込みエラー:", error)
      toast({
        title: "エラー",
        description: "詳細データの読み込みに失敗しました",
        variant: "destructive",
      })
    }
  }

  const distributeBonus = async () => {
    if (!companyProfit || !weekStart || !weekEnd) {
      toast({
        title: "入力エラー",
        description: "すべての項目を入力してください",
        variant: "destructive",
      })
      return
    }

    if (selectedBonusRate < minBonusRate) {
      toast({
        title: "ボーナス率エラー",
        description: `ボーナス率は${minBonusRate}%以上である必要があります`,
        variant: "destructive",
      })
      return
    }

    try {
      setProcessing(true)

      const { data, error } = await supabase.rpc("calculate_and_distribute_tenka_bonus", {
        company_profit_param: Number.parseFloat(companyProfit),
        week_start_param: weekStart,
        week_end_param: weekEnd,
        bonus_rate_param: selectedBonusRate,
      })

      if (error) {
        throw error
      }

      const result = data[0]
      toast({
        title: "天下統一ボーナス分配完了",
        description: `${result.beneficiary_count}名に総額$${result.distributed_amount.toLocaleString()}を分配しました（${selectedBonusRate}%）`,
      })

      // 最小ボーナス率を更新
      setMinBonusRate(selectedBonusRate)

      // フォームをリセット
      setCompanyProfit("")
      setWeekStart("")
      setWeekEnd("")

      // データを再読み込み
      await loadDistributions()
    } catch (error) {
      console.error("ボーナス分配エラー:", error)
      toast({
        title: "エラー",
        description: "ボーナスの分配に失敗しました",
        variant: "destructive",
      })
    } finally {
      setProcessing(false)
    }
  }

  const getAvailableRates = () => {
    return BONUS_RATES.filter((rate) => rate >= minBonusRate)
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
            <Gift className="h-8 w-8 text-yellow-500" />
            <div>
              <h1 className="text-2xl font-bold text-white">天下統一ボーナス管理</h1>
              <p className="text-gray-400 text-sm">週間利益の一定割合をランク保有者に分配</p>
            </div>
          </div>
        </div>
      </header>

      <main className="max-w-7xl mx-auto p-6">
        {/* 新規分配フォーム */}
        <Card className="bg-gray-800 border-gray-700 mb-8">
          <CardHeader>
            <CardTitle className="text-white flex items-center gap-2">
              <TrendingUp className="h-5 w-5" />
              新規ボーナス分配
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
              <div>
                <Label htmlFor="companyProfit" className="text-gray-300">
                  会社週間利益 ($)
                </Label>
                <Input
                  id="companyProfit"
                  type="number"
                  value={companyProfit}
                  onChange={(e) => setCompanyProfit(e.target.value)}
                  placeholder="100000"
                  className="bg-gray-700 border-gray-600 text-white"
                />
              </div>
              <div>
                <Label htmlFor="bonusRate" className="text-gray-300">
                  ボーナス率 (最低{minBonusRate}%)
                </Label>
                <Select
                  value={selectedBonusRate.toString()}
                  onValueChange={(value) => setSelectedBonusRate(Number(value))}
                >
                  <SelectTrigger className="bg-gray-700 border-gray-600 text-white">
                    <SelectValue placeholder="ボーナス率を選択" />
                  </SelectTrigger>
                  <SelectContent className="bg-gray-700 border-gray-600">
                    {getAvailableRates().map((rate) => (
                      <SelectItem key={rate} value={rate.toString()} className="text-white hover:bg-gray-600">
                        {rate}%
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
              <div>
                <Label htmlFor="weekStart" className="text-gray-300">
                  週開始日
                </Label>
                <Input
                  id="weekStart"
                  type="date"
                  value={weekStart}
                  onChange={(e) => setWeekStart(e.target.value)}
                  className="bg-gray-700 border-gray-600 text-white"
                />
              </div>
              <div>
                <Label htmlFor="weekEnd" className="text-gray-300">
                  週終了日
                </Label>
                <Input
                  id="weekEnd"
                  type="date"
                  value={weekEnd}
                  onChange={(e) => setWeekEnd(e.target.value)}
                  className="bg-gray-700 border-gray-600 text-white"
                />
              </div>
            </div>
            <div className="flex justify-between items-center">
              <div className="text-gray-300 space-y-1">
                <div>
                  ボーナスプール: $
                  {companyProfit
                    ? ((Number.parseFloat(companyProfit) * selectedBonusRate) / 100).toLocaleString()
                    : "0"}
                </div>
                <div className="text-sm text-yellow-400">現在の最低ボーナス率: {minBonusRate}%</div>
              </div>
              <Button
                onClick={distributeBonus}
                disabled={processing || selectedBonusRate < minBonusRate}
                className="bg-yellow-600 hover:bg-yellow-700 text-white disabled:opacity-50"
              >
                {processing ? "分配中..." : `ボーナス分配実行 (${selectedBonusRate}%)`}
              </Button>
            </div>
          </CardContent>
        </Card>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
          {/* 分配履歴 */}
          <Card className="bg-gray-800 border-gray-700">
            <CardHeader>
              <CardTitle className="text-white">分配履歴</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-3">
                {distributions.map((distribution) => (
                  <div
                    key={distribution.id}
                    className={`p-4 rounded-lg border cursor-pointer transition-colors ${
                      selectedDistribution?.id === distribution.id
                        ? "border-yellow-500 bg-gray-700"
                        : "border-gray-600 hover:border-gray-500"
                    }`}
                    onClick={() => loadDistributionDetails(distribution)}
                  >
                    <div className="flex justify-between items-start mb-2">
                      <div className="flex items-center space-x-2">
                        <Calendar className="h-4 w-4 text-gray-400" />
                        <span className="text-white font-medium">
                          {new Date(distribution.week_start_date).toLocaleDateString("ja-JP")} -{" "}
                          {new Date(distribution.week_end_date).toLocaleDateString("ja-JP")}
                        </span>
                      </div>
                      <Badge className="bg-yellow-600 text-white">{distribution.bonus_rate || 20}%</Badge>
                    </div>
                    <div className="grid grid-cols-2 gap-4 text-sm">
                      <div>
                        <span className="text-gray-400">会社利益:</span>
                        <span className="text-white ml-2">${distribution.total_company_profit.toLocaleString()}</span>
                      </div>
                      <div>
                        <span className="text-gray-400">分配額:</span>
                        <span className="text-yellow-400 ml-2">${distribution.total_distributed.toLocaleString()}</span>
                      </div>
                    </div>
                  </div>
                ))}
                {distributions.length === 0 && (
                  <div className="text-center py-8 text-gray-400">分配履歴がありません</div>
                )}
              </div>
            </CardContent>
          </Card>

          {/* 分配詳細 */}
          <Card className="bg-gray-800 border-gray-700">
            <CardHeader>
              <CardTitle className="text-white">分配詳細</CardTitle>
            </CardHeader>
            <CardContent>
              {selectedDistribution ? (
                <div className="space-y-4">
                  <div className="bg-gray-700 rounded-lg p-4">
                    <h3 className="text-white font-medium mb-2 flex items-center justify-between">
                      <span>
                        {new Date(selectedDistribution.week_start_date).toLocaleDateString("ja-JP")} -{" "}
                        {new Date(selectedDistribution.week_end_date).toLocaleDateString("ja-JP")}
                      </span>
                      <Badge className="bg-yellow-600 text-white">{selectedDistribution.bonus_rate || 20}%</Badge>
                    </h3>
                    <div className="grid grid-cols-2 gap-4 text-sm">
                      <div>
                        <span className="text-gray-400">ボーナスプール:</span>
                        <span className="text-yellow-400 ml-2">
                          ${selectedDistribution.bonus_pool.toLocaleString()}
                        </span>
                      </div>
                      <div>
                        <span className="text-gray-400">分配済み:</span>
                        <span className="text-green-400 ml-2">
                          ${selectedDistribution.total_distributed.toLocaleString()}
                        </span>
                      </div>
                    </div>
                  </div>

                  <div className="space-y-2">
                    {userBonuses.map((bonus, index) => (
                      <div key={index} className="flex justify-between items-center p-3 bg-gray-700 rounded">
                        <div>
                          <div className="text-white font-medium">{bonus.user_name}</div>
                          <div className="text-gray-400 text-sm">{bonus.user_id_display}</div>
                        </div>
                        <div className="text-right">
                          <Badge className="bg-indigo-600 text-white mb-1">{bonus.rank_name}</Badge>
                          <div className="text-yellow-400 font-medium">${bonus.bonus_amount.toLocaleString()}</div>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              ) : (
                <div className="text-center py-8 text-gray-400">分配履歴を選択してください</div>
              )}
            </CardContent>
          </Card>
        </div>
      </main>
    </div>
  )
}
