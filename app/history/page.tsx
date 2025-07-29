"use client"

import { useState, useEffect } from "react"
import { useRouter } from "next/navigation"
import { Card, CardContent } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { ArrowLeft, ShoppingCart, Gift, Users, TrendingUp } from "lucide-react"
import { createClient } from "@/lib/supabase/supabaseBrowserClient"

interface Transaction {
  id: string
  type: "NFT_PURCHASE" | "REWARD_CLAIM" | "REFERRAL_BONUS" | "DAILY_REWARD"
  amount: number
  status: "PENDING" | "APPROVED" | "REJECTED"
  date: string
  description: string
}

export default function HistoryPage() {
  const [transactions, setTransactions] = useState<Transaction[]>([])
  const [loading, setLoading] = useState(true)
  const [user, setUser] = useState<any>(null)
  const router = useRouter()
  const supabase = createClient()

  useEffect(() => {
    checkAuth()
  }, [])

  useEffect(() => {
    if (user) {
      loadTransactions()
    }
  }, [user])

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

  const loadTransactions = async () => {
    try {
      // サンプルデータを表示（実際のデータがない場合）
      const sampleTransactions: Transaction[] = [
        {
          id: "1",
          type: "NFT_PURCHASE",
          amount: -1000,
          status: "APPROVED",
          date: "2025-06-25",
          description: "SHOGUN NFT 1000 購入",
        },
        {
          id: "2",
          type: "DAILY_REWARD",
          amount: 5.5,
          status: "APPROVED",
          date: "2025-06-24",
          description: "日利報酬",
        },
        {
          id: "3",
          type: "REWARD_CLAIM",
          amount: 75.5,
          status: "PENDING",
          date: "2025-06-23",
          description: "エアドロップ報酬申請",
        },
        {
          id: "4",
          type: "REFERRAL_BONUS",
          amount: 50,
          status: "APPROVED",
          date: "2025-06-22",
          description: "紹介ボーナス",
        },
      ]

      setTransactions(sampleTransactions)
    } catch (error) {
      console.error("取引履歴読み込みエラー:", error)
    } finally {
      setLoading(false)
    }
  }

  const getTransactionIcon = (type: string) => {
    switch (type) {
      case "NFT_PURCHASE":
        return <ShoppingCart className="h-4 w-4" />
      case "REWARD_CLAIM":
        return <Gift className="h-4 w-4" />
      case "REFERRAL_BONUS":
        return <Users className="h-4 w-4" />
      case "DAILY_REWARD":
        return <TrendingUp className="h-4 w-4" />
      default:
        return <TrendingUp className="h-4 w-4" />
    }
  }

  const getStatusBadge = (status: string) => {
    switch (status) {
      case "APPROVED":
        return <Badge className="bg-green-600">承認済み</Badge>
      case "PENDING":
        return <Badge className="bg-yellow-600">承認待ち</Badge>
      case "REJECTED":
        return <Badge className="bg-red-600">却下</Badge>
      default:
        return <Badge>{status}</Badge>
    }
  }

  const filterTransactions = (type?: string) => {
    if (!type) return transactions
    return transactions.filter((t) => t.type === type)
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
            <h1 className="text-2xl font-bold text-white">取引履歴</h1>
            <p className="text-gray-400">あなたの取引履歴を確認できます</p>
          </div>
        </div>
      </header>

      <main className="container mx-auto px-4 py-8">
        <Tabs defaultValue="all" className="w-full">
          <TabsList className="grid w-full grid-cols-5 bg-gray-900/80">
            <TabsTrigger value="all" className="text-white">
              全て
            </TabsTrigger>
            <TabsTrigger value="NFT_PURCHASE" className="text-white">
              NFT購入
            </TabsTrigger>
            <TabsTrigger value="DAILY_REWARD" className="text-white">
              日利報酬
            </TabsTrigger>
            <TabsTrigger value="REWARD_CLAIM" className="text-white">
              報酬申請
            </TabsTrigger>
            <TabsTrigger value="REFERRAL_BONUS" className="text-white">
              紹介ボーナス
            </TabsTrigger>
          </TabsList>

          <TabsContent value="all" className="mt-6">
            <div className="space-y-4">
              {transactions.map((transaction) => (
                <Card key={transaction.id} className="bg-gray-900/80 border-gray-700">
                  <CardContent className="p-4">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center space-x-3">
                        <div className="text-blue-400">{getTransactionIcon(transaction.type)}</div>
                        <div>
                          <h3 className="text-white font-medium">{transaction.description}</h3>
                          <p className="text-gray-400 text-sm">{transaction.date}</p>
                        </div>
                      </div>
                      <div className="text-right space-y-1">
                        <div
                          className={`text-lg font-bold ${transaction.amount > 0 ? "text-green-400" : "text-red-400"}`}
                        >
                          {transaction.amount > 0 ? "+" : ""}${Math.abs(transaction.amount).toFixed(2)}
                        </div>
                        {getStatusBadge(transaction.status)}
                      </div>
                    </div>
                  </CardContent>
                </Card>
              ))}
            </div>
          </TabsContent>

          {["NFT_PURCHASE", "DAILY_REWARD", "REWARD_CLAIM", "REFERRAL_BONUS"].map((type) => (
            <TabsContent key={type} value={type} className="mt-6">
              <div className="space-y-4">
                {filterTransactions(type).map((transaction) => (
                  <Card key={transaction.id} className="bg-gray-900/80 border-gray-700">
                    <CardContent className="p-4">
                      <div className="flex items-center justify-between">
                        <div className="flex items-center space-x-3">
                          <div className="text-blue-400">{getTransactionIcon(transaction.type)}</div>
                          <div>
                            <h3 className="text-white font-medium">{transaction.description}</h3>
                            <p className="text-gray-400 text-sm">{transaction.date}</p>
                          </div>
                        </div>
                        <div className="text-right space-y-1">
                          <div
                            className={`text-lg font-bold ${
                              transaction.amount > 0 ? "text-green-400" : "text-red-400"
                            }`}
                          >
                            {transaction.amount > 0 ? "+" : ""}${Math.abs(transaction.amount).toFixed(2)}
                          </div>
                          {getStatusBadge(transaction.status)}
                        </div>
                      </div>
                    </CardContent>
                  </Card>
                ))}
              </div>
            </TabsContent>
          ))}
        </Tabs>
      </main>
    </div>
  )
}
