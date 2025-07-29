"use client"

import { useState, useEffect } from "react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { ArrowLeft, Edit, User, Mail, Calendar, Hash, Wallet, Share, Copy, Check } from "lucide-react"
import { useRouter } from "next/navigation"
import { createClient } from "@/lib/supabase/supabaseBrowserClient"
import { useToast } from "@/hooks/use-toast"
import QRCode from "qrcode"

interface UserProfile {
  id: string
  name: string
  email: string
  user_id: string
  phone: string
  referrer_id?: string
  my_referral_code?: string
  referral_link?: string
  usdt_address?: string
  wallet_type?: string
  created_at: string
  is_admin: boolean
  referrer?: {
    name: string
    user_id: string
  }
}

interface UserNFT {
  id: string
  current_investment: number
  total_earned: number
  max_earning: number
  purchase_date: string
  nfts: {
    name: string
    price: number
    daily_rate_limit: number
  }
}

export default function ProfilePage() {
  const [profile, setProfile] = useState<UserProfile | null>(null)
  const [userNft, setUserNft] = useState<UserNFT | null>(null)
  const [loading, setLoading] = useState(true)
  const [qrCodeUrl, setQrCodeUrl] = useState("")
  const [copied, setCopied] = useState("")
  const [error, setError] = useState<string | null>(null)
  const router = useRouter()
  const supabase = createClient()
  const { toast } = useToast()

  useEffect(() => {
    loadProfile()

    // リアルタイム更新の設定
    const channel = supabase
      .channel("profile-changes")
      .on(
        "postgres_changes",
        {
          event: "UPDATE",
          schema: "public",
          table: "users",
        },
        (payload) => {
          // 現在のユーザーの更新のみ処理
          if (payload.new.id === profile?.id) {
            setProfile((prev) => (prev ? { ...prev, ...payload.new } : null))
          }
        },
      )
      .subscribe()

    return () => {
      supabase.removeChannel(channel)
    }
  }, [profile?.id])

  const loadProfile = async () => {
    try {
      setLoading(true)
      setError(null)

      const {
        data: { user },
      } = await supabase.auth.getUser()

      if (!user) {
        router.push("/")
        return
      }

      // プロフィール情報を取得（紹介者情報も含む）- 重複対策
      const { data: profileDataArray, error: profileError } = await supabase
        .from("users")
        .select(`
          *,
          referrer:referrer_id (
            name,
            user_id
          )
        `)
        .eq("id", user.id)
        .order("created_at", { ascending: false })

      if (profileError) {
        console.error("プロフィール取得エラー:", profileError)
        setError(`プロフィール取得エラー: ${profileError.message}`)
        return
      }

      if (!profileDataArray || profileDataArray.length === 0) {
        setError("プロフィールが見つかりません")

        // プロフィールが見つからない場合、基本的なプロフィールを作成
        const defaultProfile: UserProfile = {
          id: user.id,
          name: user.email?.split("@")[0] || "ユーザー",
          email: user.email || "unknown",
          user_id: "unknown",
          phone: "",
          created_at: new Date().toISOString(),
          is_admin: false,
        }
        setProfile(defaultProfile)
        return
      }

      // 複数のレコードがある場合は最新のものを使用
      const profileData = profileDataArray[0]

      // 紹介コードと紹介リンクを user_id ベースで正しく設定
      const correctReferralCode = profileData.user_id
      const correctReferralLink = `https://shogun-trade.vercel.app/register?ref=${correctReferralCode}`

      // データベースの値が間違っている場合は修正
      if (profileData.my_referral_code !== correctReferralCode || profileData.referral_link !== correctReferralLink) {
        // データベースを正しい値で更新
        const { error: updateError } = await supabase
          .from("users")
          .update({
            my_referral_code: correctReferralCode,
            referral_link: correctReferralLink,
          })
          .eq("id", user.id)

        if (updateError) {
          console.error("紹介コード更新エラー:", updateError)
        }
      }

      const updatedProfile = {
        ...profileData,
        my_referral_code: correctReferralCode,
        referral_link: correctReferralLink,
      }

      setProfile(updatedProfile)

      // 紹介リンクのQRコード生成
      if (correctReferralLink) {
        try {
          const qrUrl = await QRCode.toDataURL(correctReferralLink)
          setQrCodeUrl(qrUrl)
        } catch (qrError) {
          console.error("QRコード生成エラー:", qrError)
        }
      }

      // NFT情報を取得
      const { data: nftData, error: nftError } = await supabase
        .from("user_nfts")
        .select(`
          *,
          nfts (name, price, daily_rate_limit)
        `)
        .eq("user_id", user.id)
        .eq("is_active", true)
        .order("created_at", { ascending: false })
        .limit(1)

      if (nftError && nftError.code !== "PGRST116") {
        console.error("NFT取得エラー:", nftError)
      } else if (nftData && nftData.length > 0) {
        setUserNft(nftData[0])
      }
    } catch (error) {
      console.error("プロフィール読み込みエラー:", error)
      const errorMessage = error instanceof Error ? error.message : "プロフィールの読み込みに失敗しました"
      setError(errorMessage)
    } finally {
      setLoading(false)
    }
  }

  const copyToClipboard = async (text: string, type: string) => {
    try {
      await navigator.clipboard.writeText(text)
      setCopied(type)
      setTimeout(() => setCopied(""), 2000)

      toast({
        title: "コピーしました",
        description: `${type}をクリップボードにコピーしました`,
      })
    } catch (error) {
      toast({
        title: "コピーに失敗しました",
        description: "クリップボードへのアクセスに失敗しました",
        variant: "destructive",
      })
    }
  }

  if (loading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-red-900 via-black to-red-900 flex items-center justify-center">
        <div className="text-white text-xl">読み込み中...</div>
      </div>
    )
  }

  if (error) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-red-900 via-black to-red-900">
        <div className="container mx-auto px-4 py-8">
          <Card className="bg-red-900/50 border-red-600 mb-6">
            <CardContent className="p-4">
              <p className="text-red-200">⚠️ {error}</p>
              <Button onClick={() => router.push("/dashboard")} className="mt-4 bg-red-600 hover:bg-red-700">
                ダッシュボードに戻る
              </Button>
            </CardContent>
          </Card>
        </div>
      </div>
    )
  }

  if (!profile) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-red-900 via-black to-red-900 flex items-center justify-center">
        <div className="text-white text-xl">プロフィールが見つかりません</div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-red-900 via-black to-red-900">
      {/* ヘッダー */}
      <header className="container mx-auto px-4 py-6">
        <div className="flex justify-between items-center">
          <Button onClick={() => router.push("/dashboard")} variant="ghost" className="text-white hover:bg-white/10">
            <ArrowLeft className="mr-2 h-4 w-4" />
            ダッシュボードに戻る
          </Button>
          <div className="text-2xl font-bold text-white">プロフィール</div>
          <div></div>
        </div>
      </header>

      {/* メインコンテンツ */}
      <main className="container mx-auto px-4 py-8">
        <div className="grid gap-6 md:grid-cols-2">
          {/* 基本情報 */}
          <Card className="bg-gray-900/80 border-red-800">
            <CardHeader className="flex flex-row items-center justify-between">
              <CardTitle className="text-white flex items-center">
                <User className="mr-2 h-5 w-5" />
                基本情報
              </CardTitle>
              <Button
                onClick={() => router.push("/profile/edit")}
                size="sm"
                className="bg-red-600 hover:bg-red-700 text-white"
              >
                <Edit className="mr-1 h-4 w-4" />
                編集
              </Button>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="flex items-center space-x-3">
                <User className="h-5 w-5 text-gray-400" />
                <div>
                  <p className="text-gray-400 text-sm">お名前</p>
                  <p className="text-white font-medium">{profile.name}</p>
                </div>
              </div>

              <div className="flex items-center space-x-3">
                <Hash className="h-5 w-5 text-gray-400" />
                <div>
                  <p className="text-gray-400 text-sm">電話番号</p>
                  <p className="text-white font-medium">{profile.phone || "未設定"}</p>
                </div>
              </div>

              <div className="flex items-center space-x-3">
                <Hash className="h-5 w-5 text-gray-400" />
                <div>
                  <p className="text-gray-400 text-sm">ユーザーID</p>
                  <p className="text-white font-medium">{profile.user_id}</p>
                </div>
              </div>

              <div className="flex items-center space-x-3">
                <Mail className="h-5 w-5 text-gray-400" />
                <div>
                  <p className="text-gray-400 text-sm">メールアドレス</p>
                  <p className="text-white font-medium">{profile.email}</p>
                </div>
              </div>

              {/* USDT(BEP20)アドレス */}
              {profile.usdt_address && (
                <div className="flex items-start space-x-3">
                  <Wallet className="h-5 w-5 text-gray-400 mt-1" />
                  <div className="flex-1 min-w-0">
                    <p className="text-gray-400 text-sm">USDT(BEP20)アドレス</p>
                    <div className="flex items-center space-x-2">
                      <p className="text-white font-medium font-mono text-sm break-all">{profile.usdt_address}</p>
                      <Button
                        onClick={() => copyToClipboard(profile.usdt_address!, "USDTアドレス")}
                        size="sm"
                        variant="outline"
                        className="border-gray-600 text-gray-400 hover:bg-gray-600 flex-shrink-0"
                      >
                        {copied === "USDTアドレス" ? <Check className="h-4 w-4" /> : <Copy className="h-4 w-4" />}
                      </Button>
                    </div>
                  </div>
                </div>
              )}

              {/* ウォレットタイプ */}
              <div className="flex items-center space-x-3">
                <Wallet className="h-5 w-5 text-gray-400" />
                <div>
                  <p className="text-gray-400 text-sm">ウォレットタイプ</p>
                  <div className="flex items-center space-x-2">
                    <p className="text-white font-medium">{profile.wallet_type || "未設定"}</p>
                    {profile.wallet_type === "EVO" && <Badge className="bg-purple-600 text-white text-xs">EVO</Badge>}
                  </div>
                </div>
              </div>

              <div className="flex items-center space-x-3">
                <Calendar className="h-5 w-5 text-gray-400" />
                <div>
                  <p className="text-gray-400 text-sm">登録日</p>
                  <p className="text-white font-medium">{new Date(profile.created_at).toLocaleDateString("ja-JP")}</p>
                </div>
              </div>

              {profile.referrer && (
                <div className="flex items-center space-x-3">
                  <Hash className="h-5 w-5 text-gray-400" />
                  <div>
                    <p className="text-gray-400 text-sm">紹介者</p>
                    <p className="text-white font-medium">
                      {profile.referrer.name} ({profile.referrer.user_id})
                    </p>
                  </div>
                </div>
              )}

              {!profile.referrer && !profile.is_admin && (
                <div className="flex items-center space-x-3">
                  <Hash className="h-5 w-5 text-red-400" />
                  <div>
                    <p className="text-red-400 text-sm">⚠️ 紹介者情報</p>
                    <p className="text-red-300 font-medium">紹介者が設定されていません</p>
                  </div>
                </div>
              )}

              {profile.is_admin && (
                <div className="pt-2">
                  <Badge className="bg-yellow-600">管理者</Badge>
                </div>
              )}
            </CardContent>
          </Card>

          {/* 紹介システム */}
          <Card className="bg-gray-900/80 border-green-800">
            <CardHeader>
              <CardTitle className="text-white flex items-center">
                <Share className="mr-2 h-5 w-5" />
                紹介システム
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              {profile.my_referral_code && (
                <div>
                  <p className="text-gray-400 text-sm mb-2">あなたの紹介コード</p>
                  <div className="flex items-center space-x-2">
                    <div className="bg-gray-800 px-3 py-2 rounded font-mono text-white text-lg">
                      {profile.my_referral_code}
                    </div>
                    <Button
                      onClick={() => copyToClipboard(profile.my_referral_code!, "紹介コード")}
                      size="sm"
                      variant="outline"
                      className="border-green-600 text-green-400 hover:bg-green-600 hover:text-white"
                    >
                      {copied === "紹介コード" ? <Check className="h-4 w-4" /> : <Copy className="h-4 w-4" />}
                    </Button>
                  </div>
                </div>
              )}

              {profile.referral_link && (
                <div>
                  <p className="text-gray-400 text-sm mb-2">紹介リンク</p>
                  <div className="flex items-center space-x-2 mb-3">
                    <div className="bg-gray-800 px-3 py-2 rounded text-white text-sm break-all flex-1">
                      {profile.referral_link}
                    </div>
                    <Button
                      onClick={() => copyToClipboard(profile.referral_link!, "紹介リンク")}
                      size="sm"
                      variant="outline"
                      className="border-green-600 text-green-400 hover:bg-green-600 hover:text-white"
                    >
                      {copied === "紹介リンク" ? <Check className="h-4 w-4" /> : <Copy className="h-4 w-4" />}
                    </Button>
                  </div>

                  {qrCodeUrl && (
                    <div className="text-center">
                      <p className="text-gray-400 text-sm mb-2">QRコード</p>
                      <div className="inline-block p-3 bg-white rounded-lg">
                        <img src={qrCodeUrl || "/placeholder.svg"} alt="Referral QR Code" className="w-32 h-32" />
                      </div>
                    </div>
                  )}
                </div>
              )}

              <div className="bg-gray-800 p-3 rounded">
                <p className="text-gray-400 text-sm mb-1">MLMランクシステム</p>
                <p className="text-green-400 font-medium">紹介者のMLMランクに応じて天下統一ボーナスを獲得</p>
                <p className="text-gray-400 text-xs mt-1">
                  ※天下統一ボーナスは会社週間利益の20%をMLMランク保有者に分配
                </p>
              </div>
            </CardContent>
          </Card>

          {/* NFT情報 */}
          <Card className="bg-gray-900/80 border-blue-800 md:col-span-2">
            <CardHeader>
              <CardTitle className="text-white">NFT保有状況</CardTitle>
            </CardHeader>
            <CardContent>
              {userNft ? (
                <div className="space-y-4">
                  <div>
                    <h3 className="text-lg font-medium text-white mb-2">{userNft.nfts.name}</h3>
                    <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-sm">
                      <div>
                        <p className="text-gray-400">投資額</p>
                        <p className="text-white font-medium">${Number(userNft.current_investment).toLocaleString()}</p>
                      </div>
                      <div>
                        <p className="text-gray-400">累積収益</p>
                        <p className="text-green-400 font-medium">${Number(userNft.total_earned).toFixed(2)}</p>
                      </div>
                      <div>
                        <p className="text-gray-400">収益上限</p>
                        <p className="text-white font-medium">${Number(userNft.max_earning).toFixed(2)}</p>
                      </div>
                      <div>
                        <p className="text-gray-400">日利上限</p>
                        <p className="text-blue-400 font-medium">
                          {(Number(userNft.nfts.daily_rate_limit) * 100).toFixed(1)}%
                        </p>
                      </div>
                    </div>
                    <div className="mt-4">
                      <p className="text-gray-400 text-sm mb-1">収益進捗</p>
                      <div className="w-full bg-gray-700 rounded-full h-2">
                        <div
                          className="bg-gradient-to-r from-green-500 to-red-500 h-2 rounded-full"
                          style={{
                            width: `${Math.min((Number(userNft.total_earned) / Number(userNft.max_earning)) * 100, 100)}%`,
                          }}
                        ></div>
                      </div>
                      <p className="text-gray-400 text-sm mt-1">
                        {((Number(userNft.total_earned) / Number(userNft.max_earning)) * 100).toFixed(1)}% 完了
                      </p>
                    </div>
                  </div>
                </div>
              ) : (
                <div className="text-center py-8">
                  <p className="text-gray-400 mb-4">NFTを保有していません</p>
                  <Button
                    onClick={() => router.push("/nft/purchase")}
                    className="bg-red-600 hover:bg-red-700 text-white"
                  >
                    NFTを購入する
                  </Button>
                </div>
              )}
            </CardContent>
          </Card>
        </div>
      </main>
    </div>
  )
}
