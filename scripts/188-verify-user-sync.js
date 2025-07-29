import { createClient } from "@supabase/supabase-js"

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY

if (!supabaseUrl || !supabaseServiceKey) {
  console.error("環境変数が設定されていません")
  process.exit(1)
}

const supabase = createClient(supabaseUrl, supabaseServiceKey)

async function verifyUserSync() {
  try {
    console.log("=== ユーザー同期確認 ===\n")

    // 1. 総数確認
    const { data: authUsers, error: authError } = await supabase.auth.admin.listUsers()
    const { data: publicUsers, error: publicError } = await supabase.from("users").select("*")

    if (authError || publicError) {
      console.error("データ取得エラー:", authError || publicError)
      return
    }

    console.log(`auth.users総数: ${authUsers.users.length}`)
    console.log(`public.users総数: ${publicUsers.length}`)

    // 2. 一致確認
    const authIds = new Set(authUsers.users.map((u) => u.id))
    const publicIds = new Set(publicUsers.map((u) => u.id))

    const matchedCount = [...authIds].filter((id) => publicIds.has(id)).length
    console.log(`一致するレコード数: ${matchedCount}`)

    // 3. 不一致確認
    const authOnlyIds = [...authIds].filter((id) => !publicIds.has(id))
    const publicOnlyIds = [...publicIds].filter((id) => !authIds.has(id))

    console.log(`\nauth.usersのみ: ${authOnlyIds.length}件`)
    if (authOnlyIds.length > 0) {
      authOnlyIds.slice(0, 5).forEach((id) => {
        const user = authUsers.users.find((u) => u.id === id)
        console.log(`  - ${id} (${user?.email})`)
      })
      if (authOnlyIds.length > 5) {
        console.log(`  ... 他${authOnlyIds.length - 5}件`)
      }
    }

    console.log(`\npublic.usersのみ: ${publicOnlyIds.length}件`)
    if (publicOnlyIds.length > 0) {
      publicOnlyIds.slice(0, 5).forEach((id) => {
        const user = publicUsers.find((u) => u.id === id)
        console.log(`  - ${id} (${user?.email})`)
      })
      if (publicOnlyIds.length > 5) {
        console.log(`  ... 他${publicOnlyIds.length - 5}件`)
      }
    }

    // 4. 特定ユーザー確認
    console.log("\n=== 特定ユーザー確認 ===")

    // admin001
    const admin001Auth = authUsers.users.find((u) => u.email === "admin@shogun-trade.com")
    const admin001Public = publicUsers.find((u) => u.email === "admin@shogun-trade.com")

    console.log("\nadmin001 (admin@shogun-trade.com):")
    console.log(`  auth.users: ${admin001Auth ? "存在" : "存在しない"}`)
    console.log(`  public.users: ${admin001Public ? "存在" : "存在しない"}`)

    if (admin001Auth && admin001Public) {
      console.log(`  ID一致: ${admin001Auth.id === admin001Public.id ? "YES" : "NO"}`)
      if (admin001Auth.id !== admin001Public.id) {
        console.log(`    auth.users ID: ${admin001Auth.id}`)
        console.log(`    public.users ID: ${admin001Public.id}`)
      }
    }

    // 5. メールアドレス重複確認
    console.log("\n=== メールアドレス重複確認 ===")
    const emailCounts = {}
    publicUsers.forEach((user) => {
      if (emailCounts[user.email]) {
        emailCounts[user.email]++
      } else {
        emailCounts[user.email] = 1
      }
    })

    const duplicateEmails = Object.entries(emailCounts).filter(([email, count]) => count > 1)
    if (duplicateEmails.length > 0) {
      console.log("重複メールアドレス:")
      duplicateEmails.forEach(([email, count]) => {
        console.log(`  ${email}: ${count}件`)
      })
    } else {
      console.log("メールアドレスの重複なし")
    }

    // 6. 最初の数件のユーザーでテスト
    console.log("\n=== ランダムユーザーテスト ===")
    const testUsers = authUsers.users.slice(0, 5)
    testUsers.forEach((authUser) => {
      const publicUser = publicUsers.find((p) => p.id === authUser.id)
      console.log(`${authUser.email}: ${publicUser ? "✅ OK" : "❌ NG"}`)
    })

    // 7. 同期状況サマリー
    console.log("\n=== 同期状況サマリー ===")
    const syncPercentage = ((matchedCount / authUsers.users.length) * 100).toFixed(1)
    console.log(`同期率: ${syncPercentage}% (${matchedCount}/${authUsers.users.length})`)

    if (authOnlyIds.length === 0 && publicOnlyIds.length <= 1) {
      console.log("✅ 同期完了！")
    } else {
      console.log("⚠️  同期未完了")
    }
  } catch (error) {
    console.error("確認エラー:", error)
  }
}

verifyUserSync()
