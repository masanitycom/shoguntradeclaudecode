"use client"

import { useState, useEffect } from "react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table"
import { ArrowLeft, Calendar, TrendingUp, Loader2, Save } from "lucide-react"
import { useRouter } from "next/navigation"
import { createClient } from "@/lib/supabase/supabaseBrowserClient"

interface WeeklyProfit {
  id: string
  week_start_date: string
  total_profit: number
  tenka_bonus_pool: number
  created_at: string
}

interface DailyRate {
  date: string
  day_name: string
  rate: number
  is_business_day: boolean
}

export default function AdminDailyRatesPage() {
  const [weeklyProfits, setWeeklyProfits] = useState<WeeklyProfit[]>([])
  const [currentWeekRate, setCurrentWeekRate] = useState("")
  const [weeklyDistribution, setWeeklyDistribution] = useState<DailyRate[]>([])
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const router = useRouter()
  const supabase = createClient()
  const [bonusPercentage, setBonusPercentage] = useState("20")

  useEffect(() => {
    checkAdminAuth()
    loadWeeklyProfits()
    loadCurrentWeekDistribution()
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
  }

  const loadWeeklyProfits = async () => {
    try {
      const { data, error } = await supabase
        .from("weekly_profits")
        .select("*")
        .order("week_start_date", { ascending: false })
        .limit(10)

      if (error) throw error
      setWeeklyProfits(data || [])
    } catch (error) {
      console.error("週間利益読み込みエラー:", error)
    } finally {
      setLoading(false)
    }
  }

  const loadCurrentWeekDistribution = async () => {
    try {
      // 今週の営業日配分を取得（PostgreSQL関数を使用）
      const { data, error } = await supabase.rpc("distribute_weekly_rate", {
        weekly_rate: 0.026, // デフォルト2.6%
        week_start: getWeekStart(new Date()),
      })

      if (error) throw error

      // 結果を整形
      const distribution =
        data?.map((item: any) => ({
          date: item.business_date,
          day_name: new Date(item.business_date).toLocaleDateString("ja-JP", { weekday: "short" }),
          rate: item.daily_rate * 100, // パーセント表示
          is_business_day: true,
        })) || []

      setWeeklyDistribution(distribution)
    } catch (error) {
      console.error("日利配分読み込みエラー:", error)
      // フォールバック：手動で営業日を生成
      generateFallbackDistribution()
    }
  }

  const generateFallbackDistribution = () => {
    const weekStart = getWeekStart(new Date())
    const distribution: DailyRate[] = []

    for (let i = 0; i < 7; i++) {
      const date = new Date(weekStart)
      date.setDate(date.getDate() + i)
      const dayOfWeek = date.getDay()
      const isBusinessDay = dayOfWeek >= 1 && dayOfWeek <= 5 // 月-金

      distribution.push({
        date: date.toISOString().split("T")[0],
        day_name: date.toLocaleDateString("ja-JP", { weekday: "short" }),
        rate: isBusinessDay ? 0.52 : 0, // 2.6% ÷ 5日 = 0.52%
        is_business_day: isBusinessDay,
      })
    }

    setWeeklyDistribution(distribution)
  }

  const getWeekStart = (date: Date) => {
    const d = new Date(date)
    const day = d.getDay()
    const diff = d.getDate() - day + (day === 0 ? -6 : 1) // 月曜日を週の開始とする
    return new Date(d.setDate(diff)).toISOString().split("T")[0]
  }

  const handleSaveWeeklyProfit = async () => {
    if (!currentWeekRate || Number.parseFloat(currentWeekRate) <= 0) {
      alert("有効な週利を入力してください")
      return
    }

    setSaving(true)
    try {
      const {
        data: { user },
      } = await supabase.auth.getUser()
      const weekStart = getWeekStart(new Date())

      const { error } = await supabase.from("weekly_profits").upsert({
        week_start_date: weekStart,
        total_profit: Number.parseFloat(currentWeekRate),
        bonus_percentage: Number.parseFloat(bonusPercentage),
        tenka_bonus_pool: Number.parseFloat(currentWeekRate) * (Number.parseFloat(bonusPercentage) / 100),
        input_by: user?.id,
      })

      if (error) throw error

      alert("週間利益を保存しました")
      setCurrentWeekRate("")
      loadWeeklyProfits()

      // 新しい週利で日利配分を再計算
      await updateWeeklyDistribution(Number.parseFloat(currentWeekRate))
    } catch (error) {
      console.error("保存エラー:", error)
      alert("保存に失敗しました")
    } finally {
      setSaving(false)
    }
  }

  const updateWeeklyDistribution = async (weeklyRate: number) => {
    try {
      const weeklyRateDecimal = weeklyRate / 100 // パーセントを小数に変換
      const { data, error } = await supabase.rpc("distribute_weekly_rate", {
        weekly_rate: weeklyRateDecimal,
        week_start: getWeekStart(new Date()),
      })

      if (error) throw error

      const distribution =
        data?.map((item: any) => ({
          date: item.business_date,
          day_name: new Date(item.business_date).toLocaleDateString("ja-JP", { weekday: "short" }),
          rate: item.daily_rate * 100,
          is_business_day: true,
        })) || []

      setWeeklyDistribution(distribution)
    } catch (error) {
      console.error("日利配分更新エラー:", error)
    }
  }

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-900 flex items-center justify-center">
        <Loader2 className="h-8 w-8 animate-spin text-white" />
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
              <h1 className="text-2xl font-bold text-white">日利設定</h1>
              <p className="text-gray-400 text-sm">週利入力と日利配分管理</p>
            </div>
          </div>
        </div>
      </header>

      <main className="max-w-7xl mx-auto p-6">
        <div className="grid gap-6 lg:grid-cols-2">
          {/* 週利入力 */}
          <Card className="bg-gray-800 border-gray-700">
            <CardHeader>
              <CardTitle className="text-white flex items-center">
                <TrendingUp className="mr-2 h-5 w-5" />
                今週の週利設定
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div>
                <Label htmlFor="weeklyRate" className="text-white">
                  週利 (%)
                </Label>
                <Input
                  id="weeklyRate"
                  type="number"
                  step="0.1"
                  value={currentWeekRate}
                  onChange={(e) => setCurrentWeekRate(e.target.value)}
                  placeholder="例: 2.6"
                  className="bg-gray-700 border-gray-600 text-white"
                />
                <p className="text-gray-400 text-sm mt-1">入力した週利が平日（月〜金）に自動配分されます</p>
              </div>
              <div>
                <Label htmlFor="bonusRate" className="text-white">
                  天下統一ボーナス率 (%)
                </Label>
                <select
                  id="bonusRate"
                  value={bonusPercentage}
                  onChange={(e) => setBonusPercentage(e.target.value)}
                  className="w-full bg-gray-700 border-gray-600 text-white rounded px-3 py-2"
                >
                  <option value="20">20%</option>
                  <option value="22">22%</option>
                  <option value="25">25%</option>
                  <option value="30">30%</option>
                </select>
              </div>

              <Button
                onClick={handleSaveWeeklyProfit}
                disabled={saving}
                className="w-full bg-red-600 hover:bg-red-700 text-white"
              >
                {saving ? (
                  <>
                    <Loader2 className="h-4 w-4 animate-spin mr-2" />
                    保存中...
                  </>
                ) : (
                  <>
                    <Save className="h-4 w-4 mr-2" />
                    週利を保存
                  </>
                )}
              </Button>
            </CardContent>
          </Card>

          {/* 今週の日利配分 */}
          <Card className="bg-gray-800 border-gray-700">
            <CardHeader>
              <CardTitle className="text-white flex items-center">
                <Calendar className="mr-2 h-5 w-5" />
                今週の日利配分
              </CardTitle>
            </CardHeader>
            <CardContent>
              <Table>
                <TableHeader>
                  <TableRow className="border-gray-700">
                    <TableHead className="text-gray-300">日付</TableHead>
                    <TableHead className="text-gray-300">曜日</TableHead>
                    <TableHead className="text-gray-300">日利率</TableHead>
                    <TableHead className="text-gray-300">営業日</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {weeklyDistribution.map((day) => (
                    <TableRow key={day.date} className="border-gray-700">
                      <TableCell className="text-white">{new Date(day.date).toLocaleDateString("ja-JP")}</TableCell>
                      <TableCell className="text-white">{day.day_name}</TableCell>
                      <TableCell className={day.is_business_day ? "text-green-400 font-medium" : "text-gray-400"}>
                        {day.rate.toFixed(3)}%
                      </TableCell>
                      <TableCell>
                        {day.is_business_day ? (
                          <span className="text-green-400">営業日</span>
                        ) : (
                          <span className="text-gray-400">休日</span>
                        )}
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>

              <div className="mt-4 p-3 bg-gray-700 rounded">
                <p className="text-gray-400 text-sm">※ 土日・祝日は自動的に除外され、平日のみに日利が配分されます</p>
              </div>
            </CardContent>
          </Card>
        </div>

        {/* 週間利益履歴 */}
        <Card className="bg-gray-800 border-gray-700 mt-6">
          <CardHeader>
            <CardTitle className="text-white">週間利益履歴</CardTitle>
          </CardHeader>
          <CardContent>
            <Table>
              <TableHeader>
                <TableRow className="border-gray-700">
                  <TableHead className="text-gray-300">週開始日</TableHead>
                  <TableHead className="text-gray-300">総利益</TableHead>
                  <TableHead className="text-gray-300">天下統一ボーナス原資</TableHead>
                  <TableHead className="text-gray-300">入力日時</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {weeklyProfits.map((profit) => (
                  <TableRow key={profit.id} className="border-gray-700">
                    <TableCell className="text-white">
                      {new Date(profit.week_start_date).toLocaleDateString("ja-JP")}
                    </TableCell>
                    <TableCell className="text-green-400 font-medium">
                      ${profit.total_profit.toLocaleString()}
                    </TableCell>
                    <TableCell className="text-blue-400 font-medium">
                      ${profit.tenka_bonus_pool.toLocaleString()}
                    </TableCell>
                    <TableCell className="text-gray-400">
                      {new Date(profit.created_at).toLocaleDateString("ja-JP")}
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>

            {weeklyProfits.length === 0 && (
              <div className="text-center py-8 text-gray-400">週間利益の履歴がありません</div>
            )}
          </CardContent>
        </Card>
      </main>
    </div>
  )
}
