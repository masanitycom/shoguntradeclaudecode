"use client"

import { useState } from "react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Badge } from "@/components/ui/badge"
import { Save, Loader2, Calendar, CheckCircle, AlertTriangle } from "lucide-react"
import { createClient } from "@/lib/supabase/supabaseBrowserClient"
import { useToast } from "@/hooks/use-toast"

interface GroupRate {
  group_name: string
  weekly_rate: string
}

export default function SafeWeeklyRateManager() {
  const [selectedDate, setSelectedDate] = useState("")
  const [saving, setSaving] = useState(false)
  const [groupRates, setGroupRates] = useState<GroupRate[]>([
    { group_name: "0.5%グループ", weekly_rate: "1.500" },
    { group_name: "1.0%グループ", weekly_rate: "2.000" },
    { group_name: "1.25%グループ", weekly_rate: "2.300" },
    { group_name: "1.5%グループ", weekly_rate: "2.600" },
    { group_name: "1.75%グループ", weekly_rate: "2.900" },
    { group_name: "2.0%グループ", weekly_rate: "3.200" },
  ])

  const supabase = createClient()
  const { toast } = useToast()

  const getNextMonday = (date: Date): Date => {
    const nextMonday = new Date(date)
    const dayOfWeek = nextMonday.getDay()
    const daysUntilMonday = dayOfWeek === 0 ? 1 : 8 - dayOfWeek
    nextMonday.setDate(nextMonday.getDate() + daysUntilMonday)
    return nextMonday
  }

  const handleSetWeeklyRates = async () => {
    if (!selectedDate) {
      toast({
        title: "入力エラー",
        description: "日付を選択してください",
        variant: "destructive",
      })
      return
    }

    const selectedDateObj = new Date(selectedDate)
    if (selectedDateObj.getDay() !== 1) {
      toast({
        title: "日付エラー",
        description: "月曜日を選択してください",
        variant: "destructive",
      })
      return
    }

    // 入力値の検証
    for (const groupRate of groupRates) {
      const rate = Number.parseFloat(groupRate.weekly_rate)
      if (isNaN(rate) || rate < 0 || rate > 10) {
        toast({
          title: "入力エラー",
          description: `${groupRate.group_name}の週利は0〜10%の範囲で入力してください`,
          variant: "destructive",
        })
        return
      }
    }

    setSaving(true)

    try {
      let successCount = 0
      let errorCount = 0

      // 各グループの週利設定
      for (const groupRate of groupRates) {
        const { data, error } = await supabase.rpc("admin_manual_set_weekly_rate", {
          p_week_start_date: selectedDate,
          p_group_name: groupRate.group_name,
          p_weekly_rate: Number.parseFloat(groupRate.weekly_rate) / 100, // パーセントを小数に変換
        })

        if (error) {
          console.error(`${groupRate.group_name}の設定エラー:`, error)
          errorCount++
        } else {
          const result = data?.[0]
          if (result?.success) {
            successCount++
          } else {
            errorCount++
          }
        }
      }

      if (successCount > 0) {
        toast({
          title: "設定完了",
          description: `${selectedDate}の週に${successCount}グループの週利を設定しました`,
        })
      }

      if (errorCount > 0) {
        toast({
          title: "一部エラー",
          description: `${errorCount}グループの設定に失敗しました`,
          variant: "destructive",
        })
      }
    } catch (error: any) {
      console.error("週利設定エラー:", error)
      toast({
        title: "エラー",
        description: error.message || "週利設定に失敗しました",
        variant: "destructive",
      })
    } finally {
      setSaving(false)
    }
  }

  const updateGroupRate = (groupName: string, rate: string) => {
    // 数値のバリデーション（小数点3桁まで）
    const numericValue = rate.replace(/[^0-9.]/g, "")
    const parts = numericValue.split(".")
    let validatedValue = parts[0]

    if (parts.length > 1) {
      validatedValue += "." + parts[1].substring(0, 3) // 小数点以下3桁まで
    }

    // 最大値チェック
    const num = Number.parseFloat(validatedValue)
    if (!isNaN(num) && num > 10) {
      validatedValue = "10.000"
    }

    setGroupRates((prev) =>
      prev.map((group) => (group.group_name === groupName ? { ...group, weekly_rate: validatedValue } : group)),
    )
  }

  // 次の月曜日を初期値として設定
  useState(() => {
    const nextMonday = getNextMonday(new Date())
    setSelectedDate(nextMonday.toISOString().split("T")[0])
  })

  return (
    <Card className="bg-gray-800 border-gray-700 max-w-2xl mx-auto">
      <CardHeader>
        <CardTitle className="text-white flex items-center">
          <Calendar className="mr-2 h-5 w-5" />
          安全な週利設定
        </CardTitle>
        <div className="flex items-center space-x-2">
          <Badge className="bg-green-600 text-white">
            <CheckCircle className="mr-1 h-3 w-3" />
            手動設定モード
          </Badge>
          <Badge variant="outline" className="text-orange-400 border-orange-400">
            <AlertTriangle className="mr-1 h-3 w-3" />
            自動変更防止済み
          </Badge>
        </div>
      </CardHeader>
      <CardContent className="space-y-6">
        <div className="bg-blue-900/20 border border-blue-800 p-4 rounded-lg">
          <h4 className="font-semibold text-blue-400 mb-2">🛡️ 完全保護システム</h4>
          <ul className="text-sm text-gray-300 space-y-1">
            <li>• 手動設定のみ許可</li>
            <li>• 自動変更完全防止</li>
            <li>• 即座に反映</li>
            <li>• データ損失なし</li>
          </ul>
        </div>

        <div className="space-y-2">
          <Label htmlFor="weekDate" className="text-white">
            開始日（月曜日）
          </Label>
          <Input
            id="weekDate"
            type="date"
            value={selectedDate}
            onChange={(e) => setSelectedDate(e.target.value)}
            className="bg-gray-700 border-gray-600 text-white"
          />
        </div>

        <div className="space-y-3">
          <Label className="text-white">各グループの週利（%）</Label>
          {groupRates.map((group) => (
            <div key={group.group_name} className="flex items-center space-x-3">
              <Label className="text-gray-300 w-32 text-sm">{group.group_name}</Label>
              <Input
                type="text"
                inputMode="decimal"
                pattern="[0-9]*\.?[0-9]*"
                placeholder="0.000"
                value={group.weekly_rate}
                onChange={(e) => updateGroupRate(group.group_name, e.target.value)}
                className="bg-gray-700 border-gray-600 text-white flex-1"
                onKeyDown={(e) => {
                  // 数字、小数点、バックスペース、削除、矢印キーのみ許可
                  if (
                    !/[0-9.]/.test(e.key) &&
                    !["Backspace", "Delete", "ArrowLeft", "ArrowRight", "Tab"].includes(e.key)
                  ) {
                    e.preventDefault()
                  }
                }}
              />
              <span className="text-gray-400 text-sm">%</span>
            </div>
          ))}
        </div>

        <Button
          onClick={handleSetWeeklyRates}
          disabled={saving || !selectedDate}
          className="w-full bg-red-600 hover:bg-red-700 text-white"
        >
          {saving ? (
            <>
              <Loader2 className="mr-2 h-4 w-4 animate-spin" />
              設定中...
            </>
          ) : (
            <>
              <Save className="mr-2 h-4 w-4" />
              安全に週利設定
            </>
          )}
        </Button>

        <div className="bg-green-900/20 border border-green-800 p-3 rounded-lg">
          <p className="text-sm text-green-300">
            <strong>安全保証:</strong> この設定は手動でのみ変更可能で、自動変更は完全に防止されています。
          </p>
        </div>
      </CardContent>
    </Card>
  )
}
