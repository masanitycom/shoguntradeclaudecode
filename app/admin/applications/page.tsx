"use client"

import { useState, useEffect } from "react"

// ビルド時の静的生成を無効化（Supabase環境変数が必要なため）
export const dynamic = 'force-dynamic'
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table"
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog"
import { Loader2, Eye, CheckCircle, XCircle, ArrowLeft, CreditCard, DollarSign, Clock, AlertCircle } from "lucide-react"
import { createClient } from "@/lib/supabase/supabaseBrowserClient"
import { useRouter } from "next/navigation"
import { useToast } from "@/hooks/use-toast"

interface Application {
  id: string
  user_id: string
  nft_id: string
  status: string
  payment_method: string
  payment_address: string
  transaction_hash: string | null
  created_at: string
  updated_at: string
  users: {
    name: string
    email: string
  }
  nfts: {
    name: string
    price: string
  }
}

export default function AdminApplicationsPage() {
  const [applications, setApplications] = useState<Application[]>([])
  const [loading, setLoading] = useState(true)
  const [selectedApplication, setSelectedApplication] = useState<Application | null>(null)
  const [isDialogOpen, setIsDialogOpen] = useState(false)
  const [processing, setProcessing] = useState(false)
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
      router.push("/login")
      return
    }

    const { data: userData } = await supabase.from("users").select("is_admin").eq("id", user.id).single()

    if (!userData?.is_admin) {
      router.push("/dashboard")
      return
    }
  }

  const loadApplications = async () => {
    try {
      const { data, error } = await supabase
        .from("nft_purchase_applications")
        .select(`
          *,
          users!nft_purchase_applications_user_id_fkey (
            name,
            email
          ),
          nfts!nft_purchase_applications_nft_id_fkey (
            name,
            price
          )
        `)
        .order("created_at", { ascending: false })

      if (error) throw error
      setApplications(data || [])
    } catch (error) {
      console.error("申請読み込みエラー:", error)
      toast({
        title: "エラー",
        description: "申請の読み込みに失敗しました。",
        variant: "destructive",
      })
    } finally {
      setLoading(false)
    }
  }

  const handlePaymentConfirmation = async (applicationId: string) => {
    setProcessing(true)
    try {
      const { error } = await supabase
        .from("nft_purchase_applications")
        .update({
          status: "PAYMENT_SUBMITTED",
          updated_at: new Date().toISOString(),
        })
        .eq("id", applicationId)

      if (error) throw error

      toast({
        title: "入金確認完了",
        description: "入金を確認しました。承認待ちステータスに変更されました。",
      })

      loadApplications()
      setIsDialogOpen(false)
    } catch (error) {
      console.error("入金確認エラー:", error)
      toast({
        title: "エラー",
        description: "入金確認に失敗しました。",
        variant: "destructive",
      })
    } finally {
      setProcessing(false)
    }
  }

  const handleApproval = async (applicationId: string) => {
    setProcessing(true)
    try {
      const { error } = await supabase
        .from("nft_purchase_applications")
        .update({
          status: "APPROVED",
          updated_at: new Date().toISOString(),
        })
        .eq("id", applicationId)

      if (error) throw error

      toast({
        title: "承認完了",
        description: "申請を承認しました。",
      })

      loadApplications()
      setIsDialogOpen(false)
    } catch (error) {
      console.error("承認エラー:", error)
      toast({
        title: "エラー",
        description: "承認に失敗しました。",
        variant: "destructive",
      })
    } finally {
      setProcessing(false)
    }
  }

  const handleRejection = async (applicationId: string) => {
    if (!confirm("この申請を却下しますか？")) return

    setProcessing(true)
    try {
      const { error } = await supabase
        .from("nft_purchase_applications")
        .update({
          status: "REJECTED",
          updated_at: new Date().toISOString(),
        })
        .eq("id", applicationId)

      if (error) throw error

      toast({
        title: "却下完了",
        description: "申請を却下しました。",
      })

      loadApplications()
      setIsDialogOpen(false)
    } catch (error) {
      console.error("却下エラー:", error)
      toast({
        title: "エラー",
        description: "却下に失敗しました。",
        variant: "destructive",
      })
    } finally {
      setProcessing(false)
    }
  }

  const getStatusBadge = (status: string) => {
    switch (status) {
      case "PENDING":
        return <Badge className="bg-yellow-600 text-white">支払い待ち</Badge>
      case "PAYMENT_SUBMITTED":
        return <Badge className="bg-blue-600 text-white">承認待ち</Badge>
      case "APPROVED":
        return <Badge className="bg-green-600 text-white">承認済み</Badge>
      case "REJECTED":
        return <Badge className="bg-red-600 text-white">却下</Badge>
      default:
        return <Badge className="bg-gray-600 text-white">{status}</Badge>
    }
  }

  const getStatusIcon = (status: string) => {
    switch (status) {
      case "PENDING":
        return <Clock className="h-4 w-4" />
      case "PAYMENT_SUBMITTED":
        return <AlertCircle className="h-4 w-4" />
      case "APPROVED":
        return <CheckCircle className="h-4 w-4" />
      case "REJECTED":
        return <XCircle className="h-4 w-4" />
      default:
        return <Clock className="h-4 w-4" />
    }
  }

  const pendingCount = applications.filter((app) => app.status === "PENDING").length
  const paymentSubmittedCount = applications.filter((app) => app.status === "PAYMENT_SUBMITTED").length
  const approvedCount = applications.filter((app) => app.status === "APPROVED").length
  const rejectedCount = applications.filter((app) => app.status === "REJECTED").length

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
        <div className="max-w-7xl mx-auto flex justify-between items-center">
          <div className="flex items-center space-x-4">
            <Button onClick={() => router.push("/admin")} variant="ghost" className="text-white hover:bg-white/10">
              <ArrowLeft className="mr-2 h-4 w-4" />
              管理画面に戻る
            </Button>
            <div>
              <h1 className="text-2xl font-bold text-white">
                <CreditCard className="inline mr-2" />
                NFT購入申請管理
              </h1>
              <p className="text-gray-400 text-sm">NFT購入申請の入金確認と承認を行います</p>
            </div>
          </div>
        </div>
      </header>

      <main className="max-w-7xl mx-auto p-6">
        {/* 統計 */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-6">
          <Card className="bg-gray-900/80 border-red-800">
            <CardContent className="p-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-gray-400 text-sm">支払い待ち</p>
                  <p className="text-2xl font-bold text-yellow-400">{pendingCount}</p>
                </div>
                <Clock className="h-8 w-8 text-yellow-500" />
              </div>
            </CardContent>
          </Card>
          <Card className="bg-gray-900/80 border-red-800">
            <CardContent className="p-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-gray-400 text-sm">承認待ち</p>
                  <p className="text-2xl font-bold text-blue-400">{paymentSubmittedCount}</p>
                </div>
                <AlertCircle className="h-8 w-8 text-blue-500" />
              </div>
            </CardContent>
          </Card>
          <Card className="bg-gray-900/80 border-red-800">
            <CardContent className="p-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-gray-400 text-sm">承認済み</p>
                  <p className="text-2xl font-bold text-green-400">{approvedCount}</p>
                </div>
                <CheckCircle className="h-8 w-8 text-green-500" />
              </div>
            </CardContent>
          </Card>
          <Card className="bg-gray-900/80 border-red-800">
            <CardContent className="p-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-gray-400 text-sm">却下</p>
                  <p className="text-2xl font-bold text-red-400">{rejectedCount}</p>
                </div>
                <XCircle className="h-8 w-8 text-red-500" />
              </div>
            </CardContent>
          </Card>
        </div>

        <Card className="bg-gray-900/80 border-red-800">
          <CardHeader>
            <CardTitle className="text-white">申請一覧</CardTitle>
          </CardHeader>
          <CardContent>
            <Table>
              <TableHeader>
                <TableRow className="border-gray-700">
                  <TableHead className="text-gray-300">ユーザー</TableHead>
                  <TableHead className="text-gray-300">NFT</TableHead>
                  <TableHead className="text-gray-300">金額</TableHead>
                  <TableHead className="text-gray-300">支払い方法</TableHead>
                  <TableHead className="text-gray-300">ステータス</TableHead>
                  <TableHead className="text-gray-300">申請日</TableHead>
                  <TableHead className="text-gray-300">操作</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {applications.map((application) => (
                  <TableRow key={application.id} className="border-gray-700">
                    <TableCell>
                      <div className="text-white">
                        <div className="font-medium">{application.users.name}</div>
                        <div className="text-sm text-gray-400">{application.users.email}</div>
                      </div>
                    </TableCell>
                    <TableCell className="text-white">{application.nfts.name}</TableCell>
                    <TableCell className="text-white">
                      <div className="flex items-center">
                        <DollarSign className="h-4 w-4 mr-1" />
                        {application.nfts.price}
                      </div>
                    </TableCell>
                    <TableCell className="text-white">{application.payment_method}</TableCell>
                    <TableCell>{getStatusBadge(application.status)}</TableCell>
                    <TableCell className="text-white">
                      {new Date(application.created_at).toLocaleDateString("ja-JP")}
                    </TableCell>
                    <TableCell>
                      <Dialog
                        open={isDialogOpen && selectedApplication?.id === application.id}
                        onOpenChange={setIsDialogOpen}
                      >
                        <DialogTrigger asChild>
                          <Button
                            variant="outline"
                            size="sm"
                            onClick={() => setSelectedApplication(application)}
                            className="border-blue-600 text-blue-400 hover:bg-blue-600 hover:text-white"
                          >
                            <Eye className="h-4 w-4 mr-1" />
                            詳細
                          </Button>
                        </DialogTrigger>
                        <DialogContent className="bg-gray-900/95 border-red-800 text-white max-w-2xl">
                          <DialogHeader>
                            <DialogTitle className="text-white flex items-center">
                              {getStatusIcon(application.status)}
                              <span className="ml-2">申請詳細</span>
                            </DialogTitle>
                            <DialogDescription className="text-gray-400">NFT購入申請の詳細情報と操作</DialogDescription>
                          </DialogHeader>

                          <div className="space-y-4">
                            <div className="grid grid-cols-2 gap-4">
                              <div>
                                <h3 className="text-sm font-medium text-gray-400">ユーザー情報</h3>
                                <p className="text-white">{application.users.name}</p>
                                <p className="text-gray-300 text-sm">{application.users.email}</p>
                              </div>
                              <div>
                                <h3 className="text-sm font-medium text-gray-400">NFT情報</h3>
                                <p className="text-white">{application.nfts.name}</p>
                                <p className="text-green-400 font-medium">${application.nfts.price}</p>
                              </div>
                            </div>

                            <div className="grid grid-cols-2 gap-4">
                              <div>
                                <h3 className="text-sm font-medium text-gray-400">支払い方法</h3>
                                <p className="text-white">{application.payment_method}</p>
                              </div>
                              <div>
                                <h3 className="text-sm font-medium text-gray-400">現在のステータス</h3>
                                {getStatusBadge(application.status)}
                              </div>
                            </div>

                            <div>
                              <h3 className="text-sm font-medium text-gray-400">送金先アドレス</h3>
                              <p className="text-white font-mono text-sm bg-gray-800 p-2 rounded">
                                {application.payment_address}
                              </p>
                            </div>

                            {application.transaction_hash && (
                              <div>
                                <h3 className="text-sm font-medium text-gray-400">トランザクションハッシュ</h3>
                                <p className="text-white font-mono text-sm bg-gray-800 p-2 rounded">
                                  {application.transaction_hash}
                                </p>
                              </div>
                            )}

                            <div className="grid grid-cols-2 gap-4">
                              <div>
                                <h3 className="text-sm font-medium text-gray-400">申請日時</h3>
                                <p className="text-white">{new Date(application.created_at).toLocaleString("ja-JP")}</p>
                              </div>
                              <div>
                                <h3 className="text-sm font-medium text-gray-400">更新日時</h3>
                                <p className="text-white">{new Date(application.updated_at).toLocaleString("ja-JP")}</p>
                              </div>
                            </div>

                            <div className="flex gap-2 pt-4 border-t border-gray-700">
                              {application.status === "PENDING" && (
                                <Button
                                  onClick={() => handlePaymentConfirmation(application.id)}
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
                                      <CheckCircle className="h-4 w-4 mr-2" />
                                      入金確認
                                    </>
                                  )}
                                </Button>
                              )}

                              {application.status === "PAYMENT_SUBMITTED" && (
                                <Button
                                  onClick={() => handleApproval(application.id)}
                                  disabled={processing}
                                  className="bg-green-600 hover:bg-green-700 text-white"
                                >
                                  {processing ? (
                                    <>
                                      <Loader2 className="h-4 w-4 animate-spin mr-2" />
                                      処理中...
                                    </>
                                  ) : (
                                    <>
                                      <CheckCircle className="h-4 w-4 mr-2" />
                                      承認
                                    </>
                                  )}
                                </Button>
                              )}

                              {(application.status === "PENDING" || application.status === "PAYMENT_SUBMITTED") && (
                                <Button
                                  onClick={() => handleRejection(application.id)}
                                  disabled={processing}
                                  className="bg-red-600 hover:bg-red-700 text-white"
                                >
                                  <XCircle className="h-4 w-4 mr-2" />
                                  却下
                                </Button>
                              )}
                            </div>
                          </div>
                        </DialogContent>
                      </Dialog>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>

            {applications.length === 0 && <div className="text-center py-8 text-gray-400">申請がありません。</div>}
          </CardContent>
        </Card>
      </main>
    </div>
  )
}
