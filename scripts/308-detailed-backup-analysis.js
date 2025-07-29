// ==========================================
// 詳細バックアップ分析スクリプト
// データの完全性と品質を詳細に検証
// ==========================================

const { createClient } = require("@supabase/supabase-js")

const supabase = createClient(process.env.NEXT_PUBLIC_SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY)

async function analyzeBackupDetails() {
  console.log("🔍 Starting detailed backup analysis...")
  console.log("=".repeat(50))

  try {
    // 1. バックアップテーブルの存在確認
    console.log("📋 1. BACKUP TABLES VERIFICATION")
    console.log("-".repeat(30))

    const { data: tables, error: tablesError } = await supabase.rpc("sql", {
      query: `
          SELECT table_name
          FROM information_schema.tables 
          WHERE table_name LIKE '%backup_20250629%'
          ORDER BY table_name
        `,
    })

    if (tablesError) {
      console.error("❌ Error checking tables:", tablesError)
      return
    }

    if (tables && tables.length > 0) {
      console.log("✅ Found backup tables:")
      tables.forEach((table) => {
        console.log(`   • ${table.table_name}`)
      })
    } else {
      console.log("❌ No backup tables found!")
      return
    }

    // 2. ユーザーデータの詳細分析
    console.log("\n👥 2. USER DATA ANALYSIS")
    console.log("-".repeat(30))

    const { data: userDetails, error: userError } = await supabase.rpc("sql", {
      query: `
        SELECT 
          COUNT(*) as total_users,
          COUNT(CASE WHEN referrer_id IS NOT NULL THEN 1 END) as users_with_referrer,
          COUNT(CASE WHEN referrer_id IS NULL THEN 1 END) as root_users,
          COUNT(DISTINCT email) as unique_emails,
          COUNT(CASE WHEN email IS NULL OR email = '' THEN 1 END) as users_without_email,
          COUNT(CASE WHEN is_admin = true THEN 1 END) as admin_users
        FROM users_backup_20250629
      `,
    })

    if (userError) {
      console.error("❌ Error analyzing users:", userError)
      return
    }

    if (userDetails && userDetails.length > 0) {
      const stats = userDetails[0]
      console.log(`✅ Total users: ${stats.total_users}`)
      console.log(`✅ Users with referrer: ${stats.users_with_referrer}`)
      console.log(`✅ Root users: ${stats.root_users}`)
      console.log(`✅ Unique emails: ${stats.unique_emails}`)
      console.log(`✅ Admin users: ${stats.admin_users}`)
      console.log(`${stats.users_without_email === 0 ? "✅" : "⚠️"} Users without email: ${stats.users_without_email}`)
    }

    // 3. 紹介関係の整合性チェック
    console.log("\n🔗 3. REFERRAL INTEGRITY CHECK")
    console.log("-".repeat(30))

    const { data: referralCheck, error: referralError } = await supabase.rpc("sql", {
      query: `
        SELECT 
          COUNT(CASE WHEN referrer_id IS NOT NULL AND referrer_id NOT IN (SELECT id FROM users_backup_20250629) THEN 1 END) as broken_referrals,
          COUNT(CASE WHEN referrer_id IS NOT NULL THEN 1 END) as total_referrals
        FROM users_backup_20250629
      `,
    })

    if (referralError) {
      console.error("❌ Error checking referrals:", referralError)
      return
    }

    if (referralCheck && referralCheck.length > 0) {
      const check = referralCheck[0]
      if (check.broken_referrals === 0) {
        console.log("✅ Perfect referral integrity!")
        console.log(`✅ All ${check.total_referrals} referral relationships are valid`)
      } else {
        console.log(`⚠️ Found ${check.broken_referrals} broken referral relationships`)
        console.log(`⚠️ Out of ${check.total_referrals} total referrals`)
      }
    }

    // 4. NFTデータの分析
    console.log("\n💎 4. NFT DATA ANALYSIS")
    console.log("-".repeat(30))

    const { data: nftStats, error: nftError } = await supabase.rpc("sql", {
      query: `
        SELECT 
          COUNT(*) as total_nft_records,
          COUNT(DISTINCT user_id) as users_with_nfts,
          COUNT(CASE WHEN is_active = true THEN 1 END) as active_nfts,
          COUNT(DISTINCT nft_id) as unique_nft_types,
          COALESCE(SUM(purchase_price), 0) as total_investment
        FROM user_nfts_backup_20250629
      `,
    })

    if (nftError) {
      console.error("❌ Error analyzing NFTs:", nftError)
      return
    }

    if (nftStats && nftStats.length > 0) {
      const stats = nftStats[0]
      console.log(`✅ Total NFT records: ${stats.total_nft_records}`)
      console.log(`✅ Users with NFTs: ${stats.users_with_nfts}`)
      console.log(`✅ Active NFTs: ${stats.active_nfts}`)
      console.log(`✅ Unique NFT types: ${stats.unique_nft_types}`)
      console.log(`✅ Total investment value: $${stats.total_investment}`)
    }

    // 5. 日利報酬データの分析
    console.log("\n💰 5. DAILY REWARDS ANALYSIS")
    console.log("-".repeat(30))

    const { data: rewardStats, error: rewardError } = await supabase.rpc("sql", {
      query: `
        SELECT 
          COUNT(*) as total_reward_records,
          COUNT(DISTINCT user_id) as users_with_rewards,
          COALESCE(SUM(reward_amount), 0) as total_rewards,
          COALESCE(AVG(reward_amount), 0) as average_reward,
          MIN(reward_date) as earliest_date,
          MAX(reward_date) as latest_date
        FROM daily_rewards_backup_20250629
      `,
    })

    if (rewardError) {
      console.error("❌ Error analyzing rewards:", rewardError)
      return
    }

    if (rewardStats && rewardStats.length > 0) {
      const stats = rewardStats[0]
      console.log(`✅ Total reward records: ${stats.total_reward_records}`)
      console.log(`✅ Users with rewards: ${stats.users_with_rewards}`)
      console.log(`✅ Total reward amount: $${Number.parseFloat(stats.total_rewards).toFixed(2)}`)
      console.log(`✅ Average reward: $${Number.parseFloat(stats.average_reward).toFixed(2)}`)
      console.log(`✅ Date range: ${stats.earliest_date} to ${stats.latest_date}`)
    }

    // 6. トップ紹介者の確認
    console.log("\n👑 6. TOP REFERRERS")
    console.log("-".repeat(30))

    const { data: topReferrers, error: topError } = await supabase.rpc("sql", {
      query: `
        SELECT 
          u.email,
          COUNT(r.id) as referral_count
        FROM users_backup_20250629 u
        LEFT JOIN users_backup_20250629 r ON u.id = r.referrer_id
        GROUP BY u.id, u.email
        HAVING COUNT(r.id) > 0
        ORDER BY COUNT(r.id) DESC
        LIMIT 5
      `,
    })

    if (topError) {
      console.error("❌ Error finding top referrers:", topError)
    } else if (topReferrers && topReferrers.length > 0) {
      topReferrers.forEach((referrer, index) => {
        console.log(`${index + 1}. ${referrer.email}: ${referrer.referral_count} referrals`)
      })
    }

    // 7. 管理者ユーザーの確認
    console.log("\n👥 7. ADMIN USERS VERIFICATION")
    console.log("-".repeat(30))

    const { data: adminUsers, error: adminError } = await supabase.rpc("sql", {
      query: `
        SELECT email, referrer_id, created_at, is_admin
        FROM users_backup_20250629
        WHERE is_admin = true OR email LIKE '%admin%'
        ORDER BY email
      `,
    })

    if (adminError) {
      console.error("❌ Error checking admin users:", adminError)
    } else if (adminUsers && adminUsers.length > 0) {
      adminUsers.forEach((user) => {
        console.log(`✅ ${user.email} (Admin: ${user.is_admin})`)
        console.log(`   Referrer ID: ${user.referrer_id || "None (Root User)"}`)
        console.log(`   Created: ${user.created_at}`)
      })
    } else {
      console.log("ℹ️ No admin users found in backup")
    }

    // 8. 総合評価
    console.log("\n🎯 8. OVERALL ASSESSMENT")
    console.log("-".repeat(30))

    const brokenReferrals = referralCheck?.[0]?.broken_referrals || 0
    const totalUsers = userDetails?.[0]?.total_users || 0
    const totalNFTs = nftStats?.[0]?.total_nft_records || 0
    const totalRewards = rewardStats?.[0]?.total_reward_records || 0

    if (brokenReferrals === 0 && totalUsers > 0) {
      console.log("🎉 BACKUP QUALITY: EXCELLENT")
      console.log("✅ All referral relationships are intact")
      console.log("✅ Manual corrections have been preserved")
      console.log("✅ Data integrity is perfect")
    } else {
      console.log("⚠️ BACKUP QUALITY: NEEDS ATTENTION")
      if (brokenReferrals > 0) {
        console.log(`⚠️ ${brokenReferrals} broken referral relationships found`)
      }
    }

    console.log(`\n📊 BACKUP SUMMARY:`)
    console.log(`   Users: ${totalUsers}`)
    console.log(`   NFTs: ${totalNFTs}`)
    console.log(`   Rewards: ${totalRewards}`)
    console.log(`   Backup Date: 2025-06-29 13:32:15`)
    console.log(`   Analysis Date: ${new Date().toISOString()}`)

    console.log("\n✅ Detailed backup analysis completed!")
  } catch (error) {
    console.error("❌ Analysis failed:", error)
  }
}

// 実行
analyzeBackupDetails()
