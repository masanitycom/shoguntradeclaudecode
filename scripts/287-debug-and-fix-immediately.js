const { createClient } = require("@supabase/supabase-js")

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY

if (!supabaseUrl || !supabaseServiceKey) {
  console.error("❌ Supabase環境変数が設定されていません")
  process.exit(1)
}

const supabase = createClient(supabaseUrl, supabaseServiceKey)

async function debugAndFixImmediately() {
  console.log("🔥 緊急修正開始 - 一発で全て修正します！")
  console.log("=" * 60)

  try {
    // 1. まず現在の状態を確認
    console.log("1️⃣ 現在の状態確認...")
    const { data: currentUsers, error: currentError } = await supabase
      .from("users")
      .select(`
        user_id,
        name,
        referrer_id,
        referrer:referrer_id(user_id, name)
      `)
      .eq("is_admin", false)
      .order("user_id")

    if (currentError) {
      console.error("❌ データベース取得エラー:", currentError)
      return
    }

    console.log(`📊 現在のユーザー数: ${currentUsers.length}人`)

    // 2. CSVファイルを取得（最新のURL）
    console.log("\n2️⃣ CSVファイル取得...")
    const csvUrl =
      "https://hebbkx1anhila5yf.public.blob.vercel-storage.com/E-NISA%E3%83%AA%E3%82%B9%E3%83%88%20-%20SHOGUN%2BENISA%E7%B4%B9%E4%BB%8B%E8%80%85%E9%A0%86%E3%81%AB%E4%B8%A6%E3%81%B9%E6%9B%BF%E3%81%88-xqLb3E20fjpzRQiUkpfqPjUkP0puIK.csv"

    const response = await fetch(csvUrl)
    if (!response.ok) {
      throw new Error(`CSV取得エラー: ${response.status}`)
    }

    const csvText = await response.text()
    const lines = csvText.split("\n").filter((line) => line.trim())

    console.log(`📊 CSV行数: ${lines.length}行`)

    // CSVデータを解析
    const csvUsers = []
    for (let i = 1; i < lines.length; i++) {
      if (lines[i].trim()) {
        const values = lines[i].split(",")
        const user = {
          name: values[0]?.replace(/"/g, "").trim(),
          user_id: values[1]?.replace(/"/g, "").trim(),
          email: values[2]?.replace(/"/g, "").trim(),
          proxyEmail: values[3]?.replace(/"/g, "").trim(),
          pass: values[4]?.replace(/"/g, "").trim(),
          tel: values[5]?.replace(/"/g, "").trim(),
          referrer: values[6]?.replace(/"/g, "").trim() || null,
        }
        if (user.user_id) {
          csvUsers.push(user)
        }
      }
    }

    console.log(`📊 有効なCSVユーザー: ${csvUsers.length}人`)

    // 3. 現在間違っているユーザーを特定
    console.log("\n3️⃣ 間違いを特定中...")
    const csvUserMap = new Map()
    csvUsers.forEach((user) => {
      csvUserMap.set(user.user_id, user)
    })

    const corrections = []
    let correctCount = 0
    let wrongCount = 0

    for (const dbUser of currentUsers) {
      const csvUser = csvUserMap.get(dbUser.user_id)

      if (csvUser) {
        const currentReferrer = dbUser.referrer?.user_id || null
        const correctReferrer = csvUser.referrer || null

        if (currentReferrer !== correctReferrer) {
          wrongCount++
          corrections.push({
            user_id: dbUser.user_id,
            name: dbUser.name,
            current_referrer: currentReferrer,
            correct_referrer: correctReferrer,
            user_internal_id: dbUser.id || null,
          })
        } else {
          correctCount++
        }
      }
    }

    console.log(`✅ 既に正しい: ${correctCount}人`)
    console.log(`❌ 修正が必要: ${wrongCount}人`)

    if (corrections.length === 0) {
      console.log("🎉 全て正しく設定されています！")
      return
    }

    // 4. 一括修正実行
    console.log("\n4️⃣ 一括修正実行中...")
    let successCount = 0
    let failCount = 0

    for (const correction of corrections) {
      try {
        let referrerId = null

        if (correction.correct_referrer) {
          // 正しい紹介者のIDを取得
          const { data: referrerData, error: referrerError } = await supabase
            .from("users")
            .select("id")
            .eq("user_id", correction.correct_referrer)
            .single()

          if (referrerError || !referrerData) {
            console.log(`⚠️ 紹介者が見つからない: ${correction.user_id} -> ${correction.correct_referrer}`)
            failCount++
            continue
          }
          referrerId = referrerData.id
        }

        // ユーザーの紹介者を更新
        const { error: updateError } = await supabase
          .from("users")
          .update({
            referrer_id: referrerId,
            updated_at: new Date().toISOString(),
          })
          .eq("user_id", correction.user_id)

        if (updateError) {
          console.log(`❌ 更新失敗: ${correction.user_id} - ${updateError.message}`)
          failCount++
        } else {
          successCount++
          if (successCount % 50 === 0) {
            console.log(`📈 進捗: ${successCount}/${corrections.length}人完了`)
          }
        }
      } catch (error) {
        console.log(`❌ エラー: ${correction.user_id} - ${error.message}`)
        failCount++
      }
    }

    console.log("\n5️⃣ 修正結果:")
    console.log(`✅ 成功: ${successCount}人`)
    console.log(`❌ 失敗: ${failCount}人`)

    // 6. 最終検証
    console.log("\n6️⃣ 最終検証中...")
    const { data: finalUsers, error: finalError } = await supabase
      .from("users")
      .select(`
        user_id,
        name,
        referrer_id,
        referrer:referrer_id(user_id, name)
      `)
      .eq("is_admin", false)

    if (finalError) {
      console.error("❌ 最終検証エラー:", finalError)
      return
    }

    let finalCorrect = 0
    let finalWrong = 0

    for (const dbUser of finalUsers) {
      const csvUser = csvUserMap.get(dbUser.user_id)

      if (csvUser) {
        const currentReferrer = dbUser.referrer?.user_id || null
        const correctReferrer = csvUser.referrer || null

        if (currentReferrer === correctReferrer) {
          finalCorrect++
        } else {
          finalWrong++
        }
      }
    }

    console.log("\n🎯 最終結果:")
    console.log(`✅ 正しく設定: ${finalCorrect}人`)
    console.log(`❌ まだ間違い: ${finalWrong}人`)
    console.log(`📈 成功率: ${((finalCorrect / (finalCorrect + finalWrong)) * 100).toFixed(2)}%`)

    if (finalWrong === 0) {
      console.log("\n🎉 完璧！全ての紹介関係が正しく修正されました！")
    } else {
      console.log(`\n⚠️ まだ${finalWrong}人の修正が必要です`)

      // 残りの間違いを表示
      console.log("\n❌ まだ間違っているユーザー:")
      for (const dbUser of finalUsers) {
        const csvUser = csvUserMap.get(dbUser.user_id)

        if (csvUser) {
          const currentReferrer = dbUser.referrer?.user_id || null
          const correctReferrer = csvUser.referrer || null

          if (currentReferrer !== correctReferrer) {
            console.log({
              user_id: dbUser.user_id,
              name: dbUser.name,
              現在: currentReferrer || "なし",
              正解: correctReferrer || "なし",
            })
          }
        }
      }
    }

    return {
      totalCorrections: corrections.length,
      successCount,
      failCount,
      finalCorrect,
      finalWrong,
      successRate: ((finalCorrect / (finalCorrect + finalWrong)) * 100).toFixed(2),
    }
  } catch (error) {
    console.error("❌ 緊急修正中にエラー:", error)
    throw error
  }
}

// 実行
debugAndFixImmediately()
  .then((result) => {
    if (result) {
      console.log("\n🔥 緊急修正完了")
      console.log(`📊 最終成功率: ${result.successRate}%`)

      if (result.finalWrong === 0) {
        console.log("🎉 全て完璧に修正されました！")
      } else {
        console.log(`⚠️ ${result.finalWrong}人がまだ間違っています`)
      }
    }
  })
  .catch((error) => {
    console.error("❌ 緊急修正エラー:", error)
  })
