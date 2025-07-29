"use client"

import { useState, useEffect } from "react"
import { useRouter } from "next/navigation"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Textarea } from "@/components/ui/textarea"
import { ArrowLeft, ShoppingCart, Loader2, Copy, ExternalLink } from "lucide-react"
import { createClient } from "@/lib/supabase/supabaseBrowserClient"
import { useToast } from "@/hooks/use-toast"
import { QRCodeSVG } from "qrcode.react"

interface NFT {
  id: string
  name: string
  price: string
  daily_rate_limit: string
  is_special: boolean
  is_active: boolean
}

export default function NFTPurchasePage() {
  const [nfts, setNfts] = useState<NFT[]>([])
  const [selectedNFT, setSelectedNFT] = useState<NFT | null>(null)
  const [loading, setLoading] = useState(true)
  const [submitting, setSubmitting] = useState(false)
  const [user, setUser] = useState<any>(null)
  const [formData, setFormData] = useState({
    payment_method: "USDT",
    transaction_hash: "",
    notes: "",
  })
  const [paymentAddress, setPaymentAddress] = useState<string>("")
  const router = useRouter()
  const supabase = createClient()
  const { toast } = useToast()

  useEffect(() => {
    checkAuth()
    loadNFTs()
    loadPaymentAddress()
  }, [])

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

  const loadNFTs = async () => {
    try {
      const { data, error } = await supabase
        .from("nfts")
        .select("*")
        .eq("is_active", true)
        .eq("is_special", false) // 通常NFTのみ表示
        .order("price", { ascending: true })

      if (error) throw error
      setNfts(data || [])
    } catch (error) {
      console.error("NFT読み込みエラー:", error)
      toast({
        title: "エラー",
        description: "NFTデータの読み込みに失敗しました",
        variant: "destructive",
      })
    } finally {
      setLoading(false)
    }
  }

  const loadPaymentAddress = async () => {
    try {
      const { data, error } = await supabase
        .from("payment_addresses")
        .select("address")
        .eq("payment_method", "USDT_BEP20")
        .eq("is_active", true)
        .single()

      if (error) throw error
      setPaymentAddress(data?.address || "アドレス未設定")
    } catch (error) {
      console.error("支払いアドレス読み込みエラー:", error)
      setPaymentAddress("アドレス未設定")
    }
  }

  const copyAddress = () => {
    navigator.clipboard.writeText(paymentAddress)
    toast({
      title: "コピー完了",
      description: "送金先アドレスをクリップボードにコピーしました",
    })
  }

  const handleSubmit = async () => {
    if (!selectedNFT || !user || !formData.transaction_hash.trim()) {
      toast({
        title: "エラー",
        description: "NFTを選択し、トランザクションハッシュを入力してください",
        variant: "destructive",
      })
      return
    }

    setSubmitting(true)
    try {
      const { error } = await supabase.from("nft_purchase_applications").insert({
        user_id: user.id,
        nft_id: selectedNFT.id,
        requested_price: Number.parseFloat(selectedNFT.price),
        payment_method: formData.payment_method,
        transaction_hash: formData.transaction_hash.trim(),
        notes: formData.notes.trim(),
        status: "PENDING",
      })

      if (error) throw error

      toast({
        title: "申請完了",
        description: "NFT購入申請が完了しました。管理者の承認をお待ちください。",
      })

      router.push("/dashboard")
    } catch (error) {
      console.error("購入申請エラー:", error)
      toast({
        title: "エラー",
        description: "購入申請に失敗しました。もう一度お試しください。",
        variant: "destructive",
      })
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
            <h1 className="text-2xl font-bold text-white">NFT購入申請</h1>
            <p className="text-gray-400">お好みのNFTを選択して購入申請を行ってください</p>
          </div>
        </div>
      </header>

      <main className="container mx-auto px-4 py-8">
        <div className="grid gap-6 lg:grid-cols-2">
          {/* NFT選択 */}
          <div>
            <h2 className="text-xl font-bold text-white mb-4">NFTを選択</h2>
            <div className="grid gap-4">
              {nfts.map((nft) => (
                <Card
                  key={nft.id}
                  className={`cursor-pointer transition-all ${
                    selectedNFT?.id === nft.id
                      ? "bg-blue-900/50 border-blue-600"
                      : "bg-gray-900/80 border-gray-700 hover:border-gray-600"
                  }`}
                  onClick={() => setSelectedNFT(nft)}
                >
                  <CardContent className="p-4">
                    <div className="flex justify-between items-center">
                      <div>
                        <h3 className="text-white font-medium">{nft.name}</h3>
                        <p className="text-gray-400 text-sm">日利上限: {Number(nft.daily_rate_limit).toFixed(2)}%</p>
                      </div>
                      <div className="text-right">
                        <div className="text-2xl font-bold text-green-400">${Number(nft.price).toLocaleString()}</div>
                        <Badge variant="outline" className="border-green-600 text-green-400">
                          通常NFT
                        </Badge>
                      </div>
                    </div>
                  </CardContent>
                </Card>
              ))}
            </div>
          </div>

          {/* 購入申請フォーム */}
          <div>
            {/* 送金先アドレス表示 */}
            <div className="mb-6">
              <Card className="bg-blue-900/20 border-blue-600">
                <CardHeader>
                  <CardTitle className="text-blue-400 flex items-center">
                    <ExternalLink className="mr-2 h-5 w-5" />
                    送金先アドレス (USDT BEP-20)
                  </CardTitle>
                </CardHeader>
                <CardContent className="space-y-4">
                  <div className="flex items-center space-x-4">
                    <div className="flex-1">
                      <div className="bg-gray-800 p-3 rounded border border-gray-700">
                        <p className="text-white font-mono text-sm break-all">{paymentAddress}</p>
                      </div>
                      <Button
                        onClick={copyAddress}
                        variant="outline"
                        size="sm"
                        className="mt-2 border-blue-600 text-blue-400 hover:bg-blue-600 hover:text-white"
                        disabled={paymentAddress === "アドレス未設定"}
                      >
                        <Copy className="mr-2 h-4 w-4" />
                        アドレスをコピー
                      </Button>
                    </div>
                    {paymentAddress !== "アドレス未設定" && (
                      <div className="bg-white p-2 rounded">
                        <QRCodeSVG value={paymentAddress} size={120} level="M" />
                      </div>
                    )}
                  </div>
                  <div className="text-yellow-400 text-sm">⚠️ 必ずBEP-20ネットワークでUSDTを送金してください</div>
                </CardContent>
              </Card>
            </div>

            <h2 className="text-xl font-bold text-white mb-4">購入申請フォーム</h2>
            <Card className="bg-gray-900/80 border-gray-700">
              <CardHeader>
                <CardTitle className="text-white">{selectedNFT ? selectedNFT.name : "NFTを選択してください"}</CardTitle>
                {selectedNFT && (
                  <p className="text-green-400 text-xl font-bold">${Number(selectedNFT.price).toLocaleString()}</p>
                )}
              </CardHeader>
              <CardContent className="space-y-4">
                <div>
                  <Label htmlFor="payment_method" className="text-gray-400">
                    支払い方法
                  </Label>
                  <Input
                    id="payment_method"
                    value={formData.payment_method}
                    readOnly
                    className="bg-gray-800 border-gray-700 text-white"
                  />
                </div>

                <div>
                  <Label htmlFor="transaction_hash" className="text-gray-400">
                    トランザクションハッシュ *
                  </Label>
                  <Input
                    id="transaction_hash"
                    value={formData.transaction_hash}
                    onChange={(e) => setFormData({ ...formData, transaction_hash: e.target.value })}
                    placeholder="0x..."
                    className="bg-gray-800 border-gray-700 text-white"
                  />
                  <p className="text-gray-500 text-xs mt-1">支払い完了後のトランザクションハッシュを入力してください</p>
                </div>

                <div>
                  <Label htmlFor="notes" className="text-gray-400">
                    備考
                  </Label>
                  <Textarea
                    id="notes"
                    value={formData.notes}
                    onChange={(e) => setFormData({ ...formData, notes: e.target.value })}
                    placeholder="その他の情報があれば入力してください"
                    className="bg-gray-800 border-gray-700 text-white"
                    rows={3}
                  />
                </div>

                <Button
                  onClick={handleSubmit}
                  disabled={!selectedNFT || submitting || !formData.transaction_hash.trim()}
                  className="w-full bg-red-600 hover:bg-red-700 text-white"
                >
                  {submitting ? (
                    <>
                      <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                      申請中...
                    </>
                  ) : (
                    <>
                      <ShoppingCart className="mr-2 h-4 w-4" />
                      購入申請を送信
                    </>
                  )}
                </Button>
              </CardContent>
            </Card>
          </div>
        </div>
      </main>
    </div>
  )
}
