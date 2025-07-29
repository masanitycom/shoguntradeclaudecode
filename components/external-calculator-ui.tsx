// 🚀 外部計算システム用UI

"use client"

import { useState } from "react"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Badge } from "@/components/ui/badge"
import { Loader2, Zap, CheckCircle, AlertCircle } from "lucide-react"
import { useToast } from "@/hooks/use-toast"

interface CalculationResult {
  success: boolean
  message: string
  processed_count: number
  total_amount: number
}

export function ExternalCalculatorUI() {
  const [loading, setLoading] = useState(false)
  const [result, setResult] = useState<CalculationResult | null>(null)
  const [selectedDate, setSelectedDate] = useState(new Date().toISOString().split("T")[0])
  const { toast } = useToast()

  const handleCalculate = async () => {
    setLoading(true)
    setResult(null)

    try {
      console.log("🚀 外部計算API呼び出し開始")

      const response = await fetch("/api/calculate-rewards", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          date: selectedDate,
        }),
      })

      const data = await response.json()

      if (!response.ok) {
        throw new Error(data.error || "計算APIエラー")
      }

      setResult(data)

      if (data.success) {
        toast({
          title: "✅ 計算完了",
          description: data.message,
        })
      } else {
        toast({
          title: "❌ 計算エラー",
          description: data.message,
          variant: "destructive",
        })
      }
    } catch (error) {
      console.error("❌ 外部計算エラー:", error)
      toast({
        title: "❌ エラー",
        description: `計算に失敗しました: ${error}`,
        variant: "destructive",
      })
    } finally {
      setLoading(false)
    }
  }

  return (
    <Card className="bg-gray-800 border-gray-700">
      <CardHeader>
        <CardTitle className="text-white flex items-center">
          <Zap className="mr-2 h-5 w-5 text-yellow-400" />🚀 外部計算システム
          <Badge className="ml-2 bg-green-600">高速・安定</Badge>
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        <div className="bg-green-900/20 border border-green-800 p-3 rounded-lg">
          <h4 className="font-semibold text-green-400 mb-2">✨ 外部計算の利点</h4>
          <ul className="text-sm text-gray-300 space-y-1">
            <li>• PostgreSQL関数エラーなし</li>
            <li>• TypeScript/JavaScriptで高速計算</li>
            <li>• デバッグとテストが簡単</li>
            <li>• スケーラブルで保守しやすい</li>
          </ul>
        </div>

        <div className="space-y-2">
          <Label htmlFor="calcDate" className="text-white">
            計算対象日
          </Label>
          <Input
            id="calcDate"
            type="date"
            value={selectedDate}
            onChange={(e) => setSelectedDate(e.target.value)}
            className="bg-gray-700 border-gray-600 text-white"
          />
        </div>

        <Button
          onClick={handleCalculate}
          disabled={loading}
          className="w-full bg-yellow-600 hover:bg-yellow-700 text-black font-bold"
        >
          {loading ? (
            <>
              <Loader2 className="mr-2 h-4 w-4 animate-spin" />🚀 外部計算実行中...
            </>
          ) : (
            <>
              <Zap className="mr-2 h-4 w-4" />🚀 外部計算実行
            </>
          )}
        </Button>

        {result && (
          <div
            className={`p-4 rounded-lg border ${
              result.success ? "bg-green-900/20 border-green-800" : "bg-red-900/20 border-red-800"
            }`}
          >
            <div className="flex items-center mb-2">
              {result.success ? (
                <CheckCircle className="h-5 w-5 text-green-400 mr-2" />
              ) : (
                <AlertCircle className="h-5 w-5 text-red-400 mr-2" />
              )}
              <span className={result.success ? "text-green-400" : "text-red-400"}>
                {result.success ? "計算成功" : "計算失敗"}
              </span>
            </div>
            <p className="text-white text-sm mb-2">{result.message}</p>
            {result.success && (
              <div className="grid grid-cols-2 gap-2 text-sm">
                <div>
                  <span className="text-gray-400">処理件数:</span>
                  <span className="text-white ml-1">{result.processed_count}件</span>
                </div>
                <div>
                  <span className="text-gray-400">合計金額:</span>
                  <span className="text-white ml-1">${result.total_amount.toFixed(2)}</span>
                </div>
              </div>
            )}
          </div>
        )}
      </CardContent>
    </Card>
  )
}
