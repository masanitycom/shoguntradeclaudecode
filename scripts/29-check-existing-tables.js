import { createClient } from "@supabase/supabase-js"

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY

const supabase = createClient(supabaseUrl, supabaseKey)

async function checkExistingTables() {
  console.log("=== 既存テーブル構造確認 ===")

  try {
    // usersテーブルの確認
    const { count: userCount } = await supabase.from("users").select("*", { count: "exact", head: true })

    console.log(`👥 既存ユーザー数: ${userCount}人`)

    // nftsテーブルの確認
    const { data: existingNfts } = await supabase.from("nfts").select("id, name, price, is_special").order("price")

    console.log("\n🎨 既存NFT一覧:")
    existingNfts?.forEach((nft) => {
      console.log(`  - ${nft.name}: $${nft.price} (特別: ${nft.is_special})`)
    })

    // user_nftsテーブルの確認
    const { count: userNftCount } = await supabase
      .from("user_nfts")
      .select("*", { count: "exact", head: true })
      .eq("is_active", true)

    console.log(`\n💎 アクティブなuser_nfts数: ${userNftCount}`)

    // tasksテーブルの存在確認
    const { data: tasks, error: tasksError } = await supabase.from("tasks").select("count").limit(1)

    if (tasksError) {
      console.log("📋 tasksテーブル: 存在しません")
    } else {
      console.log("📋 tasksテーブル: 既に存在します")
    }

    // nft_purchase_applicationsテーブルの存在確認
    const { data: apps, error: appsError } = await supabase.from("nft_purchase_applications").select("count").limit(1)

    if (appsError) {
      console.log("🛒 nft_purchase_applicationsテーブル: 存在しません")
    } else {
      console.log("🛒 nft_purchase_applicationsテーブル: 既に存在します")
    }
  } catch (error) {
    console.error("エラー:", error.message)
  }
}

checkExistingTables()
