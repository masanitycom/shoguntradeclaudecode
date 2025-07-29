"use client"

import { useState, useEffect } from "react"
import { useRouter, useParams } from "next/navigation"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Checkbox } from "@/components/ui/checkbox"
import { ArrowLeft, Save, Loader2, User, Mail, Phone, Wallet, Shield } from "lucide-react"
import { createClient } from "@/lib/supabase/supabaseBrowserClient"
import { useToast } from "@/hooks/use-toast"

interface UserData {
  id: string
  name: string
  email: string
  user_id: string
  phone: string
  usdt_address?: string
  wallet_type?: string
  is_admin: boolean
  created_at: string
  my_referral_code?: string
  referrer?: {
    name: string
    user_id: string
  }
}

export default function EditUserPage() {
  const router = useRouter()
  const params = useParams()
  const userId = params.userId as string
  const supabase = createClient()
  const { toast } = useToast()

  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [userData, setUserData] = useState<UserData | null>(null)
  const [formData, setFormData] = useState({
    name: "",
    email: "",
    user_id: "",
    phone: "",
    usdt_address: "",
    wallet_type: "その他",
    is_admin: false,
  })

  useEffect(() => {
    checkAdminAuth()
    loadUserData()
  }, [userId])

  const checkAdminAuth = async () => {
    const {
      data: { user },
    } = await supabase.auth.getUser()
    if (!user) {
      router.push("/login")
      return
    }

    const { data: adminData } = await supabase.from("users").select("is_admin").eq("id", user.id).single()

    if (!adminData?.is_admin) {
      router.push("/dashboard")
      return
    }
  }

  const loadUserData = async () => {
    try {
      const { data, error } = await supabase
        .from("users")
        .select(`
          *,
          referrer:referrer_id (
            name,
            user_id
          )
        `)
        .eq("id", userId)
        .single()

      if (error) throw error

      setUserData(data)
      setFormData({
        name: data.name || "",
        email: data.email || "",
        user_id: data.user_id || "",
        phone: data.phone || "",
        usdt_address: data.usdt_address || "",
        wallet_type: data.wallet_type || "その他",
        is_admin: data.is_admin || false,
      })
    } catch (error: any) {
      console.error("ユーザーデータ読み込みエラー:", error)
      toast({
        title: "エラー",
        description: "ユーザーデータの読み込みに失敗しました",
        variant: "destructive",
      })
    } finally {
      setLoading(false)
    }
  }

  const handleInputChange = (field: string, value: string | boolean) => {
    setFormData((prev) => ({ ...prev, [field]: value }))
  }

  const validateForm = () => {
    if (!formData.name.trim()) {
      toast({
        title: "入力エラー",
        description: "お名前は必須です",
        variant: "destructive",
      })
      return false
    }

    if (!formData.email.trim()) {
      toast({
        title: "入力エラー",
        description: "メールアドレスは必須です",
        variant: "destructive",
      })
      return false
    }

    if (!formData.user_id.trim()) {
      toast({
        title: "入力エラー",
        description: "ユーザーIDは必須です",
        variant: "destructive",
      })
      return false
    }

    if (!formData.phone.trim()) {
      toast({
        title: "入力エラー",
        description: "電話番号は必須です",
        variant: "destructive",
      })
      return false
    }

    return true
  }

  const handleSave = async () => {
    if (!validateForm()) return

    setSaving(true)

    try {
      // メールアドレスが変更された場合の警告
      if (formData.email !== userData?.email) {
        toast({
          title: "注意",
          description: "メールアドレスの変更は認証システムに影響する可能性があります",
          variant: "destructive",
        })
        setSaving(false)
        return
      }

      const { error } = await supabase
        .from("users")
        .update({
          name: formData.name.trim(),
          user_id: formData.user_id.trim(),
          phone: formData.phone.trim(),
          usdt_address: formData.usdt_address.trim() || null,
          wallet_type: formData.wallet_type,
          is_admin: formData.is_admin,
          updated_at: new Date().toISOString(),
        })
        .eq("id", userId)

      if (error) throw error

      toast({
        title: "成功",
        description: "ユーザー情報を更新しました",
      })

      // データを再読み込み
      loadUserData()
    } catch (error: any) {
      console.error("保存エラー:", error)
      toast({
        title: "エラー",
        description: error.message || "保存に失敗しました",
        variant: "destructive",
      })
    } finally {
      setSaving(false)
    }
  }

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-900 flex items-center justify-center">
        <Loader2 className="h-8 w-8 animate-spin text-white" />
      </div>
    )
  }

  if (!userData) {
    return (
      <div className="min-h-screen bg-gray-900 flex items-center justify-center">
        <div className="text-white text-center">
          <h1 className="text-2xl font-bold mb-4">ユーザーが見つかりません</h1>
          <Button onClick={() => router.push("/admin/users")} className="bg-red-600 hover:bg-red-700">
            ユーザー一覧に戻る
          </Button>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gray-900">
      {/* ヘッダー */}
      <header className="bg-gray-800 border-b border-red-800 px-6 py-4">
        <div className="max-w-4xl mx-auto flex justify-between items-center">
          <div className="flex items-center space-x-4">
            <Button
              onClick={() => router.push("/admin/users")}
              variant="ghost"
              className="text-white hover:bg-white/10"
            >
              <ArrowLeft className="mr-2 h-4 w-4" />
              ユーザー一覧に戻る
            </Button>
            <div>
              <h1 className="text-2xl font-bold text-white">ユーザー編集</h1>
              <p className="text-gray-400 text-sm">
                {userData.name} ({userData.user_id})
              </p>
            </div>
          </div>
          <Button onClick={handleSave} disabled={saving} className="bg-red-600 hover:bg-red-700 text-white">
            {saving ? (
              <>
                <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                保存中...
              </>
            ) : (
              <>
                <Save className="mr-2 h-4 w-4" />
                保存
              </>
            )}
          </Button>
        </div>
      </header>

      <main className="max-w-4xl mx-auto p-6">
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* 基本情報 */}
          <div className="lg:col-span-2">
            <Card className="bg-gray-800 border-gray-700">
              <CardHeader>
                <CardTitle className="text-white flex items-center">
                  <User className="mr-2 h-5 w-5" />
                  基本情報
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <Label htmlFor="name" className="text-white">
                      お名前 <span className="text-red-400">*</span>
                    </Label>
                    <Input
                      id="name"
                      value={formData.name}
                      onChange={(e) => handleInputChange("name", e.target.value)}
                      className="bg-gray-700 border-gray-600 text-white"
                    />
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="user_id" className="text-white">
                      ユーザーID <span className="text-red-400">*</span>
                    </Label>
                    <Input
                      id="user_id"
                      value={formData.user_id}
                      onChange={(e) => handleInputChange("user_id", e.target.value)}
                      className="bg-gray-700 border-gray-600 text-white"
                    />
                  </div>
                </div>

                <div className="space-y-2">
                  <Label htmlFor="email" className="text-white flex items-center">
                    <Mail className="mr-1 h-4 w-4" />
                    メールアドレス <span className="text-red-400">*</span>
                  </Label>
                  <Input
                    id="email"
                    type="email"
                    value={formData.email}
                    onChange={(e) => handleInputChange("email", e.target.value)}
                    className="bg-gray-700 border-gray-600 text-white"
                    disabled
                  />
                  <p className="text-yellow-400 text-xs">
                    ⚠️ メールアドレスの変更は認証システムに影響するため無効化されています
                  </p>
                </div>

                <div className="space-y-2">
                  <Label htmlFor="phone" className="text-white flex items-center">
                    <Phone className="mr-1 h-4 w-4" />
                    電話番号 <span className="text-red-400">*</span>
                  </Label>
                  <Input
                    id="phone"
                    value={formData.phone}
                    onChange={(e) => handleInputChange("phone", e.target.value)}
                    className="bg-gray-700 border-gray-600 text-white"
                  />
                </div>
              </CardContent>
            </Card>

            {/* ウォレット情報 */}
            <Card className="bg-gray-800 border-gray-700 mt-6">
              <CardHeader>
                <CardTitle className="text-white flex items-center">
                  <Wallet className="mr-2 h-5 w-5" />
                  ウォレット情報
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="space-y-2">
                  <Label htmlFor="usdt_address" className="text-white">
                    USDT(BEP20)アドレス
                  </Label>
                  <Input
                    id="usdt_address"
                    value={formData.usdt_address}
                    onChange={(e) => handleInputChange("usdt_address", e.target.value)}
                    placeholder="0x..."
                    className="bg-gray-700 border-gray-600 text-white"
                  />
                </div>

                <div className="space-y-2">
                  <Label htmlFor="wallet_type" className="text-white">
                    ウォレットタイプ
                  </Label>
                  <Select
                    value={formData.wallet_type}
                    onValueChange={(value) => handleInputChange("wallet_type", value)}
                  >
                    <SelectTrigger className="bg-gray-700 border-gray-600 text-white">
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent className="bg-gray-700 border-gray-600">
                      <SelectItem value="その他" className="text-white">
                        その他
                      </SelectItem>
                      <SelectItem value="EVO" className="text-white">
                        EVO
                      </SelectItem>
                    </SelectContent>
                  </Select>
                </div>
              </CardContent>
            </Card>

            {/* 権限設定 */}
            <Card className="bg-gray-800 border-gray-700 mt-6">
              <CardHeader>
                <CardTitle className="text-white flex items-center">
                  <Shield className="mr-2 h-5 w-5" />
                  権限設定
                </CardTitle>
              </CardHeader>
              <CardContent>
                <div className="flex items-center space-x-2">
                  <Checkbox
                    id="is_admin"
                    checked={formData.is_admin}
                    onCheckedChange={(checked) => handleInputChange("is_admin", checked as boolean)}
                    className="border-gray-600"
                  />
                  <Label htmlFor="is_admin" className="text-white">
                    管理者権限を付与
                  </Label>
                </div>
                <p className="text-gray-400 text-sm mt-2">
                  管理者権限を付与すると、このユーザーは管理画面にアクセスできるようになります
                </p>
              </CardContent>
            </Card>
          </div>

          {/* サイドバー情報 */}
          <div className="space-y-6">
            <Card className="bg-gray-800 border-gray-700">
              <CardHeader>
                <CardTitle className="text-white text-sm">ユーザー情報</CardTitle>
              </CardHeader>
              <CardContent className="space-y-3 text-sm">
                <div>
                  <p className="text-gray-400">登録日</p>
                  <p className="text-white">{new Date(userData.created_at).toLocaleDateString("ja-JP")}</p>
                </div>
                {userData.my_referral_code && (
                  <div>
                    <p className="text-gray-400">紹介コード</p>
                    <p className="text-white font-mono">{userData.my_referral_code}</p>
                  </div>
                )}
                {userData.referrer && (
                  <div>
                    <p className="text-gray-400">紹介者</p>
                    <p className="text-white">{userData.referrer.name}</p>
                    <p className="text-gray-400 text-xs">({userData.referrer.user_id})</p>
                  </div>
                )}
              </CardContent>
            </Card>

            <Card className="bg-gray-800 border-gray-700">
              <CardHeader>
                <CardTitle className="text-white text-sm">クイックアクション</CardTitle>
              </CardHeader>
              <CardContent className="space-y-2">
                <Button
                  onClick={() => router.push(`/admin/users/${userId}/nfts`)}
                  className="w-full bg-green-600 hover:bg-green-700 text-white"
                >
                  NFT管理
                </Button>
                <Button
                  onClick={() => router.push(`/admin/users/${userId}/history`)}
                  variant="outline"
                  className="w-full border-gray-600 text-gray-300 hover:bg-gray-600"
                >
                  取引履歴
                </Button>
              </CardContent>
            </Card>
          </div>
        </div>
      </main>
    </div>
  )
}
