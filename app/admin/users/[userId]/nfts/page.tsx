"use client"

import { useState, useEffect } from "react"
import { useRouter, useParams } from "next/navigation"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
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
import { ArrowLeft, Plus, Loader2, Coins, Calendar, DollarSign, TrendingUp, Trash2 } from "lucide-react"
import { createClient } from "@/lib/supabase/supabaseBrowserClient"
import { useToast } from "@/hooks/use-toast"

interface UserData {
  id: string
  name: string
  user_id: string
  email: string
}

interface NFT {
  id: string
  name: string
  price: number
  daily_rate_limit: number
  is_special: boolean
  is_active: boolean
}

interface UserNFT {
  id: string
  nft_id: string
  purchase_date: string
  current_investment: number
  total_earned: number
  is_active: boolean
  created_at: string
  nfts: NFT
}

export default function UserNFTsPage() {
  const router = useRouter()
  const params = useParams()
  const userId = params.userId as string
  const supabase = createClient()
  const { toast } = useToast()

  const [loading, setLoading] = useState(true)
  const [userData, setUserData] = useState<UserData | null>(null)
  const [userNFTs, setUserNFTs] = useState<UserNFT[]>([])
  const [availableNFTs, setAvailableNFTs] = useState<NFT[]>([])
  const [showAddDialog, setShowAddDialog] = useState(false)
  const [addingNFT, setAddingNFT] = useState(false)
  const [selectedNFT, setSelectedNFT] = useState("")
  const [purchaseDate, setPurchaseDate] = useState(new Date().toISOString().split("T")[0])

  useEffect(() => {
    checkAdminAuth()
    loadData()
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

  const loadData = async () => {
    try {
      // ユーザーデータ取得
      const { data: user, error: userError } = await supabase
        .from("users")
        .select("id, name, user_id, email")
        .eq("id", userId)
        .single()

      if (userError) throw userError
      setUserData(user)

      // ユーザーのNFT取得
      const { data: nfts, error: nftsError } = await supabase
        .from("user_nfts")
        .select(`
          *,
          nfts (*)
        `)
        .eq("user_id", userId)
        .order("created_at", { ascending: false })

      if (nftsError) throw nftsError
      setUserNFTs(nfts || [])

      // 利用可能なNFT取得
      const { data: availableNfts, error: availableError } = await supabase
        .from("nfts")
        .select("*")
        .eq("is_active", true)
        .order("price", { ascending: true })

      if (availableError) throw availableError
      setAvailableNFTs(availableNfts || [])
    } catch (error: any) {
      console.error("データ読み込みエラー:", error)
      toast({
        title: "エラー",
        description: "データの読み込みに失敗しました",
        variant: "destructive",
      })
    } finally {
      setLoading(false)
    }
  }

  const handleAddNFT = async () => {
    if (!selectedNFT || !purchaseDate) {
      toast({
        title: "入力エラー",
        description: "NFTと購入日を選択してください",
        variant: "destructive",
      })
      return
    }

    setAddingNFT(true)

    try {
      const selectedNFTData = availableNFTs.find((nft) => nft.id === selectedNFT)
      if (!selectedNFTData) throw new Error("選択されたNFTが見つかりません")

      // 購入日から運用開始日を計算（翌週を準備期間、翌々週の月曜日から運用開始）
      const purchaseDateObj = new Date(purchaseDate + 'T15:00:00.000Z')
      
      // 購入日の翌々週の月曜日を計算
      const operationStartDate = new Date(purchaseDateObj)
      const dayOfWeek = purchaseDateObj.getDay() // 0=日曜, 1=月曜, ..., 6=土曜
      
      // 今週の月曜日を取得
      const daysToMonday = dayOfWeek === 0 ? 1 : (8 - dayOfWeek) % 7 || 7
      operationStartDate.setDate(purchaseDateObj.getDate() + daysToMonday + 7) // 翌々週の月曜日

      const { error } = await supabase.from("user_nfts").insert({
        user_id: userId,
        nft_id: selectedNFT,
        purchase_date: purchaseDateObj.toISOString(),
        operation_start_date: operationStartDate.toISOString(),
        purchase_price: selectedNFTData.price,
        current_investment: selectedNFTData.price,
        max_earning: selectedNFTData.price * 3, // 300%キャップ
        total_earned: 0,
        is_active: true,
      })

      if (error) throw error

      toast({
        title: "成功",
        description: "NFTを付与しました",
      })

      setShowAddDialog(false)
      setSelectedNFT("")
      setPurchaseDate(new Date().toISOString().split("T")[0])
      loadData()
    } catch (error: any) {
      console.error("NFT付与エラー:", error)
      toast({
        title: "エラー",
        description: error.message || "NFT付与に失敗しました",
        variant: "destructive",
      })
    } finally {
      setAddingNFT(false)
    }
  }

  const handleDeactivateNFT = async (nftId: string) => {
    try {
      const { error } = await supabase.from("user_nfts").update({ is_active: false }).eq("id", nftId)

      if (error) throw error

      toast({
        title: "成功",
        description: "NFTを無効化しました",
      })

      loadData()
    } catch (error: any) {
      console.error("NFT無効化エラー:", error)
      toast({
        title: "エラー",
        description: "NFT無効化に失敗しました",
        variant: "destructive",
      })
    }
  }

  const calculateProgress = (nft: UserNFT) => {
    const maxEarnings = nft.current_investment * 3 // 300%
    const progress = (nft.total_earned / maxEarnings) * 100
    return Math.min(progress, 100)
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
        <div className="max-w-7xl mx-auto flex justify-between items-center">
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
              <h1 className="text-2xl font-bold text-white">NFT管理</h1>
              <p className="text-gray-400 text-sm">
                {userData.name} ({userData.user_id})
              </p>
            </div>
          </div>
          <Dialog open={showAddDialog} onOpenChange={setShowAddDialog}>
            <DialogTrigger asChild>
              <Button className="bg-red-600 hover:bg-red-700 text-white">
                <Plus className="mr-2 h-4 w-4" />
                NFT付与
              </Button>
            </DialogTrigger>
            <DialogContent className="bg-gray-800 border-gray-700 text-white">
              <DialogHeader>
                <DialogTitle>NFT付与</DialogTitle>
                <DialogDescription className="text-gray-400">ユーザーにNFTを直接付与します</DialogDescription>
              </DialogHeader>
              <div className="space-y-4">
                <div className="space-y-2">
                  <Label htmlFor="nft-select" className="text-white">
                    NFT選択 <span className="text-red-400">*</span>
                  </Label>
                  <Select value={selectedNFT} onValueChange={setSelectedNFT}>
                    <SelectTrigger className="bg-gray-700 border-gray-600 text-white">
                      <SelectValue placeholder="NFTを選択してください" />
                    </SelectTrigger>
                    <SelectContent className="bg-gray-700 border-gray-600">
                      {availableNFTs.map((nft) => (
                        <SelectItem key={nft.id} value={nft.id} className="text-white">
                          <div className="flex items-center justify-between w-full">
                            <span>{nft.name}</span>
                            <div className="flex items-center space-x-2 ml-4">
                              <span className="text-green-400">${nft.price.toLocaleString()}</span>
                              {nft.is_special && <Badge className="bg-purple-600 text-white text-xs">特別</Badge>}
                            </div>
                          </div>
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>

                <div className="space-y-2">
                  <Label htmlFor="purchase-date" className="text-white">
                    購入日 <span className="text-red-400">*</span>
                  </Label>
                  <Input
                    id="purchase-date"
                    type="date"
                    value={purchaseDate}
                    onChange={(e) => setPurchaseDate(e.target.value)}
                    className="bg-gray-700 border-gray-600 text-white"
                  />
                </div>

                <div className="flex justify-end space-x-2 pt-4">
                  <Button
                    variant="outline"
                    onClick={() => setShowAddDialog(false)}
                    className="border-gray-600 text-gray-400 hover:bg-gray-600"
                  >
                    キャンセル
                  </Button>
                  <Button
                    onClick={handleAddNFT}
                    disabled={addingNFT}
                    className="bg-red-600 hover:bg-red-700 text-white"
                  >
                    {addingNFT ? (
                      <>
                        <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                        付与中...
                      </>
                    ) : (
                      "NFT付与"
                    )}
                  </Button>
                </div>
              </div>
            </DialogContent>
          </Dialog>
        </div>
      </header>

      <main className="max-w-7xl mx-auto p-6">
        {/* 統計カード */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-6">
          <Card className="bg-gray-800 border-gray-700">
            <CardContent className="p-6">
              <div className="flex items-center">
                <Coins className="h-8 w-8 text-blue-400" />
                <div className="ml-4">
                  <p className="text-sm font-medium text-gray-400">保有NFT数</p>
                  <p className="text-2xl font-bold text-white">{userNFTs.filter((nft) => nft.is_active).length}</p>
                </div>
              </div>
            </CardContent>
          </Card>

          <Card className="bg-gray-800 border-gray-700">
            <CardContent className="p-6">
              <div className="flex items-center">
                <DollarSign className="h-8 w-8 text-green-400" />
                <div className="ml-4">
                  <p className="text-sm font-medium text-gray-400">総投資額</p>
                  <p className="text-2xl font-bold text-white">
                    $
                    {userNFTs
                      .reduce((sum, nft) => sum + (nft.is_active ? nft.current_investment : 0), 0)
                      .toLocaleString()}
                  </p>
                </div>
              </div>
            </CardContent>
          </Card>

          <Card className="bg-gray-800 border-gray-700">
            <CardContent className="p-6">
              <div className="flex items-center">
                <TrendingUp className="h-8 w-8 text-yellow-400" />
                <div className="ml-4">
                  <p className="text-sm font-medium text-gray-400">総収益</p>
                  <p className="text-2xl font-bold text-white">
                    ${userNFTs.reduce((sum, nft) => sum + nft.total_earned, 0).toFixed(2)}
                  </p>
                </div>
              </div>
            </CardContent>
          </Card>

          <Card className="bg-gray-800 border-gray-700">
            <CardContent className="p-6">
              <div className="flex items-center">
                <Calendar className="h-8 w-8 text-purple-400" />
                <div className="ml-4">
                  <p className="text-sm font-medium text-gray-400">アクティブNFT</p>
                  <p className="text-2xl font-bold text-white">{userNFTs.filter((nft) => nft.is_active).length}</p>
                </div>
              </div>
            </CardContent>
          </Card>
        </div>

        {/* NFT一覧 */}
        <Card className="bg-gray-800 border-gray-700">
          <CardHeader>
            <CardTitle className="text-white">NFT一覧</CardTitle>
          </CardHeader>
          <CardContent>
            {userNFTs.length === 0 ? (
              <div className="text-center py-8 text-gray-400">
                <Coins className="h-12 w-12 mx-auto mb-4 opacity-50" />
                <p>このユーザーはまだNFTを保有していません</p>
              </div>
            ) : (
              <Table>
                <TableHeader>
                  <TableRow className="border-gray-700">
                    <TableHead className="text-gray-300">NFT情報</TableHead>
                    <TableHead className="text-gray-300">購入日</TableHead>
                    <TableHead className="text-gray-300">投資額</TableHead>
                    <TableHead className="text-gray-300">収益</TableHead>
                    <TableHead className="text-gray-300">300%進捗</TableHead>
                    <TableHead className="text-gray-300">ステータス</TableHead>
                    <TableHead className="text-gray-300">操作</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {userNFTs.map((userNft) => {
                    const progress = calculateProgress(userNft)
                    return (
                      <TableRow key={userNft.id} className="border-gray-700">
                        <TableCell>
                          <div>
                            <div className="text-white font-medium">{userNft.nfts.name}</div>
                            <div className="flex items-center space-x-2 mt-1">
                              <span className="text-gray-400 text-sm">${userNft.nfts.price.toLocaleString()}</span>
                              {userNft.nfts.is_special && (
                                <Badge className="bg-purple-600 text-white text-xs">特別NFT</Badge>
                              )}
                            </div>
                          </div>
                        </TableCell>
                        <TableCell className="text-gray-300">
                          {new Date(userNft.purchase_date).toLocaleDateString("ja-JP", { timeZone: 'UTC' })}
                        </TableCell>
                        <TableCell className="text-white">${userNft.current_investment.toLocaleString()}</TableCell>
                        <TableCell className="text-green-400">${userNft.total_earned.toFixed(2)}</TableCell>
                        <TableCell>
                          <div className="space-y-1">
                            <div className="flex justify-between text-sm">
                              <span className="text-gray-400">{progress.toFixed(1)}%</span>
                              <span className="text-gray-400">
                                ${(userNft.current_investment * 3).toLocaleString()}
                              </span>
                            </div>
                            <div className="w-full bg-gray-700 rounded-full h-2">
                              <div
                                className="bg-gradient-to-r from-green-500 to-red-500 h-2 rounded-full transition-all duration-300"
                                style={{ width: `${progress}%` }}
                              />
                            </div>
                          </div>
                        </TableCell>
                        <TableCell>
                          {userNft.is_active ? (
                            <Badge className="bg-green-600 text-white">アクティブ</Badge>
                          ) : (
                            <Badge variant="outline" className="border-gray-600 text-gray-400">
                              無効
                            </Badge>
                          )}
                        </TableCell>
                        <TableCell>
                          <div className="flex space-x-2">
                            {userNft.is_active && (
                              <Button
                                variant="outline"
                                size="sm"
                                className="border-red-600 text-red-400 hover:bg-red-600 hover:text-white"
                                onClick={() => handleDeactivateNFT(userNft.id)}
                              >
                                <Trash2 className="h-4 w-4" />
                              </Button>
                            )}
                          </div>
                        </TableCell>
                      </TableRow>
                    )
                  })}
                </TableBody>
              </Table>
            )}
          </CardContent>
        </Card>
      </main>
    </div>
  )
}
