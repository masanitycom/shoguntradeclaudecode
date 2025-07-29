const { createClient } = require("@supabase/supabase-js")

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY

if (!supabaseUrl || !supabaseServiceKey) {
  console.error("Missing Supabase environment variables")
  process.exit(1)
}

const supabase = createClient(supabaseUrl, supabaseServiceKey)

async function finalVerification() {
  try {
    console.log("🔍 最終確認を開始...\n")

    // 1. 基本統計
    const { data: authUsers, error: authError } = await supabase.auth.admin.listUsers()
    if (authError) throw authError

    const { data: publicUsers, error: publicError } = await supabase
      .from("users")
      .select("id, email, user_id, name, is_admin")

    if (publicError) throw publicError

    console.log("📊 最終統計:")
    console.log(`   auth.users: ${authUsers.users.length}人`)
    console.log(`   public.users: ${publicUsers.length}人`)

    // 2. 完全一致の確認
    const perfectMatches = publicUsers.filter((pu) =>
      authUsers.users.some((au) => au.id === pu.id && au.email === pu.email),
    )
    console.log(`   完全一致: ${perfectMatches.length}人`)

    // 3. 残りの不一致確認
    const authOnlyUsers = authUsers.users.filter((au) => !publicUsers.some((pu) => pu.id === au.id))
    const publicOnlyUsers = publicUsers.filter((pu) => !authUsers.users.some((au) => au.id === pu.id))

    console.log(`   auth.usersのみ: ${authOnlyUsers.length}人`)
    console.log(`   public.usersのみ: ${publicOnlyUsers.length}人`)

    // 4. メール重複（ID不一致）の確認
    const emailMismatches = []
    for (const authUser of authUsers.users) {
      const publicUser = publicUsers.find((pu) => pu.email === authUser.email)
      if (publicUser && publicUser.id !== authUser.id) {
        emailMismatches.push({
          email: authUser.email,
          authId: authUser.id,
          publicId: publicUser.id,
        })
      }
    }

    console.log(`   メール一致・ID不一致: ${emailMismatches.length}人\n`)

    // 5. admin001の詳細確認
    const adminAuthUser = authUsers.users.find((u) => u.email === "admin@shogun-trade.com")
    const adminPublicUser = publicUsers.find((u) => u.email === "admin@shogun-trade.com")

    console.log("👑 admin001の最終状況:")
    if (adminAuthUser && adminPublicUser) {
      const isIdMatch = adminAuthUser.id === adminPublicUser.id
      console.log(`   ✅ 両方に存在`)
      console.log(`   auth ID: ${adminAuthUser.id}`)
      console.log(`   public ID: ${adminPublicUser.id}`)
      console.log(`   user_id: ${adminPublicUser.user_id}`)
      console.log(`   ID一致: ${isIdMatch ? "✅ 完璧" : "❌ まだ不一致"}`)
      console.log(`   管理者権限: ${adminPublicUser.is_admin ? "✅" : "❌"}`)

      if (isIdMatch) {
        console.log("   🎉 admin001のログインテスト可能！")
      } else {
        console.log("   ⚠️  admin001の修正が必要")
      }
    } else {
      console.log(`   ❌ 不完全な状態`)
      console.log(`   auth存在: ${adminAuthUser ? "✅" : "❌"}`)
      console.log(`   public存在: ${adminPublicUser ? "✅" : "❌"}`)
    }
    console.log()

    // 6. 関連データの整合性確認
    const { data: userNfts, error: nftError } = await supabase
      .from("user_nfts")
      .select("user_id, is_active")
      .eq("is_active", true)

    if (nftError) throw nftError

    // 1人1枚制限の確認
    const nftCounts = {}
    userNfts.forEach((nft) => {
      nftCounts[nft.user_id] = (nftCounts[nft.user_id] || 0) + 1
    })

    const multipleNftUsers = Object.entries(nftCounts).filter(([userId, count]) => count > 1)

    console.log("🎯 NFT所有状況:")
    console.log(`   アクティブNFT総数: ${userNfts.length}個`)
    console.log(`   複数NFT所有者: ${multipleNftUsers.length}人`)

    if (multipleNftUsers.length > 0) {
      console.log("   ⚠️  1人1枚制限違反:")
      multipleNftUsers.slice(0, 5).forEach(([userId, count]) => {
        const user = publicUsers.find((u) => u.id === userId)
        console.log(`     ${user?.email || userId}: ${count}個`)
      })
    } else {
      console.log("   ✅ 1人1枚制限が正常に機能")
    }

    console.log("\n🎉 最終確認完了！")

    // 7. 問題がある場合の対処法提示
    if (emailMismatches.length > 0) {
      console.log("\n⚠️  まだ修正が必要な項目:")
      console.log(`   - メール一致・ID不一致: ${emailMismatches.length}人`)
      console.log("   → 再度修正スクリプトを実行してください")
    }

    if (multipleNftUsers.length > 0) {
      console.log(`   - 複数NFT所有者: ${multipleNftUsers.length}人`)
      console.log("   → NFTの重複を解消してください")
    }

    if (emailMismatches.length === 0 && multipleNftUsers.length === 0) {
      console.log("\n✅ 全ての問題が解決されました！")
      console.log("   admin001でのログインテストを実行してください")
    }
  } catch (error) {
    console.error("❌ エラーが発生しました:", error)
  }
}

finalVerification()
