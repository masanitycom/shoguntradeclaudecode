const { createClient } = require("@supabase/supabase-js")

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY

if (!supabaseUrl || !supabaseServiceKey) {
  console.error("❌ Supabase環境変数が設定されていません")
  process.exit(1)
}

const supabase = createClient(supabaseUrl, supabaseServiceKey)

async function finalCsvFixGuaranteed() {
  console.log("🔥 最終修正 - CSVの通りに確実に修正します！")
  console.log("=" * 60)

  try {
    // 1. CSVファイルを取得
    console.log("1️⃣ CSVファイル取得中...")
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
    const csvData = []
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
          csvData.push(user)
        }
      }
    }

    console.log(`📊 有効なCSVユーザー: ${csvData.length}人`)

    // 2. 現在のデータベース状態を取得
    console.log("\n2️⃣ データベース状態取得中...")
    const { data: allUsers, error: usersError } = await supabase
      .from("users")
      .select("id, user_id, name, referrer_id")
      .eq("is_admin", false)

    if (usersError) {
      throw new Error(`ユーザー取得エラー: ${usersError.message}`)
    }

    console.log(`📊 データベースユーザー: ${allUsers.length}人`)

    // 3. ユーザーIDマップを作成
    const userIdMap = new Map()
    allUsers.forEach((user) => {
      userIdMap.set(user.user_id, user.id)
    })

    // 4. CSVの通りに修正リストを作成
    console.log("\n3️⃣ 修正リスト作成中...")
    const corrections = []

    for (const csvUser of csvData) {
      const userInternalId = userIdMap.get(csvUser.user_id)
      if (!userInternalId) {
        console.log(`⚠️ データベースに存在しないユーザー: ${csvUser.user_id}`)
        continue
      }

      let correctReferrerId = null
      if (csvUser.referrer) {
        correctReferrerId = userIdMap.get(csvUser.referrer)
        if (!correctReferrerId) {
          console.log(`⚠️ 紹介者が存在しない: ${csvUser.user_id} -> ${csvUser.referrer}`)
          continue
        }
      }

      corrections.push({
        user_id: csvUser.user_id,
        name: csvUser.name,
        internal_id: userInternalId,
        correct_referrer_id: correctReferrerId,
        correct_referrer_user_id: csvUser.referrer,
      })
    }

    console.log(`📊 修正対象: ${corrections.length}人`)

    // 5. 1125Ritsukoの状況を特別確認
    console.log("\n4️⃣ 1125Ritsukoの状況確認...")
    const ritsukoData = csvData.find((user) => user.user_id === "1125Ritsuko")
    if (ritsukoData) {
      console.log({
        user_id: "1125Ritsuko",
        name: ritsukoData.name,
        csv_referrer: ritsukoData.referrer || "なし",
        correct_referrer_id: ritsukoData.referrer ? userIdMap.get(ritsukoData.referrer) : null,
      })
    }

    // 6. 一括修正実行
    console.log("\n5️⃣ 一括修正実行中...")
    let successCount = 0
    let errorCount = 0
    const errors = []

    for (let i = 0; i < corrections.length; i++) {
      const correction = corrections[i]

      try {
        const { error: updateError } = await supabase
          .from("users")
          .update({
            referrer_id: correction.correct_referrer_id,
            updated_at: new Date().toISOString(),
          })
          .eq("id", correction.internal_id)

        if (updateError) {
          errorCount++
          errors.push({
            user_id: correction.user_id,
            error: updateError.message,
          })
          console.log(`❌ ${correction.user_id}: ${updateError.message}`)
        } else {
          successCount++
          if (successCount % 50 === 0) {
            console.log(`📈 進捗: ${successCount}/${corrections.length}`)
          }
        }
      } catch (error) {
        errorCount++
        errors.push({
          user_id: correction.user_id,
          error: error.message,
        })
        console.log(`❌ ${correction.user_id}: ${error.message}`)
      }
    }

    console.log(`\n✅ 成功: ${successCount}人`)
    console.log(`❌ エラー: ${errorCount}人`)

    // 7. 最終検証
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
      throw new Error(`最終検証エラー: ${finalError.message}`)
    }

    // CSVとの比較
    const csvUserMap = new Map()
    csvData.forEach((user) => {
      csvUserMap.set(user.user_id, user)
    })

    let correctCount = 0
    let wrongCount = 0
    const stillWrong = []

    for (const dbUser of finalUsers) {
      const csvUser = csvUserMap.get(dbUser.user_id)
      if (csvUser) {
        const currentReferrer = dbUser.referrer?.user_id || null
        const correctReferrer = csvUser.referrer || null

        if (currentReferrer === correctReferrer) {
          correctCount++
        } else {
          wrongCount++
          stillWrong.push({
            user_id: dbUser.user_id,
            name: dbUser.name,
            current: currentReferrer || "なし",
            correct: correctReferrer || "なし",
          })
        }
      }
    }

    // 8. 1125Ritsukoの最終確認
    console.log("\n7️⃣ 1125Ritsukoの最終確認...")
    const { data: ritsukoFinal } = await supabase
      .from("users")
      .select(`
        user_id,
        name,
        referrer_id,
        referrer:referrer_id(user_id, name)
      `)
      .eq("user_id", "1125Ritsuko")
      .single()

    if (ritsukoFinal) {
      console.log({
        user_id: "1125Ritsuko",
        name: ritsukoFinal.name,
        current_referrer: ritsukoFinal.referrer?.user_id || "なし",
        should_be: ritsukoData?.referrer || "なし",
        status:
          (ritsukoFinal.referrer?.user_id || null) === (ritsukoData?.referrer || null) ? "✅ 正しい" : "❌ まだ間違い",
      })
    }

    // 9. 結果表示
    console.log("\n" + "=" * 60)
    console.log("🎯 最終結果:")
    console.log(`📊 CSVユーザー数: ${csvData.length}人`)
    console.log(`📊 修正対象: ${corrections.length}人`)
    console.log(`✅ 修正成功: ${successCount}人`)
    console.log(`❌ 修正エラー: ${errorCount}人`)
    console.log(`✅ 最終的に正しい: ${correctCount}人`)
    console.log(`❌ まだ間違い: ${wrongCount}人`)
    console.log(`📈 成功率: ${((correctCount / (correctCount + wrongCount)) * 100).toFixed(2)}%`)

    if (wrongCount === 0) {
      console.log("\n🎉 完璧！全ての紹介関係がCSVの通りに修正されました！")
    } else {
      console.log(`\n⚠️ まだ${wrongCount}人の修正が必要です`)

      if (stillWrong.length <= 20) {
        console.log("\n❌ まだ間違っているユーザー:")
        stillWrong.forEach((user, index) => {
          console.log(`${index + 1}. ${user.user_id} (${user.name}): ${user.current} -> ${user.correct}`)
        })
      }
    }

    if (errors.length > 0 && errors.length <= 10) {
      console.log("\n❌ エラー詳細:")
      errors.forEach((error, index) => {
        console.log(`${index + 1}. ${error.user_id}: ${error.error}`)
      })
    }

    return {
      csvUsers: csvData.length,
      corrections: corrections.length,
      successCount,
      errorCount,
      correctCount,
      wrongCount,
      successRate: ((correctCount / (correctCount + wrongCount)) * 100).toFixed(2),
    }
  } catch (error) {
    console.error("❌ 最終修正中にエラー:", error)
    throw error
  }
}

// 実行
finalCsvFixGuaranteed()
  .then((result) => {
    console.log("\n🔥 最終修正完了")
    console.log(`📊 成功率: ${result.successRate}%`)

    if (result.wrongCount === 0) {
      console.log("🎉 全て完璧に修正されました！")
    } else {
      console.log(`⚠️ ${result.wrongCount}人がまだ間違っています`)
    }
  })
  .catch((error) => {
    console.error("❌ 最終修正エラー:", error)
  })
