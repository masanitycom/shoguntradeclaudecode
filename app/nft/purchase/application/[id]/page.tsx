"use client"

import { useState, useEffect } from "react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Badge } from "@/components/ui/badge"
import { Loader2, Copy, Check } from "lucide-react"
import { Alert, AlertDescription } from "@/components/ui/alert"
import { createClient } from "@/lib/supabase/supabaseBrowserClient"
import { useRouter } from "next/navigation"
import { useParams } from "next/navigation"
import QRCode from "qrcode"

interface PurchaseApplication {
  id: string
  user_id: string
  nft_id: string
  requested_price: number
  payment_method: string
  status: string
  payment_proof_url?: string
  created_at: string
  nfts: {
    name: string
    price: number
  }
}

interface PaymentAddress {
  address: string
  qr_code_url?: string
}

export default function PurchaseApplicationPage() {
  const [application, setApplication] = useState<PurchaseApplication | null>(null)
  const [paymentAddress, setPaymentAddress] = useState<PaymentAddress | null>(null)
  const [transactionId, setTransactionId] = useState("")
  const [qrCodeUrl, setQrCodeUrl] = useState("")
  const [loading, setLoading] = useState(true)
  const [submitting, setSubmitting] = useState(false)
  const [copied, setCopied] = useState(false)
  const router = useRouter()
  const params = useParams()
  const supabase = createClient()

  useEffect(() => {
    if (params.id) {
      loadApplication()
      loadPaymentAddress()
    }
  }, [params.id])

  const loadApplication = async () => {
    try {
      const {
        data: { user },
      } = await supabase.auth.getUser()
      if (!user) {
        router.push("/login")
        return
      }

      const { data, error } = await supabase
        .from("nft_purchase_applications")
        .select(`
          *,
          nfts (name, price)
        `)
        .eq("id", params.id)
        .eq("user_id", user.id)
        .single()

      if (error) throw error
      setApplication(data)
    } catch (error) {
      console.error("申請情報読み込みエラー:", error)
      router.push("/nft/purchase")
    }
  }

  const loadPaymentAddress = async () => {
    try {
      const { data, error } = await supabase
        .from("payment_addresses")
        .select("*")
        .eq("payment_method", "USDT_BEP20")
        .eq("is_active", true)
        .single()

      if (error) throw error
      setPaymentAddress(data)

      // QRコード生成
      if (data.address) {
        const qrUrl = await QRCode.toDataURL(data.address)
        setQrCodeUrl(qrUrl)
      }
    } catch (error) {
      console.error("支払いアドレス読み込みエラー:", error)
    } finally {
      setLoading(false)
    }
  }

  const copyAddress = async () => {
    if (paymentAddress?.address) {
      await navigator.clipboard.writeText(paymentAddress.address)
      setCopied(true)
      setTimeout(() => setCopied(false), 2000)
    }
  }

  const submitTransactionId = async () => {
    if (!transactionId.trim()) {
      alert("トランザクションIDを入力してください")
      return
    }

    setSubmitting(true)
    try {
      const { error } = await supabase
        .from("nft_purchase_applications")
        .update({
          payment_proof_url: transactionId.trim(),
          status: "PAYMENT_SUBMITTED",
        })
        .eq("id", params.id)

      if (error) throw error

      alert("トランザクションIDを送信しました。管理者の承認をお待ちください。")
      router.push("/dashboard")
    } catch (error) {
      console.error("トランザクションID送信エラー:", error)
      alert("送信に失敗しました。もう一度お試しください。")
    } finally {
      setSubmitting(false)
    }
  }

  if (loading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-red-900 via-black to-red-900 flex items-center justify-center">
        <Loader2 className="h-8 w-8 animate-spin text-white" />
      </div>
    )
  }

  if (!application || !paymentAddress) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-red-900 via-black to-red-900 flex items-center justify-center">
        <div className="text-center text-white">
          <p className="text-xl mb-4">申請情報が見つかりません</p>
          <Button onClick={() => router.push("/nft/purchase")} variant="outline">
            NFT購入ページに戻る
          </Button>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-red-900 via-black to-red-900 p-4">
      <div className="max-w-2xl mx-auto">
        <div className="text-center mb-8">
          <h1 className="text-3xl font-bold text-white mb-4">NFT購入申請</h1>
          <Badge variant={application.status === "PENDING" ? "destructive" : "default"}>
            {application.status === "PENDING"
              ? "支払い待ち"
              : application.status === "PAYMENT_SUBMITTED"
                ? "承認待ち"
                : application.status}
          </Badge>
        </div>

        <div className="space-y-6">
          {/* 申請情報 */}
          <Card className="bg-gray-900/80 border-red-800">
            <CardHeader>
              <CardTitle className="text-white">申請情報</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="grid grid-cols-2 gap-4 text-sm">
                <div>
                  <Label className="text-gray-400">NFT名</Label>
                  <p className="text-white font-medium">{application.nfts.name}</p>
                </div>
                <div>
                  <Label className="text-gray-400">価格</Label>
                  <p className="text-white font-medium">${application.requested_price.toLocaleString()}</p>
                </div>
                <div>
                  <Label className="text-gray-400">支払い方法</Label>
                  <p className="text-white font-medium">USDT (BEP-20)</p>
                </div>
                <div>
                  <Label className="text-gray-400">申請日時</Label>
                  <p className="text-white font-medium">{new Date(application.created_at).toLocaleString("ja-JP")}</p>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* 支払い情報 */}
          {application.status === "PENDING" && (
            <Card className="bg-gray-900/80 border-red-800">
              <CardHeader>
                <CardTitle className="text-white">支払い情報</CardTitle>
              </CardHeader>
              <CardContent className="space-y-6">
                <Alert className="bg-blue-900/50 border-blue-600">
                  <AlertDescription className="text-blue-200">
                    以下のアドレスに正確な金額のUSDT (BEP-20) を送金してください。
                    送金後、トランザクションIDを入力して送信してください。
                  </AlertDescription>
                </Alert>

                <div className="space-y-4">
                  <div>
                    <Label className="text-gray-400 mb-2 block">送金先アドレス</Label>
                    <div className="flex gap-2">
                      <Input
                        value={paymentAddress.address}
                        readOnly
                        className="bg-gray-800 border-gray-600 text-white font-mono text-sm"
                      />
                      <Button onClick={copyAddress} variant="outline" size="icon" className="border-gray-600">
                        {copied ? <Check className="h-4 w-4" /> : <Copy className="h-4 w-4" />}
                      </Button>
                    </div>
                  </div>

                  <div>
                    <Label className="text-gray-400 mb-2 block">送金金額</Label>
                    <div className="text-2xl font-bold text-green-400">{application.requested_price} USDT</div>
                  </div>

                  {qrCodeUrl && (
                    <div className="text-center">
                      <Label className="text-gray-400 mb-2 block">QRコード</Label>
                      <div className="inline-block p-4 bg-white rounded-lg">
                        <img src={qrCodeUrl || "/placeholder.svg"} alt="Payment QR Code" className="w-48 h-48" />
                      </div>
                    </div>
                  )}
                </div>

                <div className="space-y-4">
                  <div>
                    <Label htmlFor="transactionId" className="text-gray-400 mb-2 block">
                      トランザクションID
                    </Label>
                    <Input
                      id="transactionId"
                      value={transactionId}
                      onChange={(e) => setTransactionId(e.target.value)}
                      placeholder="送金後のトランザクションIDを入力してください"
                      className="bg-gray-800 border-gray-600 text-white"
                    />
                  </div>

                  <Button
                    onClick={submitTransactionId}
                    disabled={submitting || !transactionId.trim()}
                    className="w-full bg-red-600 hover:bg-red-700"
                  >
                    {submitting ? (
                      <>
                        <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                        送信中...
                      </>
                    ) : (
                      "トランザクションIDを送信"
                    )}
                  </Button>
                </div>
              </CardContent>
            </Card>
          )}

          {/* 承認待ち状態 */}
          {application.status === "PAYMENT_SUBMITTED" && (
            <Card className="bg-gray-900/80 border-yellow-600">
              <CardContent className="pt-6">
                <div className="text-center">
                  <div className="text-yellow-400 text-lg font-medium mb-2">承認待ち</div>
                  <p className="text-gray-300">管理者が送金を確認中です。承認されるまでお待ちください。</p>
                  {application.payment_proof_url && (
                    <div className="mt-4 p-3 bg-gray-800 rounded">
                      <Label className="text-gray-400 text-sm">送信済みトランザクションID:</Label>
                      <p className="text-white font-mono text-sm break-all">{application.payment_proof_url}</p>
                    </div>
                  )}
                </div>
              </CardContent>
            </Card>
          )}

          <div className="text-center">
            <Button
              onClick={() => router.push("/dashboard")}
              variant="outline"
              className="border-gray-600 text-gray-300 hover:bg-gray-800"
            >
              ダッシュボードに戻る
            </Button>
          </div>
        </div>
      </div>
    </div>
  )
}
