"use client"

import { useState, useEffect } from "react"
import { useRouter } from "next/navigation"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table"
import { Badge } from "@/components/ui/badge"
import { ArrowLeft, CheckCircle, XCircle, Clock, DollarSign } from "lucide-react"
import { createClient } from "@/lib/supabase/supabaseBrowserClient"

interface RewardApplication {
  id: string
  user_name: string
  total_reward_amount: number
  application_type: string
  status: string
  applied_at: string
  net_amount: number
  fee_amount: number
}

export default function AdminRewardsPage() {
  const [applications, setApplications] = useState<RewardApplication[]>([])
  const [loading, setLoading] = useState(true)
  const [processing, setProcessing] = useState<string | null>(null)
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

    loadRewardApplications()
  }

  const loadRewardApplications = async () => {
    try {
      const { data, error } = await supabase
        .from("reward_applications")
        .select(`
          id,
          total_reward_amount,
          application_type,
          status,
          applied_at,
          net_amount,
          fee_amount,
          users!inner(name)
        `)
        .order("applied_at", { ascending: false })

      if (error) throw error

      const formattedData = data.map((app: any) => ({
        id: app.id,
        user_name: app.users.name,
        total_reward_amount: app.total_reward_amount,
        application_type: app.application_type,
        status: app.status,
        applied_at: app.applied_at,
        net_amount: app.net_amount,
        fee_amount: app.fee_amount,
      }))

      setApplications(formattedData)
    } catch (error) {
      console.error("報酬申請読み込みエラー:", error)
    } finally {
      setLoading(false)
    }
  }

  const handleApproveApplication = async (applicationId: string) => {
    setProcessing(applicationId)
    try {
      const { error } = await supabase
        .from("reward_applications")
        .update({
          status: "approved",
          processed_at: new Date().toISOString(),
        })
        .eq("id", applicationId)

      if (error) throw error

      await loadRewardApplications()
      alert("報酬申請を承認しました")
    } catch (error) {
      console.error("承認エラー:", error)
      alert("承認に失敗しました")
    } finally {
      setProcessing(null)
    }
  }

  const handleRejectApplication = async (applicationId: string) => {
    setProcessing(applicationId)
    try {
      const { error } = await supabase
        .from("reward_applications")
        .update({
          status: "rejected",
          processed_at: new Date().toISOString(),
        })
        .eq("id", applicationId)

      if (error) throw error

      await loadRewardApplications()
      alert("報酬申請を却下しました")
    } catch (error) {
      console.error("却下エラー:", error)
      alert("却下に失敗しました")
    } finally {
      setProcessing(null)
    }
  }

  const getStatusBadge = (status: string) => {
    switch (status) {
      case "pending":
        return (
          <Badge variant="outline" className="text-yellow-400 border-yellow-400">
            <Clock className="w-3 h-3 mr-1" />
            承認待ち
          </Badge>
        )
      case "approved":
        return (
          <Badge variant="outline" className="text-green-400 border-green-400">
            <CheckCircle className="w-3 h-3 mr-1" />
            承認済み
          </Badge>
        )
      case "rejected":
        return (
          <Badge variant="outline" className="text-red-400 border-red-400">
            <XCircle className="w-3 h-3 mr-1" />
            却下
          </Badge>
        )
      default:
        return <Badge variant="outline">{status}</Badge>
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
              <h1 className="text-2xl font-bold text-white">報酬申請管理</h1>
              <p className="text-gray-400 text-sm">エアドロップタスクの報酬申請を管理</p>
            </div>
          </div>
        </div>
      </header>

      <main className="max-w-7xl mx-auto p-6">
        <Card className="bg-gray-800 border-gray-700">
          <CardHeader>
            <CardTitle className="text-white flex items-center">
              <DollarSign className="mr-2 h-5 w-5" />
              報酬申請一覧
            </CardTitle>
          </CardHeader>
          <CardContent>
            {applications.length > 0 ? (
              <Table>
                <TableHeader>
                  <TableRow className="border-gray-700">
                    <TableHead className="text-gray-300">ユーザー</TableHead>
                    <TableHead className="text-gray-300">申請額</TableHead>
                    <TableHead className="text-gray-300">手数料</TableHead>
                    <TableHead className="text-gray-300">受取額</TableHead>
                    <TableHead className="text-gray-300">種別</TableHead>
                    <TableHead className="text-gray-300">状態</TableHead>
                    <TableHead className="text-gray-300">申請日</TableHead>
                    <TableHead className="text-gray-300">操作</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {applications.map((app) => (
                    <TableRow key={app.id} className="border-gray-700">
                      <TableCell className="text-white font-medium">{app.user_name}</TableCell>
                      <TableCell className="text-green-400">${app.total_reward_amount.toLocaleString()}</TableCell>
                      <TableCell className="text-red-400">${app.fee_amount.toLocaleString()}</TableCell>
                      <TableCell className="text-blue-400 font-bold">${app.net_amount.toLocaleString()}</TableCell>
                      <TableCell className="text-gray-300">{app.application_type}</TableCell>
                      <TableCell>{getStatusBadge(app.status)}</TableCell>
                      <TableCell className="text-gray-300">
                        {new Date(app.applied_at).toLocaleDateString("ja-JP")}
                      </TableCell>
                      <TableCell>
                        {app.status === "pending" && (
                          <div className="flex space-x-2">
                            <Button
                              size="sm"
                              onClick={() => handleApproveApplication(app.id)}
                              disabled={processing === app.id}
                              className="bg-green-600 hover:bg-green-700 text-white"
                            >
                              <CheckCircle className="w-3 h-3 mr-1" />
                              承認
                            </Button>
                            <Button
                              size="sm"
                              variant="outline"
                              onClick={() => handleRejectApplication(app.id)}
                              disabled={processing === app.id}
                              className="border-red-600 text-red-400 hover:bg-red-600 hover:text-white"
                            >
                              <XCircle className="w-3 h-3 mr-1" />
                              却下
                            </Button>
                          </div>
                        )}
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            ) : (
              <div className="text-center py-8">
                <DollarSign className="h-12 w-12 text-gray-400 mx-auto mb-4" />
                <p className="text-gray-400">報酬申請がありません</p>
              </div>
            )}
          </CardContent>
        </Card>
      </main>
    </div>
  )
}
