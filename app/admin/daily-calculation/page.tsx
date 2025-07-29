"use client"

import { useState, useEffect } from "react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table"
import { ArrowLeft, Calculator, Play, TrendingUp, Loader2 } from "lucide-react"
import { useRouter } from "next/navigation"
import { createClient } from "@/lib/supabase/supabaseBrowserClient"

interface WeeklyRateDistribution {
  day_name: string
  day_date: string
  rate: number
}

export default function AdminDailyCalculationPage() {
  const [loading, setLoading] = useState(true)
  const [calculating, setCalculating] = useState(false)
  const [weeklyRate, setWeeklyRate] = useState("")
  const [selectedWeekStart, setSelectedWeekStart] = useState(getNextMonday())
  const [distribution, setDistribution] = useState<WeeklyRateDistribution[]>([])
  const [calculationResult, setCalculationResult] = useState<string>("")
  const router = useRouter()
  const supabase = createClient()

  function getNextMonday() {
    const today = new Date()
    const dayOfWeek = today.getDay()
    const daysUntilMonday = dayOfWeek === 0 ? 1 : 8 - dayOfWeek
    const nextMonday = new Date(today)
    nextMonday.setDate(today.getDate() + daysUntilMonday)
    return nextMonday.toISOString().split("T")[0]
  }

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

    setLoading(false)
  }

  const handleSetWeeklyRate = async () => {
    if (!weeklyRate || Number.parseFloat(weeklyRate) <= 0) {
      alert("有効な週利率を入力してください")
      return
    }

    setCalculating(true)
    try {
      const { data, error } = await supabase.rpc("set_weekly_rate", {
        p_weekly_rate: Number.parseFloat(weeklyRate),
        p_week_start_date: selectedWeekStart,
        p_admin_user_id: (await supabase.auth.getUser()).data.user?.id,
      })

      if (error) throw error

      const result = data[0]
      if (result.success) {
        setDistribution(result.distribution)
        setCalculationResult(`✅ 週利${weeklyRate}%を日利に自動振り分けしました`)
      } else {
        setCalculationResult("❌ エラー: " + result.message)
      }
    } catch (error) {
      console.error("週利設定エラー:", error)
      setCalculationResult("❌ エラー: " + (error as Error).message)
    } finally {
      setCalculating(false)
    }
  }

  const handleExecuteDailyCalculation = async () => {
    if (distribution.length === 0) {
      alert("まず週利設定を行ってください")
      return
    }

    setCalculating(true)
    try {
      // 各日の日利計算を実行
      let totalCalculated = 0
      for (const day of distribution) {
        if (day.rate > 0) {
          const { data, error } = await supabase.rpc("calculate_daily_rewards", {
            target_date: day.day_date,
          })
          if (!error && data) {
            totalCalculated += data.length
          }
        }
      }

      setCalculationResult(`✅ 日利計算完了: ${totalCalculated}件の報酬を記録しました`)
    } catch (error) {
      console.error("日利計算エラー:", error)
      setCalculationResult("❌ エラー: " + (error as Error).message)
    } finally {
      setCalculating(false)
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
              <h1 className="text-2xl font-bold text-white">日利計算実行</h1>
              <p className="text-gray-400 text-sm">週利入力→日利自動振り分け→計算実行</p>
            </div>
          </div>
        </div>
      </header>

      <main className="max-w-7xl mx-auto p-6">
        {/* 週利設定パネル */}
        <Card className="bg-gray-800 border-gray-700 mb-6">
          <CardHeader>
            <CardTitle className="text-white flex items-center">
              <Calculator className="mr-2 h-5 w-5" />
              週利設定
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div>
                <label htmlFor="weekStart" className="text-white text-sm block mb-2">
                  週開始日（月曜日）
                </label>
                <input
                  id="weekStart"
                  type="date"
                  value={selectedWeekStart}
                  onChange={(e) => setSelectedWeekStart(e.target.value)}
                  className="bg-gray-700 border-gray-600 text-white rounded px-3 py-2 w-full"
                />
              </div>
              <div>
                <label htmlFor="weeklyRate" className="text-white text-sm block mb-2">
                  週利率（%）
                </label>
                <Input
                  id="weeklyRate"
                  type="number"
                  step="0.1"
                  placeholder="例: 3.6"
                  value={weeklyRate}
                  onChange={(e) => setWeeklyRate(e.target.value)}
                  className="bg-gray-700 border-gray-600 text-white"
                />
              </div>
              <div className="flex items-end">
                <Button
                  onClick={handleSetWeeklyRate}
                  disabled={calculating}
                  className="bg-blue-600 hover:bg-blue-700 text-white w-full"
                >
                  {calculating ? (
                    <>
                      <Loader2 className="h-4 w-4 animate-spin mr-2" />
                      設定中...
                    </>
                  ) : (
                    <>
                      <TrendingUp className="h-4 w-4 mr-2" />
                      日利振り分け
                    </>
                  )}
                </Button>
              </div>
            </div>

            {calculationResult && (
              <div
                className={`p-3 rounded ${
                  calculationResult.includes("✅")
                    ? "bg-green-900/50 text-green-300"
                    : calculationResult.includes("❌")
                      ? "bg-red-900/50 text-red-300"
                      : "bg-blue-900/50 text-blue-300"
                }`}
              >
                {calculationResult}
              </div>
            )}
          </CardContent>
        </Card>

        {/* 日利振り分け結果 */}
        {distribution.length > 0 && (
          <Card className="bg-gray-800 border-gray-700 mb-6">
            <CardHeader>
              <CardTitle className="text-white">日利振り分け結果</CardTitle>
            </CardHeader>
            <CardContent>
              <Table>
                <TableHeader>
                  <TableRow className="border-gray-700">
                    <TableHead className="text-gray-300">曜日</TableHead>
                    <TableHead className="text-gray-300">日付</TableHead>
                    <TableHead className="text-gray-300">日利率</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {distribution.map((day, index) => (
                    <TableRow key={index} className="border-gray-700">
                      <TableCell className="text-white">{day.day_name}</TableCell>
                      <TableCell className="text-gray-300">{day.day_date}</TableCell>
                      <TableCell className={`font-bold ${day.rate > 0 ? "text-green-400" : "text-gray-500"}`}>
                        {day.rate.toFixed(3)}%
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
              <div className="mt-4">
                <Button
                  onClick={handleExecuteDailyCalculation}
                  disabled={calculating}
                  className="bg-red-600 hover:bg-red-700 text-white"
                >
                  <Play className="h-4 w-4 mr-2" />
                  日利計算実行
                </Button>
              </div>
            </CardContent>
          </Card>
        )}
      </main>
    </div>
  )
}
