"use client"

import { useEffect, useState } from "react"
import { useRouter } from "next/navigation"
import { Button } from "@/components/ui/button"
import { createClient } from "@/lib/supabase/supabaseBrowserClient"

export function AuthButtonClient() {
  const supabase = createClient()
  const router = useRouter()
  const [isLoading, setIsLoading] = useState(false)
  const [isAuthenticated, setIsAuthenticated] = useState(false)

  // Check auth state on mount
  useEffect(() => {
    const getSession = async () => {
      const { data } = await supabase.auth.getUser()
      setIsAuthenticated(!!data.user)
    }

    getSession()

    // Listen for auth changes
    const { data: listener } = supabase.auth.onAuthStateChange(() => {
      getSession()
    })

    return () => {
      listener.subscription.unsubscribe()
    }
  }, [supabase])

  const handleSignOut = async () => {
    setIsLoading(true)
    await supabase.auth.signOut()
    setIsLoading(false)
    router.refresh()
    router.push("/")
  }

  if (isAuthenticated) {
    return (
      <Button onClick={handleSignOut} disabled={isLoading} className="bg-red-600 hover:bg-red-700 text-white">
        {isLoading ? "ログアウト中…" : "ログアウト"}
      </Button>
    )
  }

  return (
    <Button onClick={() => router.push("/login")} className="bg-red-600 hover:bg-red-700 text-white">
      ログイン
    </Button>
  )
}
