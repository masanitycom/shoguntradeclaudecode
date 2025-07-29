"use client"

import { useState, useEffect } from "react"

// ビルド時の静的生成を無効化（Supabase環境変数が必要なため）
export const dynamic = 'force-dynamic'
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Badge } from "@/components/ui/badge"
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { ArrowLeft, Save, CheckCircle, Loader2, BarChart3, Settings, Trash2, Plus, RotateCcw } from "lucide-react"
import { useRouter } from "next/navigation"
import { createClient } from "@/lib/supabase/supabaseBrowserClient"
import { useToast } from "@/hooks/use-toast"

interface WeeklyRate {
  id: string
  week_start_date: string
  week_end_date: string
  weekly_rate: number
  monday_rate: number
  tuesday_rate: number
  wednesday_rate: number
  thursday_rate: number
  friday_rate: number
  group_name: string
  distribution_method: string
  has_backup: boolean
}

interface SystemStatus {
  total_users: number
  active_nfts: number
  pending_rewards: number
  last_calculation: string
  current_week_rates: number
  total_backups: number
}

interface GroupRate {
  group_name: string
  weekly_rate: string
}

interface WeeklyRateGroup {
  week_start_date: string
  week_end_date: string
  rates: WeeklyRate[]
  total_groups: number
  has_rewards: boolean
  affected_users: number
}

