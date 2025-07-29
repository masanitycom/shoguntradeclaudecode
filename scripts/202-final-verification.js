const { createClient } = require("@supabase/supabase-js")

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY

if (!supabaseUrl || !supabaseServiceKey) {
  console.error("Missing Supabase environment variables")
  process.exit(1)
}

const supabase = createClient(supabaseUrl, supabaseServiceKey)

async function verifyFinalSync() {
  console.log("🔍 最終同期確認を開始...\n")

  try {
    // 1. 基本統計
    const { data: authUsers } = await supabase.rpc("get_auth_users_count")
    const { data: publicUsers } = await supabase.from("users").select("id", { count: "exact" })

    console.log("📊 基本統計:")
    console.log(`   auth.users: ${authUsers || "N/A"} 件`)
    console.log(`   public.users: ${publicUsers?.length || 0} 件\n`)

    // 2. ID一致確認
    const { data: perfectMatches } = await supabase.rpc("check_perfect_id_matches")
    console.log(`✅ 完全一致 (ID): ${perfectMatches || 0} 件`)

    // 3. メール一致・ID不一致確認
    const { data: emailMismatches } = await supabase.rpc("check_email_id_mismatches")
    console.log(`❌ メール一致・ID不一致: ${emailMismatches || 0} 件`)

    // 4. admin001確認
    const { data: adminCheck } = await supabase
      .from("users")
      .select("id, user_id, email, is_admin")
      .eq("email", "admin@shogun-trade.com")
      .single()

    console.log("\n👑 admin001確認:")
    if (adminCheck) {
      console.log(`   ID: ${adminCheck.id}`)
      console.log(`   User ID: ${adminCheck.user_id}`)
      console.log(`   Email: ${adminCheck.email}`)
      console.log(`   Is Admin: ${adminCheck.is_admin}`)
    } else {
      console.log("   ❌ admin001が見つかりません")
    }

    // 5. NFT所有状況確認
    const { data: nftOwnership } = await supabase.from("user_nfts").select("user_id").eq("is_active", true)

    const userNftCounts = {}
    nftOwnership?.forEach((nft) => {
      userNftCounts[nft.user_id] = (userNftCounts[nft.user_id] || 0) + 1
    })

    const multipleNftUsers = Object.entries(userNftCounts).filter(([_, count]) => count > 1)

    console.log("\n🎯 NFT所有状況:")
    console.log(`   アクティブNFT総数: ${nftOwnership?.length || 0} 件`)
    console.log(`   複数NFT所有ユーザー: ${multipleNftUsers.length} 人`)

    if (multipleNftUsers.length > 0) {
      console.log("   ⚠️ 複数NFT所有者:")
      multipleNftUsers.slice(0, 5).forEach(([userId, count]) => {
        console.log(`     ${userId}: ${count} 件`)
      })
    }

    // 6. 関連データ整合性確認
    const { data: orphanedNfts } = await supabase
      .from("user_nfts")
      .select("user_id")
      .not("user_id", "in", `(${publicUsers?.map((u) => `'${u.id}'`).join(",") || "''"})`)
      .eq("is_active", true)

    console.log("\n🔗 データ整合性:")
    console.log(`   孤立したNFT: ${orphanedNfts?.length || 0} 件`)

    // 7. 最終判定
    console.log("\n🎉 最終判定:")
    if (emailMismatches === 0 && multipleNftUsers.length === 0 && (orphanedNfts?.length || 0) === 0) {
      console.log("   ✅ 同期完了！すべて正常です")
      console.log("   ✅ admin001でログインテストを実行してください")
    } else {
      console.log("   ⚠️ まだ問題があります:")
      if (emailMismatches > 0) console.log(`     - メール不一致: ${emailMismatches} 件`)
      if (multipleNftUsers.length > 0) console.log(`     - 複数NFT: ${multipleNftUsers.length} 人`)
      if ((orphanedNfts?.length || 0) > 0) console.log(`     - 孤立NFT: ${orphanedNfts.length} 件`)
    }
  } catch (error) {
    console.error("❌ 確認中にエラーが発生:", error.message)
  }
}

verifyFinalSync()
