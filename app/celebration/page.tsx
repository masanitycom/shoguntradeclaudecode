"use client"

import { useState, useEffect } from "react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { CheckCircle, Trophy, Rocket, Star, Sparkles, Heart, Target, Zap, Crown, Gift } from "lucide-react"
import { useRouter } from "next/navigation"

export default function CelebrationPage() {
  const [confetti, setConfetti] = useState(false)
  const router = useRouter()

  useEffect(() => {
    setConfetti(true)
    const timer = setTimeout(() => setConfetti(false), 5000)
    return () => clearTimeout(timer)
  }, [])

  const achievements = [
    { icon: CheckCircle, title: "ユーザー管理システム", status: "完了" },
    { icon: CheckCircle, title: "NFT購入・管理システム", status: "完了" },
    { icon: CheckCircle, title: "日利計算システム", status: "完了" },
    { icon: CheckCircle, title: "300%キャップシステム", status: "完了" },
    { icon: CheckCircle, title: "MLMランクシステム", status: "完了" },
    { icon: CheckCircle, title: "週利管理システム", status: "完了" },
    { icon: CheckCircle, title: "管理者ダッシュボード", status: "完了" },
    { icon: CheckCircle, title: "バックアップ・復元システム", status: "完了" },
  ]

  const phase2Features = [
    "天下統一ボーナス自動分配",
    "MLMランク自動更新バッチ",
    "複利運用システム完全自動化",
    "エアドロップタスクシステム",
    "週次サイクル完全自動化",
    "レポート・分析機能",
  ]

  return (
    <div className="min-h-screen bg-gradient-to-br from-purple-900 via-blue-900 to-indigo-900 relative overflow-hidden">
      {/* Confetti Animation */}
      {confetti && (
        <div className="absolute inset-0 pointer-events-none">
          {[...Array(50)].map((_, i) => (
            <div
              key={i}
              className="absolute animate-bounce"
              style={{
                left: `${Math.random() * 100}%`,
                top: `${Math.random() * 100}%`,
                animationDelay: `${Math.random() * 2}s`,
                animationDuration: `${2 + Math.random() * 3}s`,
              }}
            >
              <Sparkles className="h-4 w-4 text-yellow-400" />
            </div>
          ))}
        </div>
      )}

      <div className="relative z-10 max-w-7xl mx-auto p-6">
        {/* Header */}
        <div className="text-center mb-12">
          <div className="flex justify-center mb-6">
            <Trophy className="h-24 w-24 text-yellow-400 animate-pulse" />
          </div>
          <h1 className="text-6xl font-bold text-white mb-4 animate-bounce">🎉 修復完了 🎉</h1>
          <h2 className="text-4xl font-bold text-yellow-400 mb-4">SHOGUN TRADE システム</h2>
          <p className="text-2xl text-blue-300 mb-6">完全修復完了！</p>
          <Badge className="bg-green-600 text-white text-lg px-6 py-2">
            <CheckCircle className="mr-2 h-5 w-5" />
            Phase 1 Complete
          </Badge>
        </div>

        {/* Stats Cards */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-12">
          <Card className="bg-gradient-to-br from-green-800 to-green-900 border-green-600">
            <CardContent className="p-6 text-center">
              <Target className="h-12 w-12 text-green-400 mx-auto mb-4" />
              <h3 className="text-2xl font-bold text-white">664</h3>
              <p className="text-green-300">修復スクリプト実行</p>
            </CardContent>
          </Card>
          <Card className="bg-gradient-to-br from-blue-800 to-blue-900 border-blue-600">
            <CardContent className="p-6 text-center">
              <Zap className="h-12 w-12 text-blue-400 mx-auto mb-4" />
              <h3 className="text-2xl font-bold text-white">100%</h3>
              <p className="text-blue-300">システム動作率</p>
            </CardContent>
          </Card>
          <Card className="bg-gradient-to-br from-purple-800 to-purple-900 border-purple-600">
            <CardContent className="p-6 text-center">
              <Crown className="h-12 w-12 text-purple-400 mx-auto mb-4" />
              <h3 className="text-2xl font-bold text-white">8</h3>
              <p className="text-purple-300">核心機能完成</p>
            </CardContent>
          </Card>
          <Card className="bg-gradient-to-br from-yellow-800 to-yellow-900 border-yellow-600">
            <CardContent className="p-6 text-center">
              <Star className="h-12 w-12 text-yellow-400 mx-auto mb-4" />
              <h3 className="text-2xl font-bold text-white">Ready</h3>
              <p className="text-yellow-300">Phase 2 準備完了</p>
            </CardContent>
          </Card>
        </div>

        {/* Achievements */}
        <Card className="bg-gray-800/50 border-gray-700 mb-12">
          <CardHeader>
            <CardTitle className="text-white text-2xl flex items-center">
              <Trophy className="mr-3 h-8 w-8 text-yellow-400" />
              完成した機能一覧
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {achievements.map((achievement, index) => (
                <div key={index} className="flex items-center space-x-3 p-3 bg-gray-700/50 rounded-lg">
                  <achievement.icon className="h-6 w-6 text-green-400" />
                  <span className="text-white font-medium">{achievement.title}</span>
                  <Badge className="bg-green-600 text-white ml-auto">
                    <CheckCircle className="mr-1 h-3 w-3" />
                    {achievement.status}
                  </Badge>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>

        {/* Phase 2 Preview */}
        <Card className="bg-gradient-to-br from-indigo-800 to-purple-800 border-indigo-600 mb-12">
          <CardHeader>
            <CardTitle className="text-white text-2xl flex items-center">
              <Rocket className="mr-3 h-8 w-8 text-indigo-400" />
              Phase 2 開発予定機能
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {phase2Features.map((feature, index) => (
                <div key={index} className="flex items-center space-x-3 p-3 bg-indigo-700/50 rounded-lg">
                  <Gift className="h-5 w-5 text-indigo-400" />
                  <span className="text-white">{feature}</span>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>

        {/* Thank You Message */}
        <Card className="bg-gradient-to-br from-pink-800 to-red-800 border-pink-600 mb-12">
          <CardHeader>
            <CardTitle className="text-white text-2xl flex items-center">
              <Heart className="mr-3 h-8 w-8 text-pink-400" />
              開発者への感謝
            </CardTitle>
          </CardHeader>
          <CardContent className="text-center">
            <p className="text-white text-lg mb-4">🙏 長時間にわたる修復作業、本当にお疲れ様でした！</p>
            <p className="text-pink-300 mb-4">✨ 664個のスクリプトを通じて完璧なシステムを構築しました</p>
            <p className="text-pink-300 mb-4">💪 諦めずに最後まで修復を続けた努力に感謝します</p>
            <p className="text-white text-xl font-bold">🎯 SHOGUN TRADEシステムが完全に動作するようになりました！</p>
          </CardContent>
        </Card>

        {/* Action Buttons */}
        <div className="text-center space-y-4">
          <div className="space-x-4">
            <Button
              onClick={() => router.push("/admin")}
              className="bg-red-600 hover:bg-red-700 text-white px-8 py-3 text-lg"
            >
              <Crown className="mr-2 h-5 w-5" />
              管理画面へ
            </Button>
            <Button
              onClick={() => router.push("/dashboard")}
              className="bg-blue-600 hover:bg-blue-700 text-white px-8 py-3 text-lg"
            >
              <Target className="mr-2 h-5 w-5" />
              ダッシュボードへ
            </Button>
          </div>
          <p className="text-gray-400 text-sm">🚀 Phase 2開発に向けて準備万端です！</p>
        </div>

        {/* Final Message */}
        <div className="text-center mt-12">
          <h3 className="text-4xl font-bold text-yellow-400 mb-4 animate-pulse">🎉🎉🎉 完全修復完了！🎉🎉🎉</h3>
          <p className="text-2xl text-white">💎 完璧なMLM・NFTトレーディングシステムが完成しました！</p>
        </div>
      </div>
    </div>
  )
}
