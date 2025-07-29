"use client"

import { useState, useEffect } from "react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Switch } from "@/components/ui/switch"
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table"
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog"
import { Loader2, Plus, Edit, Trash2, ArrowLeft, HelpCircle } from "lucide-react"
import { createClient } from "@/lib/supabase/supabaseBrowserClient"
import { useRouter } from "next/navigation"
import { useToast } from "@/hooks/use-toast"

interface Task {
  id: string
  title?: string
  question: string
  option1: string
  option2: string
  option3: string
  is_active: boolean
  created_at: string
  updated_at: string
}

export default function AdminTasksPage() {
  const [tasks, setTasks] = useState<Task[]>([])
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [editingTask, setEditingTask] = useState<Task | null>(null)
  const [isDialogOpen, setIsDialogOpen] = useState(false)
  const [formData, setFormData] = useState({
    title: "",
    question: "",
    option1: "",
    option2: "",
    option3: "",
    is_active: true,
  })
  const router = useRouter()
  const supabase = createClient()
  const { toast } = useToast()

  useEffect(() => {
    checkAdminAuth()
    loadTasks()
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

  const loadTasks = async () => {
    try {
      const { data, error } = await supabase.from("tasks").select("*").order("created_at", { ascending: false })

      if (error) throw error
      setTasks(data || [])
    } catch (error) {
      console.error("タスク読み込みエラー:", error)
      toast({
        title: "エラー",
        description: "タスクの読み込みに失敗しました。",
        variant: "destructive",
      })
    } finally {
      setLoading(false)
    }
  }

  const handleSave = async () => {
    if (!formData.question.trim() || !formData.option1.trim() || !formData.option2.trim() || !formData.option3.trim()) {
      toast({
        title: "入力エラー",
        description: "すべての項目を入力してください。",
        variant: "destructive",
      })
      return
    }

    setSaving(true)
    try {
      const taskData = {
        title: formData.title.trim() || `タスク ${new Date().toLocaleDateString()}`,
        question: formData.question.trim(),
        option1: formData.option1.trim(),
        option2: formData.option2.trim(),
        option3: formData.option3.trim(),
        is_active: formData.is_active,
        updated_at: new Date().toISOString(),
      }

      if (editingTask) {
        // 更新
        const { error } = await supabase.from("tasks").update(taskData).eq("id", editingTask.id)

        if (error) throw error
        toast({
          title: "更新完了",
          description: "タスクを更新しました。",
        })
      } else {
        // 新規作成
        const { error } = await supabase.from("tasks").insert(taskData)

        if (error) throw error
        toast({
          title: "作成完了",
          description: "タスクを作成しました。",
        })
      }

      loadTasks()
      resetForm()
      setIsDialogOpen(false)
    } catch (error) {
      console.error("保存エラー:", error)
      toast({
        title: "エラー",
        description: "保存に失敗しました。",
        variant: "destructive",
      })
    } finally {
      setSaving(false)
    }
  }

  const handleEdit = (task: Task) => {
    setEditingTask(task)
    setFormData({
      title: task.title || "",
      question: task.question,
      option1: task.option1,
      option2: task.option2,
      option3: task.option3,
      is_active: task.is_active,
    })
    setIsDialogOpen(true)
  }

  const handleDelete = async (taskId: string) => {
    if (!confirm("このタスクを削除しますか？")) return

    try {
      const { error } = await supabase.from("tasks").delete().eq("id", taskId)

      if (error) throw error
      toast({
        title: "削除完了",
        description: "タスクを削除しました。",
      })
      loadTasks()
    } catch (error) {
      console.error("削除エラー:", error)
      toast({
        title: "エラー",
        description: "削除に失敗しました。",
        variant: "destructive",
      })
    }
  }

  const toggleActive = async (taskId: string, isActive: boolean) => {
    try {
      const { error } = await supabase
        .from("tasks")
        .update({
          is_active: !isActive,
          updated_at: new Date().toISOString(),
        })
        .eq("id", taskId)

      if (error) throw error
      loadTasks()
    } catch (error) {
      console.error("ステータス更新エラー:", error)
      toast({
        title: "エラー",
        description: "ステータス更新に失敗しました。",
        variant: "destructive",
      })
    }
  }

  const resetForm = () => {
    setEditingTask(null)
    setFormData({
      title: "",
      question: "",
      option1: "",
      option2: "",
      option3: "",
      is_active: true,
    })
  }

  const handleNewTask = () => {
    resetForm()
    setIsDialogOpen(true)
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
      {/* ヘッダー */}
      <header className="bg-gray-800 border-b border-red-800 px-6 py-4">
        <div className="max-w-7xl mx-auto flex justify-between items-center">
          <div className="flex items-center space-x-4">
            <Button onClick={() => router.push("/admin")} variant="ghost" className="text-white hover:bg-white/10">
              <ArrowLeft className="mr-2 h-4 w-4" />
              管理画面に戻る
            </Button>
            <div>
              <h1 className="text-2xl font-bold text-white">
                <HelpCircle className="inline mr-2" />
                エアドロップタスク管理
              </h1>
              <p className="text-gray-400 text-sm">報酬申請時に出題される問題を管理します</p>
            </div>
          </div>
          <Dialog open={isDialogOpen} onOpenChange={setIsDialogOpen}>
            <DialogTrigger asChild>
              <Button onClick={handleNewTask} className="bg-red-600 hover:bg-red-700 text-white">
                <Plus className="h-4 w-4 mr-2" />
                新しいタスク
              </Button>
            </DialogTrigger>
            <DialogContent className="bg-gray-800 border-gray-700 text-white">
              <DialogHeader>
                <DialogTitle className="text-white">{editingTask ? "タスク編集" : "新しいタスク"}</DialogTitle>
                <DialogDescription className="text-gray-400">
                  エアドロップタスクの問題を作成・編集します
                </DialogDescription>
              </DialogHeader>

              <div className="space-y-4">
                <div>
                  <Label htmlFor="title" className="text-white">
                    タイトル
                  </Label>
                  <Input
                    id="title"
                    value={formData.title}
                    onChange={(e) => setFormData({ ...formData, title: e.target.value })}
                    placeholder="例: エアドロップタスク1"
                    className="bg-gray-700 border-gray-600 text-white"
                  />
                </div>

                <div>
                  <Label htmlFor="question" className="text-white">
                    質問
                  </Label>
                  <Input
                    id="question"
                    value={formData.question}
                    onChange={(e) => setFormData({ ...formData, question: e.target.value })}
                    placeholder="例: あなたの好きな戦国武将は？"
                    className="bg-gray-700 border-gray-600 text-white"
                  />
                </div>

                <div>
                  <Label htmlFor="option1" className="text-white">
                    選択肢1
                  </Label>
                  <Input
                    id="option1"
                    value={formData.option1}
                    onChange={(e) => setFormData({ ...formData, option1: e.target.value })}
                    placeholder="例: 豊臣秀吉"
                    className="bg-gray-700 border-gray-600 text-white"
                  />
                </div>

                <div>
                  <Label htmlFor="option2" className="text-white">
                    選択肢2
                  </Label>
                  <Input
                    id="option2"
                    value={formData.option2}
                    onChange={(e) => setFormData({ ...formData, option2: e.target.value })}
                    placeholder="例: 徳川家康"
                    className="bg-gray-700 border-gray-600 text-white"
                  />
                </div>

                <div>
                  <Label htmlFor="option3" className="text-white">
                    選択肢3
                  </Label>
                  <Input
                    id="option3"
                    value={formData.option3}
                    onChange={(e) => setFormData({ ...formData, option3: e.target.value })}
                    placeholder="例: 織田信長"
                    className="bg-gray-700 border-gray-600 text-white"
                  />
                </div>

                <div className="flex items-center space-x-2">
                  <Switch
                    id="is_active"
                    checked={formData.is_active}
                    onCheckedChange={(checked) => setFormData({ ...formData, is_active: checked })}
                  />
                  <Label htmlFor="is_active" className="text-white">
                    アクティブ
                  </Label>
                </div>

                <div className="flex gap-2">
                  <Button onClick={handleSave} disabled={saving} className="bg-red-600 hover:bg-red-700 text-white">
                    {saving ? (
                      <>
                        <Loader2 className="h-4 w-4 animate-spin mr-2" />
                        保存中...
                      </>
                    ) : (
                      "保存"
                    )}
                  </Button>
                  <Button
                    variant="outline"
                    onClick={() => setIsDialogOpen(false)}
                    className="border-gray-600 text-gray-400 hover:bg-gray-700 hover:text-white"
                  >
                    キャンセル
                  </Button>
                </div>
              </div>
            </DialogContent>
          </Dialog>
        </div>
      </header>

      <main className="max-w-7xl mx-auto p-6">
        {/* 統計 */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-6">
          <Card className="bg-gray-800 border-gray-700">
            <CardContent className="p-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-gray-400 text-sm">総タスク数</p>
                  <p className="text-2xl font-bold text-white">{tasks.length}</p>
                </div>
                <HelpCircle className="h-8 w-8 text-red-500" />
              </div>
            </CardContent>
          </Card>
          <Card className="bg-gray-800 border-gray-700">
            <CardContent className="p-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-gray-400 text-sm">アクティブ</p>
                  <p className="text-2xl font-bold text-green-400">{tasks.filter((t) => t.is_active).length}</p>
                </div>
                <HelpCircle className="h-8 w-8 text-green-500" />
              </div>
            </CardContent>
          </Card>
          <Card className="bg-gray-800 border-gray-700">
            <CardContent className="p-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-gray-400 text-sm">非アクティブ</p>
                  <p className="text-2xl font-bold text-gray-400">{tasks.filter((t) => !t.is_active).length}</p>
                </div>
                <HelpCircle className="h-8 w-8 text-gray-500" />
              </div>
            </CardContent>
          </Card>
        </div>

        <Card className="bg-gray-800 border-gray-700">
          <CardHeader>
            <CardTitle className="text-white">タスク一覧</CardTitle>
          </CardHeader>
          <CardContent>
            <Table>
              <TableHeader>
                <TableRow className="border-gray-700">
                  <TableHead className="text-gray-300">タイトル</TableHead>
                  <TableHead className="text-gray-300">質問</TableHead>
                  <TableHead className="text-gray-300">選択肢</TableHead>
                  <TableHead className="text-gray-300">ステータス</TableHead>
                  <TableHead className="text-gray-300">作成日</TableHead>
                  <TableHead className="text-gray-300">操作</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {tasks.map((task) => (
                  <TableRow key={task.id} className="border-gray-700">
                    <TableCell className="text-white">{task.title || "無題"}</TableCell>
                    <TableCell className="max-w-xs">
                      <div className="truncate text-white" title={task.question}>
                        {task.question}
                      </div>
                    </TableCell>
                    <TableCell>
                      <div className="text-sm space-y-1 text-gray-300">
                        <div>1. {task.option1}</div>
                        <div>2. {task.option2}</div>
                        <div>3. {task.option3}</div>
                        <div>4. その他</div>
                      </div>
                    </TableCell>
                    <TableCell>
                      <Switch checked={task.is_active} onCheckedChange={() => toggleActive(task.id, task.is_active)} />
                    </TableCell>
                    <TableCell className="text-white">
                      {new Date(task.created_at).toLocaleDateString("ja-JP")}
                    </TableCell>
                    <TableCell>
                      <div className="flex gap-2">
                        <Button
                          variant="outline"
                          size="sm"
                          onClick={() => handleEdit(task)}
                          className="border-blue-600 text-blue-400 hover:bg-blue-600 hover:text-white"
                        >
                          <Edit className="h-4 w-4" />
                        </Button>
                        <Button
                          variant="outline"
                          size="sm"
                          onClick={() => handleDelete(task.id)}
                          className="border-red-600 text-red-400 hover:bg-red-600 hover:text-white"
                        >
                          <Trash2 className="h-4 w-4" />
                        </Button>
                      </div>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>

            {tasks.length === 0 && (
              <div className="text-center py-8 text-gray-400">タスクがありません。新しいタスクを作成してください。</div>
            )}
          </CardContent>
        </Card>
      </main>
    </div>
  )
}
