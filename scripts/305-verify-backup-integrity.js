// ==========================================
// バックアップ整合性検証スクリプト
// データの正確性と完全性を確認
// ==========================================

import { createClient } from "@supabase/supabase-js"

const supabase = createClient(process.env.NEXT_PUBLIC_SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY)

async function verifyBackupIntegrity() {
  console.log("🔍 Starting backup integrity verification...")

  try {
    // 1. バックアップテーブルの存在確認
    const { data: backupTables, error: tablesError } = await supabase
      .from("information_schema.tables")
      .select("table_name")
      .like("table_name", "%backup_20250629%")

    if (tablesError) {
      console.error("❌ Error checking backup tables:", tablesError)
      return
    }

    console.log(
      "📋 Found backup tables:",
      backupTables?.map((t) => t.table_name),
    )

    // 2. ユーザーデータの整合性チェック
    const { data: userCheck, error: userError } = await supabase.rpc("sql", {
      query: `
        SELECT 
          'Original vs Backup User Count' as check_type,
          (SELECT COUNT(*) FROM users) as original_count,
          (SELECT COUNT(*) FROM users_backup_20250629) as backup_count,
          CASE 
            WHEN (SELECT COUNT(*) FROM users) = (SELECT COUNT(*) FROM users_backup_20250629) 
            THEN '✅ MATCH' 
            ELSE '❌ MISMATCH' 
          END as status
      `,
    })

    if (userError) {
      console.error("❌ Error checking user data:", userError)
      return
    }

    console.log("👥 User Data Verification:", userCheck)

    // 3. 紹介関係の整合性チェック
    const { data: referralCheck, error: referralError } = await supabase.rpc("sql", {
      query: `
        SELECT 
          'Referral Integrity Check' as check_type,
          COUNT(*) as total_users,
          COUNT(CASE WHEN referrer_id IS NOT NULL THEN 1 END) as users_with_referrer,
          COUNT(CASE WHEN referrer_id IS NOT NULL AND referrer_id NOT IN (SELECT id FROM users_backup_20250629) THEN 1 END) as broken_referrals
        FROM users_backup_20250629
      `,
    })

    if (referralError) {
      console.error("❌ Error checking referral integrity:", referralError)
      return
    }

    console.log("🔗 Referral Integrity:", referralCheck)

    // 4. NFTデータの整合性チェック
    const { data: nftCheck, error: nftError } = await supabase.rpc("sql", {
      query: `
        SELECT 
          'NFT Data Check' as check_type,
          (SELECT COUNT(*) FROM user_nfts) as original_nft_count,
          (SELECT COUNT(*) FROM user_nfts_backup_20250629) as backup_nft_count,
          CASE 
            WHEN (SELECT COUNT(*) FROM user_nfts) = (SELECT COUNT(*) FROM user_nfts_backup_20250629) 
            THEN '✅ MATCH' 
            ELSE '❌ MISMATCH' 
          END as status
      `,
    })

    if (nftError) {
      console.error("❌ Error checking NFT data:", nftError)
      return
    }

    console.log("🎨 NFT Data Verification:", nftCheck)

    // 5. 日利報酬データの整合性チェック
    const { data: rewardCheck, error: rewardError } = await supabase.rpc("sql", {
      query: `
        SELECT 
          'Daily Rewards Check' as check_type,
          (SELECT COUNT(*) FROM daily_rewards) as original_reward_count,
          (SELECT COUNT(*) FROM daily_rewards_backup_20250629) as backup_reward_count,
          (SELECT SUM(reward_amount) FROM daily_rewards) as original_total_amount,
          (SELECT SUM(reward_amount) FROM daily_rewards_backup_20250629) as backup_total_amount
      `,
    })

    if (rewardError) {
      console.error("❌ Error checking reward data:", rewardError)
      return
    }

    console.log("💰 Reward Data Verification:", rewardCheck)

    console.log("✅ Backup integrity verification completed successfully!")
  } catch (error) {
    console.error("❌ Verification failed:", error)
  }
}

// 実行
verifyBackupIntegrity()
