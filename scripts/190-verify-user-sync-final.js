// ユーザー同期の最終確認スクリプト

const { createClient } = require("@supabase/supabase-js")

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY

if (!supabaseUrl || !supabaseServiceKey) {
  console.error("❌ Supabase環境変数が設定されていません")
  process.exit(1)
}

const supabase = createClient(supabaseUrl, supabaseServiceKey)

async function verifyUserSync() {
  try {
    console.log("🔍 ユーザー同期の最終確認を開始...\n")

    // 1. 基本統計
    const { data: authUsers, error: authError } = await supabase.auth.admin.listUsers()
    if (authError) throw authError

    const { data: publicUsers, error: publicError } = await supabase.from("users").select("id, email, user_id, name")

    if (publicError) throw publicError

    console.log("📊 基本統計:")
    console.log(`   auth.users: ${authUsers.users.length}人`)
    console.log(`   public.users: ${publicUsers.length}人`)

    // 2. ID一致確認
    const matchedUsers = publicUsers.filter((pu) => authUsers.users.some((au) => au.id === pu.id))
    console.log(`   ID一致: ${matchedUsers.length}人`)

    // 3. メール一致確認
    const emailMatched = publicUsers.filter((pu) => authUsers.users.some((au) => au.email === pu.email))
    console.log(`   メール一致: ${emailMatched.length}人\n`)

    // 4. 不一致ユーザーの確認
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
      console.log("")
    }

    if (publicOnlyUsers.length > 0) {
      console.log("⚠️  public.usersのみに存在するユーザー:")
      publicOnlyUsers.slice(0, 5).forEach((user) => {
        console.log(`   - ${user.email} (${user.id})`)
      })
      if (publicOnlyUsers.length > 5) {
        console.log(`   ... 他${publicOnlyUsers.length - 5}人`)
      }
      console.log("")
    }

    // 5. admin001の確認
    const adminAuthUser = authUsers.users.find((u) => u.email === "admin@shogun-trade.com")
    const adminPublicUser = publicUsers.find((u) => u.email === "admin@shogun-trade.com")

    console.log("👑 admin001の状況:")
    if (adminAuthUser && adminPublicUser) {
      if (adminAuthUser.id === adminPublicUser.id) {
        console.log(`   ✅ 正常に同期済み (ID: ${adminAuthUser.id})`)
        console.log(`   📧 メール: ${adminAuthUser.email}`)
        console.log(`   🆔 ユーザーID: ${adminPublicUser.user_id}`)
      } else {
        console.log(`   ❌ ID不一致`)
        console.log(`   📧 auth ID: ${adminAuthUser.id}`)
        console.log(`   📧 public ID: ${adminPublicUser.id}`)
      }
    } else {
      console.log(`   ❌ admin001が見つかりません`)
      console.log(`   📧 auth: ${adminAuthUser ? "存在" : "不存在"}`)
      console.log(`   📧 public: ${adminPublicUser ? "存在" : "不存在"}`)
    }
    console.log("")

    // 6. データ整合性チェック
    console.log("🔗 データ整合性チェック:")

    const { data: orphanNfts, error: nftError } = await supabase
      .from("user_nfts")
      .select("user_id")
      .not("user_id", "in", `(${publicUsers.map((u) => `'${u.id}'`).join(",")})`)

    if (!nftError && orphanNfts) {
      console.log(`   user_nfts孤児レコード: ${orphanNfts.length}件`)
    }

    const { data: orphanRewards, error: rewardError } = await supabase
      .from("daily_rewards")
      .select("user_id")
      .not("user_id", "in", `(${publicUsers.map((u) => `'${u.id}'`).join(",")})`)

    if (!rewardError && orphanRewards) {
      console.log(`   daily_rewards孤児レコード: ${orphanRewards.length}件`)
    }

    // 7. 同期率の計算
    const syncRate = (matchedUsers.length / Math.max(authUsers.users.length, publicUsers.length)) * 100
    console.log(`\n📈 同期率: ${syncRate.toFixed(1)}%`)

    if (syncRate >= 95) {
      console.log("✅ 同期は正常に完了しています！")
    } else if (syncRate >= 90) {
      console.log("⚠️  同期はほぼ完了していますが、いくつかの不一致があります")
    } else {
      console.log("❌ 同期に問題があります。追加の修正が必要です")
    }

    // 8. 推奨アクション
    console.log("\n🎯 推奨アクション:")
    if (authOnlyUsers.length > 0) {
      console.log("   - auth.usersのみのユーザーをpublic.usersに追加")
    }
    if (publicOnlyUsers.length > 0) {
      console.log("   - public.usersのみのユーザーを確認・削除検討")
    }
    if (syncRate < 95) {
      console.log("   - 同期スクリプトの再実行を検討")
    }
    if (syncRate >= 95) {
      console.log("   - ダッシュボードのテストを実行")
      console.log("   - admin001でのログインテスト")
    }
  } catch (error) {
    console.error("❌ エラーが発生しました:", error.message)
    if (error.details) {
      console.error("詳細:", error.details)
    }
  }
}

// スクリプト実行
verifyUserSync()
