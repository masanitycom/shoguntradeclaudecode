"use client"

import { useState, useEffect } from "react"
import { useRouter } from "next/navigation"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { Input } from "@/components/ui/input"
import { Share2, Users, Copy, QrCode, ArrowLeft } from "lucide-react"
import { createClient } from "@/lib/supabase/supabaseBrowserClient"
import { useToast } from "@/hooks/use-toast"

interface ReferralData {
  referral_link: string
  referral_count: number
  referrals: Array<{
    name: string
    user_id: string
    created_at: string
  }>
}

export default function ReferralsPage() {
  const [loading, setLoading] = useState(true)
  const [referralData, setReferralData] = useState<ReferralData | null>(null)
  const [showQR, setShowQR] = useState(false)
  const router = useRouter()
  const supabase = createClient()
  const { toast } = useToast()

  useEffect(() => {
    loadReferralData()
  }, [])

  const loadReferralData = async () => {
    try {
      const {
        data: { user },
      } = await supabase.auth.getUser()
      if (!user) {
        router.push("/login")
        return
      }

      // ユーザーの紹介情報を取得
      const { data: userData } = await supabase.from("users").select("referral_link").eq("id", user.id).single()

      if (!userData) {
        throw new Error("ユーザーデータが見つかりません")
      }

      // 紹介した人数を取得
      const { data: referrals, count } = await supabase
        .from("users")
        .select("name, user_id, created_at", { count: "exact" })
        .eq("referrer_id", user.id)
        .order("created_at", { ascending: false })

      setReferralData({
        referral_link: userData.referral_link || "",
        referral_count: count || 0,
        referrals: referrals || [],
      })
    } catch (error) {
      console.error("紹介データ読み込みエラー:", error)
      toast({
        title: "エラー",
        description: "紹介データの読み込みに失敗しました",
        variant: "destructive",
      })
    } finally {
      setLoading(false)
    }
  }

  const copyToClipboard = async (text: string, type: string) => {
    try {
      await navigator.clipboard.writeText(text)
      toast({
        title: "コピー完了",
        description: `${type}をクリップボードにコピーしました`,
      })
    } catch (error) {
      toast({
        title: "エラー",
        description: "コピーに失敗しました",
        variant: "destructive",
      })
    }
  }

  const generateQRCode = (text: string) => {
    const qrUrl = `https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=${encodeURIComponent(text)}`
    return qrUrl
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
            <h1 className="text-2xl font-bold text-white">紹介管理</h1>
            <p className="text-gray-400">あなたの紹介リンクを共有しましょう</p>
          </div>
        </div>
      </header>

      <main className="container mx-auto px-4 py-8">
        <div className="grid gap-6 md:grid-cols-2">
          {/* 紹介リンク */}
          <Card className="bg-gray-900/80 border-blue-800">
            <CardHeader>
              <CardTitle className="text-white flex items-center">
                <Share2 className="mr-2 h-5 w-5" />
                紹介リンク
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div>
                <label className="text-gray-400 text-sm">あなたの紹介リンク</label>
                <div className="flex space-x-2 mt-1">
                  <Input
                    value={referralData?.referral_link || ""}
                    readOnly
                    className="bg-gray-800 border-gray-700 text-white text-xs"
                  />
                  <Button
                    onClick={() => copyToClipboard(referralData?.referral_link || "", "紹介リンク")}
                    variant="outline"
                    size="sm"
                    className="border-blue-600 text-blue-400 hover:bg-blue-600 hover:text-white"
                  >
                    <Copy className="h-4 w-4" />
                  </Button>
                </div>
              </div>

              <Button onClick={() => setShowQR(!showQR)} className="w-full bg-blue-600 hover:bg-blue-700 text-white">
                <QrCode className="h-4 w-4 mr-2" />
                QRコード{showQR ? "を隠す" : "を表示"}
              </Button>

              {showQR && referralData?.referral_link && (
                <div className="text-center">
                  <img
                    src={generateQRCode(referralData.referral_link) || "/placeholder.svg"}
                    alt="紹介リンクQRコード"
                    className="mx-auto bg-white p-2 rounded"
                    crossOrigin="anonymous"
                  />
                  <p className="text-gray-400 text-xs mt-2">QRコードをスキャンして登録</p>
                </div>
              )}
            </CardContent>
          </Card>

          {/* 紹介実績 */}
          <Card className="bg-gray-900/80 border-green-800">
            <CardHeader>
              <CardTitle className="text-white flex items-center">
                <Users className="mr-2 h-5 w-5" />
                紹介実績
              </CardTitle>
            </CardHeader>
            <CardContent>
              <div className="text-center mb-4">
                <div className="text-3xl font-bold text-green-400">{referralData?.referral_count || 0}</div>
                <div className="text-gray-400">紹介した人数</div>
              </div>

              {referralData?.referrals && referralData.referrals.length > 0 ? (
                <div className="space-y-2 max-h-60 overflow-y-auto">
                  {referralData.referrals.map((referral, index) => (
                    <div key={index} className="flex justify-between items-center p-2 bg-gray-800 rounded">
                      <div>
                        <div className="text-white text-sm">{referral.name}</div>
                        <div className="text-gray-400 text-xs">ID: {referral.user_id}</div>
                      </div>
                      <div className="text-gray-400 text-xs">{new Date(referral.created_at).toLocaleDateString()}</div>
                    </div>
                  ))}
                </div>
              ) : (
                <div className="text-center text-gray-400">まだ紹介実績がありません</div>
              )}
            </CardContent>
          </Card>
        </div>

        {/* MLMランク情報 */}
        <Card className="bg-gray-900/80 border-yellow-800 mt-6">
          <CardHeader>
            <CardTitle className="text-white">MLMランク進捗</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="flex items-center justify-between">
              <div>
                <Badge variant="outline" className="border-yellow-600 text-yellow-400">
                  現在のランク: なし
                </Badge>
                <p className="text-gray-400 text-sm mt-2">足軽ランクまで: NFT1000 + 組織1,000が必要</p>
              </div>
              <div className="text-right">
                <div className="text-yellow-400 font-bold">0%</div>
                <div className="text-gray-400 text-sm">達成率</div>
              </div>
            </div>
          </CardContent>
        </Card>
      </main>
    </div>
  )
}
