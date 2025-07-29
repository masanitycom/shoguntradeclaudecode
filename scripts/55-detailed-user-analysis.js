// ユーザーデータの詳細分析

import { createClient } from "@supabase/supabase-js"

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY

if (!supabaseUrl || !supabaseKey) {
  console.error("❌ Supabase環境変数が設定されていません")
  process.exit(1)
}

const supabase = createClient(supabaseUrl, supabaseKey)

async function analyzeUserData() {
  console.log("🔍 ユーザーデータの詳細分析を開始...\n")

  try {
    // 1. 基本統計
    console.log("=== 基本統計 ===")
    const { data: stats, error: statsError } = await supabase.from("users").select("*", { count: "exact" })

    if (statsError) throw statsError

    console.log(`📊 総ユーザー数: ${stats.length}人`)

    // 2. 管理者ユーザー確認
    console.log("\n=== 管理者ユーザー ===")
    const { data: admins, error: adminError } = await supabase
      .from("users")
      .select("name, user_id, email, is_admin")
      .eq("is_admin", true)

    if (adminError) throw adminError

    console.log(`👑 管理者数: ${admins.length}人`)
    admins.forEach((admin) => {
      console.log(`  - ${admin.name} (${admin.user_id}) - ${admin.email}`)
    })

    // 3. 紹介システムの状況
    console.log("\n=== 紹介システム状況 ===")
    const { data: referralStats, error: referralError } = await supabase
      .from("users")
      .select("referral_code, my_referral_code, referral_link")

    if (referralError) throw referralError

    const withReferralCode = referralStats.filter((u) => u.referral_code).length
    const withMyReferralCode = referralStats.filter((u) => u.my_referral_code).length
    const withReferralLink = referralStats.filter((u) => u.referral_link).length

    console.log(`📝 紹介コード保有: ${withReferralCode}人`)
    console.log(`🔗 自分の紹介コード保有: ${withMyReferralCode}人`)
    console.log(`🌐 紹介リンク保有: ${withReferralLink}人`)

    // 4. NFT保有状況
    console.log("\n=== NFT保有状況 ===")
    const { data: nftStats, error: nftError } = await supabase.from("user_nfts").select(`
        *,
        users(name, user_id),
        nfts(name, price)
      `)

    if (nftError) throw nftError

    console.log(`💎 NFT保有記録数: ${nftStats.length}件`)

    const activeNfts = nftStats.filter((nft) => nft.is_active)
    console.log(`✅ アクティブNFT: ${activeNfts.length}件`)

    // 5. 最近のユーザー登録
    console.log("\n=== 最近のユーザー登録（上位5件）===")
    const { data: recentUsers, error: recentError } = await supabase
      .from("users")
      .select("name, user_id, email, created_at")
      .eq("is_admin", false)
      .order("created_at", { ascending: false })
      .limit(5)

    if (recentError) throw recentError

    recentUsers.forEach((user, index) => {
      const date = new Date(user.created_at).toLocaleDateString("ja-JP")
      console.log(`  ${index + 1}. ${user.name} (${user.user_id}) - ${date}`)
    })

    // 6. テーブル構造確認
    console.log("\n=== テーブル構造確認 ===")

    // usersテーブルの構造を確認
    const { data: userColumns, error: columnError } = await supabase
      .rpc("get_table_columns", { table_name: "users" })
      .catch(() => {
        // RPCが使えない場合は、直接クエリで確認
        return supabase.from("users").select("*").limit(1)
      })

    if (!columnError && userColumns) {
      console.log("✅ usersテーブルは正常にアクセス可能")
    }

    console.log("\n🎉 分析完了！")
  } catch (error) {
    console.error("❌ 分析中にエラーが発生:", error.message)
  }
}

analyzeUserData()
