"use client"

import type React from "react"

import { useState } from "react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Alert, AlertDescription } from "@/components/ui/alert"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Loader2, ArrowLeft, CheckCircle, XCircle } from "lucide-react"
import { useRouter } from "next/navigation"
import { createClient } from "@/lib/supabase/supabaseBrowserClient"
import { useToast } from "@/hooks/use-toast"
import Link from "next/link"

interface RegisterForm {
  name: string
  email: string
  password: string
  confirmPassword: string
  userId: string
  phone: string
  referrerId: string
  usdtAddress: string
  walletType: string
}

interface ValidationErrors {
  name?: string
  userId?: string
  email?: string
  password?: string
  confirmPassword?: string
  phone?: string
  referrerId?: string
  usdtAddress?: string
}

export default function RegisterPage() {
  const [formData, setFormData] = useState<RegisterForm>({
    name: "",
    email: "",
    password: "",
    confirmPassword: "",
    userId: "",
    phone: "",
    referrerId: "",
    usdtAddress: "",
    walletType: "その他",
  })
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState("")
  const [success, setSuccess] = useState("")
  const [validationErrors, setValidationErrors] = useState<ValidationErrors>({})
  const [referrerExists, setReferrerExists] = useState<boolean | null>(null)
  const router = useRouter()
  const supabase = createClient()
  const { toast } = useToast()

  // バリデーション関数
  const validateKatakanaAndNumbers = (value: string) => {
    return /^[ァ-ヶー0-9]+$/.test(value)
  }

  const validateAlphanumeric = (value: string) => {
    return /^[a-zA-Z0-9]+$/.test(value)
  }

  const validateEmail = (value: string) => {
    return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value)
  }

  const validatePhone = (value: string) => {
    return /^[0-9-]+$/.test(value)
  }

  const validateUsdtAddress = (value: string) => {
    return /^0x[a-fA-F0-9]{40}$/.test(value) || /^[13][a-km-zA-HJ-NP-Z1-9]{25,34}$/.test(value)
  }

  // リアルタイムバリデーション
  const validateField = async (field: keyof RegisterForm, value: string) => {
    const errors: ValidationErrors = { ...validationErrors }

    switch (field) {
      case "name":
        if (!value) {
          errors.name = "お名前は必須です"
        } else if (!validateKatakanaAndNumbers(value)) {
          errors.name = "カタカナと数字のみ入力可能です"
        } else {
          delete errors.name
        }
        break

      case "userId":
        if (!value) {
          errors.userId = "ユーザーIDは必須です"
        } else if (!validateAlphanumeric(value)) {
          errors.userId = "英数字のみ入力可能です"
        } else {
          // 重複チェック
          const { data } = await supabase.from("users").select("id").eq("user_id", value).single()
          if (data) {
            errors.userId = "このユーザーIDは既に使用されています"
          } else {
            delete errors.userId
          }
        }
        break

      case "email":
        if (!value) {
          errors.email = "メールアドレスは必須です"
        } else if (!validateEmail(value)) {
          errors.email = "正しいメールアドレスを入力してください"
        } else {
          // 重複チェック
          const { data } = await supabase.from("users").select("id").eq("email", value).single()
          if (data) {
            errors.email = "このメールアドレスは既に使用されています"
          } else {
            delete errors.email
          }
        }
        break

      case "password":
        if (!value) {
          errors.password = "パスワードは必須です"
        } else if (value.length < 6) {
          errors.password = "パスワードは6文字以上で入力してください"
        } else {
          delete errors.password
        }
        break

      case "confirmPassword":
        if (!value) {
          errors.confirmPassword = "パスワード確認は必須です"
        } else if (value !== formData.password) {
          errors.confirmPassword = "パスワードが一致しません"
        } else {
          delete errors.confirmPassword
        }
        break

      case "phone":
        if (!value) {
          errors.phone = "電話番号は必須です"
        } else if (!validatePhone(value)) {
          errors.phone = "正しい電話番号を入力してください"
        } else {
          delete errors.phone
        }
        break

      case "referrerId":
        if (!value) {
          errors.referrerId = "紹介者IDは必須です"
          setReferrerExists(null)
        } else {
          // 紹介者存在チェック（名前は取得しない）
          const { data } = await supabase.from("users").select("id").eq("user_id", value).single()
          if (data) {
            setReferrerExists(true)
            delete errors.referrerId
          } else {
            errors.referrerId = "指定された紹介者IDが見つかりません"
            setReferrerExists(false)
          }
        }
        break

      case "usdtAddress":
        if (value && !validateUsdtAddress(value)) {
          errors.usdtAddress = "正しいUSDTアドレスを入力してください"
        } else {
          delete errors.usdtAddress
        }
        break
    }

    setValidationErrors(errors)
  }

  const handleInputChange = async (field: keyof RegisterForm, value: string) => {
    setFormData((prev) => ({ ...prev, [field]: value }))
    await validateField(field, value)
  }

  const handleRegister = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)
    setError("")
    setSuccess("")

    try {
      // 最終バリデーション
      const hasErrors = Object.keys(validationErrors).length > 0
      if (hasErrors) {
        setError("入力内容を確認してください")
        return
      }

      // 紹介者IDを取得
      const { data: referrerData } = await supabase
        .from("users")
        .select("id")
        .eq("user_id", formData.referrerId)
        .single()

      if (!referrerData) {
        setError("紹介者が見つかりません")
        return
      }

      // Supabase認証でユーザー作成
      const { data, error: authError } = await supabase.auth.signUp({
        email: formData.email,
        password: formData.password,
        options: {
          data: {
            name: formData.name,
            user_id: formData.userId,
            phone: formData.phone,
          },
        },
      })

      if (authError) throw authError

      if (data.user) {
        // usersテーブルにユーザー情報を挿入（紹介リンクも自動生成）
        const baseUrl =
          process.env.NODE_ENV === "production" ? "https://shogun-trade.vercel.app" : "http://localhost:3000"

        const { error: insertError } = await supabase.from("users").insert({
          id: data.user.id,
          name: formData.name,
          email: formData.email,
          user_id: formData.userId,
          phone: formData.phone,
          referrer_id: referrerData.id,
          usdt_address: formData.usdtAddress || null,
          wallet_type: formData.walletType,
          is_admin: false,
          referral_link: `${baseUrl}/register?ref=${formData.userId}`, // 🆕 紹介リンク自動生成
        })

        if (insertError) throw insertError

        setSuccess("登録が完了しました！ログインしてください。")
        setTimeout(() => {
          router.push("/login")
        }, 2000)
      }
    } catch (error: any) {
      setError(error.message || "登録に失敗しました")
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-red-900 via-black to-red-900 flex items-center justify-center p-4">
      <div className="w-full max-w-md">
        <div className="mb-6">
          <Link href="/">
            <Button variant="ghost" className="text-white hover:bg-white/10">
              <ArrowLeft className="mr-2 h-4 w-4" />
              戻る
            </Button>
          </Link>
        </div>

        <Card className="bg-gray-900/80 border-red-800">
          <CardHeader className="text-center">
            <CardTitle className="text-2xl font-bold text-white">新規登録</CardTitle>
            <CardDescription className="text-gray-300">SHOGUN TRADEのアカウントを作成してください</CardDescription>
          </CardHeader>
          <CardContent>
            <form onSubmit={handleRegister} className="space-y-4">
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

              {/* お名前 */}
              <div className="space-y-2">
                <Label htmlFor="name" className="text-white">
                  お名前（カタカナ）<span className="text-red-400">*</span>
                </Label>
                <Input
                  id="name"
                  name="name"
                  type="text"
                  value={formData.name}
                  onChange={(e) => handleInputChange("name", e.target.value)}
                  placeholder="ヤマダタロウ"
                  required
                  className="bg-gray-800 border-gray-600 text-white placeholder-gray-400"
                />
                {validationErrors.name && (
                  <p className="text-red-400 text-sm flex items-center">
                    <XCircle className="h-4 w-4 mr-1" />
                    {validationErrors.name}
                  </p>
                )}
              </div>

              {/* ユーザーID */}
              <div className="space-y-2">
                <Label htmlFor="userId" className="text-white">
                  ユーザーID（英数字）<span className="text-red-400">*</span>
                </Label>
                <Input
                  id="userId"
                  name="userId"
                  type="text"
                  value={formData.userId}
                  onChange={(e) => handleInputChange("userId", e.target.value)}
                  placeholder="user123"
                  required
                  className="bg-gray-800 border-gray-600 text-white placeholder-gray-400"
                />
                {validationErrors.userId && (
                  <p className="text-red-400 text-sm flex items-center">
                    <XCircle className="h-4 w-4 mr-1" />
                    {validationErrors.userId}
                  </p>
                )}
              </div>

              {/* メールアドレス */}
              <div className="space-y-2">
                <Label htmlFor="email" className="text-white">
                  メールアドレス<span className="text-red-400">*</span>
                </Label>
                <Input
                  id="email"
                  name="email"
                  type="email"
                  value={formData.email}
                  onChange={(e) => handleInputChange("email", e.target.value)}
                  placeholder="your@email.com"
                  required
                  className="bg-gray-800 border-gray-600 text-white placeholder-gray-400"
                />
                {validationErrors.email && (
                  <p className="text-red-400 text-sm flex items-center">
                    <XCircle className="h-4 w-4 mr-1" />
                    {validationErrors.email}
                  </p>
                )}
              </div>

              {/* パスワード */}
              <div className="space-y-2">
                <Label htmlFor="password" className="text-white">
                  パスワード<span className="text-red-400">*</span>
                </Label>
                <Input
                  id="password"
                  name="password"
                  type="password"
                  value={formData.password}
                  onChange={(e) => handleInputChange("password", e.target.value)}
                  placeholder="6文字以上"
                  required
                  className="bg-gray-800 border-gray-600 text-white placeholder-gray-400"
                />
                {validationErrors.password && (
                  <p className="text-red-400 text-sm flex items-center">
                    <XCircle className="h-4 w-4 mr-1" />
                    {validationErrors.password}
                  </p>
                )}
              </div>

              {/* パスワード確認 */}
              <div className="space-y-2">
                <Label htmlFor="confirmPassword" className="text-white">
                  パスワード確認<span className="text-red-400">*</span>
                </Label>
                <Input
                  id="confirmPassword"
                  name="confirmPassword"
                  type="password"
                  value={formData.confirmPassword}
                  onChange={(e) => handleInputChange("confirmPassword", e.target.value)}
                  placeholder="パスワードを再入力"
                  required
                  className="bg-gray-800 border-gray-600 text-white placeholder-gray-400"
                />
                {validationErrors.confirmPassword && (
                  <p className="text-red-400 text-sm flex items-center">
                    <XCircle className="h-4 w-4 mr-1" />
                    {validationErrors.confirmPassword}
                  </p>
                )}
              </div>

              {/* 電話番号 */}
              <div className="space-y-2">
                <Label htmlFor="phone" className="text-white">
                  電話番号<span className="text-red-400">*</span>
                </Label>
                <Input
                  id="phone"
                  name="phone"
                  type="tel"
                  value={formData.phone}
                  onChange={(e) => handleInputChange("phone", e.target.value)}
                  placeholder="090-1234-5678"
                  required
                  className="bg-gray-800 border-gray-600 text-white placeholder-gray-400"
                />
                {validationErrors.phone && (
                  <p className="text-red-400 text-sm flex items-center">
                    <XCircle className="h-4 w-4 mr-1" />
                    {validationErrors.phone}
                  </p>
                )}
              </div>

              {/* 紹介者ID */}
              <div className="space-y-2">
                <Label htmlFor="referrerId" className="text-white">
                  紹介者ID<span className="text-red-400">*</span>
                </Label>
                <Input
                  id="referrerId"
                  name="referrerId"
                  type="text"
                  value={formData.referrerId}
                  onChange={(e) => handleInputChange("referrerId", e.target.value)}
                  placeholder="紹介者のユーザーID"
                  required
                  className="bg-gray-800 border-gray-600 text-white placeholder-gray-400"
                />
                {validationErrors.referrerId && (
                  <p className="text-red-400 text-sm flex items-center">
                    <XCircle className="h-4 w-4 mr-1" />
                    {validationErrors.referrerId}
                  </p>
                )}
                {referrerExists === true && (
                  <p className="text-green-400 text-sm flex items-center">
                    <CheckCircle className="h-4 w-4 mr-1" />
                    紹介者IDが確認されました
                  </p>
                )}
              </div>

              {/* ウォレットアドレス */}
              <div className="space-y-2">
                <Label htmlFor="usdtAddress" className="text-white">
                  ウォレットアドレス（USDT BEP20）
                </Label>
                <Input
                  id="usdtAddress"
                  name="usdtAddress"
                  type="text"
                  value={formData.usdtAddress}
                  onChange={(e) => handleInputChange("usdtAddress", e.target.value)}
                  placeholder="0x..."
                  className="bg-gray-800 border-gray-600 text-white placeholder-gray-400"
                />
                {validationErrors.usdtAddress && (
                  <p className="text-red-400 text-sm flex items-center">
                    <XCircle className="h-4 w-4 mr-1" />
                    {validationErrors.usdtAddress}
                  </p>
                )}
              </div>

              {/* ウォレットの種類 */}
              <div className="space-y-2">
                <Label htmlFor="walletType" className="text-white">
                  ウォレットの種類
                </Label>
                <Select value={formData.walletType} onValueChange={(value) => handleInputChange("walletType", value)}>
                  <SelectTrigger className="bg-gray-800 border-gray-600 text-white">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent className="bg-gray-800 border-gray-600">
                    <SelectItem value="その他" className="text-white">
                      その他
                    </SelectItem>
                    <SelectItem value="EVO" className="text-white">
                      EVO
                    </SelectItem>
                  </SelectContent>
                </Select>
              </div>

              <Button
                type="submit"
                disabled={loading || Object.keys(validationErrors).length > 0}
                className="w-full bg-red-600 hover:bg-red-700 text-white"
              >
                {loading ? (
                  <>
                    <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                    登録中...
                  </>
                ) : (
                  "新規登録"
                )}
              </Button>
            </form>

            <div className="mt-6 text-center">
              <p className="text-gray-400">
                既にアカウントをお持ちの方は{" "}
                <Link href="/login" className="text-red-400 hover:text-red-300 underline">
                  ログイン
                </Link>
              </p>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  )
}
