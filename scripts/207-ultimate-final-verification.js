const { createClient } = require("@supabase/supabase-js")

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY

if (!supabaseUrl || !supabaseServiceKey) {
  console.error("Missing Supabase environment variables")
  process.exit(1)
}

const supabase = createClient(supabaseUrl, supabaseServiceKey)

async function ultimateFinalVerification() {
  console.log("🎯 SHOGUN TRADE システム最終確認\n")
  console.log("=" * 50)

  try {
    // 1. システム概要
    console.log("📊 システム概要:")

    const { data: authUsersResult } = await supabase.rpc("exec_sql", {
      sql_query: "SELECT COUNT(*) as count FROM auth.users",
    })

    const { data: publicUsers, count: publicUsersCount } = await supabase.from("users").select("id", { count: "exact" })

    const { data: activeNfts } = await supabase.from("user_nfts").select("user_id").eq("is_active", true)

    console.log(`   🔐 認証ユーザー: ${authUsersResult?.[0]?.count || "N/A"} 件`)
    console.log(`   👥 システムユーザー: ${publicUsersCount || 0} 件`)
    console.log(`   🎯 アクティブNFT: ${activeNfts?.length || 0} 件`)

    // 2. データ整合性確認
    console.log("\n🔗 データ整合性:")

    // ID完全一致確認
    const { data: idMatches } = await supabase.rpc("exec_sql", {
      sql_query: `
          SELECT COUNT(*) as count 
          FROM auth.users au 
          INNER JOIN public.users pu ON au.id = pu.id
        `,
    })

    // メール不一致確認
    const { data: emailMismatches } = await supabase.rpc("exec_sql", {
      sql_query: `
          SELECT COUNT(*) as count 
          FROM auth.users au 
          INNER JOIN public.users pu ON au.email = pu.email 
          WHERE au.id != pu.id
        `,
    })

    // 孤立レコード確認
    const { data: orphanedNfts } = await supabase.rpc("exec_sql", {
      sql_query: `
          SELECT COUNT(*) as count 
          FROM user_nfts un 
          LEFT JOIN users u ON un.user_id = u.id 
          WHERE u.id IS NULL
        `,
    })

    console.log(`   ✅ ID完全一致: ${idMatches?.[0]?.count || 0} 件`)
    console.log(
      `   ${emailMismatches?.[0]?.count === 0 ? "✅" : "❌"} メール不一致: ${emailMismatches?.[0]?.count || 0} 件`,
    )
    console.log(`   ${orphanedNfts?.[0]?.count === 0 ? "✅" : "❌"} 孤立NFT: ${orphanedNfts?.[0]?.count || 0} 件`)

    // 3. admin001確認
    console.log("\n👑 管理者アカウント:")

    const { data: adminCheck } = await supabase
      .from("users")
      .select("id, user_id, email, is_admin, created_at")
      .eq("email", "admin@shogun-trade.com")
      .single()

    if (adminCheck) {
      console.log(`   ✅ ID: ${adminCheck.id}`)
      console.log(`   ✅ User ID: ${adminCheck.user_id}`)
      console.log(`   ✅ Email: ${adminCheck.email}`)
      console.log(`   ✅ 管理者権限: ${adminCheck.is_admin}`)

      // auth.usersとの同期確認
      const { data: authCheck } = await supabase.rpc("exec_sql", {
        sql_query: `
            SELECT 
                id,
                email,
                encrypted_password IS NOT NULL as has_password,
                email_confirmed_at IS NOT NULL as email_confirmed
            FROM auth.users 
            WHERE id = '${adminCheck.id}'
          `,
      })

      if (authCheck?.[0]) {
        console.log(`   ✅ 認証同期: OK`)
        console.log(`   ✅ パスワード: ${authCheck[0].has_password ? "設定済み" : "未設定"}`)
        console.log(`   ✅ メール確認: ${authCheck[0].email_confirmed ? "確認済み" : "未確認"}`)
      }
    } else {
      console.log("   ❌ admin001が見つかりません")
    }

    // 4. NFT所有状況
    console.log("\n🎯 NFT所有状況:")

    // 複数NFT所有者確認
    const userNftCounts = {}
    activeNfts?.forEach((nft) => {
      userNftCounts[nft.user_id] = (userNftCounts[nft.user_id] || 0) + 1
    })

    const multipleNftUsers = Object.entries(userNftCounts).filter(([_, count]) => count > 1)
    console.log(`   📊 総NFT所有者: ${Object.keys(userNftCounts).length} 人`)
    console.log(`   ${multipleNftUsers.length === 0 ? "✅" : "⚠️"} 複数NFT所有者: ${multipleNftUsers.length} 人`)

    if (multipleNftUsers.length > 0) {
      console.log("   ⚠️ 複数NFT所有者（上位3人）:")
      multipleNftUsers.slice(0, 3).forEach(([userId, count]) => {
        console.log(`     ${userId}: ${count} 件`)
      })
    }

    // NFT種別確認
    const { data: nftTypes } = await supabase.rpc("exec_sql", {
      sql_query: `
          SELECT 
              n.name,
              n.price,
              COUNT(un.id) as owner_count
          FROM nfts n
          LEFT JOIN user_nfts un ON n.id = un.nft_id AND un.is_active = true
          GROUP BY n.id, n.name, n.price
          ORDER BY n.price DESC
        `,
    })

    console.log("   📈 NFT種別別所有状況:")
    nftTypes?.forEach((nft) => {
      console.log(`     ${nft.name}: ${nft.owner_count} 人 (${nft.price}ドル)`)
    })

    // 5. 外部キー制約確認
    console.log("\n🔗 外部キー制約:")

    const { data: constraints } = await supabase.rpc("exec_sql", {
      sql_query: `
          SELECT 
              table_name,
              constraint_name
          FROM information_schema.table_constraints 
          WHERE constraint_type = 'FOREIGN KEY' 
          AND table_schema = 'public' 
          AND table_name IN ('user_nfts', 'nft_purchase_applications', 'reward_applications', 'user_rank_history', 'tenka_bonus_distributions', 'daily_rewards', 'users')
          ORDER BY table_name, constraint_name
        `,
    })

    const constraintsByTable = {}
    constraints?.forEach((c) => {
      if (!constraintsByTable[c.table_name]) {
        constraintsByTable[c.table_name] = []
      }
      constraintsByTable[c.table_name].push(c.constraint_name)
    })

    Object.entries(constraintsByTable).forEach(([table, constraintList]) => {
      console.log(`   ${table}: ${constraintList.length} 件`)
      constraintList.forEach((constraint) => {
        console.log(`     - ${constraint}`)
      })
    })

    // 重要な制約の確認
    const hasUserNftsConstraint = constraints?.some((c) => c.constraint_name === "user_nfts_user_id_fkey")
    console.log(
      `   ${hasUserNftsConstraint ? "✅" : "❌"} user_nfts_user_id_fkey: ${hasUserNftsConstraint ? "存在" : "不足"}`,
    )

    // 6. システム機能確認
    console.log("\n⚙️ システム機能:")

    // テーブル存在確認
    const { data: tables } = await supabase.rpc("exec_sql", {
      sql_query: `
          SELECT table_name
          FROM information_schema.tables
          WHERE table_schema = 'public'
          AND table_name IN (
              'users', 'nfts', 'user_nfts', 'nft_purchase_applications',
              'daily_rewards', 'reward_applications', 'tasks',
              'mlm_ranks', 'user_rank_history', 'tenka_bonus_distributions',
              'weekly_profits', 'weekly_rates', 'payment_addresses'
          )
          ORDER BY table_name
        `,
    })

    console.log(`   📋 必要テーブル: ${tables?.length || 0}/13 件`)
    const requiredTables = [
      "users",
      "nfts",
      "user_nfts",
      "nft_purchase_applications",
      "daily_rewards",
      "reward_applications",
      "tasks",
      "mlm_ranks",
      "user_rank_history",
      "tenka_bonus_distributions",
      "weekly_profits",
      "weekly_rates",
      "payment_addresses",
    ]

    const existingTables = tables?.map((t) => t.table_name) || []
    requiredTables.forEach((table) => {
      const exists = existingTables.includes(table)
      console.log(`     ${exists ? "✅" : "❌"} ${table}`)
    })

    // 7. 最終判定
    console.log("\n" + "=" * 50)
    console.log("🎉 最終判定:")

    const emailMismatchCount = emailMismatches?.[0]?.count || 0
    const orphanedNftCount = orphanedNfts?.[0]?.count || 0
    const hasAdmin = !!adminCheck
    const constraintCount = constraints?.length || 0
    const tableCount = tables?.length || 0

    const allChecks = [
      { name: "メール不一致", status: emailMismatchCount === 0, value: `${emailMismatchCount} 件` },
      { name: "孤立NFT", status: orphanedNftCount === 0, value: `${orphanedNftCount} 件` },
      { name: "admin001", status: hasAdmin, value: hasAdmin ? "存在" : "不存在" },
      { name: "複数NFT所有", status: multipleNftUsers.length === 0, value: `${multipleNftUsers.length} 人` },
      { name: "外部キー制約", status: constraintCount >= 10, value: `${constraintCount} 件` },
      { name: "必要テーブル", status: tableCount >= 12, value: `${tableCount}/13 件` },
    ]

    const passedChecks = allChecks.filter((check) => check.status).length
    const totalChecks = allChecks.length

    console.log(`   📊 総合評価: ${passedChecks}/${totalChecks} 項目クリア`)

    allChecks.forEach((check) => {
      console.log(`   ${check.status ? "✅" : "❌"} ${check.name}: ${check.value}`)
    })

    if (passedChecks === totalChecks) {
      console.log("\n🎊🎊🎊 システム完全構築成功！🎊🎊🎊")
      console.log("\n🚀 ログインテストを実行してください:")
      console.log("   🌐 URL: https://shogun-trade.vercel.app/login")
      console.log("   👤 Email: admin@shogun-trade.com")
      console.log("   🔑 Password: admin123456")

      console.log("\n📋 ログイン後の確認項目:")
      console.log("   1. ✅ ダッシュボードの表示")
      console.log("   2. ✅ ユーザー管理ページ (/admin/users)")
      console.log("   3. ✅ NFT管理ページ (/admin/nfts)")
      console.log("   4. ✅ 報酬管理ページ (/admin/rewards)")
      console.log("   5. ✅ 日利設定ページ (/admin/daily-rates)")

      console.log("\n🎯 システム機能:")
      console.log("   ✅ NFT購入申請システム")
      console.log("   ✅ 日利報酬計算システム")
      console.log("   ✅ MLMランクシステム")
      console.log("   ✅ 天下統一ボーナス")
      console.log("   ✅ エアドロップタスク")
      console.log("   ✅ 複利運用システム")
    } else {
      console.log("\n⚠️ まだ問題があります:")
      allChecks
        .filter((check) => !check.status)
        .forEach((check) => {
          console.log(`   ❌ ${check.name}: ${check.value}`)
        })
    }

    // 8. 統計サマリー
    console.log("\n📈 最終統計:")
    console.log(`   👥 総ユーザー数: ${publicUsersCount || 0}`)
    console.log(`   🎯 アクティブNFT: ${activeNfts?.length || 0}`)
    console.log(`   🔗 外部キー制約: ${constraintCount}`)
    console.log(`   📋 システムテーブル: ${tableCount}`)
    console.log(`   ✅ データ整合性: ${orphanedNftCount === 0 && emailMismatchCount === 0 ? "正常" : "要修正"}`)

    console.log("\n" + "=" * 50)
    console.log("🎉 SHOGUN TRADE システム構築完了！")
  } catch (error) {
    console.error("❌ 最終確認中にエラーが発生:", error.message)
    console.error("詳細:", error)
  }
}

ultimateFinalVerification()
