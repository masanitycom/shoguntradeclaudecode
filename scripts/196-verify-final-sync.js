const { createClient } = require("@supabase/supabase-js")

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY

if (!supabaseUrl || !supabaseServiceKey) {
  console.error("Missing Supabase environment variables")
  process.exit(1)
}

const supabase = createClient(supabaseUrl, supabaseServiceKey)

async function verifyUserSync() {
  try {
    console.log("🔍 ユーザー同期の最終確認を開始...\n")

    // 1. 基本統計
    const { data: authUsers, error: authError } = await supabase.auth.admin.listUsers()
    if (authError) throw authError

    const { data: publicUsers, error: publicError } = await supabase
      .from("users")
      .select("id, email, user_id, name, is_admin")

    if (publicError) throw publicError

    console.log("📊 基本統計:")
    console.log(`   auth.users: ${authUsers.users.length}人`)
    console.log(`   public.users: ${publicUsers.length}人`)

    // 2. ID一致確認
    const matchedUsers = publicUsers.filter((pu) => authUsers.users.some((au) => au.id === pu.id))
    console.log(`   ID一致: ${matchedUsers.length}人`)

    // 3. メール一致確認
    const emailMatches = publicUsers.filter((pu) => authUsers.users.some((au) => au.email === pu.email))
    console.log(`   メール一致: ${emailMatches.length}人\n`)

    // 4. 不一致の詳細確認
    const authOnlyUsers = authUsers.users.filter((au) => !publicUsers.some((pu) => pu.id === au.id))

    const publicOnlyUsers = publicUsers.filter((pu) => !authUsers.users.some((au) => au.id === pu.id))

    if (authOnlyUsers.length > 0) {
      console.log("⚠️  auth.usersのみに存在するユーザー:")
      authOnlyUsers.slice(0, 5).forEach((user) => {
        console.log(`   - ${user.email} (${user.id})`)
      })
      if (authOnlyUsers.length > 5) {
        console.log(`   ... 他${authOnlyUsers.length - 5}人`)
      }
      console.log()
    }

    if (publicOnlyUsers.length > 0) {
      console.log("⚠️  public.usersのみに存在するユーザー:")
      publicOnlyUsers.slice(0, 5).forEach((user) => {
        console.log(`   - ${user.email} (${user.id})`)
      })
      if (publicOnlyUsers.length > 5) {
        console.log(`   ... 他${publicOnlyUsers.length - 5}人`)
      }
      console.log()
    }

    // 5. admin001の確認
    const adminAuthUser = authUsers.users.find((u) => u.email === "admin@shogun-trade.com")
    const adminPublicUser = publicUsers.find((u) => u.email === "admin@shogun-trade.com")

    console.log("👑 admin001の状況:")
    if (adminAuthUser && adminPublicUser) {
      console.log(`   ✅ 両方に存在`)
      console.log(`   auth ID: ${adminAuthUser.id}`)
      console.log(`   public ID: ${adminPublicUser.id}`)
      console.log(`   user_id: ${adminPublicUser.user_id}`)
      console.log(`   ID一致: ${adminAuthUser.id === adminPublicUser.id ? "✅" : "❌"}`)
      console.log(`   管理者権限: ${adminPublicUser.is_admin ? "✅" : "❌"}`)
    } else {
      console.log(`   ❌ 不完全な状態`)
      console.log(`   auth存在: ${adminAuthUser ? "✅" : "❌"}`)
      console.log(`   public存在: ${adminPublicUser ? "✅" : "❌"}`)
    }
    console.log()

    // 6. 関連データの整合性確認
    console.log("🔗 関連データの整合性確認:")

    // user_nfts
    const { data: userNfts, error: nftError } = await supabase.from("user_nfts").select("user_id").limit(1000)

    if (!nftError && userNfts) {
      const orphanedNfts = userNfts.filter((nft) => !publicUsers.some((user) => user.id === nft.user_id))
      console.log(`   user_nfts: ${userNfts.length}件中 ${orphanedNfts.length}件が孤立`)
    }

    // nft_purchase_applications
    const { data: applications, error: appError } = await supabase
      .from("nft_purchase_applications")
      .select("user_id")
      .limit(1000)

    if (!appError && applications) {
      const orphanedApps = applications.filter((app) => !publicUsers.some((user) => user.id === app.user_id))
      console.log(`   nft_purchase_applications: ${applications.length}件中 ${orphanedApps.length}件が孤立`)
    }

    // reward_applications
    const { data: rewards, error: rewardError } = await supabase
      .from("reward_applications")
      .select("user_id")
      .limit(1000)

    if (!rewardError && rewards) {
      const orphanedRewards = rewards.filter((reward) => !publicUsers.some((user) => user.id === reward.user_id))
      console.log(`   reward_applications: ${rewards.length}件中 ${orphanedRewards.length}件が孤立`)
    }

    // 7. 1人1枚制限の確認
    const { data: nftCounts, error: nftCountError } = await supabase
      .from("user_nfts")
      .select("user_id")
      .eq("is_active", true)

    if (!nftCountError && nftCounts) {
      const userNftCounts = nftCounts.reduce((acc, nft) => {
        acc[nft.user_id] = (acc[nft.user_id] || 0) + 1
        return acc
      }, {})

      const multipleNftUsers = Object.entries(userNftCounts).filter(([_, count]) => count > 1)
      console.log(`   1人1枚制限違反: ${multipleNftUsers.length}人`)

      if (multipleNftUsers.length > 0) {
        console.log("   違反ユーザー:")
        multipleNftUsers.slice(0, 3).forEach(([userId, count]) => {
          const user = publicUsers.find((u) => u.id === userId)
          console.log(`     - ${user?.name || "Unknown"} (${user?.user_id}): ${count}枚`)
        })
      }
    }

    // 8. 推奨アクション
    console.log("\n📋 推奨アクション:")

    if (authOnlyUsers.length === 0 && publicOnlyUsers.length === 0) {
      console.log("   ✅ 同期完了！追加のアクションは不要です")
    } else {
      if (authOnlyUsers.length > 0) {
        console.log(`   🔧 ${authOnlyUsers.length}人のauth.usersユーザーをpublic.usersに追加`)
      }
      if (publicOnlyUsers.length > 0) {
        console.log(`   🗑️  ${publicOnlyUsers.length}人の孤立したpublic.usersレコードを確認`)
      }
    }

    if (adminAuthUser && adminPublicUser && adminAuthUser.id === adminPublicUser.id) {
      console.log("   ✅ admin001のログインテストを実行可能")
    } else {
      console.log("   ⚠️  admin001の設定を再確認してください")
    }

    console.log("\n🎯 次のステップ:")
    console.log("   1. ダッシュボードページのテスト")
    console.log("   2. admin001でのログインテスト")
    console.log("   3. 一般ユーザーでのログインテスト")
    console.log("   4. NFT購入・報酬申請機能のテスト")
  } catch (error) {
    console.error("❌ 確認中にエラーが発生:", error.message)
  }
}

verifyUserSync()
