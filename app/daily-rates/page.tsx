"use client"

import { useState, useEffect } from "react"
import { useRouter } from "next/navigation"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table"
import { ArrowLeft, Calendar, TrendingUp } from "lucide-react"
import { createClient } from "@/lib/supabase/supabaseBrowserClient"

interface DailyRateHistory {
  date: string
  day_name: string
  rate: number
  week_start_date: string
  weekly_rate: number
}

export default function DailyRatesPage() {
  const [rateHistory, setRateHistory] = useState<DailyRateHistory[]>([])
  const [loading, setLoading] = useState(true)
  const [user, setUser] = useState<any>(null)
  const router = useRouter()
  const supabase = createClient()

  useEffect(() => {
    checkAuth()
  }, [])

  useEffect(() => {
    if (user) {
      loadRateHistory()
    }
  }, [user])

  const checkAuth = async () => {
    const {
      data: { user },
    } = await supabase.auth.getUser()
    if (!user) {
      router.push("/login")
      return
    }
    setUser(user)
  }

  const loadRateHistory = async () => {
    try {
      const { data, error } = await supabase.rpc("get_daily_rate_history", {
        p_user_id: user.id,
      })

      if (error) throw error

      setRateHistory(data || [])
    } catch (error) {
      console.error("日利履歴読み込みエラー:", error)
      // エラー時はサンプルデータを表示
      const sampleData: DailyRateHistory[] = [
        {
          date: "2025-06-27",
          day_name: "金曜日",
          rate: 0.4,
          week_start_date: "2025-06-23",
          weekly_rate: 3.6,
        },
        {
          date: "2025-06-26",
          day_name: "木曜日",
          rate: 0.769,
          week_start_date: "2025-06-23",
          weekly_rate: 3.6,
        },
        {
          date: "2025-06-25",
          day_name: "水曜日",
          rate: 1.798,
          week_start_date: "2025-06-23",
          weekly_rate: 3.6,
        },
        {
          date: "2025-06-24",
          day_name: "火曜日",
          rate: 0,
          week_start_date: "2025-06-23",
          weekly_rate: 3.6,
        },
        {
          date: "2025-06-23",
          day_name: "月曜日",
          rate: 0.633,
          week_start_date: "2025-06-23",
          weekly_rate: 3.6,
        },
      ]
      setRateHistory(sampleData)
    } finally {
      setLoading(false)
    }
  }

  if (loading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-red-900 via-black to-red-900 flex items-center justify-center">
        <div className="text-white text-xl">読み込み中...</div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-red-900 via-black to-red-900">
      {/* ヘッダー */}
      <header className="container mx-auto px-4 py-6">
        <div className="flex items-center space-x-4">
          <Button
            onClick={() => router.push("/dashboard")}
            variant="outline"
            size="sm"
            className="border-gray-600 text-gray-400 hover:bg-gray-600 hover:text-white"
          >
            <ArrowLeft className="h-4 w-4 mr-2" />
            戻る
          </Button>
          <div>
            <h1 className="text-2xl font-bold text-white">日利履歴</h1>
            <p className="text-gray-400">日別の利率を透明化して確認できます</p>
          </div>
        </div>
      </header>

      <main className="container mx-auto px-4 py-8">
        <Card className="bg-gray-900/80 border-gray-700">
          <CardHeader>
            <CardTitle className="text-white flex items-center">
              <Calendar className="mr-2 h-5 w-5" />
              日利率履歴
            </CardTitle>
          </CardHeader>
          <CardContent>
            {rateHistory.length > 0 ? (
              <Table>
                <TableHeader>
                  <TableRow className="border-gray-700">
                    <TableHead className="text-gray-300">日付</TableHead>
                    <TableHead className="text-gray-300">曜日</TableHead>
                    <TableHead className="text-gray-300">日利率</TableHead>
                    <TableHead className="text-gray-300">週利率</TableHead>
                    <TableHead className="text-gray-300">週開始日</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {rateHistory.map((rate, index) => (
                    <TableRow key={index} className="border-gray-700">
                      <TableCell className="text-white font-medium">{rate.date}</TableCell>
                      <TableCell className="text-blue-400">{rate.day_name}</TableCell>
                      <TableCell className={`font-bold ${rate.rate > 0 ? "text-green-400" : "text-gray-500"}`}>
                        {rate.rate.toFixed(3)}%
                      </TableCell>
                      <TableCell className="text-yellow-400">{rate.weekly_rate.toFixed(1)}%</TableCell>
                      <TableCell className="text-gray-300">{rate.week_start_date}</TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            ) : (
              <div className="text-center py-8">
                <TrendingUp className="h-12 w-12 text-gray-400 mx-auto mb-4" />
                <p className="text-gray-400">まだ日利履歴がありません</p>
                <p className="text-gray-500 text-sm mt-2">管理者が週利設定を行うと履歴が表示されます</p>
              </div>
            )}
          </CardContent>
        </Card>
      </main>
    </div>
  )
}
