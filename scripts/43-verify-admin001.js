import { createClient } from "@supabase/supabase-js"

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY

const supabase = createClient(supabaseUrl, supabaseKey)

async function verifyAdmin001() {
  console.log("🔍 === admin001ユーザー検証 ===")

  try {
    // admin001ユーザーの確認
    const { data: admin001, error: userError } = await supabase
      .from("users")
      .select("*")
      .eq("user_id", "admin001")
      .single()

    if (userError) {
      console.log("❌ admin001ユーザーが見つかりません")
      return
    }

    console.log("✅ admin001ユーザー情報:")
    console.log(`   ID: ${admin001.id}`)
    console.log(`   名前: ${admin001.name}`)
    console.log(`   メール: ${admin001.email}`)
    console.log(`   管理者権限: ${admin001.is_admin}`)

    // 認証情報の確認
    const { data: authUser, error: authError } = await supabase
      .from("auth.users")
      .select("id, email, email_confirmed_at")
      .eq("id", admin001.id)
      .single()

    if (authError) {
      console.log("❌ 認証情報が見つかりません")
      console.log("修正スクリプトを実行してください: scripts/42-fix-admin001-login.sql")
    } else {
      console.log("✅ 認証情報が存在します")
      console.log(`   認証メール: ${authUser.email}`)
      console.log(`   メール確認済み: ${authUser.email_confirmed_at ? "はい" : "いいえ"}`)
    }

    console.log("\n📋 ログイン方法:")
    console.log("1. /login にアクセス")
    console.log("2. ユーザーID: admin001")
    console.log("3. パスワード: admin123456 (デフォルト)")
    console.log("4. 自動的に管理画面にリダイレクトされます")
  } catch (error) {
    console.error("❌ エラー:", error.message)
  }
}

verifyAdmin001()
