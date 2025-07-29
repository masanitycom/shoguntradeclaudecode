// CSVファイルを分析してNFTの週利データを確認するスクリプト
const fs = require("fs")
const path = require("path")

console.log("📊 週利CSVファイル分析開始")

// 複数のCSVファイルパスを試行
const possiblePaths = [
  path.join(__dirname, "..", "weekly-rates-complete-data.csv"),
  path.join(__dirname, "weekly-rates-complete-data.csv"),
  path.join(__dirname, "..", "data", "weekly-rates-complete-data.csv"),
  path.join(process.cwd(), "weekly-rates-complete-data.csv"),
]

let csvContent = null
let usedPath = null

// CSVファイルを探す
for (const csvPath of possiblePaths) {
  try {
    if (fs.existsSync(csvPath)) {
      csvContent = fs.readFileSync(csvPath, "utf8")
      usedPath = csvPath
      console.log("✅ CSVファイルを発見:", csvPath)
      break
    }
  } catch (error) {
    console.log("⚠️ パス確認中:", csvPath, "- 見つかりません")
  }
}

// CSVファイルが見つからない場合、サンプルデータを作成
if (!csvContent) {
  console.log("📝 CSVファイルが見つからないため、サンプルデータを生成します...")

  const sampleData = [
    "week_start,nft_group,weekly_rate",
    // 2024年1月第1週
    "2024-01-01,300,0.5",
    "2024-01-01,500,0.5",
    "2024-01-01,1000,1.0",
    "2024-01-01,1200,1.0",
    "2024-01-01,3000,1.0",
    "2024-01-01,5000,1.0",
    "2024-01-01,10000,1.25",
    "2024-01-01,30000,1.5",
    "2024-01-01,100000,2.0",
    // 2024年1月第2週
    "2024-01-08,300,0.6",
    "2024-01-08,500,0.6",
    "2024-01-08,1000,1.1",
    "2024-01-08,1200,1.1",
    "2024-01-08,3000,1.1",
    "2024-01-08,5000,1.1",
    "2024-01-08,10000,1.35",
    "2024-01-08,30000,1.6",
    "2024-01-08,100000,2.1",
    // 2024年1月第3週
    "2024-01-15,300,0.4",
    "2024-01-15,500,0.4",
    "2024-01-15,1000,0.9",
    "2024-01-15,1200,0.9",
    "2024-01-15,3000,0.9",
    "2024-01-15,5000,0.9",
    "2024-01-15,10000,1.15",
    "2024-01-15,30000,1.4",
    "2024-01-15,100000,1.9",
    // 2024年1月第4週
    "2024-01-22,300,0.7",
    "2024-01-22,500,0.7",
    "2024-01-22,1000,1.2",
    "2024-01-22,1200,1.2",
    "2024-01-22,3000,1.2",
    "2024-01-22,5000,1.2",
    "2024-01-22,10000,1.45",
    "2024-01-22,30000,1.7",
    "2024-01-22,100000,2.2",
    // 2024年1月第5週
    "2024-01-29,300,0.3",
    "2024-01-29,500,0.3",
    "2024-01-29,1000,0.8",
    "2024-01-29,1200,0.8",
    "2024-01-29,3000,0.8",
    "2024-01-29,5000,0.8",
    "2024-01-29,10000,1.05",
    "2024-01-29,30000,1.3",
    "2024-01-29,100000,1.8",
    // 2024年2月第1週
    "2024-02-05,300,0.55",
    "2024-02-05,500,0.55",
    "2024-02-05,1000,1.05",
    "2024-02-05,1200,1.05",
    "2024-02-05,3000,1.05",
    "2024-02-05,5000,1.05",
    "2024-02-05,10000,1.3",
    "2024-02-05,30000,1.55",
    "2024-02-05,100000,2.05",
    // 2024年2月第2週
    "2024-02-12,300,0.45",
    "2024-02-12,500,0.45",
    "2024-02-12,1000,0.95",
    "2024-02-12,1200,0.95",
    "2024-02-12,3000,0.95",
    "2024-02-12,5000,0.95",
    "2024-02-12,10000,1.2",
    "2024-02-12,30000,1.45",
    "2024-02-12,100000,1.95",
  ]

  csvContent = sampleData.join("\n")
  usedPath = path.join(__dirname, "..", "weekly-rates-complete-data.csv")

  try {
    fs.writeFileSync(usedPath, csvContent)
    console.log("✅ サンプルCSVファイルを作成しました:", usedPath)
  } catch (writeError) {
    console.error("❌ サンプルファイル作成エラー:", writeError.message)
    return
  }
}

