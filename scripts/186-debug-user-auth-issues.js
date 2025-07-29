import { createClient } from "@supabase/supabase-js"

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY

if (!supabaseUrl || !supabaseServiceKey) {
  console.error("環境変数が設定されていません")
  console.error("NEXT_PUBLIC_SUPABASE_URL:", !!supabaseUrl)
  console.error("SUPABASE_SERVICE_ROLE_KEY:", !!supabaseServiceKey)
  process.exit(1)
}

const supabase = createClient(supabaseUrl, supabaseServiceKey)

async function debugUserAuthIssues() {
  try {
    console.log("=== ユーザー認証問題のデバッグ ===\n")

    // 1. auth.usersテーブルの確認
    console.log("1. auth.usersテーブルの確認:")
    const { data: authUsers, error: authError } = await supabase.auth.admin.listUsers()

    if (authError) {
      console.error("auth.users取得エラー:", authError)
    } else {
      console.log(`auth.usersの総数: ${authUsers.users.length}`)
      authUsers.users.forEach((user) => {
        console.log(`  - ID: ${user.id}, Email: ${user.email}, Created: ${user.created_at}`)
      })
    }

    console.log("\n2. public.usersテーブルの確認:")
    const { data: publicUsers, error: publicError } = await supabase
      .from("users")
      .select("*")
      .order("created_at", { ascending: false })

    if (publicError) {
      console.error("public.users取得エラー:", publicError)
    } else {
      console.log(`public.usersの総数: ${publicUsers.length}`)
      publicUsers.forEach((user) => {
        console.log(`  - ID: ${user.id}, Name: ${user.name}, Email: ${user.email}, UserID: ${user.user_id}`)
      })
    }

    console.log("\n3. IDの一致確認:")
    if (authUsers && publicUsers) {
      const authIds = new Set(authUsers.users.map((u) => u.id))
      const publicIds = new Set(publicUsers.map((u) => u.id))

      console.log("auth.usersにあってpublic.usersにないID:")
      authIds.forEach((id) => {
        if (!publicIds.has(id)) {
          const authUser = authUsers.users.find((u) => u.id === id)
          console.log(`  - ${id} (${authUser?.email})`)
        }
      })

      console.log("public.usersにあってauth.usersにないID:")
      publicIds.forEach((id) => {
        if (!authIds.has(id)) {
          const publicUser = publicUsers.find((u) => u.id === id)
          console.log(`  - ${id} (${publicUser?.email})`)
        }
      })

      console.log("\n4. 重複チェック:")
      const emailCounts = {}
      publicUsers.forEach((user) => {
        emailCounts[user.email] = (emailCounts[user.email] || 0) + 1
      })

      Object.entries(emailCounts).forEach(([email, count]) => {
        if (count > 1) {
          console.log(`重複メール: ${email} (${count}件)`)
          const duplicates = publicUsers.filter((u) => u.email === email)
          duplicates.forEach((dup) => {
            console.log(`  - ID: ${dup.id}, Name: ${dup.name}, UserID: ${dup.user_id}`)
          })
        }
      })
    }

    console.log("\n5. 最近のログイン試行確認:")
    // 最近作成されたユーザーを確認
    if (authUsers) {
      const recentUsers = authUsers.users
        .filter((u) => new Date(u.created_at) > new Date(Date.now() - 24 * 60 * 60 * 1000))
        .sort((a, b) => new Date(b.created_at) - new Date(a.created_at))

      console.log(`過去24時間に作成されたauth.users: ${recentUsers.length}件`)
      recentUsers.forEach((user) => {
        console.log(`  - ID: ${user.id}, Email: ${user.email}, Created: ${user.created_at}`)

        // 対応するpublic.usersレコードがあるかチェック
        const publicUser = publicUsers?.find((p) => p.id === user.id)
        if (publicUser) {
          console.log(`    → public.usersに存在: ${publicUser.name} (${publicUser.user_id})`)
        } else {
          console.log(`    → public.usersに存在しない`)
        }
      })
    }

    console.log("\n6. 特定ユーザーの詳細確認:")
    // admin001の確認
    const admin001Auth = authUsers?.users.find((u) => u.email === "admin@shogun-trade.com")
    const admin001Public = publicUsers?.find((u) => u.email === "admin@shogun-trade.com")

    console.log("admin001 (admin@shogun-trade.com):")
    console.log("  auth.users:", admin001Auth ? `存在 (ID: ${admin001Auth.id})` : "存在しない")
    console.log("  public.users:", admin001Public ? `存在 (ID: ${admin001Public.id})` : "存在しない")

    // ohtakiyoの確認
    const ohtakiyoAuth = authUsers?.users.find((u) => u.email === "ohtakiyo@gmail.com")
    const ohtakiyoPublic = publicUsers?.find((u) => u.email === "ohtakiyo@gmail.com")

    console.log("ohtakiyo (ohtakiyo@gmail.com):")
    console.log("  auth.users:", ohtakiyoAuth ? `存在 (ID: ${ohtakiyoAuth.id})` : "存在しない")
    console.log("  public.users:", ohtakiyoPublic ? `存在 (ID: ${ohtakiyoPublic.id})` : "存在しない")
  } catch (error) {
    console.error("デバッグ実行エラー:", error)
  }
}

debugUserAuthIssues()
