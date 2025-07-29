import { createClient } from "@supabase/supabase-js"

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY

if (!supabaseUrl || !supabaseServiceKey) {
  throw new Error("Missing Supabase environment variables")
}

const supabase = createClient(supabaseUrl, supabaseServiceKey)

async function verifyEmergencyFix() {
  console.log("🚨 緊急修正の検証を開始します...")
  console.log("=".repeat(60))

  try {
    // 正しい紹介関係の定義
    const correctReferrals = {
      OHTAKIYO: "klmiklmi0204",
      "1125Ritsuko": "USER0a18",
      USER0a18: null, // ルートユーザー
      bighand1011: "USER0a18",
      Mira: "Mickey",
      klmiklmi0204: "yasui001",
    }

    console.log("📋 正しい紹介関係:")
    Object.entries(correctReferrals).forEach(([user, referrer]) => {
      console.log(`  ${user} → ${referrer || "なし（ルートユーザー）"}`)
    })

    // 現在の状態を取得
    const { data: targetUsers, error: targetError } = await supabase
      .from("users")
      .select(`
        user_id,
        name,
        email,
        referrer_id
      `)
      .in("user_id", Object.keys(correctReferrals))
      .order("user_id")

    if (targetError) {
      console.error("❌ ユーザー取得エラー:", targetError)
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

    console.log("\n🔍 現在の状態と正しい状態の比較:")
    let correctCount = 0
    let totalCount = 0
    const stillIncorrect = []

    targetUsers.forEach((user) => {
      const expected = correctReferrals[user.user_id]
      const actual = user.referrer_id ? referrerMap[user.referrer_id]?.user_id : null
      const isCorrect = expected === actual

      console.log({
        user_id: user.user_id,
        name: user.name,
        expected: expected || "なし",
        actual: actual || "なし",
        status: isCorrect ? "✅ 正しい" : "❌ まだ間違い",
      })

      if (isCorrect) {
        correctCount++
      } else {
        stillIncorrect.push({
          user_id: user.user_id,
          expected: expected || "なし",
          actual: actual || "なし",
        })
      }
      totalCount++
    })

    console.log(`\n📊 修正結果: ${correctCount}/${totalCount} 件が正しい`)

    if (stillIncorrect.length > 0) {
      console.log("\n❌ まだ修正が必要なユーザー:")
      stillIncorrect.forEach((user) => {
        console.log(`  ${user.user_id}: ${user.actual} → ${user.expected}`)
      })

      // 存在しない紹介者をチェック
      console.log("\n🔍 存在しない紹介者をチェック:")
      const missingReferrers = ["yasui001", "Mickey"]

      for (const referrerId of missingReferrers) {
        const { data: referrerExists } = await supabase
          .from("users")
          .select("user_id, name")
          .eq("user_id", referrerId)
          .single()

        if (referrerExists) {
          console.log(`✅ ${referrerId} は存在します (${referrerExists.name})`)
        } else {
          console.log(`❌ ${referrerId} は存在しません - 作成が必要`)
        }
      }
    } else {
      console.log("\n🎉 すべての紹介関係が正しく修正されました！")
    }

    // システム健全性の確認
    console.log("\n🏥 システム健全性確認:")

    // 循環参照チェック
    const { data: circularRefs, error: circularError } = await supabase.rpc("check_circular_references")

    if (!circularError) {
      if (circularRefs && circularRefs.length > 0) {
        console.log(`❌ 循環参照: ${circularRefs.length}件`)
      } else {
        console.log("✅ 循環参照: なし")
      }
    }

    // 無効な紹介者チェック
    const { data: invalidRefs, error: invalidError } = await supabase.rpc("check_invalid_referrers")

    if (!invalidError) {
      if (invalidRefs && invalidRefs.length > 0) {
        console.log(`❌ 無効な紹介者: ${invalidRefs.length}件`)
        invalidRefs.forEach((ref) => {
          console.log(`  ${ref.user_id}: 無効な紹介者ID`)
        })
      } else {
        console.log("✅ 無効な紹介者: なし")
      }
    }

    console.log("\n" + "=".repeat(60))
    if (correctCount === totalCount) {
      console.log("🎊 緊急修正成功！すべての紹介関係が正しくなりました！")
    } else {
      console.log("⚠️ まだ修正が必要です。存在しない紹介者の確認が必要かもしれません。")
    }
  } catch (error) {
    console.error("❌ 検証中にエラーが発生しました:", error)
  }
}

// 実行
verifyEmergencyFix()
  .then(() => {
    console.log("\n✅ 緊急修正検証完了")
  })
  .catch((error) => {
    console.error("❌ 緊急修正検証エラー:", error)
  })
