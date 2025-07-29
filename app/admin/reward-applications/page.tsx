"use client"

import { useState, useEffect } from "react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { Textarea } from "@/components/ui/textarea"
import { Label } from "@/components/ui/label"
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table"
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog"
import { Loader2, Eye, Check, X, Gift, ArrowLeft } from "lucide-react"
import { createClient } from "@/lib/supabase/supabaseBrowserClient"
import { useRouter } from "next/navigation"
import { useToast } from "@/hooks/use-toast"

interface RewardApplication {
  id: string
  user_id: string
  week_start_date: string
  total_reward_amount: number
  application_type: string
  task_id?: string
  task_answers?: any
  status: string
  admin_notes?: string
  applied_at: string
  processed_at?: string
  users: {
    name: string
    email: string
    user_id: string
  }
}

export default function AdminRewardApplicationsPage() {
  const [applications, setApplications] = useState<RewardApplication[]>([])
  const [loading, setLoading] = useState(true)
  const [processing, setProcessing] = useState<string | null>(null)
  const [selectedApp, setSelectedApp] = useState<RewardApplication | null>(null)
  const [adminNotes, setAdminNotes] = useState("")
  const router = useRouter()
  const supabase = createClient()
  const { toast } = useToast()

  useEffect(() => {
    checkAdminAuth()
    loadApplications()
  }, [])

  const checkAdminAuth = async () => {
    const {
      data: { user },
    } = await supabase.auth.getUser()
    if (!user) {
      router.push("/admin/login")
      return
    }
  }

  const loadApplications = async () => {
    try {
      const { data, error } = await supabase
        .from("reward_applications")
        .select(`
          *,
          users!inner(name, email, user_id)
        `)
        .order("applied_at", { ascending: false })

      if (error) throw error
      setApplications(data || [])
    } catch (error) {
      console.error("報酬申請一覧読み込みエラー:", error)
    } finally {
      setLoading(false)
    }
  }

  const handleApprove = async (applicationId: string) => {
    setProcessing(applicationId)
    try {
      const application = applications.find((app) => app.id === applicationId)
      if (!application) return

      // 申請を承認
      const { error: updateError } = await supabase
        .from("reward_applications")
        .update({
          status: "approved",
          processed_at: new Date().toISOString(),
          admin_notes: adminNotes,
        })
        .eq("id", applicationId)

      if (updateError) throw updateError

      toast({
        title: "承認完了",
        description: "報酬申請を承認しました。",
      })

      loadApplications()
      setSelectedApp(null)
      setAdminNotes("")
    } catch (error) {
      console.error("承認エラー:", error)
      toast({
        title: "エラー",
        description: "承認に失敗しました。",
        variant: "destructive",
      })
    } finally {
      setProcessing(null)
    }
  }

  const handleReject = async (applicationId: string) => {
    setProcessing(applicationId)
    try {
      const { error } = await supabase
        .from("reward_applications")
        .update({
          status: "rejected",
          admin_notes: adminNotes,
        })
        .eq("id", applicationId)

      if (error) throw error

      toast({
        title: "却下完了",
        description: "報酬申請を却下しました。",
      })

      loadApplications()
      setSelectedApp(null)
      setAdminNotes("")
    } catch (error) {
      console.error("却下エラー:", error)
      toast({
        title: "エラー",
        description: "却下に失敗しました。",
        variant: "destructive",
      })
    } finally {
      setProcessing(null)
    }
  }

  const getStatusBadge = (status: string) => {
    switch (status) {
      case "pending":
        return <Badge className="bg-yellow-600">承認待ち</Badge>
      case "approved":
        return <Badge className="bg-green-600">承認済み</Badge>
      case "rejected":
        return <Badge className="bg-red-600">却下</Badge>
      default:
        return <Badge>{status}</Badge>
    }
  }

  const getSelectedAnswer = (taskAnswers: any) => {
    if (!taskAnswers || !taskAnswers.selected_answer) return "未回答"

    const { selected_answer } = taskAnswers
    if (selected_answer === "other") return "その他"

    // option1, option2, option3の場合
    const optionMap: { [key: string]: string } = {
      option1: "選択肢1",
      option2: "選択肢2",
      option3: "選択肢3",
    }

    return optionMap[selected_answer] || selected_answer
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
              <h1 className="text-2xl font-bold text-white">
                <Gift className="inline mr-2" />
                報酬申請管理
              </h1>
              <p className="text-gray-400 text-sm">ユーザーからの報酬申請を確認・承認します</p>
            </div>
          </div>
        </div>
      </header>

      <main className="max-w-7xl mx-auto p-6">
        <Card className="bg-gray-800 border-gray-700">
          <CardHeader>
            <CardTitle className="text-white">報酬申請一覧</CardTitle>
          </CardHeader>
          <CardContent>
            <Table>
              <TableHeader>
                <TableRow className="border-gray-700">
                  <TableHead className="text-gray-300">申請日時</TableHead>
                  <TableHead className="text-gray-300">ユーザー</TableHead>
                  <TableHead className="text-gray-300">申請金額</TableHead>
                  <TableHead className="text-gray-300">申請タイプ</TableHead>
                  <TableHead className="text-gray-300">ステータス</TableHead>
                  <TableHead className="text-gray-300">操作</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {applications.map((app) => (
                  <TableRow key={app.id} className="border-gray-700">
                    <TableCell className="text-white">{new Date(app.applied_at).toLocaleString("ja-JP")}</TableCell>
                    <TableCell>
                      <div>
                        <div className="font-medium text-white">{app.users.name}</div>
                        <div className="text-sm text-gray-400">{app.users.user_id}</div>
                      </div>
                    </TableCell>
                    <TableCell className="font-medium text-green-400">${app.total_reward_amount.toFixed(2)}</TableCell>
                    <TableCell>
                      <Badge variant="outline" className="text-blue-400 border-blue-400">
                        {app.application_type === "AIRDROP_TASK" ? "エアドロップ" : app.application_type}
                      </Badge>
                    </TableCell>
                    <TableCell>{getStatusBadge(app.status)}</TableCell>
                    <TableCell>
                      <Dialog>
                        <DialogTrigger asChild>
                          <Button
                            variant="outline"
                            size="sm"
                            onClick={() => {
                              setSelectedApp(app)
                              setAdminNotes(app.admin_notes || "")
                            }}
                            className="text-white border-gray-600 hover:bg-gray-700"
                          >
                            <Eye className="h-4 w-4 mr-1" />
                            詳細
                          </Button>
                        </DialogTrigger>
                        <DialogContent className="max-w-2xl bg-gray-800 border-gray-700">
                          <DialogHeader>
                            <DialogTitle className="text-white">報酬申請詳細</DialogTitle>
                            <DialogDescription className="text-gray-400">
                              申請内容を確認して承認・却下を行ってください
                            </DialogDescription>
                          </DialogHeader>

                          {selectedApp && (
                            <div className="space-y-6">
                              <div className="grid grid-cols-2 gap-4">
                                <div>
                                  <Label className="text-sm font-medium text-gray-300">ユーザー名</Label>
                                  <p className="text-sm text-white">{selectedApp.users.name}</p>
                                </div>
                                <div>
                                  <Label className="text-sm font-medium text-gray-300">ユーザーID</Label>
                                  <p className="text-sm text-white">{selectedApp.users.user_id}</p>
                                </div>
                                <div>
                                  <Label className="text-sm font-medium text-gray-300">申請金額</Label>
                                  <p className="text-sm font-bold text-green-400">
                                    ${selectedApp.total_reward_amount.toFixed(2)}
                                  </p>
                                </div>
                                <div>
                                  <Label className="text-sm font-medium text-gray-300">週開始日</Label>
                                  <p className="text-sm text-white">{selectedApp.week_start_date}</p>
                                </div>
                                <div>
                                  <Label className="text-sm font-medium text-gray-300">申請タイプ</Label>
                                  <p className="text-sm text-white">{selectedApp.application_type}</p>
                                </div>
                                <div>
                                  <Label className="text-sm font-medium text-gray-300">ステータス</Label>
                                  <div className="mt-1">{getStatusBadge(selectedApp.status)}</div>
                                </div>
                              </div>

                              {/* エアドロップタスクの回答 */}
                              {selectedApp.application_type === "AIRDROP_TASK" && selectedApp.task_answers && (
                                <div className="border rounded-lg p-4 bg-gray-700 border-gray-600">
                                  <Label className="text-sm font-medium text-gray-300">エアドロップタスク回答</Label>
                                  <div className="mt-2 space-y-2">
                                    <div>
                                      <p className="text-sm font-medium text-gray-300">回答:</p>
                                      <p className="text-sm text-blue-400">
                                        {getSelectedAnswer(selectedApp.task_answers)}
                                      </p>
                                    </div>
                                  </div>
                                </div>
                              )}

                              <div>
                                <Label htmlFor="adminNotes" className="text-sm font-medium text-gray-300">
                                  管理者メモ
                                </Label>
                                <Textarea
                                  id="adminNotes"
                                  value={adminNotes}
                                  onChange={(e) => setAdminNotes(e.target.value)}
                                  placeholder="承認・却下の理由や備考を入力"
                                  className="mt-1 bg-gray-700 border-gray-600 text-white"
                                />
                              </div>

                              {selectedApp.status === "pending" && (
                                <div className="flex gap-2">
                                  <Button
                                    onClick={() => handleApprove(selectedApp.id)}
                                    disabled={processing === selectedApp.id}
                                    className="bg-green-600 hover:bg-green-700"
                                  >
                                    {processing === selectedApp.id ? (
                                      <Loader2 className="h-4 w-4 animate-spin mr-2" />
                                    ) : (
                                      <Check className="h-4 w-4 mr-2" />
                                    )}
                                    承認
                                  </Button>
                                  <Button
                                    onClick={() => handleReject(selectedApp.id)}
                                    disabled={processing === selectedApp.id}
                                    variant="destructive"
                                  >
                                    {processing === selectedApp.id ? (
                                      <Loader2 className="h-4 w-4 animate-spin mr-2" />
                                    ) : (
                                      <X className="h-4 w-4 mr-2" />
                                    )}
                                    却下
                                  </Button>
                                </div>
                              )}
                            </div>
                          )}
                        </DialogContent>
                      </Dialog>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>

            {applications.length === 0 && <div className="text-center py-8 text-gray-400">報酬申請はありません</div>}
          </CardContent>
        </Card>
      </main>
    </div>
  )
}
