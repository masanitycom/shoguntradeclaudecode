"use client"

import { useState, useEffect } from "react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table"
import { ArrowLeft, Play, Clock, CheckCircle, AlertCircle, Loader2 } from "lucide-react"
import { useRouter } from "next/navigation"
import { createClient } from "@/lib/supabase/supabaseBrowserClient"

interface BatchHistory {
  id: string
  batch_type: string
  status: string
  start_time: string
  end_time: string
  affected_records: number
  execution_details: any
}

export default function BatchManagementPage() {
  const [loading, setLoading] = useState(true)
  const [processing, setProcessing] = useState(false)
  const [batchHistory, setBatchHistory] = useState<BatchHistory[]>([])
  const [result, setResult] = useState<string>("")
  const router = useRouter()
  const supabase = createClient()

  useEffect(() => {
    checkAdminAuth()
    loadBatchHistory()
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

  const loadBatchHistory = async () => {
    try {
      const { data, error } = await supabase.rpc("get_batch_execution_history", { limit_count: 20 })
      if (error) throw error
      setBatchHistory(data || [])
    } catch (error) {
      console.error("バッチ履歴読み込みエラー:", error)
    }
  }

  const executeWeeklyBatch = async () => {
    setProcessing(true)
    try {
      const { data, error } = await supabase.rpc("execute_weekly_batch")
      if (error) throw error

      setResult(`✅ 週次バッチ処理完了: ${data[0]?.batch_summary || "処理完了"}`)
      await loadBatchHistory()
    } catch (error) {
      console.error("バッチ処理エラー:", error)
      setResult("❌ エラー: " + (error as Error).message)
    } finally {
      setProcessing(false)
    }
  }

  const executeRankUpdate = async () => {
    setProcessing(true)
    try {
      const { data, error } = await supabase.rpc("execute_weekly_rank_update")
      if (error) throw error

      setResult(`✅ ランク更新完了: ${data[0]?.updated_users || 0}ユーザー処理`)
      await loadBatchHistory()
    } catch (error) {
      console.error("ランク更新エラー:", error)
      setResult("❌ エラー: " + (error as Error).message)
    } finally {
      setProcessing(false)
    }
  }

  const executeCompoundProcessing = async () => {
    setProcessing(true)
    try {
      const { data, error } = await supabase.rpc("execute_weekly_compound_processing")
      if (error) throw error

      setResult(`✅ 複利処理完了: ${data[0]?.processed_users || 0}ユーザー処理`)
      await loadBatchHistory()
    } catch (error) {
      console.error("複利処理エラー:", error)
      setResult("❌ エラー: " + (error as Error).message)
    } finally {
      setProcessing(false)
    }
  }

  const getStatusIcon = (status: string) => {
    switch (status) {
      case "completed":
        return <CheckCircle className="h-4 w-4 text-green-400" />
      case "running":
        return <Loader2 className="h-4 w-4 text-blue-400 animate-spin" />
      case "failed":
        return <AlertCircle className="h-4 w-4 text-red-400" />
      default:
        return <Clock className="h-4 w-4 text-gray-400" />
    }
  }

  const getBatchTypeName = (type: string) => {
    switch (type) {
      case "weekly_batch":
        return "週次バッチ処理"
      case "weekly_rank_update":
        return "ランク更新"
      case "weekly_compound_processing":
        return "複利処理"
      default:
        return type
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
              <h1 className="text-2xl font-bold text-white">バッチ処理管理</h1>
              <p className="text-gray-400 text-sm">週次処理の実行と履歴管理</p>
            </div>
          </div>
        </div>
      </header>

      <main className="max-w-7xl mx-auto p-6">
        {/* バッチ実行パネル */}
        <Card className="bg-gray-800 border-gray-700 mb-6">
          <CardHeader>
            <CardTitle className="text-white flex items-center">
              <Play className="mr-2 h-5 w-5" />
              バッチ処理実行
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <Button
                onClick={executeWeeklyBatch}
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
                    <Play className="h-4 w-4 mr-2" />
                    週次バッチ実行
                  </>
                )}
              </Button>
              <Button
                onClick={executeRankUpdate}
                disabled={processing}
                className="bg-green-600 hover:bg-green-700 text-white"
              >
                <Play className="h-4 w-4 mr-2" />
                ランク更新のみ
              </Button>
              <Button
                onClick={executeCompoundProcessing}
                disabled={processing}
                className="bg-purple-600 hover:bg-purple-700 text-white"
              >
                <Play className="h-4 w-4 mr-2" />
                複利処理のみ
              </Button>
            </div>

            {result && (
              <div
                className={`p-3 rounded ${
                  result.includes("✅") ? "bg-green-900/50 text-green-300" : "bg-red-900/50 text-red-300"
                }`}
              >
                {result}
              </div>
            )}
          </CardContent>
        </Card>

        {/* バッチ実行履歴 */}
        <Card className="bg-gray-800 border-gray-700">
          <CardHeader>
            <CardTitle className="text-white">バッチ実行履歴</CardTitle>
          </CardHeader>
          <CardContent>
            <Table>
              <TableHeader>
                <TableRow className="border-gray-700">
                  <TableHead className="text-gray-300">ステータス</TableHead>
                  <TableHead className="text-gray-300">バッチ種別</TableHead>
                  <TableHead className="text-gray-300">開始時刻</TableHead>
                  <TableHead className="text-gray-300">終了時刻</TableHead>
                  <TableHead className="text-gray-300">処理件数</TableHead>
                  <TableHead className="text-gray-300">詳細</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {batchHistory.map((batch) => (
                  <TableRow key={batch.id} className="border-gray-700">
                    <TableCell className="flex items-center space-x-2">
                      {getStatusIcon(batch.status)}
                      <span className="text-white capitalize">{batch.status}</span>
                    </TableCell>
                    <TableCell className="text-white">{getBatchTypeName(batch.batch_type)}</TableCell>
                    <TableCell className="text-gray-300">
                      {new Date(batch.start_time).toLocaleString("ja-JP")}
                    </TableCell>
                    <TableCell className="text-gray-300">
                      {batch.end_time ? new Date(batch.end_time).toLocaleString("ja-JP") : "-"}
                    </TableCell>
                    <TableCell className="text-blue-400">{batch.affected_records || 0}</TableCell>
                    <TableCell className="text-gray-300 max-w-xs truncate">
                      {batch.execution_details ? JSON.stringify(batch.execution_details) : "-"}
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </CardContent>
        </Card>
      </main>
    </div>
  )
}
