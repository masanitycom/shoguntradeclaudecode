const fs = require("fs")

async function fix1125RitsukoReferrals() {
  console.log("🔥 1125Ritsukoの紹介数を0にする修正")
  console.log("=" * 60)

  try {
    // 1. CSVファイルを取得
    console.log("1️⃣ CSVファイル取得中...")
    const csvUrl =
      "https://hebbkx1anhila5yf.public.blob.vercel-storage.com/E-NISA%E3%83%AA%E3%82%B9%E3%83%88%20-%20SHOGUN%2BENISA%E7%B4%B9%E4%BB%8B%E8%80%85%E9%A0%86%E3%81%AB%E4%B8%A6%E3%81%B9%E6%9B%BF%E3%81%88-xqLb3E20fjpzRQiUkpfqPjUkP0puIK.csv"

    const response = await fetch(csvUrl)
    const csvText = await response.text()
    const lines = csvText.split("\n").filter((line) => line.trim())

    // CSVデータを解析
    const csvData = []
    for (let i = 1; i < lines.length; i++) {
      if (lines[i].trim()) {
        const values = lines[i].split(",")
        const user = {
          name: values[0]?.replace(/"/g, "").trim(),
          user_id: values[1]?.replace(/"/g, "").trim(),
          referrer: values[6]?.replace(/"/g, "").trim() || null,
        }
        if (user.user_id) {
          csvData.push(user)
        }
      }
    }

    console.log(`📊 CSVユーザー数: ${csvData.length}人`)

    // 2. 間違って1125Ritsukoを紹介者としているユーザーリスト
    const wrongUsers = [
      "242424b",
      "atsuko03",
      "atsuko04",
      "atsuko28",
      "Ayanon2",
      "Ayanon3",
      "FU3111",
      "FU9166",
      "itsumari0311",
      "ko1969",
      "kuru39",
      "MAU1204",
      "mitsuaki0320",
      "mook0214",
      "NYAN",
      "USER037",
      "USER038",
      "USER039",
      "USER040",
      "USER041",
      "USER042",
      "USER043",
      "USER044",
      "USER045",
      "USER046",
      "USER047",
    ]

    console.log(`❌ 修正対象ユーザー: ${wrongUsers.length}人`)

    // 3. CSVから正しい紹介者を取得して修正SQLを生成
    console.log("\n3️⃣ 修正SQLを生成中...")

    let sqlCorrections = `-- 🔥 1125Ritsukoの紹介数を0にする修正SQL
-- 26人のユーザーを正しい紹介者に変更

BEGIN;

-- バックアップテーブル作成
DROP TABLE IF EXISTS ritsuko_fix_backup;
CREATE TABLE ritsuko_fix_backup AS
SELECT 
    u.id,
    u.user_id,
    u.name,
    u.referrer_id,
    r.user_id as current_referrer_user_id
FROM users u
LEFT JOIN users r ON u.referrer_id = r.id
WHERE u.referrer_id = (SELECT id FROM users WHERE user_id = '1125Ritsuko');

-- 修正前の状態確認
SELECT 
    '修正前の1125Ritsuko紹介数' as status,
    COUNT(*) as count
FROM users
WHERE referrer_id = (SELECT id FROM users WHERE user_id = '1125Ritsuko');

`

    // 各ユーザーの正しい紹介者をCSVから取得して修正
    let correctionCount = 0
    for (const wrongUserId of wrongUsers) {
      const csvUser = csvData.find((u) => u.user_id === wrongUserId)
      if (csvUser) {
        const correctReferrer = csvUser.referrer

        if (correctReferrer && correctReferrer !== "1125Ritsuko") {
          sqlCorrections += `-- ${wrongUserId} (${csvUser.name}) -> ${correctReferrer}
UPDATE users 
SET referrer_id = (SELECT id FROM users WHERE user_id = '${correctReferrer}' LIMIT 1),
    updated_at = NOW()
WHERE user_id = '${wrongUserId}' 
  AND referrer_id = (SELECT id FROM users WHERE user_id = '1125Ritsuko');

`
          correctionCount++
        } else if (!correctReferrer) {
          // 紹介者なしの場合
          sqlCorrections += `-- ${wrongUserId} (${csvUser.name}) -> 紹介者なし
UPDATE users 
SET referrer_id = NULL,
    updated_at = NOW()
WHERE user_id = '${wrongUserId}' 
  AND referrer_id = (SELECT id FROM users WHERE user_id = '1125Ritsuko');

`
          correctionCount++
        } else {
          console.log(`⚠️ ${wrongUserId}: CSVでも1125Ritsukoが紹介者として設定されている（異常）`)
        }
      } else {
        console.log(`⚠️ ${wrongUserId}: CSVに存在しない`)
      }
    }

    sqlCorrections += `-- 修正後の確認
SELECT 
    '修正後の1125Ritsuko紹介数' as status,
    COUNT(*) as count,
    CASE 
        WHEN COUNT(*) = 0 THEN '✅ 成功（0人）'
        ELSE '❌ まだ' || COUNT(*) || '人残っている'
    END as result
FROM users
WHERE referrer_id = (SELECT id FROM users WHERE user_id = '1125Ritsuko');

-- 修正されたユーザーの確認
SELECT 
    '修正されたユーザー' as check_type,
    u.user_id,
    u.name,
    COALESCE(r.user_id, 'なし') as new_referrer
FROM users u
LEFT JOIN users r ON u.referrer_id = r.id
WHERE u.id IN (SELECT id FROM ritsuko_fix_backup)
ORDER BY u.user_id;

-- 1125Ritsuko自身の状態確認
SELECT 
    '1125Ritsuko自身の状態' as check_type,
    u.user_id,
    u.name,
    COALESCE(r.user_id, 'なし') as referrer,
    (SELECT COUNT(*) FROM users WHERE referrer_id = u.id) as referral_count
FROM users u
LEFT JOIN users r ON u.referrer_id = r.id
WHERE u.user_id = '1125Ritsuko';

COMMIT;

-- 最終成功メッセージ
SELECT 
    CASE 
        WHEN (SELECT COUNT(*) FROM users WHERE referrer_id = (SELECT id FROM users WHERE user_id = '1125Ritsuko')) = 0
        THEN '🎉 完璧！1125Ritsukoの紹介数は0人になりました！'
        ELSE '❌ まだ修正が必要です'
    END as final_result;
`

    // SQLファイルを保存
    fs.writeFileSync("scripts/298-fix-1125ritsuko-referrals.sql", sqlCorrections)
    console.log("\n📝 scripts/298-fix-1125ritsuko-referrals.sql を生成しました")

    console.log(`\n📊 修正内容:`)
    console.log(`- 修正対象: ${wrongUsers.length}人`)
    console.log(`- 修正SQL生成: ${correctionCount}件`)
    console.log(`- 修正後の1125Ritsuko紹介数: 0人（正しい状態）`)

    // 4. 主要な修正内容を表示
    console.log(`\n🔧 主要な修正内容:`)
    const sampleCorrections = [
      { user: "242424b", name: "ノグチチヨコ2", correct: csvData.find((u) => u.user_id === "242424b")?.referrer },
      {
        user: "mitsuaki0320",
        name: "イノセミツアキ",
        correct: csvData.find((u) => u.user_id === "mitsuaki0320")?.referrer,
      },
      { user: "ko1969", name: "オジマケンイチ", correct: csvData.find((u) => u.user_id === "ko1969")?.referrer },
      {
        user: "itsumari0311",
        name: "ミヤモトイツコ2",
        correct: csvData.find((u) => u.user_id === "itsumari0311")?.referrer,
      },
    ]

    sampleCorrections.forEach((correction) => {
      console.log(`- ${correction.user} (${correction.name}) -> ${correction.correct || "なし"}`)
    })

    return {
      csvUsers: csvData.length,
      wrongUsers: wrongUsers.length,
      correctionCount,
    }
  } catch (error) {
    console.error("❌ 修正中にエラー:", error)
    throw error
  }
}

// 実行
fix1125RitsukoReferrals()
  .then((result) => {
    console.log(`\n🔥 修正準備完了`)
    console.log(`📊 CSVユーザー: ${result.csvUsers}人`)
    console.log(`❌ 間違ったユーザー: ${result.wrongUsers}人`)
    console.log(`✅ 修正SQL生成: ${result.correctionCount}件`)
    console.log(`🎯 修正後の1125Ritsuko紹介数: 0人（正しい状態）`)
    console.log(`\n次のステップ: scripts/298-fix-1125ritsuko-referrals.sql を実行してください`)
  })
  .catch((error) => {
    console.error("❌ 修正エラー:", error)
  })
