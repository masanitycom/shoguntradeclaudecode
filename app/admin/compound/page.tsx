"use client"

import { useState, useEffect } from "react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table"
import { ArrowLeft, Calculator, Play, TrendingUp, Loader2, DollarSign } from "lucide-react"
import { useRouter } from "next/navigation"
import { createClient } from "@/lib/supabase/supabaseBrowserClient"

interface CompoundResult {
  user_id: string
  user_name: string
  unclaimed_amount: number
  fee_rate: number
  fee_amount: number
  compound_amount: number
}

export default function AdminCompoundPage() {
  const [loading, setLoading] = useState(true)
  const [processing, setProcessing] = useState(false)
  const [compoundResults, setCompoundResults] = useState<CompoundResult[]>([])
  const [selectedDate, setSelectedDate] = useState(new Date().toISOString().split("T")[0])
  const [processResult, setProcessResult] = useState<string>("")
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

    setLoading(false)
  }

  const handleProcessCompound = async () => {
    setProcessing(true)
    try {
      const weekStart = getWeekStartDate(selectedDate)
      const { data, error } = await supabase.rpc("process_compound_interest", {
        target_week_start: weekStart,
      })

      if (error) throw error

      setCompoundResults(data || [])
      setProcessResult(`✅ 複利処理完了: ${data?.length || 0}人のユーザーを処理しました`)
    } catch (error) {
      console.error("複利処理エラー:", error)
      setProcessResult("❌ エラー: " + (error as Error).message)
    } finally {
      setProcessing(false)
    }
  }

  const handleApplyToInvestments = async () => {
    setProcessing(true)
    try {
      const { data, error } = await supabase.rpc("apply_compound_to_investments")

      if (error) throw error

      setProcessResult(`✅ 投資額適用完了: ${data}件のNFTに複利額を適用しました`)
    } catch (error) {
      console.error("投資額適用エラー:", error)
      setProcessResult("❌ エラー: " + (error as Error).message)
    } finally {
      setProcessing(false)
    }
  }

  const getWeekStartDate = (dateString: string) => {
    const date = new Date(dateString)
    const dayOfWeek = date.getDay()
    const diff = date.getDate() - dayOfWeek + (dayOfWeek === 0 ? -6 : 1)
    const monday = new Date(date.setDate(diff))
    return monday.toISOString().split("T")[0]
  }

  const getTotalCompound = () => {
    return compoundResults.reduce((sum, result) => sum + result.compound_amount, 0)
  }

  const getTotalFees = () => {
    return compoundResults.reduce((sum, result) => sum + result.fee_amount, 0)
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
              <h1 className="text-2xl font-bold text-white">複利運用管理</h1>
              <p className="text-gray-400 text-sm">未申請報酬の自動複利処理</p>
            </div>
          </div>
        </div>
      </header>

      <main className="max-w-7xl mx-auto p-6">
        {/* 処理実行パネル */}
        <Card className="bg-gray-800 border-gray-700 mb-6">
          <CardHeader>
            <CardTitle className="text-white flex items-center">
              <Calculator className="mr-2 h-5 w-5" />
              複利処理実行
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="flex items-center space-x-4">
              <div>
                <label htmlFor="targetDate" className="text-white text-sm">
                  対象週開始日
                </label>
                <input
                  id="targetDate"
                  type="date"
                  value={selectedDate}
                  onChange={(e) => setSelectedDate(e.target.value)}
                  className="bg-gray-700 border-gray-600 text-white rounded px-3 py-2 ml-2"
                />
              </div>
              <Button
                onClick={handleProcessCompound}
                disabled={processing}
                className="bg-blue-600 hover:bg-blue-700 text-white"
              >
                {processing ? (
                  <>
                    <Loader2 className="h-4 w-4 animate-spin mr-2" />
                    処理中...
                  </>
                ) : (
                  <>
                    <TrendingUp className="h-4 w-4 mr-2" />
                    複利処理実行
                  </>
                )}
              </Button>
              <Button
                onClick={handleApplyToInvestments}
                disabled={processing || compoundResults.length === 0}
                className="bg-green-600 hover:bg-green-700 text-white"
              >
                <Play className="h-4 w-4 mr-2" />
                投資額に適用
              </Button>
            </div>

            {processResult && (
              <div
                className={`p-3 rounded ${
                  processResult.includes("✅") ? "bg-green-900/50 text-green-300" : "bg-red-900/50 text-red-300"
                }`}
              >
                {processResult}
              </div>
            )}
          </CardContent>
        </Card>

        {/* 統計カード */}
        {compoundResults.length > 0 && (
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-6">
            <Card className="bg-gray-800 border-gray-700">
              <CardContent className="p-6">
                <div className="flex items-center">
                  <DollarSign className="h-8 w-8 text-green-400" />
                  <div className="ml-4">
                    <p className="text-sm font-medium text-gray-400">総複利額</p>
                    <p className="text-2xl font-bold text-white">${getTotalCompound().toFixed(2)}</p>
                  </div>
                </div>
              </CardContent>
            </Card>

            <Card className="bg-gray-800 border-gray-700">
              <CardContent className="p-6">
                <div className="flex items-center">
                  <TrendingUp className="h-8 w-8 text-yellow-400" />
                  <div className="ml-4">
                    <p className="text-sm font-medium text-gray-400">総手数料</p>
                    <p className="text-2xl font-bold text-white">${getTotalFees().toFixed(2)}</p>
                  </div>
                </div>
              </CardContent>
            </Card>

            <Card className="bg-gray-800 border-gray-700">
              <CardContent className="p-6">
                <div className="flex items-center">
                  <Calculator className="h-8 w-8 text-blue-400" />
                  <div className="ml-4">
                    <p className="text-sm font-medium text-gray-400">処理ユーザー数</p>
                    <p className="text-2xl font-bold text-white">{compoundResults.length}</p>
                  </div>
                </div>
              </CardContent>
            </Card>
          </div>
        )}

        {/* 複利処理結果 */}
        {compoundResults.length > 0 && (
          <Card className="bg-gray-800 border-gray-700">
            <CardHeader>
              <CardTitle className="text-white">複利処理結果</CardTitle>
            </CardHeader>
            <CardContent>
              <Table>
                <TableHeader>
                  <TableRow className="border-gray-700">
                    <TableHead className="text-gray-300">ユーザー</TableHead>
                    <TableHead className="text-gray-300">未申請報酬</TableHead>
                    <TableHead className="text-gray-300">手数料率</TableHead>
                    <TableHead className="text-gray-300">手数料</TableHead>
                    <TableHead className="text-gray-300">複利額</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {compoundResults.map((result, index) => (
                    <TableRow key={index} className="border-gray-700">
                      <TableCell className="text-white">{result.user_name}</TableCell>
                      <TableCell className="text-yellow-400">${result.unclaimed_amount.toFixed(2)}</TableCell>
                      <TableCell className="text-blue-400">{(result.fee_rate * 100).toFixed(1)}%</TableCell>
                      <TableCell className="text-red-400">${result.fee_amount.toFixed(2)}</TableCell>
                      <TableCell className="text-green-400">${result.compound_amount.toFixed(2)}</TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </CardContent>
          </Card>
        )}
      </main>
    </div>
  )
}