export default function WeeklyRatesPage() {
  const [weeklyRates, setWeeklyRates] = useState<WeeklyRate[]>([])
  const [weeklyGroups, setWeeklyGroups] = useState<WeeklyRateGroup[]>([])
  const [systemStatus, setSystemStatus] = useState<SystemStatus>({
    total_users: 0,
    active_nfts: 0,
    pending_rewards: 0,
    last_calculation: "",
    current_week_rates: 0,
    total_backups: 0,
  })
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [selectedDate, setSelectedDate] = useState("")
  const [deletingWeek, setDeletingWeek] = useState<string | null>(null)
  const [groupRates, setGroupRates] = useState<GroupRate[]>([
    { group_name: "0.5%グループ", weekly_rate: "1.500" },
    { group_name: "1.0%グループ", weekly_rate: "2.000" },
    { group_name: "1.25%グループ", weekly_rate: "2.300" },
    { group_name: "1.5%グループ", weekly_rate: "2.600" },
    { group_name: "1.75%グループ", weekly_rate: "2.900" },
    { group_name: "2.0%グループ", weekly_rate: "3.200" },
  ])

  const router = useRouter()
  const supabase = createClient()
  const { toast } = useToast()

  const safeToLocaleString = (value: any): string => {
    const num = Number(value) || 0
    return num.toLocaleString()
  }

  const safePercentage = (value: any): string => {
    const num = Number(value) || 0
    return (num * 100).toFixed(3) + "%"
  }

  const getNextMonday = (date: Date): Date => {
    const nextMonday = new Date(date)
    const dayOfWeek = nextMonday.getDay()
    const daysUntilMonday = dayOfWeek === 0 ? 1 : 8 - dayOfWeek
    nextMonday.setDate(nextMonday.getDate() + daysUntilMonday)
    return nextMonday
  }

  useEffect(() => {
    const nextMonday = getNextMonday(new Date())
    setSelectedDate(nextMonday.toISOString().split("T")[0])
  }, [])

  useEffect(() => {
    checkAdminAuth()
    loadWeeklyRates()
    loadSystemStatus()
  }, [])

  const checkAdminAuth = async () => {
    const {
      data: { user },
    } = await supabase.auth.getUser()
    if (!user) {
      router.push("/login")
      return
    }

    const { data: userData } = await supabase.from("users").select("is_admin").eq("id", user.id).single()

    if (!userData?.is_admin) {
      router.push("/dashboard")
      return
    }
  }

  const loadWeeklyRates = async () => {
    try {
      const { data, error } = await supabase.rpc("get_weekly_rates_with_groups_ui")

      if (error) {
        console.error("週利データ読み込みエラー:", error)
        setWeeklyRates([])
        return
      }

      const processedData = (data || []).map((rate: any) => ({
        id: rate.id || "",
        week_start_date: rate.week_start_date || "",
        week_end_date: rate.week_end_date || "",
        weekly_rate: Number(rate.weekly_rate) || 0,
        monday_rate: Number(rate.monday_rate) || 0,
        tuesday_rate: Number(rate.tuesday_rate) || 0,
        wednesday_rate: Number(rate.wednesday_rate) || 0,
        thursday_rate: Number(rate.thursday_rate) || 0,
        friday_rate: Number(rate.friday_rate) || 0,
        group_name: rate.group_name || "",
        distribution_method: rate.distribution_method || "manual",
        has_backup: Boolean(rate.has_backup),
      }))

      setWeeklyRates(processedData)

      // 週ごとにグループ化
      const groupedByWeek = processedData.reduce((acc: { [key: string]: WeeklyRate[] }, rate) => {
        const weekKey = rate.week_start_date
        if (!acc[weekKey]) {
          acc[weekKey] = []
        }
        acc[weekKey].push(rate)
        return acc
      }, {})

      // 各週の報酬データとユーザー数を取得
      const weeklyGroupsData = await Promise.all(
        Object.entries(groupedByWeek).map(async ([weekStart, rates]) => {
          // その週の報酬が存在するかチェック
          const { count: rewardCount } = await supabase
            .from('daily_rewards')
            .select('id', { count: 'exact', head: true })
            .gte('reward_date', weekStart)
            .lte('reward_date', rates[0]?.week_end_date || weekStart)

          // その週にアクティブなNFTを持つユーザー数を取得
          const { count: userCount } = await supabase
            .from('user_nfts')
            .select('id', { count: 'exact', head: true })
            .eq('is_active', true)
            .lte('operation_start_date', weekStart)

          return {
            week_start_date: weekStart,
            week_end_date: rates[0]?.week_end_date || "",
            rates,
            total_groups: rates.length,
            has_rewards: (rewardCount || 0) > 0,
            affected_users: userCount || 0,
          }
        })
      )

      weeklyGroupsData.sort((a, b) => new Date(b.week_start_date).getTime() - new Date(a.week_start_date).getTime())
      setWeeklyGroups(weeklyGroupsData)
    } catch (error) {
      console.error("週利データ読み込みエラー:", error)
      setWeeklyRates([])
      setWeeklyGroups([])
    } finally {
      setLoading(false)
    }
  }

  const loadSystemStatus = async () => {
    try {
      const { data, error } = await supabase.rpc("get_simple_system_status")

      if (error) {
        console.error("システム状況読み込みエラー:", error)
        setSystemStatus({
          total_users: 0,
          active_nfts: 0,
          pending_rewards: 0,
          last_calculation: "取得失敗",
          current_week_rates: 0,
          total_backups: 0,
        })
        return
      }

      const status = data?.[0] || {}
      setSystemStatus({
        total_users: Number(status.total_users) || 0,
        active_nfts: Number(status.active_nfts) || 0,
        pending_rewards: Number(status.pending_rewards) || 0,
        last_calculation: status.last_calculation || "手動設定モード",
        current_week_rates: Number(status.current_week_rates) || 0,
        total_backups: Number(status.total_backups) || 0,
      })
    } catch (error) {
      console.error("システム状況読み込みエラー:", error)
      setSystemStatus({
        total_users: 0,
        active_nfts: 0,
        pending_rewards: 0,
        last_calculation: "取得失敗",
        current_week_rates: 0,
        total_backups: 0,
      })
    }
  }

  const handleSetGroupWeeklyRates = async () => {
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
        const { data, error } = await supabase.rpc("set_group_weekly_rate_ui", {
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
        await loadWeeklyRates()
        await loadSystemStatus()
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

  const handleDeleteWeeklyRates = async (weekStartDate: string) => {
    if (!confirm(`${weekStartDate}週の設定を削除しますか？\n\n削除前にバックアップが作成されます。`)) {
      return
    }

    setDeletingWeek(weekStartDate)

    try {
      const { data, error } = await supabase.rpc("admin_delete_weekly_rates_by_week", {
        p_week_start_date: weekStartDate,
        p_reason: "管理画面からの手動削除",
      })

      if (error) throw error

      const result = data?.[0]
      if (result?.success) {
        toast({
          title: "削除完了",
          description: result.message,
        })
        await loadWeeklyRates()
        await loadSystemStatus()
      } else {
        throw new Error(result?.message || "削除に失敗しました")
      }
    } catch (error: any) {
      console.error("削除エラー:", error)
      toast({
        title: "エラー",
        description: error.message || "削除に失敗しました",
        variant: "destructive",
      })
    } finally {
      setDeletingWeek(null)
    }
  }

  const handleRestoreWeeklyRates = async (weekStartDate: string) => {
    if (!confirm(`${weekStartDate}週の設定をバックアップから復元しますか？`)) {
      return
    }

    setSaving(true)

    try {
      const { data, error } = await supabase.rpc("restore_weekly_rates_from_backup", {
        p_week_start_date: weekStartDate,
      })

      if (error) throw error

      const result = data?.[0]
      if (result?.success) {
        toast({
          title: "復元完了",
          description: result.message,
        })
        await loadWeeklyRates()
        await loadSystemStatus()
      } else {
        throw new Error(result?.message || "復元に失敗しました")
      }
    } catch (error: any) {
      console.error("復元エラー:", error)
      toast({
        title: "エラー",
        description: error.message || "復元に失敗しました",
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

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-900 flex items-center justify-center">
        <Loader2 className="h-8 w-8 animate-spin text-white" />
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gray-900">
      <header className="bg-gray-800 border-b border-red-800 px-6 py-4">
        <div className="max-w-7xl mx-auto flex justify-between items-center">
          <div className="flex items-center space-x-4">
            <Button onClick={() => router.push("/admin")} variant="ghost" className="text-white hover:bg-white/10">
              <ArrowLeft className="mr-2 h-4 w-4" />
              管理画面に戻る
            </Button>
            <div>
              <h1 className="text-2xl font-bold text-white">週利管理（個別削除対応）</h1>
              <p className="text-gray-400 text-sm">週ごとの個別削除・復元機能付き</p>
            </div>
          </div>
          <Badge className="bg-green-600 text-white">
            <CheckCircle className="mr-1 h-3 w-3" />
            個別削除対応
          </Badge>
        </div>
      </header>

      <main className="max-w-7xl mx-auto p-6">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-8">
          <Card className="bg-gray-800 border-gray-700">
            <CardContent className="p-4">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-gray-400 text-sm">総ユーザー数</p>
                  <p className="text-2xl font-bold text-white">{safeToLocaleString(systemStatus.total_users)}</p>
                </div>
                <BarChart3 className="h-8 w-8 text-blue-400" />
              </div>
            </CardContent>
          </Card>
          <Card className="bg-gray-800 border-gray-700">
            <CardContent className="p-4">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-gray-400 text-sm">アクティブNFT</p>
                  <p className="text-2xl font-bold text-white">{safeToLocaleString(systemStatus.active_nfts)}</p>
                </div>
                <CheckCircle className="h-8 w-8 text-green-400" />
              </div>
            </CardContent>
          </Card>
          <Card className="bg-gray-800 border-gray-700">
            <CardContent className="p-4">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-gray-400 text-sm">設定済み週数</p>
                  <p className="text-2xl font-bold text-white">{safeToLocaleString(systemStatus.current_week_rates)}</p>
                </div>
                <Settings className="h-8 w-8 text-purple-400" />
              </div>
            </CardContent>
          </Card>
          <Card className="bg-gray-800 border-gray-700">
            <CardContent className="p-4">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-gray-400 text-sm">バックアップ数</p>
                  <p className="text-2xl font-bold text-white">{safeToLocaleString(systemStatus.total_backups)}</p>
                </div>
                <RotateCcw className="h-8 w-8 text-orange-400" />
              </div>
            </CardContent>
          </Card>
        </div>

        <Tabs defaultValue="setting" className="space-y-6">
          <TabsList className="bg-gray-800 border-gray-700">
            <TabsTrigger value="setting" className="data-[state=active]:bg-red-600">
              週利設定
            </TabsTrigger>
            <TabsTrigger value="manage" className="data-[state=active]:bg-red-600">
              週別管理
            </TabsTrigger>
            <TabsTrigger value="history" className="data-[state=active]:bg-red-600">
              詳細履歴
            </TabsTrigger>
          </TabsList>

          <TabsContent value="setting">
            <div className="grid gap-6 md:grid-cols-1">
              <Card className="bg-gray-800 border-gray-700">
                <CardHeader>
                  <CardTitle className="text-white flex items-center">
                    <Plus className="mr-2 h-5 w-5" />
                    新規週利設定
                  </CardTitle>
                </CardHeader>
                <CardContent className="space-y-4">
                  <div className="bg-blue-900/20 border border-blue-800 p-4 rounded-lg">
                    <h4 className="font-semibold text-blue-400 mb-2">📅 週利設定機能</h4>
                    <ul className="text-sm text-gray-300 space-y-1">
                      <li>• 週ごとに個別設定可能</li>
                      <li>• 設定後は週別管理で個別削除可能</li>
                      <li>• 削除時は自動バックアップ作成</li>
                      <li>• バックアップからの復元も可能</li>
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
                    onClick={handleSetGroupWeeklyRates}
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
                        週利設定実行
                      </>
                    )}
                  </Button>
                </CardContent>
              </Card>
            </div>
          </TabsContent>

          <TabsContent value="manage">
            <Card className="bg-gray-800 border-gray-700">
              <CardHeader>
                <CardTitle className="text-white">週別管理（個別削除・復元）</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-4">
                  {weeklyGroups.map((weekGroup) => (
                    <Card key={weekGroup.week_start_date} className="bg-gray-700 border-gray-600">
                      <CardContent className="p-4">
                        <div className="flex justify-between items-start">
                          <div className="flex-1">
                            <h3 className="text-white font-semibold mb-2">
                              {new Date(weekGroup.week_start_date).toLocaleDateString("ja-JP")} -{" "}
                              {new Date(weekGroup.week_end_date).toLocaleDateString("ja-JP")}
                            </h3>
                            <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-sm">
                              <div>
                                <span className="text-gray-400">グループ数:</span>
                                <span className="text-white ml-2">{weekGroup.total_groups}件</span>
                              </div>
                              <div>
                                <span className="text-gray-400">設定方法:</span>
                                <Badge variant="outline" className="text-green-400 border-green-400 ml-2">
                                  手動設定
                                </Badge>
                              </div>
                              <div>
                                <span className="text-gray-400">バックアップ:</span>
                                <Badge className="bg-blue-600 text-white ml-2">
                                  <CheckCircle className="mr-1 h-3 w-3" />
                                  利用可能
                                </Badge>
                              </div>
                            </div>
                            <div className="mt-3">
                              <div className="text-xs text-gray-400 mb-1">設定済みグループ:</div>
                              <div className="flex flex-wrap gap-1">
                                {weekGroup.rates.map((rate) => (
                                  <Badge key={rate.id} variant="outline" className="text-xs">
                                    {rate.group_name}: {safePercentage(rate.weekly_rate)}
                                  </Badge>
                                ))}
                              </div>
                            </div>
                          </div>
                          <div className="flex space-x-2 ml-4">
                            <Button
                              onClick={() => handleRestoreWeeklyRates(weekGroup.week_start_date)}
                              disabled={saving}
                              variant="outline"
                              size="sm"
                              className="text-blue-400 border-blue-400 hover:bg-blue-400/10"
                            >
                              <RotateCcw className="mr-1 h-3 w-3" />
                              復元
                            </Button>
                            <Button
                              onClick={() => handleDeleteWeeklyRates(weekGroup.week_start_date)}
                              disabled={deletingWeek === weekGroup.week_start_date}
                              variant="destructive"
                              size="sm"
                              className="bg-red-600 hover:bg-red-700"
                            >
                              {deletingWeek === weekGroup.week_start_date ? (
                                <>
                                  <Loader2 className="mr-1 h-3 w-3 animate-spin" />
                                  削除中
                                </>
                              ) : (
                                <>
                                  <Trash2 className="mr-1 h-3 w-3" />
                                  削除
                                </>
                              )}
                            </Button>
                          </div>
                        </div>
                      </CardContent>
                    </Card>
                  ))}
                  {weeklyGroups.length === 0 && (
                    <div className="text-center py-8 text-gray-400">設定済みの週利がありません</div>
                  )}
                </div>
              </CardContent>
            </Card>
          </TabsContent>

          <TabsContent value="history">
            <Card className="bg-gray-800 border-gray-700">
              <CardHeader>
                <CardTitle className="text-white">詳細履歴</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="overflow-x-auto">
                  <Table>
                    <TableHeader>
                      <TableRow className="border-gray-700">
                        <TableHead className="text-gray-300">期間</TableHead>
                        <TableHead className="text-gray-300">グループ</TableHead>
                        <TableHead className="text-gray-300">週利</TableHead>
                        <TableHead className="text-gray-300">月</TableHead>
                        <TableHead className="text-gray-300">火</TableHead>
                        <TableHead className="text-gray-300">水</TableHead>
                        <TableHead className="text-gray-300">木</TableHead>
                        <TableHead className="text-gray-300">金</TableHead>
                        <TableHead className="text-gray-300">設定方法</TableHead>
                      </TableRow>
                    </TableHeader>
                    <TableBody>
                      {weeklyRates.map((rate) => (
                        <TableRow key={rate.id} className="border-gray-700">
                          <TableCell className="text-white">
                            {new Date(rate.week_start_date).toLocaleDateString("ja-JP")} -{" "}
                            {new Date(rate.week_end_date).toLocaleDateString("ja-JP")}
                          </TableCell>
                          <TableCell className="text-white">{rate.group_name}</TableCell>
                          <TableCell className="text-white">{safePercentage(rate.weekly_rate)}</TableCell>
                          <TableCell className="text-white">{safePercentage(rate.monday_rate)}</TableCell>
                          <TableCell className="text-white">{safePercentage(rate.tuesday_rate)}</TableCell>
                          <TableCell className="text-white">{safePercentage(rate.wednesday_rate)}</TableCell>
                          <TableCell className="text-white">{safePercentage(rate.thursday_rate)}</TableCell>
                          <TableCell className="text-white">{safePercentage(rate.friday_rate)}</TableCell>
                          <TableCell>
                            <Badge variant="outline" className="text-green-400 border-green-400">
                              手動設定
                            </Badge>
                          </TableCell>
                        </TableRow>
                      ))}
                    </TableBody>
                  </Table>
                  {weeklyRates.length === 0 && (
                    <div className="text-center py-8 text-gray-400">設定履歴がありません</div>
                  )}
                </div>
              </CardContent>
            </Card>
          </TabsContent>
        </Tabs>
      </main>
    </div>
  )
}
