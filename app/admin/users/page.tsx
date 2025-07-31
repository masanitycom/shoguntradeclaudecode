"use client"

import { DialogTrigger } from "@/components/ui/dialog"

import { useState, useEffect } from "react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Badge } from "@/components/ui/badge"
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from "@/components/ui/dialog"
import {
  ArrowLeft,
  Search,
  Eye,
  Edit,
  UserPlus,
  Loader2,
  Copy,
  CheckCircle,
  XCircle,
  Trash2,
  Coins,
  Users,
  Save,
} from "lucide-react"
import { useRouter } from "next/navigation"
import { createClient } from "@/lib/supabase/supabaseBrowserClient"
import { useToast } from "@/hooks/use-toast"

interface User {
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
  is_admin: boolean
  created_at: string
  referrer?: {
    name: string
    user_id: string
  }
  user_nfts?: {
    current_investment: number
    total_earned: number
    is_active: boolean
    purchase_date?: string
    operation_start_date?: string
    nfts: {
      name: string
      price: number
    }
  }[]
}

interface NewUserForm {
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

export default function AdminUsersPage() {
  const [users, setUsers] = useState<User[]>([])
  const [allUsers, setAllUsers] = useState<User[]>([]) // 紹介者選択用
  const [loading, setLoading] = useState(true)
  const [searchTerm, setSearchTerm] = useState("")
  const [selectedUser, setSelectedUser] = useState<User | null>(null)
  const [showNewUserDialog, setShowNewUserDialog] = useState(false)
  const [showReferrerDialog, setShowReferrerDialog] = useState(false)
  const [newUserLoading, setNewUserLoading] = useState(false)
  const [referrerInfo, setReferrerInfo] = useState<{ name: string; user_id: string } | null>(null)
  const [validationErrors, setValidationErrors] = useState<ValidationErrors>({})
  const [newUserForm, setNewUserForm] = useState<NewUserForm>({
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

  const [deleteLoading, setDeleteLoading] = useState(false)
  const [userToDelete, setUserToDelete] = useState<User | null>(null)
  const [showDeleteDialog, setShowDeleteDialog] = useState(false)

  // 紹介者変更用
  const [userToChangeReferrer, setUserToChangeReferrer] = useState<User | null>(null)
  const [newReferrerId, setNewReferrerId] = useState("")
  const [referrerChangeLoading, setReferrerChangeLoading] = useState(false)

  // 紹介者変更用の状態を追加
  const [referrerSearchTerm, setReferrerSearchTerm] = useState("")

  const router = useRouter()
  const supabase = createClient()
  const { toast } = useToast()

  useEffect(() => {
    checkAdminAuth()
    loadUsers()
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

  const handleDeleteUser = async () => {
    if (!userToDelete) return

    setDeleteLoading(true)

    try {
      const {
        data: { user: currentUser },
      } = await supabase.auth.getUser()

      // 自分自身を削除しようとしていないかチェック
      if (currentUser?.id === userToDelete.id) {
        toast({
          title: "エラー",
          description: "自分自身を削除することはできません",
          variant: "destructive",
        })
        return
      }

      // 関連データを削除（順序重要）
      const { error: rewardAppsError } = await supabase
        .from("reward_applications")
        .delete()
        .eq("user_id", userToDelete.id)

      const { error: dailyRewardsError } = await supabase.from("daily_rewards").delete().eq("user_id", userToDelete.id)

      const { error: userNftsError } = await supabase.from("user_nfts").delete().eq("user_id", userToDelete.id)

      const { error: purchaseAppsError } = await supabase
        .from("nft_purchase_applications")
        .delete()
        .eq("user_id", userToDelete.id)

      // 紹介関係を更新（このユーザーを紹介者としているユーザーの紹介者をnullに）
      const { error: referralUpdateError } = await supabase
        .from("users")
        .update({ referrer_id: null })
        .eq("referrer_id", userToDelete.id)

      // 認証ユーザーを削除
      const { error: authError } = await supabase.auth.admin.deleteUser(userToDelete.id)

      // usersテーブルからユーザーを削除
      const { error: userError } = await supabase.from("users").delete().eq("id", userToDelete.id)

      if (userError) throw userError

      toast({
        title: "成功",
        description: `ユーザー「${userToDelete.name}」を削除しました`,
      })

      // ダイアログを閉じてリストを更新
      setShowDeleteDialog(false)
      setUserToDelete(null)
      loadUsers()
    } catch (error: any) {
      console.error("ユーザー削除エラー:", error)
      toast({
        title: "エラー",
        description: error.message || "ユーザー削除に失敗しました",
        variant: "destructive",
      })
    } finally {
      setDeleteLoading(false)
    }
  }

  const loadUsers = async () => {
    try {
      const { data, error } = await supabase
        .from("users")
        .select(`
          *,
          referrer:referrer_id (
            name,
            user_id
          ),
          user_nfts (
            current_investment,
            total_earned,
            is_active,
            purchase_date,
            operation_start_date,
            nfts (name, price)
          )
        `)
        .order("created_at", { ascending: false })

      if (error) throw error
      setUsers(data || [])
      setAllUsers(data || []) // 紹介者選択用にも保存
    } catch (error) {
      console.error("ユーザー読み込みエラー:", error)
    } finally {
      setLoading(false)
    }
  }

  // 紹介者変更処理
  const handleChangeReferrer = async () => {
    if (!userToChangeReferrer || !newReferrerId) return

    setReferrerChangeLoading(true)

    try {
      // 新しい紹介者の情報を取得
      const { data: newReferrer, error: referrerError } = await supabase
        .from("users")
        .select("id, name, user_id")
        .eq("user_id", newReferrerId)
        .single()

      if (referrerError || !newReferrer) {
        toast({
          title: "エラー",
          description: "指定された紹介者が見つかりません",
          variant: "destructive",
        })
        return
      }

      // 自分自身を紹介者にしようとしていないかチェック
      if (newReferrer.id === userToChangeReferrer.id) {
        toast({
          title: "エラー",
          description: "自分自身を紹介者にすることはできません",
          variant: "destructive",
        })
        return
      }

      // 循環参照チェック（簡易版）
      const { data: circularCheck } = await supabase
        .from("users")
        .select("referrer_id")
        .eq("id", newReferrer.id)
        .single()

      if (circularCheck?.referrer_id === userToChangeReferrer.id) {
        toast({
          title: "エラー",
          description: "循環参照が発生するため、この紹介者は設定できません",
          variant: "destructive",
        })
        return
      }

      // 紹介者を更新
      const { error: updateError } = await supabase
        .from("users")
        .update({
          referrer_id: newReferrer.id,
          updated_at: new Date().toISOString(),
        })
        .eq("id", userToChangeReferrer.id)

      if (updateError) throw updateError

      toast({
        title: "成功",
        description: `${userToChangeReferrer.name}の紹介者を${newReferrer.name}(${newReferrer.user_id})に変更しました`,
      })

      // ダイアログを閉じてリストを更新
      setShowReferrerDialog(false)
      setUserToChangeReferrer(null)
      setNewReferrerId("")
      loadUsers()
    } catch (error: any) {
      console.error("紹介者変更エラー:", error)
      toast({
        title: "エラー",
        description: error.message || "紹介者変更に失敗しました",
        variant: "destructive",
      })
    } finally {
      setReferrerChangeLoading(false)
    }
  }

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
  const validateField = async (field: keyof NewUserForm, value: string) => {
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
        } else if (value !== newUserForm.password) {
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
          setReferrerInfo(null)
        } else {
          // 紹介者存在チェック
          const { data } = await supabase.from("users").select("id, name, user_id").eq("user_id", value).single()
          if (data) {
            setReferrerInfo({ name: data.name, user_id: data.user_id })
            delete errors.referrerId
          } else {
            errors.referrerId = "指定された紹介者IDが見つかりません"
            setReferrerInfo(null)
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

  const handleNewUserInputChange = async (field: keyof NewUserForm, value: string) => {
    setNewUserForm((prev) => ({ ...prev, [field]: value }))
    await validateField(field, value)
  }

  const handleCreateUser = async () => {
    setNewUserLoading(true)

    try {
      // 最終バリデーション
      const hasErrors = Object.keys(validationErrors).length > 0
      if (hasErrors) {
        toast({
          title: "入力エラー",
          description: "入力内容を確認してください",
          variant: "destructive",
        })
        return
      }

      // 紹介者IDを取得
      const { data: referrerData } = await supabase
        .from("users")
        .select("id")
        .eq("user_id", newUserForm.referrerId)
        .single()

      if (!referrerData) {
        toast({
          title: "エラー",
          description: "紹介者が見つかりません",
          variant: "destructive",
        })
        return
      }

      // Supabase認証でユーザー作成
      const { data: authData, error: authError } = await supabase.auth.signUp({
        email: newUserForm.email,
        password: newUserForm.password,
        options: {
          data: {
            name: newUserForm.name,
            user_id: newUserForm.userId,
            phone: newUserForm.phone,
          },
        },
      })

      if (authError) throw authError

      if (authData.user) {
        // usersテーブルにユーザー情報を挿入
        const { error: insertError } = await supabase.from("users").insert({
          id: authData.user.id,
          name: newUserForm.name,
          email: newUserForm.email,
          user_id: newUserForm.userId,
          phone: newUserForm.phone,
          referrer_id: referrerData.id,
          usdt_address: newUserForm.usdtAddress || null,
          wallet_type: newUserForm.walletType,
          is_admin: false,
        })

        if (insertError) throw insertError

        toast({
          title: "成功",
          description: "新規ユーザーを作成しました",
        })

        // フォームリセット
        setNewUserForm({
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
        setValidationErrors({})
        setReferrerInfo(null)
        setShowNewUserDialog(false)

        // ユーザーリスト再読み込み
        loadUsers()
      }
    } catch (error: any) {
      toast({
        title: "エラー",
        description: error.message || "ユーザー作成に失敗しました",
        variant: "destructive",
      })
    } finally {
      setNewUserLoading(false)
    }
  }

  const filteredUsers = users.filter(
    (user) =>
      user.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      user.email.toLowerCase().includes(searchTerm.toLowerCase()) ||
      user.user_id.toLowerCase().includes(searchTerm.toLowerCase()),
  )

  const getUserNFTInfo = (user: User) => {
    const activeNft = user.user_nfts?.find((nft) => nft.is_active)
    if (!activeNft) return { hasNft: false, investment: 0, earned: 0, nftName: "-", purchaseDate: null, operationStartDate: null }

    return {
      hasNft: true,
      investment: activeNft.current_investment,
      earned: activeNft.total_earned,
      nftName: activeNft.nfts.name,
      purchaseDate: activeNft.purchase_date,
      operationStartDate: activeNft.operation_start_date,
    }
  }

  const copyToClipboard = async (text: string, label: string) => {
    try {
      await navigator.clipboard.writeText(text)
      toast({
        title: "コピーしました",
        description: `${label}をクリップボードにコピーしました`,
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
              <h1 className="text-2xl font-bold text-white">ユーザー管理</h1>
              <p className="text-gray-400 text-sm">総ユーザー数: {users.length}人</p>
            </div>
          </div>
          <Dialog open={showNewUserDialog} onOpenChange={setShowNewUserDialog}>
            <DialogTrigger asChild>
              <Button className="bg-red-600 hover:bg-red-700 text-white">
                <UserPlus className="mr-2 h-4 w-4" />
                新規ユーザー追加
              </Button>
            </DialogTrigger>
            <DialogContent className="bg-gray-800 border-gray-700 text-white max-w-2xl max-h-[90vh] overflow-y-auto">
              <DialogHeader>
                <DialogTitle>新規ユーザー作成</DialogTitle>
                <DialogDescription className="text-gray-400">新しいユーザーアカウントを作成します</DialogDescription>
              </DialogHeader>
              <div className="space-y-4">
                {/* お名前 */}
                <div className="space-y-2">
                  <Label htmlFor="name" className="text-white">
                    お名前（カタカナ）<span className="text-red-400">*</span>
                  </Label>
                  <Input
                    id="name"
                    value={newUserForm.name}
                    onChange={(e) => handleNewUserInputChange("name", e.target.value)}
                    placeholder="ヤマダタロウ"
                    className="bg-gray-700 border-gray-600 text-white"
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
                    value={newUserForm.userId}
                    onChange={(e) => handleNewUserInputChange("userId", e.target.value)}
                    placeholder="user123"
                    className="bg-gray-700 border-gray-600 text-white"
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
                    type="email"
                    value={newUserForm.email}
                    onChange={(e) => handleNewUserInputChange("email", e.target.value)}
                    placeholder="user@example.com"
                    className="bg-gray-700 border-gray-600 text-white"
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
                    type="password"
                    value={newUserForm.password}
                    onChange={(e) => handleNewUserInputChange("password", e.target.value)}
                    placeholder="6文字以上"
                    className="bg-gray-700 border-gray-600 text-white"
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
                    type="password"
                    value={newUserForm.confirmPassword}
                    onChange={(e) => handleNewUserInputChange("confirmPassword", e.target.value)}
                    placeholder="パスワードを再入力"
                    className="bg-gray-700 border-gray-600 text-white"
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
                    type="tel"
                    value={newUserForm.phone}
                    onChange={(e) => handleNewUserInputChange("phone", e.target.value)}
                    placeholder="090-1234-5678"
                    className="bg-gray-700 border-gray-600 text-white"
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
                    value={newUserForm.referrerId}
                    onChange={(e) => handleNewUserInputChange("referrerId", e.target.value)}
                    placeholder="紹介者のユーザーID"
                    className="bg-gray-700 border-gray-600 text-white"
                  />
                  {validationErrors.referrerId && (
                    <p className="text-red-400 text-sm flex items-center">
                      <XCircle className="h-4 w-4 mr-1" />
                      {validationErrors.referrerId}
                    </p>
                  )}
                  {referrerInfo && (
                    <p className="text-green-400 text-sm flex items-center">
                      <CheckCircle className="h-4 w-4 mr-1" />
                      紹介者: {referrerInfo.name} ({referrerInfo.user_id})
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
                    value={newUserForm.usdtAddress}
                    onChange={(e) => handleNewUserInputChange("usdtAddress", e.target.value)}
                    placeholder="0x..."
                    className="bg-gray-700 border-gray-600 text-white"
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
                  <Select
                    value={newUserForm.walletType}
                    onValueChange={(value) => handleNewUserInputChange("walletType", value)}
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

                {/* 作成ボタン */}
                <div className="flex justify-end space-x-2 pt-4">
                  <Button
                    variant="outline"
                    onClick={() => setShowNewUserDialog(false)}
                    className="border-gray-600 text-gray-400 hover:bg-gray-600"
                  >
                    キャンセル
                  </Button>
                  <Button
                    onClick={handleCreateUser}
                    disabled={newUserLoading || Object.keys(validationErrors).length > 0}
                    className="bg-red-600 hover:bg-red-700 text-white"
                  >
                    {newUserLoading ? (
                      <>
                        <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                        作成中...
                      </>
                    ) : (
                      "ユーザー作成"
                    )}
                  </Button>
                </div>
              </div>
            </DialogContent>
          </Dialog>
        </div>
      </header>

      <main className="max-w-full mx-auto p-6">
        {/* 検索・フィルター */}
        <Card className="bg-gray-800 border-gray-700 mb-6">
          <CardContent className="p-6">
            <div className="flex items-center space-x-4">
              <div className="relative flex-1">
                <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 h-4 w-4" />
                <Input
                  placeholder="ユーザー名、メール、IDで検索..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  className="pl-10 bg-gray-700 border-gray-600 text-white"
                />
              </div>
              <div className="text-gray-400 text-sm">
                {filteredUsers.length} / {users.length} 件表示
              </div>
            </div>
          </CardContent>
        </Card>

        {/* ユーザー一覧 */}
        <Card className="bg-gray-800 border-gray-700">
          <CardHeader>
            <CardTitle className="text-white">ユーザー一覧</CardTitle>
          </CardHeader>
          <CardContent className="p-0">
            <div className="overflow-x-auto">
              <Table className="min-w-full">
                <TableHeader>
                  <TableRow className="border-gray-700">
                    <TableHead className="text-gray-300">ユーザー情報</TableHead>
                    <TableHead className="text-gray-300">紹介者</TableHead>
                    <TableHead className="text-gray-300">NFT・投資状況</TableHead>
                    <TableHead className="text-gray-300">権限</TableHead>
                    <TableHead className="text-gray-300">操作</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {filteredUsers.map((user) => {
                    const nftInfo = getUserNFTInfo(user)
                    return (
                      <TableRow key={user.id} className="border-gray-700 hover:bg-gray-800/50">
                        {/* ユーザー情報 */}
                        <TableCell className="p-4 hover:text-white">
                          <div className="space-y-2">
                            <div>
                              <div className="text-white font-medium">{user.name}</div>
                              <div className="text-gray-400 text-sm">{user.user_id}</div>
                              <div className="text-gray-400 text-xs">{user.email}</div>
                            </div>
                            <div className="text-xs">
                              <span className="text-gray-400">登録: </span>
                              <span className="text-white">{new Date(user.created_at).toLocaleDateString("ja-JP")}</span>
                            </div>
                            {user.usdt_address && (
                              <div className="text-xs">
                                <div className="text-gray-400">USDT: </div>
                                <div className="text-white font-mono truncate max-w-32">
                                  {user.usdt_address}
                                </div>
                              </div>
                            )}
                          </div>
                        </TableCell>
                        
                        {/* 紹介者 */}
                        <TableCell className="p-4 hover:text-white">
                          {user.referrer ? (
                            <div>
                              <div className="text-white text-sm">{user.referrer.name}</div>
                              <div className="text-gray-400 text-xs">{user.referrer.user_id}</div>
                            </div>
                          ) : (
                            <span className="text-gray-500 text-sm">なし</span>
                          )}
                        </TableCell>
                        
                        {/* NFT・投資状況 */}
                        <TableCell className="p-4 hover:text-white">
                          {nftInfo.hasNft ? (
                            <div className="space-y-2">
                              <div className="flex items-center space-x-2">
                                <Badge className="bg-green-600 text-white text-xs">保有</Badge>
                                <div className="text-gray-400 text-xs truncate">{nftInfo.nftName}</div>
                              </div>
                              <div className="text-xs space-y-1">
                                <div className="text-white">投資: ${nftInfo.investment.toLocaleString()}</div>
                                <div className="text-green-400">収益: ${nftInfo.earned.toFixed(2)}</div>
                              </div>
                              {nftInfo.purchaseDate && nftInfo.operationStartDate && (
                                <div className="text-xs space-y-1 pt-1 border-t border-gray-700">
                                  <div className="text-gray-400">
                                    購入: {new Date(nftInfo.purchaseDate).toLocaleDateString("ja-JP", { timeZone: 'UTC' })}
                                  </div>
                                  <div className="text-white">
                                    運用: {new Date(nftInfo.operationStartDate).toLocaleDateString("ja-JP", { timeZone: 'UTC' })}
                                  </div>
                                </div>
                              )}
                            </div>
                          ) : (
                            <Badge
                              variant="outline"
                              className="border-gray-600 text-gray-400 text-xs whitespace-nowrap"
                            >
                              未保有
                            </Badge>
                          )}
                        </TableCell>
                        
                        {/* 権限 */}
                        <TableCell className="p-4 hover:text-white">
                          {user.is_admin ? (
                            <Badge className="bg-yellow-600 text-white text-xs whitespace-nowrap">管理者</Badge>
                          ) : (
                            <Badge
                              variant="outline"
                              className="border-gray-600 text-gray-400 text-xs whitespace-nowrap"
                            >
                              一般
                            </Badge>
                          )}
                        </TableCell>
                        
                        {/* 操作 */}
                        <TableCell className="p-4 hover:text-white">
                          <div className="grid grid-cols-5 gap-1 w-full">
                            {/* 詳細ボタン */}
                            <Dialog>
                              <DialogTrigger asChild>
                                <Button
                                  variant="outline"
                                  size="sm"
                                  className="border-gray-600 text-gray-400 hover:bg-gray-600 bg-gray-800 h-8 w-full"
                                  onClick={() => setSelectedUser(user)}
                                  title="詳細"
                                >
                                  <Eye className="h-3 w-3" />
                                </Button>
                              </DialogTrigger>
                              <DialogContent className="bg-gray-800 border-gray-700 text-white max-w-2xl">
                                <DialogHeader>
                                  <DialogTitle>ユーザー詳細</DialogTitle>
                                  <DialogDescription className="text-gray-400">
                                    ユーザー情報の詳細表示
                                  </DialogDescription>
                                </DialogHeader>
                                {selectedUser && (
                                  <div className="space-y-4">
                                    <div className="grid grid-cols-2 gap-4">
                                      <div>
                                        <p className="text-gray-400 text-sm">お名前</p>
                                        <p className="text-white">{selectedUser.name}</p>
                                      </div>
                                      <div>
                                        <p className="text-gray-400 text-sm">ユーザーID</p>
                                        <p className="text-white">{selectedUser.user_id}</p>
                                      </div>
                                      <div>
                                        <p className="text-gray-400 text-sm">メールアドレス</p>
                                        <p className="text-white">{selectedUser.email}</p>
                                      </div>
                                      <div>
                                        <p className="text-gray-400 text-sm">電話番号</p>
                                        <p className="text-white">{selectedUser.phone}</p>
                                      </div>
                                      <div>
                                        <p className="text-gray-400 text-sm">自分の紹介コード</p>
                                        <p className="text-white">{selectedUser.my_referral_code || "-"}</p>
                                      </div>
                                      <div>
                                        <p className="text-gray-400 text-sm">ウォレットタイプ</p>
                                        <p className="text-white">{selectedUser.wallet_type || "-"}</p>
                                      </div>
                                      <div>
                                        <p className="text-gray-400 text-sm">登録日</p>
                                        <p className="text-white">
                                          {new Date(selectedUser.created_at).toLocaleDateString("ja-JP")}
                                        </p>
                                      </div>
                                    </div>
                                    {selectedUser.usdt_address && (
                                      <div>
                                        <p className="text-gray-400 text-sm">USDT(BEP20)アドレス</p>
                                        <div className="flex items-center space-x-2">
                                          <p className="text-white font-mono text-sm break-all flex-1">
                                            {selectedUser.usdt_address}
                                          </p>
                                          <Button
                                            variant="ghost"
                                            size="sm"
                                            className="h-8 w-8 p-0 text-gray-400 hover:text-white"
                                            onClick={() => copyToClipboard(selectedUser.usdt_address!, "USDTアドレス")}
                                          >
                                            <Copy className="h-4 w-4" />
                                          </Button>
                                        </div>
                                      </div>
                                    )}
                                    {selectedUser.referral_link && (
                                      <div>
                                        <p className="text-gray-400 text-sm">紹介リンク</p>
                                        <p className="text-blue-400 text-sm break-all">{selectedUser.referral_link}</p>
                                      </div>
                                    )}
                                  </div>
                                )}
                              </DialogContent>
                            </Dialog>

                            {/* 編集ボタン */}
                            <Button
                              variant="outline"
                              size="sm"
                              className="border-blue-600 text-blue-400 hover:bg-blue-600 hover:text-white bg-gray-800 h-8 w-full"
                              onClick={() => router.push(`/admin/users/${user.id}/edit`)}
                              title="編集"
                            >
                              <Edit className="h-3 w-3" />
                            </Button>

                            {/* NFT付与ボタン */}
                            <Button
                              variant="outline"
                              size="sm"
                              className="border-green-600 text-green-400 hover:bg-green-600 hover:text-white bg-gray-800 h-8 w-full"
                              onClick={() => router.push(`/admin/users/${user.id}/nfts`)}
                              title="NFT付与"
                            >
                              <Coins className="h-3 w-3" />
                            </Button>

                            {/* 紹介者変更ボタン */}
                            <Button
                              variant="outline"
                              size="sm"
                              className="border-orange-600 text-orange-400 hover:bg-orange-600 hover:text-white bg-gray-800 h-8 w-full"
                              onClick={() => {
                                setUserToChangeReferrer(user)
                                setShowReferrerDialog(true)
                              }}
                              title="紹介者変更"
                            >
                              <Users className="h-3 w-3" />
                            </Button>

                            {/* 削除ボタン */}
                            <Button
                              variant="outline"
                              size="sm"
                              className="border-red-600 text-red-400 hover:bg-red-600 hover:text-white bg-gray-800 h-8 w-full"
                              onClick={() => {
                                setUserToDelete(user)
                                setShowDeleteDialog(true)
                              }}
                              disabled={user.is_admin}
                              title="削除"
                            >
                              <Trash2 className="h-3 w-3" />
                            </Button>
                          </div>
                        </TableCell>
                      </TableRow>
                    )
                  })}
                </TableBody>
              </Table>

              {filteredUsers.length === 0 && (
                <div className="text-center py-8 text-gray-400">
                  {searchTerm ? "検索条件に一致するユーザーが見つかりません" : "ユーザーがいません"}
                </div>
              )}
            </div>
          </CardContent>
        </Card>
      </main>

      {/* 紹介者変更ダイアログ */}
      <Dialog open={showReferrerDialog} onOpenChange={setShowReferrerDialog}>
        <DialogContent className="bg-gray-800 border-gray-700 text-white">
          <DialogHeader>
            <DialogTitle className="text-orange-400">紹介者変更</DialogTitle>
            <DialogDescription className="text-gray-400">
              {userToChangeReferrer?.name}の紹介者を変更します
            </DialogDescription>
          </DialogHeader>
          {userToChangeReferrer && (
            <div className="space-y-4">
              <div className="bg-gray-700 p-4 rounded-lg">
                <h3 className="font-semibold text-white mb-2">現在の情報</h3>
                <div className="space-y-1 text-sm">
                  <p>
                    <span className="text-gray-400">ユーザー:</span> {userToChangeReferrer.name} (
                    {userToChangeReferrer.user_id})
                  </p>
                  <p>
                    <span className="text-gray-400">現在の紹介者:</span>{" "}
                    {userToChangeReferrer.referrer
                      ? `${userToChangeReferrer.referrer.name} (${userToChangeReferrer.referrer.user_id})`
                      : "なし"}
                  </p>
                </div>
              </div>

              <div className="space-y-2">
                <Label htmlFor="newReferrerId" className="text-white">
                  新しい紹介者を検索 <span className="text-red-400">*</span>
                </Label>
                <Input
                  placeholder="紹介者の名前またはユーザーIDで検索..."
                  value={referrerSearchTerm}
                  onChange={(e) => setReferrerSearchTerm(e.target.value)}
                  className="bg-gray-700 border-gray-600 text-white"
                />

                {/* 検索結果リスト */}
                <div className="max-h-40 overflow-y-auto border border-gray-600 rounded-md bg-gray-700">
                  {allUsers
                    .filter(
                      (u) =>
                        u.id !== userToChangeReferrer?.id &&
                        (u.name.toLowerCase().includes(referrerSearchTerm.toLowerCase()) ||
                          u.user_id.toLowerCase().includes(referrerSearchTerm.toLowerCase())),
                    )
                    .slice(0, 10) // 最大10件表示
                    .map((user) => (
                      <div
                        key={user.id}
                        className={`p-3 cursor-pointer hover:bg-gray-600 border-b border-gray-600 last:border-b-0 ${
                          newReferrerId === user.user_id ? "bg-orange-600" : ""
                        }`}
                        onClick={() => {
                          setNewReferrerId(user.user_id)
                          setReferrerSearchTerm(`${user.name} (${user.user_id})`)
                        }}
                      >
                        <div className="text-white font-medium">{user.name}</div>
                        <div className="text-gray-400 text-sm">{user.user_id}</div>
                      </div>
                    ))}
                  {referrerSearchTerm &&
                    allUsers.filter(
                      (u) =>
                        u.id !== userToChangeReferrer?.id &&
                        (u.name.toLowerCase().includes(referrerSearchTerm.toLowerCase()) ||
                          u.user_id.toLowerCase().includes(referrerSearchTerm.toLowerCase())),
                    ).length === 0 && (
                      <div className="p-3 text-gray-400 text-center">該当するユーザーが見つかりません</div>
                    )}
                </div>
              </div>

              <div className="bg-yellow-900/20 border border-yellow-800 p-4 rounded-lg">
                <h4 className="font-semibold text-yellow-400 mb-2">⚠️ 注意事項</h4>
                <ul className="text-sm text-gray-300 space-y-1">
                  <li>• 紹介者変更は慎重に行ってください</li>
                  <li>• 循環参照が発生しないよう自動チェックされます</li>
                  <li>• 変更後はMLMランクの再計算が必要な場合があります</li>
                </ul>
              </div>

              <div className="flex justify-end space-x-2">
                <Button
                  variant="outline"
                  onClick={() => {
                    setShowReferrerDialog(false)
                    setUserToChangeReferrer(null)
                    setNewReferrerId("")
                    setReferrerSearchTerm("")
                  }}
                  className="border-gray-600 text-gray-400 hover:bg-gray-600"
                >
                  キャンセル
                </Button>
                <Button
                  onClick={handleChangeReferrer}
                  disabled={referrerChangeLoading || !newReferrerId}
                  className="bg-orange-600 hover:bg-orange-700 text-white"
                >
                  {referrerChangeLoading ? (
                    <>
                      <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                      変更中...
                    </>
                  ) : (
                    <>
                      <Save className="mr-2 h-4 w-4" />
                      紹介者変更
                    </>
                  )}
                </Button>
              </div>
            </div>
          )}
        </DialogContent>
      </Dialog>

      {/* 削除確認ダイアログ */}
      <Dialog open={showDeleteDialog} onOpenChange={setShowDeleteDialog}>
        <DialogContent className="bg-gray-800 border-gray-700 text-white">
          <DialogHeader>
            <DialogTitle className="text-red-400">ユーザー削除の確認</DialogTitle>
            <DialogDescription className="text-gray-400">
              この操作は取り消すことができません。本当に削除しますか？
            </DialogDescription>
          </DialogHeader>
          {userToDelete && (
            <div className="space-y-4">
              <div className="bg-gray-700 p-4 rounded-lg">
                <h3 className="font-semibold text-white mb-2">削除対象ユーザー</h3>
                <div className="space-y-1 text-sm">
                  <p>
                    <span className="text-gray-400">名前:</span> {userToDelete.name}
                  </p>
                  <p>
                    <span className="text-gray-400">ユーザーID:</span> {userToDelete.user_id}
                  </p>
                  <p>
                    <span className="text-gray-400">メール:</span> {userToDelete.email}
                  </p>
                </div>
              </div>

              <div className="bg-red-900/20 border border-red-800 p-4 rounded-lg">
                <h4 className="font-semibold text-red-400 mb-2">削除される関連データ</h4>
                <ul className="text-sm text-gray-300 space-y-1">
                  <li>• NFT保有情報</li>
                  <li>• 日利報酬履歴</li>
                  <li>• 報酬申請履歴</li>
                  <li>• NFT購入申請履歴</li>
                  <li>• 紹介関係（このユーザーが紹介したユーザーの紹介者情報はクリアされます）</li>
                </ul>
              </div>

              <div className="flex justify-end space-x-2">
                <Button
                  variant="outline"
                  onClick={() => {
                    setShowDeleteDialog(false)
                    setUserToDelete(null)
                  }}
                  className="border-gray-600 text-gray-400 hover:bg-gray-600"
                >
                  キャンセル
                </Button>
                <Button
                  onClick={handleDeleteUser}
                  disabled={deleteLoading}
                  className="bg-red-600 hover:bg-red-700 text-white"
                >
                  {deleteLoading ? (
                    <>
                      <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                      削除中...
                    </>
                  ) : (
                    <>
                      <Trash2 className="mr-2 h-4 w-4" />
                      削除する
                    </>
                  )}
                </Button>
              </div>
            </div>
          )}
        </DialogContent>
      </Dialog>
    </div>
  )
}
