import { createClient } from "@supabase/supabase-js"

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY

const supabase = createClient(supabaseUrl, supabaseKey)

async function checkAdminUsers() {
  console.log("🔍 === 管理者ユーザー確認 ===")

  try {
    // 全ユーザーを確認
    const { data: allUsers, error: allError } = await supabase.from("users").select("*").order("created_at")

    if (allError) throw allError

    console.log(`\n👥 総ユーザー数: ${allUsers.length}人`)

    // 管理者ユーザーを確認
    const adminUsers = allUsers.filter((user) => user.is_admin)
    console.log(`\n👑 管理者ユーザー数: ${adminUsers.length}人`)

    if (adminUsers.length > 0) {
      console.log("\n管理者ユーザー一覧:")
      adminUsers.forEach((admin, index) => {
        console.log(`${index + 1}. ${admin.name} (${admin.user_id})`)
        console.log(`   メール: ${admin.email}`)
        console.log(`   作成日: ${new Date(admin.created_at).toLocaleString("ja-JP")}`)
        console.log("")
      })
    } else {
      console.log("\n❌ 管理者ユーザーが見つかりません")
      console.log("最初のユーザーを管理者に昇格させます...")

      if (allUsers.length > 0) {
        const firstUser = allUsers[0]
        const { error: updateError } = await supabase
          .from("users")
          .update({
            is_admin: true,
            user_id: "admin001",
            name: "システム管理者",
            updated_at: new Date().toISOString(),
          })
          .eq("id", firstUser.id)

        if (updateError) throw updateError

        console.log(`✅ ${firstUser.email} を管理者に昇格しました`)
        console.log("ログイン情報:")
        console.log(`ユーザーID: admin001`)
        console.log(`メール: ${firstUser.email}`)
        console.log("パスワード: 登録時に設定したパスワード")
      }
    }

    console.log("\n📋 ログイン方法:")
    console.log("1. /admin/login にアクセス")
    console.log("2. ユーザーIDまたはメールアドレスを入力")
    console.log("3. パスワードを入力")
    console.log("4. 管理画面にアクセス")
  } catch (error) {
    console.error("❌ エラー:", error.message)
  }
}

checkAdminUsers()
