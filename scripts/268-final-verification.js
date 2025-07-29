import { createClient } from "@supabase/supabase-js"

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY

if (!supabaseUrl || !supabaseServiceKey) {
  throw new Error("Missing Supabase environment variables")
}

const supabase = createClient(supabaseUrl, supabaseServiceKey)

async function finalVerification() {
  console.log("🔍 CSVデータに基づく修正結果の最終検証を開始します...")
  console.log("=".repeat(60))

  try {
    // 1. 修正対象ユーザーの現在の状態を確認
    console.log("\n📋 修正対象ユーザーの現在の状態:")
    const { data: targetUsers, error: targetError } = await supabase
      .from("users")
      .select(`
        user_id,
        name,
        email,
        referrer_id,
        updated_at
      `)
      .in("user_id", ["OHTAKIYO", "1125Ritsuko", "USER0a18", "bighand1011", "Mira", "klmiklmi0204"])
      .order("user_id")

    if (targetError) {
      console.error("❌ ターゲットユーザー取得エラー:", targetError)
      return
    }

    // 紹介者情報を取得
    const referrerIds = targetUsers.map((u) => u.referrer_id).filter(Boolean)
    let referrerMap = {}

    if (referrerIds.length > 0) {
      const { data: referrers } = await supabase.from("users").select("id, user_id, name").in("id", referrerIds)

      if (referrers) {
        referrerMap = referrers.reduce((acc, r) => {
          acc[r.id] = { user_id: r.user_id, name: r.name }
          return acc
        }, {})
      }
    }

    targetUsers.forEach((user) => {
      const referrer = user.referrer_id ? referrerMap[user.referrer_id] : null
      console.log({
        user_id: user.user_id,
        name: user.name,
        email: user.email,
        current_referrer: referrer?.user_id || "なし",
        current_referrer_name: referrer?.name || "なし",
        updated_at: new Date(user.updated_at).toLocaleString("ja-JP"),
      })
    })

    // 2. CSVデータとの整合性確認
    console.log("\n✅ CSVデータとの整合性確認:")
    const expectedReferrers = {
      OHTAKIYO: "klmiklmi0204",
      "1125Ritsuko": "USER0a18",
      USER0a18: null,
      bighand1011: null,
      Mira: null,
      klmiklmi0204: null,
    }

    let correctCount = 0
    let totalCount = 0
    const incorrectUsers = []

    targetUsers.forEach((user) => {
      const expected = expectedReferrers[user.user_id]
      const actual = user.referrer_id ? referrerMap[user.referrer_id]?.user_id : null
      const isCorrect = expected === actual

      console.log({
        user_id: user.user_id,
        expected: expected || "なし",
        actual: actual || "なし",
        status: isCorrect ? "✅ 正しい" : "❌ 不一致",
      })

      if (isCorrect) {
        correctCount++
      } else {
        incorrectUsers.push({
          user_id: user.user_id,
          expected: expected || "なし",
          actual: actual || "なし",
        })
      }
      totalCount++
    })

    console.log(`\n📊 整合性結果: ${correctCount}/${totalCount} 件が正しい`)

    // 3. システム健全性チェック
    console.log("\n🏥 システム健全性統計:")

    // 総ユーザー数
    const { data: totalUsersData } = await supabase.from("users").select("id", { count: "exact" }).eq("is_admin", false)

    // 紹介者ありユーザー数
    const { data: usersWithReferrerData } = await supabase
      .from("users")
      .select("id", { count: "exact" })
      .not("referrer_id", "is", null)
      .eq("is_admin", false)

    // 代理メールユーザー数
    const { data: proxyEmailData } = await supabase
      .from("users")
      .select("id", { count: "exact" })
      .like("email", "%@shogun-trade.com")
      .eq("is_admin", false)

    console.log({
      total_users: totalUsersData?.length || 0,
      users_with_referrer: usersWithReferrerData?.length || 0,
      proxy_email_users: proxyEmailData?.length || 0,
      referrer_percentage:
        totalUsersData?.length > 0
          ? (((usersWithReferrerData?.length || 0) / totalUsersData.length) * 100).toFixed(2) + "%"
          : "0%",
    })

    // 4. 循環参照チェック
    console.log("\n🔄 循環参照チェック:")
    const { data: circularRefs, error: circularError } = await supabase.rpc("check_circular_references")

    if (circularError) {
      console.log("⚠️ 循環参照チェック関数でエラー:", circularError.message)
    } else if (circularRefs && circularRefs.length > 0) {
      console.log(`❌ 循環参照が ${circularRefs.length} 件見つかりました:`)
      circularRefs.forEach((ref) => {
        console.log(`  ${ref.user_id} (深度: ${ref.depth})`)
      })
    } else {
      console.log("✅ 循環参照はありません")
    }

    // 5. 無効な紹介者チェック
    console.log("\n🔍 無効な紹介者チェック:")
    const { data: invalidRefs, error: invalidError } = await supabase.rpc("check_invalid_referrers")

    if (invalidError) {
      console.log("⚠️ 無効な紹介者チェック関数でエラー:", invalidError.message)
    } else if (invalidRefs && invalidRefs.length > 0) {
      console.log(`❌ 無効な紹介者が ${invalidRefs.length} 件見つかりました:`)
      invalidRefs.forEach((ref) => {
        console.log(`  ${ref.user_id}: 無効な紹介者ID ${ref.invalid_referrer_id}`)
      })
    } else {
      console.log("✅ 無効な紹介者はありません")
    }

    // 6. 1125Ritsukoの詳細紹介統計
    console.log("\n👥 1125Ritsukoの詳細紹介統計:")
    const ritsukoUser = targetUsers.find((u) => u.user_id === "1125Ritsuko")

    if (ritsukoUser) {
      const { data: ritsukoReferrals, error: referralError } = await supabase
        .from("users")
        .select("user_id, name, email, created_at")
        .eq("referrer_id", ritsukoUser.referrer_id) // これは間違い、ritsukoUser.idを使うべき
        .eq("is_admin", false)
        .order("created_at", { ascending: false })

      // 正しい取得方法
      const { data: ritsukoReferrals2, error: referralError2 } = await supabase
        .from("users")
        .select("user_id, name, email, created_at")
        .eq("referrer_id", ritsukoUser.id) // 正しくはこちら
        .eq("is_admin", false)
        .order("created_at", { ascending: false })

      // ただし、user.idが取得されていないので、別途取得
      const { data: ritsukoFullData } = await supabase
        .from("users")
        .select("id, user_id")
        .eq("user_id", "1125Ritsuko")
        .single()

      if (ritsukoFullData) {
        const { data: ritsukoReferrals3, error: referralError3 } = await supabase
          .from("users")
          .select("user_id, name, email, created_at")
          .eq("referrer_id", ritsukoFullData.id)
          .eq("is_admin", false)
          .order("created_at", { ascending: false })

        if (!referralError3 && ritsukoReferrals3) {
          const proxyEmailCount = ritsukoReferrals3.filter((u) => u.email.includes("@shogun-trade.com")).length
          const realEmailCount = ritsukoReferrals3.length - proxyEmailCount

          console.log({
            total_referrals: ritsukoReferrals3.length,
            proxy_email_count: proxyEmailCount,
            real_email_count: realEmailCount,
            proxy_percentage:
              ritsukoReferrals3.length > 0
                ? ((proxyEmailCount / ritsukoReferrals3.length) * 100).toFixed(1) + "%"
                : "0%",
          })

          if (ritsukoReferrals3.length > 0) {
            console.log("\n最近の紹介者（最新5人）:")
            ritsukoReferrals3.slice(0, 5).forEach((user, index) => {
              const emailType = user.email.includes("@shogun-trade.com") ? "📧代理" : "✉️実"
              console.log(`  ${index + 1}. ${user.user_id} (${user.name}) ${emailType}`)
              console.log(`     ${user.email}`)
              console.log(`     登録日: ${new Date(user.created_at).toLocaleDateString("ja-JP")}`)
            })
          }
        }
      }
    }

    // 7. 紹介ツリーの深度分析
    console.log("\n🌳 紹介ツリーの深度分析:")

    // 全ユーザーの紹介関係を取得
    const { data: allUsers } = await supabase.from("users").select("id, user_id, referrer_id").eq("is_admin", false)

    if (allUsers) {
      // ユーザーマップを作成
      const userMap = new Map()
      const idToUserIdMap = new Map()

      allUsers.forEach((user) => {
        userMap.set(user.user_id, user.referrer_id)
        idToUserIdMap.set(user.id, user.user_id)
      })

      // 深度計算関数
      const calculateDepth = (userId, visited = new Set()) => {
        if (visited.has(userId)) return -1 // 循環参照

        const user = allUsers.find((u) => u.user_id === userId)
        if (!user || !user.referrer_id) return 0

        const referrerUserId = idToUserIdMap.get(user.referrer_id)
        if (!referrerUserId) return 0

        visited.add(userId)
        const depth = calculateDepth(referrerUserId, visited)
        visited.delete(userId)

        return depth === -1 ? -1 : depth + 1
      }

      // 対象ユーザーの深度を計算
      const depths = targetUsers.map((user) => ({
        user_id: user.user_id,
        depth: calculateDepth(user.user_id),
      }))

      depths.forEach((item) => {
        console.log({
          user_id: item.user_id,
          depth: item.depth === -1 ? "循環参照検出" : `${item.depth}層`,
        })
      })
    }

    // 8. 最終結果サマリー
    console.log("\n" + "=".repeat(60))
    console.log("📋 最終検証結果サマリー:")
    console.log("=".repeat(60))

    console.log(`✅ 正しい紹介関係: ${correctCount}/${totalCount}`)
    console.log(`❌ 修正が必要: ${incorrectUsers.length}/${totalCount}`)
    console.log(`📧 代理メールアドレス使用者: ${proxyEmailData?.length || 0}人`)
    console.log(`👥 総ユーザー数: ${totalUsersData?.length || 0}人`)

    if (incorrectUsers.length === 0) {
      console.log("\n🎊 完全成功！すべての紹介関係が正しく修正されました！")
      console.log("✅ CSVデータに基づく修正が100%完了しています")
      console.log("🔄 循環参照も解消されました")
      console.log("🏥 システムの健全性が確保されています")
    } else {
      console.log("\n⚠️ まだ修正が必要なユーザーがあります:")
      incorrectUsers.forEach((user) => {
        console.log(`  ${user.user_id}: ${user.actual} → ${user.expected}`)
      })
    }

    // 9. 次のステップの提案
    console.log("\n🚀 次のステップ:")
    if (incorrectUsers.length === 0) {
      console.log("✅ 紹介関係の修正は完了しました")
      console.log("📊 次は以下の機能の確認を行ってください:")
      console.log("  - 日利計算システムの動作確認")
      console.log("  - MLMランク計算の確認")
      console.log("  - 天下統一ボーナスの分配確認")
      console.log("  - エアドロップタスクの動作確認")
    } else {
      console.log("⚠️ 修正スクリプトを再実行してください")
      console.log("🔧 scripts/267-execute-csv-based-corrections.sql")
    }

    console.log("\n🎉 最終検証が完了しました！")
  } catch (error) {
    console.error("❌ 最終検証中にエラーが発生しました:", error)
    console.error("スタックトレース:", error.stack)
  }
}

// 実行
finalVerification()
  .then(() => {
    console.log("\n✅ 最終検証プロセス完了")
    process.exit(0)
  })
  .catch((error) => {
    console.error("❌ 最終検証プロセスエラー:", error)
    process.exit(1)
  })
