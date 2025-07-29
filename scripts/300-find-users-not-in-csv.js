const fs = require("fs")

async function findUsersNotInCSV() {
  console.log("🔍 CSVに存在しないユーザーを特定")
  console.log("=" * 50)

  try {
    // 1. CSVファイルを取得
    console.log("1️⃣ CSVファイル取得中...")
    const csvUrl =
      "https://hebbkx1anhila5yf.public.blob.vercel-storage.com/E-NISA%E3%83%AA%E3%82%B9%E3%83%88%20-%20SHOGUN%2BENISA%E7%B4%B9%E4%BB%8B%E8%80%85%E9%A0%86%E3%81%AB%E4%B8%A6%E3%81%B9%E6%9B%BF%E3%81%88-xqLb3E20fjpzRQiUkpfqPjUkP0puIK.csv"

    const response = await fetch(csvUrl)
    const csvText = await response.text()
    const lines = csvText.split("\n").filter((line) => line.trim())

    // CSVデータを解析
    const csvUserIds = new Set()
    for (let i = 1; i < lines.length; i++) {
      if (lines[i].trim()) {
        const values = lines[i].split(",")
        const userId = values[1]?.replace(/"/g, "").trim()
        if (userId) {
          csvUserIds.add(userId)
        }
      }
    }

    console.log(`📊 CSVユーザー数: ${csvUserIds.size}人`)

    // 2. データベースから1125Ritsukoを紹介者としているユーザーを取得
    const dbUsers = [
      { user_id: "242424b", name: "ノグチチヨコ2" },
      { user_id: "atsuko03", name: "コジマアツコ2" },
      { user_id: "atsuko04", name: "コジマアツコ3" },
      { user_id: "atsuko28", name: "コジマアツコ4" },
      { user_id: "Ayanon2", name: "ワタヌキイチロウ" },
      { user_id: "Ayanon3", name: "ゴトウアヤ" },
      { user_id: "FU3111", name: "シマダフミコ2" },
      { user_id: "FU9166", name: "シマダフミコ4" },
      { user_id: "itsumari0311", name: "ミヤモトイツコ2" },
      { user_id: "ko1969", name: "オジマケンイチ" },
      { user_id: "kuru39", name: "ワカミヤミカ" },
      { user_id: "MAU1204", name: "シマダフミコ3" },
      { user_id: "mitsuaki0320", name: "イノセミツアキ" },
      { user_id: "mook0214", name: "ハギワラサナエ" },
      { user_id: "NYAN", name: "サトウチヨコ" },
      { user_id: "USER037", name: "S" },
      { user_id: "USER038", name: "X" },
      { user_id: "USER039", name: "A4" },
      { user_id: "USER040", name: "A2" },
      { user_id: "USER041", name: "A6" },
      { user_id: "USER042", name: "T" },
      { user_id: "USER043", name: "A5" },
      { user_id: "USER044", name: "A8" },
      { user_id: "USER045", name: "A1" },
      { user_id: "USER046", name: "L" },
      { user_id: "USER047", name: "A7" },
    ]

    console.log(`📊 データベースユーザー数: ${dbUsers.length}人`)

    // 3. CSVに存在しないユーザーを特定
    console.log("\n3️⃣ CSVに存在しないユーザーを特定中...")

    const usersNotInCSV = []
    const usersInCSV = []

    dbUsers.forEach((dbUser) => {
      if (csvUserIds.has(dbUser.user_id)) {
        usersInCSV.push(dbUser)
      } else {
        usersNotInCSV.push(dbUser)
      }
    })

    // 4. 結果を表示
    console.log(`\n📊 分析結果:`)
    console.log(`✅ CSVに存在するユーザー: ${usersInCSV.length}人`)
    console.log(`❌ CSVに存在しないユーザー: ${usersNotInCSV.length}人`)

    console.log(`\n✅ CSVに存在するユーザー:`)
    usersInCSV.forEach((user, index) => {
      console.log(`${index + 1}. ${user.user_id} (${user.name})`)
    })

    console.log(`\n❌ CSVに存在しないユーザー:`)
    usersNotInCSV.forEach((user, index) => {
      console.log(`${index + 1}. ${user.user_id} (${user.name})`)
    })

    // 5. CSVに存在しないユーザーの特徴を分析
    console.log(`\n🔍 CSVに存在しないユーザーの特徴:`)

    const userPatterns = {
      USER_series: usersNotInCSV.filter((u) => u.user_id.startsWith("USER")),
      FU_series: usersNotInCSV.filter((u) => u.user_id.startsWith("FU")),
      atsuko_series: usersNotInCSV.filter((u) => u.user_id.startsWith("atsuko")),
      others: usersNotInCSV.filter(
        (u) => !u.user_id.startsWith("USER") && !u.user_id.startsWith("FU") && !u.user_id.startsWith("atsuko"),
      ),
    }

    console.log(`- USERシリーズ: ${userPatterns.USER_series.length}人`)
    userPatterns.USER_series.forEach((user) => {
      console.log(`  - ${user.user_id} (${user.name})`)
    })

    console.log(`- FUシリーズ: ${userPatterns.FU_series.length}人`)
    userPatterns.FU_series.forEach((user) => {
      console.log(`  - ${user.user_id} (${user.name})`)
    })

    console.log(`- atsukoシリーズ: ${userPatterns.atsuko_series.length}人`)
    userPatterns.atsuko_series.forEach((user) => {
      console.log(`  - ${user.user_id} (${user.name})`)
    })

    console.log(`- その他: ${userPatterns.others.length}人`)
    userPatterns.others.forEach((user) => {
      console.log(`  - ${user.user_id} (${user.name})`)
    })

    // 6. CSVに存在しないユーザーのみを抜き出してファイルに保存
    console.log(`\n📝 CSVに存在しないユーザーのみを抜き出し中...`)

    const csvMissingUsersContent = `user_id,name,category
${usersNotInCSV
  .map((user) => {
    let category = "その他"
    if (user.user_id.startsWith("USER")) category = "USERシリーズ"
    else if (user.user_id.startsWith("FU")) category = "FUシリーズ"
    else if (user.user_id.startsWith("atsuko")) category = "atsukoシリーズ"
    return `${user.user_id},${user.name},${category}`
  })
  .join("\n")}`

    fs.writeFileSync("scripts/csv-missing-users.csv", csvMissingUsersContent)
    console.log(`📄 scripts/csv-missing-users.csv を生成しました`)

    // 7. テキストファイルでも保存
    const textContent = `CSVに存在しないユーザー一覧
生成日時: ${new Date().toISOString()}

合計: ${usersNotInCSV.length}人

${usersNotInCSV.map((user, index) => `${index + 1}. ${user.user_id} (${user.name})`).join("\n")}

カテゴリ別:
- USERシリーズ: ${userPatterns.USER_series.length}人
- FUシリーズ: ${userPatterns.FU_series.length}人
- atsukoシリーズ: ${userPatterns.atsuko_series.length}人
- その他: ${userPatterns.others.length}人
`

    fs.writeFileSync("scripts/csv-missing-users.txt", textContent)
    console.log(`📄 scripts/csv-missing-users.txt を生成しました`)

    return {
      csvUsers: csvUserIds.size,
      dbUsers: dbUsers.length,
      usersInCSV: usersInCSV.length,
      usersNotInCSV: usersNotInCSV.length,
      patterns: userPatterns,
      missingUsers: usersNotInCSV,
    }
  } catch (error) {
    console.error("❌ 分析中にエラー:", error)
    throw error
  }
}

// 実行
findUsersNotInCSV()
  .then((result) => {
    console.log(`\n🎯 分析完了`)
    console.log(`📊 CSVユーザー: ${result.csvUsers}人`)
    console.log(`📊 データベースユーザー: ${result.dbUsers}人`)
    console.log(`✅ CSVに存在: ${result.usersInCSV}人`)
    console.log(`❌ CSVに存在しない: ${result.usersNotInCSV}人`)
    console.log(`\n📄 ファイル出力:`)
    console.log(`- scripts/csv-missing-users.csv`)
    console.log(`- scripts/csv-missing-users.txt`)
  })
  .catch((error) => {
    console.error("❌ 分析エラー:", error)
  })
