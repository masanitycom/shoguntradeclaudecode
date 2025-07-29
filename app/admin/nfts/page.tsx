"use client"

import type React from "react"

import { useState, useEffect, useRef } from "react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Switch } from "@/components/ui/switch"
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
import { ArrowLeft, Plus, Edit, Trash2, Loader2, Coins, Upload, ImageIcon, AlertTriangle } from "lucide-react"
import { useRouter } from "next/navigation"
import { createClient } from "@/lib/supabase/supabaseBrowserClient"

interface NFT {
  id: string
  name: string
  price: number
  daily_rate_limit: number
  description?: string
  image_url?: string
  is_active: boolean
  is_special: boolean
  created_at: string
  user_count?: number
}

export default function AdminNFTsPage() {
  const [nfts, setNfts] = useState<NFT[]>([])
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [uploading, setUploading] = useState(false)
  const [editingNft, setEditingNft] = useState<NFT | null>(null)
  const [isDialogOpen, setIsDialogOpen] = useState(false)
  const [blobTokenError, setBlobTokenError] = useState(false)
  const [formData, setFormData] = useState({
    name: "",
    price: "",
    daily_rate_limit: "",
    description: "",
    image_url: "",
    is_active: true,
    is_special: false,
  })
  const fileInputRef = useRef<HTMLInputElement>(null)
  const router = useRouter()
  const supabase = createClient()

  useEffect(() => {
    checkAdminAuth()
    loadNFTs()
    checkBlobToken()
  }, [])

  const checkBlobToken = () => {
    // Vercel Blob トークンの存在確認
    if (!process.env.NEXT_PUBLIC_BLOB_READ_WRITE_TOKEN && !process.env.BLOB_READ_WRITE_TOKEN) {
      setBlobTokenError(true)
      console.warn("Vercel Blob token not found. Image upload will be disabled.")
    }
  }

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

  const loadNFTs = async () => {
    try {
      console.log("NFTデータを読み込み中...")

      // NFTと保有者数を取得
      const { data: nftData, error: nftError } = await supabase
        .from("nfts")
        .select("*")
        .order("price", { ascending: true })

      if (nftError) {
        console.error("NFT読み込みエラー:", nftError)
        throw nftError
      }

      console.log("取得したNFTデータ:", nftData)

      // 各NFTの保有者数を取得
      const nftsWithCount = await Promise.all(
        (nftData || []).map(async (nft) => {
          const { count } = await supabase
            .from("user_nfts")
            .select("*", { count: "exact", head: true })
            .eq("nft_id", nft.id)
            .eq("is_active", true)

          console.log(`NFT ${nft.name} の画像URL:`, nft.image_url)
          return { ...nft, user_count: count || 0 }
        }),
      )

      setNfts(nftsWithCount)
    } catch (error) {
      console.error("NFT読み込みエラー:", error)
    } finally {
      setLoading(false)
    }
  }

  const handleImageUpload = async (file: File) => {
    if (!file) return null

    // Blob トークンチェック
    if (blobTokenError) {
      alert("画像アップロード機能が利用できません。環境変数 BLOB_READ_WRITE_TOKEN が設定されていません。")
      return null
    }

    setUploading(true)
    try {
      // ファイル名を生成（NFT名 + タイムスタンプ）
      const timestamp = Date.now()
      const fileName = `nft-${timestamp}-${file.name.replace(/[^a-zA-Z0-9.-]/g, "")}`

      console.log("画像アップロード開始:", fileName)

      // Vercel Blobにアップロード（動的インポート）
      const { put } = await import("@vercel/blob")
      const blob = await put(fileName, file, {
        access: "public",
        token: process.env.BLOB_READ_WRITE_TOKEN,
      })

      console.log("画像アップロード完了:", blob.url)
      return blob.url
    } catch (error) {
      console.error("画像アップロードエラー:", error)
      if (error instanceof Error && error.message.includes("No token found")) {
        setBlobTokenError(true)
        alert("画像アップロード機能が利用できません。管理者にお問い合わせください。")
      } else {
        alert("画像のアップロードに失敗しました")
      }
      return null
    } finally {
      setUploading(false)
    }
  }

  const handleFileSelect = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0]
    if (!file) return

    // ファイルサイズチェック（5MB以下）
    if (file.size > 5 * 1024 * 1024) {
      alert("ファイルサイズは5MB以下にしてください")
      return
    }

    // ファイル形式チェック
    if (!file.type.startsWith("image/")) {
      alert("画像ファイルを選択してください")
      return
    }

    const imageUrl = await handleImageUpload(file)
    if (imageUrl) {
      setFormData({ ...formData, image_url: imageUrl })
    }
  }

  const handleSave = async () => {
    if (!formData.name.trim() || !formData.price || !formData.daily_rate_limit) {
      alert("必須項目を入力してください")
      return
    }

    setSaving(true)
    try {
      const nftData = {
        name: formData.name.trim(),
        price: Number.parseFloat(formData.price),
        daily_rate_limit: Number.parseFloat(formData.daily_rate_limit),
        description: formData.description.trim() || null,
        image_url: formData.image_url || null,
        is_active: formData.is_active,
        is_special: formData.is_special,
        updated_at: new Date().toISOString(),
      }

      console.log("保存するNFTデータ:", nftData)

      if (editingNft) {
        // 更新
        const { error } = await supabase.from("nfts").update(nftData).eq("id", editingNft.id)

        if (error) throw error
        alert("NFTを更新しました")
      } else {
        // 新規作成
        const { error } = await supabase.from("nfts").insert(nftData)

        if (error) throw error
        alert("NFTを作成しました")
      }

      loadNFTs()
      resetForm()
      setIsDialogOpen(false)
    } catch (error) {
      console.error("保存エラー:", error)
      alert("保存に失敗しました")
    } finally {
      setSaving(false)
    }
  }

  const handleEdit = (nft: NFT) => {
    console.log("編集するNFT:", nft)
    setEditingNft(nft)
    setFormData({
      name: nft.name,
      price: nft.price.toString(),
      daily_rate_limit: nft.daily_rate_limit.toString(),
      description: nft.description || "",
      image_url: nft.image_url || "",
      is_active: nft.is_active,
      is_special: nft.is_special,
    })
    setIsDialogOpen(true)
  }

  const handleDelete = async (nftId: string) => {
    if (!confirm("このNFTを削除しますか？保有者がいる場合は削除できません。")) return

    try {
      const { error } = await supabase.from("nfts").delete().eq("id", nftId)

      if (error) throw error
      alert("NFTを削除しました")
      loadNFTs()
    } catch (error) {
      console.error("削除エラー:", error)
      alert("削除に失敗しました。保有者がいる可能性があります。")
    }
  }

  const toggleActive = async (nftId: string, isActive: boolean) => {
    try {
      const { error } = await supabase
        .from("nfts")
        .update({
          is_active: !isActive,
          updated_at: new Date().toISOString(),
        })
        .eq("id", nftId)

      if (error) throw error
      loadNFTs()
    } catch (error) {
      console.error("ステータス更新エラー:", error)
      alert("ステータス更新に失敗しました")
    }
  }

  const resetForm = () => {
    setEditingNft(null)
    setFormData({
      name: "",
      price: "",
      daily_rate_limit: "",
      description: "",
      image_url: "",
      is_active: true,
      is_special: false,
    })
    if (fileInputRef.current) {
      fileInputRef.current.value = ""
    }
  }

  const handleNewNFT = () => {
    resetForm()
    setIsDialogOpen(true)
  }

  // 改善された画像表示用のヘルパー関数
  const renderNFTImage = (nft: NFT) => {
    console.log(`${nft.name} の画像URL:`, nft.image_url)

    // 画像URLが存在し、空文字でない場合
    if (nft.image_url && nft.image_url.trim() !== "") {
      return (
        <div className="relative w-12 h-12">
          <img
            src={nft.image_url || "/placeholder.svg"}
            alt={nft.name}
            className="w-12 h-12 object-cover rounded-lg border border-gray-600"
            crossOrigin="anonymous"
            onLoad={() => {
              console.log(`画像読み込み成功: ${nft.name}`)
            }}
            onError={(e) => {
              console.error(`画像読み込みエラー (${nft.name}):`, nft.image_url)
              // エラー時は確実にアイコンを表示
              const target = e.currentTarget
              target.style.display = "none"
              const parent = target.parentElement
              if (parent) {
                parent.innerHTML = `
                  <div class="w-12 h-12 bg-gradient-to-br from-gray-700 to-gray-800 rounded-lg flex items-center justify-center border border-gray-600 shadow-inner">
                    <div class="text-center">
                      <svg class="h-5 w-5 text-gray-400 mx-auto mb-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
                      </svg>
                      <div class="text-xs text-gray-500 font-mono">NFT</div>
                    </div>
                  </div>
                `
              }
            }}
          />
        </div>
      )
    }

    // 画像URLがない場合のプレースホルダー
    return (
      <div className="w-12 h-12 bg-gradient-to-br from-gray-700 to-gray-800 rounded-lg flex items-center justify-center border border-gray-600 shadow-inner">
        <div className="text-center">
          <ImageIcon className="h-5 w-5 text-gray-400 mx-auto mb-1" />
          <div className="text-xs text-gray-500 font-mono">NFT</div>
        </div>
      </div>
    )
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
              <h1 className="text-2xl font-bold text-white">NFT管理</h1>
              <p className="text-gray-400 text-sm">NFTの作成・編集・管理</p>
            </div>
          </div>
          <Dialog open={isDialogOpen} onOpenChange={setIsDialogOpen}>
            <DialogTrigger asChild>
              <Button onClick={handleNewNFT} className="bg-red-600 hover:bg-red-700 text-white">
                <Plus className="mr-2 h-4 w-4" />
                新しいNFT
              </Button>
            </DialogTrigger>
            <DialogContent className="bg-gray-800 border-gray-700 text-white max-w-2xl">
              <DialogHeader>
                <DialogTitle>{editingNft ? "NFT編集" : "新しいNFT"}</DialogTitle>
                <DialogDescription className="text-gray-400">NFTの情報を入力してください</DialogDescription>
              </DialogHeader>

              <div className="space-y-4 max-h-[70vh] overflow-y-auto">
                <div>
                  <Label htmlFor="name" className="text-white">
                    NFT名
                  </Label>
                  <Input
                    id="name"
                    value={formData.name}
                    onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                    placeholder="例: SHOGUN NFT 1000"
                    className="bg-gray-700 border-gray-600 text-white"
                  />
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <Label htmlFor="price" className="text-white">
                      価格 (USDT)
                    </Label>
                    <Input
                      id="price"
                      type="number"
                      value={formData.price}
                      onChange={(e) => setFormData({ ...formData, price: e.target.value })}
                      placeholder="1000"
                      className="bg-gray-700 border-gray-600 text-white"
                    />
                  </div>
                  <div>
                    <Label htmlFor="daily_rate_limit" className="text-white">
                      日利上限 (%)
                    </Label>
                    <Input
                      id="daily_rate_limit"
                      type="number"
                      step="0.1"
                      value={formData.daily_rate_limit}
                      onChange={(e) => setFormData({ ...formData, daily_rate_limit: e.target.value })}
                      placeholder="1.0"
                      className="bg-gray-700 border-gray-600 text-white"
                    />
                  </div>
                </div>

                <div>
                  <Label htmlFor="description" className="text-white">
                    説明（任意）
                  </Label>
                  <Input
                    id="description"
                    value={formData.description}
                    onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                    placeholder="NFTの説明"
                    className="bg-gray-700 border-gray-600 text-white"
                  />
                </div>

                {/* 画像アップロード */}
                <div>
                  <Label className="text-white">NFT画像</Label>

                  {/* Blob Token エラー警告 */}
                  {blobTokenError && (
                    <div className="mb-3 p-3 bg-yellow-900/50 border border-yellow-600 rounded-lg flex items-center space-x-2">
                      <AlertTriangle className="h-5 w-5 text-yellow-500" />
                      <div className="text-sm text-yellow-200">
                        <p className="font-medium">画像アップロード機能が無効です</p>
                        <p className="text-xs">環境変数 BLOB_READ_WRITE_TOKEN が設定されていません</p>
                      </div>
                    </div>
                  )}

                  <div className="space-y-3">
                    {formData.image_url && (
                      <div className="flex items-center space-x-3">
                        <div className="relative">
                          <img
                            src={formData.image_url || "/placeholder.svg"}
                            alt="NFT Preview"
                            className="w-20 h-20 object-cover rounded-lg border border-gray-600"
                            crossOrigin="anonymous"
                            onError={(e) => {
                              console.error("プレビュー画像エラー:", formData.image_url)
                              const target = e.currentTarget
                              target.style.display = "none"
                              const parent = target.parentElement
                              if (parent) {
                                parent.innerHTML = `
                                  <div class="w-20 h-20 bg-gradient-to-br from-gray-700 to-gray-800 rounded-lg flex items-center justify-center border border-gray-600">
                                    <div class="text-center">
                                      <svg class="h-8 w-8 text-gray-400 mx-auto mb-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
                                      </svg>
                                      <div class="text-xs text-gray-500">エラー</div>
                                    </div>
                                  </div>
                                `
                              }
                            }}
                          />
                        </div>
                        <div className="flex-1">
                          <p className="text-sm text-gray-400">現在の画像</p>
                          <p className="text-xs text-gray-500 break-all max-w-xs">
                            {formData.image_url.length > 50
                              ? `${formData.image_url.substring(0, 50)}...`
                              : formData.image_url}
                          </p>
                          <Button
                            variant="outline"
                            size="sm"
                            onClick={() => setFormData({ ...formData, image_url: "" })}
                            className="mt-1 border-red-600 text-red-400 hover:bg-red-600 hover:text-white"
                          >
                            削除
                          </Button>
                        </div>
                      </div>
                    )}

                    <div className="space-y-2">
                      <div className="flex items-center space-x-2">
                        <input
                          ref={fileInputRef}
                          type="file"
                          accept="image/*"
                          onChange={handleFileSelect}
                          className="hidden"
                          disabled={blobTokenError}
                        />
                        <Button
                          type="button"
                          variant="outline"
                          onClick={() => fileInputRef.current?.click()}
                          disabled={uploading || blobTokenError}
                          className="border-blue-600 text-blue-400 hover:bg-blue-600 hover:text-white disabled:opacity-50"
                        >
                          {uploading ? (
                            <>
                              <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                              アップロード中...
                            </>
                          ) : (
                            <>
                              <Upload className="mr-2 h-4 w-4" />
                              画像を選択
                            </>
                          )}
                        </Button>
                        <span className="text-sm text-gray-400">5MB以下のJPG, PNG, GIF</span>
                      </div>

                      {/* 手動URL入力 */}
                      <div>
                        <Label htmlFor="manual_image_url" className="text-sm text-gray-400">
                          または画像URLを直接入力
                        </Label>
                        <Input
                          id="manual_image_url"
                          value={formData.image_url}
                          onChange={(e) => setFormData({ ...formData, image_url: e.target.value })}
                          placeholder="https://example.com/image.jpg"
                          className="bg-gray-700 border-gray-600 text-white text-sm"
                        />
                      </div>
                    </div>
                  </div>
                </div>

                <div className="flex items-center space-x-4">
                  <div className="flex items-center space-x-2">
                    <Switch
                      id="is_active"
                      checked={formData.is_active}
                      onCheckedChange={(checked) => setFormData({ ...formData, is_active: checked })}
                    />
                    <Label htmlFor="is_active" className="text-white">
                      アクティブ
                    </Label>
                  </div>
                  <div className="flex items-center space-x-2">
                    <Switch
                      id="is_special"
                      checked={formData.is_special}
                      onCheckedChange={(checked) => setFormData({ ...formData, is_special: checked })}
                    />
                    <Label htmlFor="is_special" className="text-white">
                      特別NFT
                    </Label>
                  </div>
                </div>

                <div className="flex gap-2">
                  <Button onClick={handleSave} disabled={saving || uploading} className="bg-red-600 hover:bg-red-700">
                    {saving ? (
                      <>
                        <Loader2 className="h-4 w-4 animate-spin mr-2" />
                        保存中...
                      </>
                    ) : (
                      "保存"
                    )}
                  </Button>
                  <Button
                    variant="outline"
                    onClick={() => setIsDialogOpen(false)}
                    className="border-gray-600 text-gray-400"
                  >
                    キャンセル
                  </Button>
                </div>
              </div>
            </DialogContent>
          </Dialog>
        </div>
      </header>

      <main className="max-w-7xl mx-auto p-6">
        {/* Blob Token エラー警告（メイン画面） */}
        {blobTokenError && (
          <div className="mb-6 p-4 bg-yellow-900/50 border border-yellow-600 rounded-lg flex items-center space-x-3">
            <AlertTriangle className="h-6 w-6 text-yellow-500" />
            <div className="text-yellow-200">
              <p className="font-medium">画像アップロード機能が無効です</p>
              <p className="text-sm">
                環境変数 BLOB_READ_WRITE_TOKEN が設定されていません。画像URLの手動入力は可能です。
              </p>
            </div>
          </div>
        )}

        {/* 統計 */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-6">
          <Card className="bg-gray-800 border-gray-700">
            <CardContent className="p-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-gray-400 text-sm">総NFT数</p>
                  <p className="text-2xl font-bold text-white">{nfts.length}</p>
                </div>
                <Coins className="h-8 w-8 text-red-500" />
              </div>
            </CardContent>
          </Card>
          <Card className="bg-gray-800 border-gray-700">
            <CardContent className="p-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-gray-400 text-sm">通常NFT</p>
                  <p className="text-2xl font-bold text-white">{nfts.filter((n) => !n.is_special).length}</p>
                </div>
                <Coins className="h-8 w-8 text-blue-500" />
              </div>
            </CardContent>
          </Card>
          <Card className="bg-gray-800 border-gray-700">
            <CardContent className="p-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-gray-400 text-sm">特別NFT</p>
                  <p className="text-2xl font-bold text-white">{nfts.filter((n) => n.is_special).length}</p>
                </div>
                <Coins className="h-8 w-8 text-yellow-500" />
              </div>
            </CardContent>
          </Card>
          <Card className="bg-gray-800 border-gray-700">
            <CardContent className="p-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-gray-400 text-sm">画像あり</p>
                  <p className="text-2xl font-bold text-white">
                    {nfts.filter((n) => n.image_url && n.image_url.trim() !== "").length}
                  </p>
                </div>
                <ImageIcon className="h-8 w-8 text-green-500" />
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
            <Table>
              <TableHeader>
                <TableRow className="border-gray-700">
                  <TableHead className="text-gray-300">画像</TableHead>
                  <TableHead className="text-gray-300">NFT名</TableHead>
                  <TableHead className="text-gray-300">価格</TableHead>
                  <TableHead className="text-gray-300">日利上限</TableHead>
                  <TableHead className="text-gray-300">種別</TableHead>
                  <TableHead className="text-gray-300">保有者数</TableHead>
                  <TableHead className="text-gray-300">ステータス</TableHead>
                  <TableHead className="text-gray-300">操作</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {nfts.map((nft) => (
                  <TableRow key={nft.id} className="border-gray-700">
                    <TableCell>{renderNFTImage(nft)}</TableCell>
                    <TableCell>
                      <div>
                        <div className="text-white font-medium">{nft.name}</div>
                        {nft.description && <div className="text-gray-400 text-sm">{nft.description}</div>}
                        {/* デバッグ情報（開発時のみ表示） */}
                        {process.env.NODE_ENV === "development" && nft.image_url && (
                          <div className="text-xs text-gray-500 mt-1">
                            画像: {nft.image_url.length > 50 ? `${nft.image_url.substring(0, 50)}...` : nft.image_url}
                          </div>
                        )}
                      </div>
                    </TableCell>
                    <TableCell className="text-white font-medium">${nft.price.toLocaleString()}</TableCell>
                    <TableCell className="text-green-400 font-medium">
                      {Number(nft.daily_rate_limit).toFixed(1)}%
                    </TableCell>
                    <TableCell>
                      {nft.is_special ? (
                        <Badge className="bg-yellow-600 text-white">特別NFT</Badge>
                      ) : (
                        <Badge className="bg-blue-600 text-white">通常NFT</Badge>
                      )}
                    </TableCell>
                    <TableCell className="text-white">{nft.user_count}人</TableCell>
                    <TableCell>
                      <Switch checked={nft.is_active} onCheckedChange={() => toggleActive(nft.id, nft.is_active)} />
                    </TableCell>
                    <TableCell>
                      <div className="flex space-x-2">
                        <Button
                          variant="outline"
                          size="sm"
                          onClick={() => handleEdit(nft)}
                          className="border-blue-600 text-blue-400 hover:bg-blue-600 hover:text-white"
                        >
                          <Edit className="h-4 w-4" />
                        </Button>
                        <Button
                          variant="outline"
                          size="sm"
                          onClick={() => handleDelete(nft.id)}
                          className="border-red-600 text-red-400 hover:bg-red-600 hover:text-white"
                          disabled={nft.user_count > 0}
                        >
                          <Trash2 className="h-4 w-4" />
                        </Button>
                      </div>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>

            {nfts.length === 0 && (
              <div className="text-center py-8 text-gray-400">NFTがありません。新しいNFTを作成してください。</div>
            )}
          </CardContent>
        </Card>
      </main>
    </div>
  )
}