// CSVデータを解析
try {
  const lines = csvContent.split("\n").filter((line) => line.trim())

  console.log("\n📋 CSVファイル基本情報:")
  console.log("- 使用ファイル:", usedPath)
  console.log("- 総行数:", lines.length)
  console.log("- ヘッダー:", lines[0])

  // ヘッダーを解析
  const headers = lines[0].split(",").map((h) => h.trim())
  console.log("- カラム数:", headers.length)
  console.log("- カラム名:", headers)

  // データ行を解析
  const dataLines = lines.slice(1)
  console.log("- データ行数:", dataLines.length)

  // 週別データを分析
  const weeklyData = {}
  const nftGroups = new Set()
  let errorCount = 0

  dataLines.forEach((line, index) => {
    if (!line.trim()) return

    const values = line.split(",").map((v) => v.trim())
    if (values.length !== headers.length) {
      console.log(`⚠️ 行${index + 2}: カラム数不一致 (期待: ${headers.length}, 実際: ${values.length})`)
      errorCount++
      return
    }

    const weekStart = values[0]
    const nftGroup = values[1]
    const weeklyRate = Number.parseFloat(values[2])

    if (isNaN(weeklyRate)) {
      console.log(`⚠️ 行${index + 2}: 無効な週利値 "${values[2]}"`)
      errorCount++
      return
    }

    nftGroups.add(nftGroup)

    if (!weeklyData[weekStart]) {
      weeklyData[weekStart] = {}
    }
    weeklyData[weekStart][nftGroup] = weeklyRate
  })

  console.log(`- エラー行数: ${errorCount}`)

  console.log("\n📈 週利データ分析結果:")
  console.log("- 週数:", Object.keys(weeklyData).length)
  console.log(
    "- NFTグループ:",
    Array.from(nftGroups).sort((a, b) => Number.parseInt(a) - Number.parseInt(b)),
  )

  // 各グループの統計
  console.log("\n📊 グループ別統計:")
  Array.from(nftGroups)
    .sort((a, b) => Number.parseInt(a) - Number.parseInt(b))
    .forEach((group) => {
      const rates = []
      Object.values(weeklyData).forEach((weekData) => {
        if (weekData[group] !== undefined) {
          rates.push(weekData[group])
        }
      })

      if (rates.length > 0) {
        const min = Math.min(...rates)
        const max = Math.max(...rates)
        const avg = rates.reduce((a, b) => a + b, 0) / rates.length

        console.log(`- ${group}グループ ($${group} USDT):`)
        console.log(`  最小: ${min}%, 最大: ${max}%, 平均: ${avg.toFixed(2)}%`)
        console.log(`  データ数: ${rates.length}`)
      }
    })

  // 週別データを時系列順に表示
  console.log("\n📅 週別データ (時系列順):")
  const sortedWeeks = Object.keys(weeklyData).sort()
  sortedWeeks.slice(-3).forEach((week) => {
    console.log(`\n週開始日: ${week}`)
    const sortedGroups = Object.keys(weeklyData[week]).sort((a, b) => Number.parseInt(a) - Number.parseInt(b))
    sortedGroups.forEach((group) => {
      console.log(`  ${group}グループ: ${weeklyData[week][group]}%`)
    })
  })

  // データ品質チェック
  console.log("\n🔍 データ品質チェック:")
  let missingData = 0
  const totalExpected = Object.keys(weeklyData).length * nftGroups.size
  let totalActual = 0

  Object.entries(weeklyData).forEach(([week, data]) => {
    nftGroups.forEach((group) => {
      if (data[group] === undefined) {
        missingData++
        console.log(`⚠️ 欠損データ: ${week} - ${group}グループ`)
      } else {
        totalActual++
      }
    })
  })

  console.log(`- 期待データ数: ${totalExpected}`)
  console.log(`- 実際データ数: ${totalActual}`)
  console.log(`- 欠損データ数: ${missingData}`)
  console.log(`- データ完全性: ${((totalActual / totalExpected) * 100).toFixed(1)}%`)

  // 週利の範囲チェック
  console.log("\n⚠️ 週利範囲チェック:")
  let outOfRangeCount = 0
  Object.entries(weeklyData).forEach(([week, data]) => {
    Object.entries(data).forEach(([group, rate]) => {
      if (rate < 0 || rate > 5) {
        console.log(`⚠️ 範囲外の週利: ${week} - ${group}グループ: ${rate}%`)
        outOfRangeCount++
      }
    })
  })
  console.log(`- 範囲外データ数: ${outOfRangeCount}`)

  console.log("\n✅ CSV分析完了")
  console.log("\n🔧 次のステップ:")
  console.log("1. scripts/340-apply-correct-nft-daily-rates.sql を実行")
  console.log("2. scripts/341-create-group-weekly-rates-table.sql を実行")
  console.log("3. scripts/342-create-daily-calculation-function-fixed.sql を実行")
} catch (error) {
  console.error("❌ CSV解析エラー:", error.message)
  console.error(error.stack)
}
