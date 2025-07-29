"use client"

import { useState, useEffect } from "react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Switch } from "@/components/ui/switch"
import { Textarea } from "@/components/ui/textarea"
import { ArrowLeft, Settings, Save, Loader2, Database, Shield, Globe } from "lucide-react"
import { useRouter } from "next/navigation"
import { createClient } from "@/lib/supabase/supabaseBrowserClient"

interface SystemSettings {
  maintenance_mode: boolean
  registration_enabled: boolean
  nft_purchase_enabled: boolean
  reward_claim_enabled: boolean
  system_message: string
  min_reward_claim: number
  default_payment_address: string
  company_name: string
  support_email: string
}

export default function AdminSettingsPage() {
  const [settings, setSettings] = useState<SystemSettings>({
    maintenance_mode: false,
    registration_enabled: true,
    nft_purchase_enabled: true,
    reward_claim_enabled: true,
    system_message: "",
    min_reward_claim: 50,
    default_payment_address: "",
    company_name: "SHOGUN TRADE",
    support_email: "support@shogun-trade.com",
  })
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const router = useRouter()
  const supabase = createClient()

  useEffect(() => {
    checkAdminAuth()
    loadSettings()
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

  const loadSettings = async () => {
    try {
      // 支払いアドレスを取得
      const { data: paymentAddr } = await supabase
        .from("payment_addresses")
        .select("address")
        .eq("payment_method", "USDT_BEP20")
        .eq("is_active", true)
        .single()

      setSettings((prev) => ({
        ...prev,
        default_payment_address: paymentAddr?.address || "アドレス未設定",
      }))
    } catch (error) {
      console.error("設定読み込みエラー:", error)
    } finally {
      setLoading(false)
    }
  }

  const handleSave = async () => {
    setSaving(true)
    try {
      // 支払いアドレスを更新
      if (settings.default_payment_address && settings.default_payment_address !== "アドレス未設定") {
        const { error: paymentError } = await supabase
          .from("payment_addresses")
          .update({
            address: settings.default_payment_address,
            updated_at: new Date().toISOString(),
          })
          .eq("payment_method", "USDT_BEP20")
          .eq("is_active", true)

        if (paymentError) throw paymentError
      }

      alert("設定を保存しました")
    } catch (error) {
      console.error("保存エラー:", error)
      alert("保存に失敗しました")
    } finally {
      setSaving(false)
    }
  }

  const handleInputChange = (field: keyof SystemSettings, value: any) => {
    setSettings((prev) => ({
      ...prev,
      [field]: value,
    }))
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
              <h1 className="text-2xl font-bold text-white">システム設定</h1>
              <p className="text-gray-400 text-sm">システム全体の設定管理</p>
            </div>
          </div>
          <Button onClick={handleSave} disabled={saving} className="bg-red-600 hover:bg-red-700 text-white">
            {saving ? (
              <>
                <Loader2 className="h-4 w-4 animate-spin mr-2" />
                保存中...
              </>
            ) : (
              <>
                <Save className="h-4 w-4 mr-2" />
                設定を保存
              </>
            )}
          </Button>
        </div>
      </header>

      <main className="max-w-4xl mx-auto p-6">
        <div className="space-y-6">
          {/* システム制御 */}
          <Card className="bg-gray-800 border-gray-700">
            <CardHeader>
              <CardTitle className="text-white flex items-center">
                <Shield className="mr-2 h-5 w-5" />
                システム制御
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="flex items-center justify-between p-3 bg-gray-700 rounded">
                  <div>
                    <Label className="text-white">メンテナンスモード</Label>
                    <p className="text-gray-400 text-sm">システム全体を停止します</p>
                  </div>
                  <Switch
                    checked={settings.maintenance_mode}
                    onCheckedChange={(checked) => handleInputChange("maintenance_mode", checked)}
                  />
                </div>

                <div className="flex items-center justify-between p-3 bg-gray-700 rounded">
                  <div>
                    <Label className="text-white">新規登録</Label>
                    <p className="text-gray-400 text-sm">新規ユーザー登録を許可</p>
                  </div>
                  <Switch
                    checked={settings.registration_enabled}
                    onCheckedChange={(checked) => handleInputChange("registration_enabled", checked)}
                  />
                </div>

                <div className="flex items-center justify-between p-3 bg-gray-700 rounded">
                  <div>
                    <Label className="text-white">NFT購入</Label>
                    <p className="text-gray-400 text-sm">NFT購入申請を許可</p>
                  </div>
                  <Switch
                    checked={settings.nft_purchase_enabled}
                    onCheckedChange={(checked) => handleInputChange("nft_purchase_enabled", checked)}
                  />
                </div>

                <div className="flex items-center justify-between p-3 bg-gray-700 rounded">
                  <div>
                    <Label className="text-white">報酬申請</Label>
                    <p className="text-gray-400 text-sm">エアドロップ報酬申請を許可</p>
                  </div>
                  <Switch
                    checked={settings.reward_claim_enabled}
                    onCheckedChange={(checked) => handleInputChange("reward_claim_enabled", checked)}
                  />
                </div>
              </div>
            </CardContent>
          </Card>

          {/* 基本設定 */}
          <Card className="bg-gray-800 border-gray-700">
            <CardHeader>
              <CardTitle className="text-white flex items-center">
                <Settings className="mr-2 h-5 w-5" />
                基本設定
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <Label htmlFor="company_name" className="text-white">
                    会社名
                  </Label>
                  <Input
                    id="company_name"
                    value={settings.company_name}
                    onChange={(e) => handleInputChange("company_name", e.target.value)}
                    className="bg-gray-700 border-gray-600 text-white"
                  />
                </div>

                <div>
                  <Label htmlFor="support_email" className="text-white">
                    サポートメール
                  </Label>
                  <Input
                    id="support_email"
                    type="email"
                    value={settings.support_email}
                    onChange={(e) => handleInputChange("support_email", e.target.value)}
                    className="bg-gray-700 border-gray-600 text-white"
                  />
                </div>

                <div>
                  <Label htmlFor="min_reward_claim" className="text-white">
                    最低報酬申請額 (USDT)
                  </Label>
                  <Input
                    id="min_reward_claim"
                    type="number"
                    value={settings.min_reward_claim}
                    onChange={(e) => handleInputChange("min_reward_claim", Number.parseFloat(e.target.value))}
                    className="bg-gray-700 border-gray-600 text-white"
                  />
                </div>
              </div>

              <div>
                <Label htmlFor="system_message" className="text-white">
                  システムメッセージ
                </Label>
                <Textarea
                  id="system_message"
                  value={settings.system_message}
                  onChange={(e) => handleInputChange("system_message", e.target.value)}
                  placeholder="ユーザーに表示するお知らせメッセージ"
                  className="bg-gray-700 border-gray-600 text-white"
                  rows={3}
                />
              </div>
            </CardContent>
          </Card>

          {/* 支払い設定 */}
          <Card className="bg-gray-800 border-gray-700">
            <CardHeader>
              <CardTitle className="text-white flex items-center">
                <Database className="mr-2 h-5 w-5" />
                支払い設定
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div>
                <Label htmlFor="default_payment_address" className="text-white">
                  デフォルト支払いアドレス (USDT BEP-20)
                </Label>
                <Input
                  id="default_payment_address"
                  value={settings.default_payment_address}
                  onChange={(e) => handleInputChange("default_payment_address", e.target.value)}
                  placeholder="0x..."
                  className="bg-gray-700 border-gray-600 text-white font-mono"
                />
                <p className="text-gray-400 text-sm mt-1">
                  NFT購入時にユーザーに表示される送金先アドレス（USDT BEP-20ネットワーク）
                </p>
              </div>
            </CardContent>
          </Card>

          {/* システム情報 */}
          <Card className="bg-gray-800 border-gray-700">
            <CardHeader>
              <CardTitle className="text-white flex items-center">
                <Globe className="mr-2 h-5 w-5" />
                システム情報
              </CardTitle>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-1 md:grid-cols-3 gap-4 text-sm">
                <div className="p-3 bg-gray-700 rounded">
                  <p className="text-gray-400">システムバージョン</p>
                  <p className="text-white font-medium">Phase 1.0</p>
                </div>
                <div className="p-3 bg-gray-700 rounded">
                  <p className="text-gray-400">データベース</p>
                  <p className="text-green-400 font-medium">接続中</p>
                </div>
                <div className="p-3 bg-gray-700 rounded">
                  <p className="text-gray-400">最終更新</p>
                  <p className="text-white font-medium">{new Date().toLocaleDateString("ja-JP")}</p>
                </div>
              </div>
            </CardContent>
          </Card>
        </div>
      </main>
    </div>
  )
}
