"use client"

import { useState, useEffect } from "react"
import { Button } from "@/components/ui/button"
import { useRouter } from "next/navigation"
import { createClient } from "@/lib/supabase/supabaseBrowserClient"

export default function HomePage() {
  const [loading, setLoading] = useState(true)
  const router = useRouter()
  const supabase = createClient()

  useEffect(() => {
    checkAuth()
  }, [])

  const checkAuth = async () => {
    try {
      const {
        data: { user },
      } = await supabase.auth.getUser()

      if (user) {
        // ログイン済みの場合、管理者かどうかチェック
        const { data: userData } = await supabase.from("users").select("is_admin").eq("id", user.id).single()

        if (userData?.is_admin) {
          router.push("/admin")
        } else {
          router.push("/dashboard")
        }
        return
      }
    } catch (error) {
      console.error("認証確認エラー:", error)
    } finally {
      setLoading(false)
    }
  }

  if (loading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-red-900 via-black to-red-900 flex items-center justify-center">
        <div className="text-white text-xl">読み込み中...</div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-red-900 via-black to-red-900 flex flex-col">
      {/* メインコンテンツ */}
      <div className="flex-1 flex items-center justify-center">
        <div className="text-center space-y-8 max-w-md mx-auto px-4">
          {/* ロゴ */}
          <div className="mb-12">
            <img src="/images/trade-logo.png" alt="TRADE" className="mx-auto w-80 h-auto drop-shadow-2xl" />
          </div>

          {/* ボタン */}
          <div className="space-y-4">
            <Button
              onClick={() => router.push("/register")}
              size="lg"
              className="bg-red-600 hover:bg-red-700 text-white text-lg px-12 py-4 w-full"
            >
              新規登録
            </Button>
            <Button
              onClick={() => router.push("/login")}
              size="lg"
              className="bg-gray-800 hover:bg-gray-700 text-white border border-gray-600 text-lg px-12 py-4 w-full"
            >
              ログイン
            </Button>
          </div>
        </div>
      </div>

      {/* フッター */}
      <footer className="py-6 text-center">
        <p className="text-gray-400 text-sm">© 2025 SHOGUN TRADE. All rights reserved.</p>
      </footer>
    </div>
  )
}
