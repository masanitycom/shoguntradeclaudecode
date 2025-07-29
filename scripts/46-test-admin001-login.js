import { createClient } from "@supabase/supabase-js"

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY

const supabase = createClient(supabaseUrl, supabaseKey)

async function testAdmin001Login() {
  console.log("🧪 === admin001ログインテスト ===")

  try {
    // admin001ユーザーの情報を取得
    const { data: adminUser, error: userError } = await supabase
      .from("users")
      .select("*")
      .eq("user_id", "admin001")
      .single()

    if (userError) {
      console.log("❌ admin001ユーザーが見つかりません")
      return
    }

    console.log("✅ admin001ユーザー情報:")
    console.log(`   ID: ${adminUser.id}`)
    console.log(`   名前: ${adminUser.name}`)
    console.log(`   メール: ${adminUser.email}`)
    console.log(`   管理者権限: ${adminUser.is_admin}`)

    // 認証情報の確認
    const { data: authUsers, error: authError } = await supabase
      .from("auth.users")
      .select("id, email, email_confirmed_at")
      .eq("email", adminUser.email)

    if (authError) {
      console.log("❌ 認証情報の確認でエラー:", authError.message)
    } else if (authUsers.length === 0) {
      console.log("❌ 認証情報が見つかりません")
    } else {
      console.log("✅ 認証情報が存在します:")
      authUsers.forEach((auth, index) => {
        console.log(`   ${index + 1}. ID: ${auth.id}`)
        console.log(`      メール: ${auth.email}`)
        console.log(`      確認済み: ${auth.email_confirmed_at ? "はい" : "いいえ"}`)
      })
    }

    console.log("\n📋 ログイン手順:")
    console.log("1. /login にアクセス")
    console.log("2. ユーザーID: admin001")
    console.log("3. パスワード: admin123456")
    console.log("4. 自動的に /admin にリダイレクト")

    console.log("\n🔧 問題がある場合:")
    console.log("- scripts/45-safe-admin001-fix.sql を再実行")
    console.log("- ブラウザのキャッシュをクリア")
    console.log("- 別のブラウザで試行")
  } catch (error) {
    console.error("❌ テスト中にエラー:", error.message)
  }
}

testAdmin001Login()
