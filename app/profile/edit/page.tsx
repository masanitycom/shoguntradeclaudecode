"use client"

import type React from "react"

import { useState, useEffect } from "react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Alert, AlertDescription } from "@/components/ui/alert"
import { ArrowLeft, Save, Loader2, AlertTriangle, Info } from "lucide-react"
import { useRouter } from "next/navigation"
import { createClient } from "@/lib/supabase/supabaseBrowserClient"

interface UserProfile {
  id: string
  name: string
  email: string
  user_id: string
  phone?: string
  usdt_address?: string
  wallet_type?: string
}

export default function ProfileEditPage() {
  const [profile, setProfile] = useState<UserProfile | null>(null)
  const [formData, setFormData] = useState({
    phone: "",
    usdt_address: "",
    wallet_type: "その他",
  })
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState("")
  const [success, setSuccess] = useState("")
  const router = useRouter()
  const supabase = createClient()

  useEffect(() => {
    loadProfile()
  }, [])

  const loadProfile = async () => {
    try {
      const {
        data: { user },
      } = await supabase.auth.getUser()

      if (!user) {
        router.push("/")
        return
      }

      const { data: profileData, error } = await supabase.from("users").select("*").eq("id", user.id).single()

      if (error) throw error

      setProfile(profileData)
      setFormData({
        phone: profileData.phone || "",
        usdt_address: profileData.usdt_address || "",
        wallet_type: profileData.wallet_type || "その他",
      })
    } catch (error) {
      console.error("プロフィール読み込みエラー:", error)
      setError("プロフィール情報の読み込みに失敗しました")
    } finally {
      setLoading(false)
    }
  }

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target
    setFormData((prev) => ({
      ...prev,
      [name]: value,
    }))
  }

  const handleSelectChange = (value: string) => {
    setFormData((prev) => ({
      ...prev,
      wallet_type: value,
    }))
  }

  const validateUsdtAddress = (address: string) => {
    if (!address) return true // 空は許可
    // BEP20 (0x...) または Bitcoin形式のアドレス
    return /^0x[a-fA-F0-9]{40}$/.test(address) || /^[13][a-km-zA-HJ-NP-Z1-9]{25,34}$/.test(address)
  }

  const validatePhone = (phone: string) => {
    if (!phone) return true // 空は許可
    // 日本の電話番号形式
    return /^[0-9-+().\s]+$/.test(phone)
  }

  const handleSave = async (e: React.FormEvent) => {
    e.preventDefault()
    setSaving(true)
    setError("")
    setSuccess("")

    try {
      if (!profile) return

      // バリデーション
      if (!validateUsdtAddress(formData.usdt_address)) {
        setError("正しいウォレットアドレス形式で入力してください")
        setSaving(false)
        return
      }

      if (!validatePhone(formData.phone)) {
        setError("正しい電話番号形式で入力してください")
        setSaving(false)
        return
      }

      // usersテーブル更新（安全な項目のみ）
      const { error } = await supabase
        .from("users")
        .update({
          phone: formData.phone.trim() || null,
          usdt_address: formData.usdt_address.trim() || null,
          wallet_type: formData.wallet_type,
          updated_at: new Date().toISOString(),
        })
        .eq("id", profile.id)

      if (error) throw error

      setSuccess("プロフィールを更新しました")
      setTimeout(() => {
        router.push("/profile")
      }, 1500)
    } catch (error: any) {
      setError(error.message || "更新に失敗しました")
    } finally {
      setSaving(false)
    }
  }

  if (loading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-red-900 via-black to-red-900 flex items-center justify-center">
        <div className="text-white text-xl">読み込み中...</div>
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
          <Button onClick={() => router.push("/profile")} variant="ghost" className="text-white hover:bg-white/10">
            <ArrowLeft className="mr-2 h-4 w-4" />
            プロフィールに戻る
          </Button>
          <div className="text-2xl font-bold text-white">プロフィール編集</div>
          <div></div>
        </div>
      </header>

      {/* メインコンテンツ */}
      <main className="container mx-auto px-4 py-8">
        <div className="max-w-md mx-auto">
          <Card className="bg-gray-900/80 border-red-800">
            <CardHeader>
              <CardTitle className="text-white">基本情報の編集</CardTitle>
            </CardHeader>
            <CardContent>
              {/* 情報メッセージ */}
              <Alert className="bg-blue-900/50 border-blue-600 mb-4">
                <Info className="h-4 w-4" />
                <AlertDescription className="text-blue-200">
                  お名前・ユーザーID・メールアドレスの変更は管理者にお問い合わせください
                </AlertDescription>
              </Alert>

              <form onSubmit={handleSave} className="space-y-4">
                {error && (
                  <Alert className="bg-red-900/50 border-red-600">
                    <AlertDescription className="text-red-200">{error}</AlertDescription>
                  </Alert>
                )}

                {success && (
                  <Alert className="bg-green-900/50 border-green-600">
                    <AlertDescription className="text-green-200">{success}</AlertDescription>
                  </Alert>
                )}

                {/* お名前（編集不可） */}
                <div className="space-y-2">
                  <Label htmlFor="name" className="text-gray-400">
                    お名前（変更不可）
                  </Label>
                  <Input
                    id="name"
                    type="text"
                    value={profile.name}
                    disabled
                    className="bg-gray-700 border-gray-600 text-gray-400"
                  />
                </div>

                {/* ユーザーID（編集不可） */}
                <div className="space-y-2">
                  <Label htmlFor="user_id" className="text-gray-400">
                    ユーザーID（変更不可）
                  </Label>
                  <Input
                    id="user_id"
                    type="text"
                    value={profile.user_id}
                    disabled
                    className="bg-gray-700 border-gray-600 text-gray-400"
                  />
                </div>

                {/* メールアドレス（編集不可） */}
                <div className="space-y-2">
                  <Label htmlFor="email" className="text-gray-400 flex items-center">
                    メールアドレス（変更不可）
                    <AlertTriangle className="ml-2 h-4 w-4 text-yellow-500" />
                  </Label>
                  <Input
                    id="email"
                    type="email"
                    value={profile.email}
                    disabled
                    className="bg-gray-700 border-gray-600 text-gray-400"
                  />
                </div>

                {/* 電話番号（編集可能） */}
                <div className="space-y-2">
                  <Label htmlFor="phone" className="text-white">
                    電話番号
                  </Label>
                  <Input
                    id="phone"
                    name="phone"
                    type="tel"
                    value={formData.phone}
                    onChange={handleInputChange}
                    placeholder="090-1234-5678"
                    className="bg-gray-800 border-gray-600 text-white"
                  />
                </div>

                {/* ウォレットアドレス（編集可能） */}
                <div className="space-y-2">
                  <Label htmlFor="usdt_address" className="text-white">
                    ウォレットアドレス（USDT BEP20）
                  </Label>
                  <Input
                    id="usdt_address"
                    name="usdt_address"
                    type="text"
                    value={formData.usdt_address}
                    onChange={handleInputChange}
                    placeholder="0x..."
                    className="bg-gray-800 border-gray-600 text-white font-mono"
                  />
                  <p className="text-gray-400 text-xs">※ BEP20形式のUSDTアドレスを入力してください</p>
                </div>

                {/* ウォレットタイプ（編集可能） */}
                <div className="space-y-2">
                  <Label htmlFor="wallet_type" className="text-white">
                    ウォレットタイプ
                  </Label>
                  <Select value={formData.wallet_type} onValueChange={handleSelectChange}>
                    <SelectTrigger className="bg-gray-800 border-gray-600 text-white">
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="その他">その他</SelectItem>
                      <SelectItem value="EVO">EVO</SelectItem>
                    </SelectContent>
                  </Select>
                </div>

                <Button type="submit" disabled={saving} className="w-full bg-red-600 hover:bg-red-700 text-white">
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
              </form>
            </CardContent>
          </Card>
        </div>
      </main>
    </div>
  )
}
