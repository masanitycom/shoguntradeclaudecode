# SHOGUN TRADE システムドキュメント

## プロジェクト概要

SHOGUN TRADEは、NFT投資とMLM（Multi-Level Marketing）を組み合わせたWeb3プラットフォームです。Next.js 15、Supabase、Tailwind CSSを使用して構築されています。

### 主要機能
- NFT購入・管理システム
- 日利報酬計算（平日のみ、300%キャップ付き）
- MLM階層システム（8段階）
- 天下統一ボーナス分配
- エアドロップタスク（報酬申請）
- 複利運用システム

## 技術スタック

### フロントエンド
- **Framework**: Next.js 15.2.4 (App Router)
- **UI**: React 19 + Tailwind CSS
- **Components**: Radix UI + shadcn/ui
- **Forms**: React Hook Form + Zod
- **Charts**: Recharts
- **Theme**: next-themes (ダークモード対応)

### バックエンド
- **Database**: Supabase (PostgreSQL)
- **Authentication**: Supabase Auth
- **Real-time**: Supabase Realtime
- **Storage**: Supabase Storage

### デプロイメント
- **Platform**: Vercel (推奨)
- **Domain**: カスタムドメイン設定可能
- **Environment**: Production/Preview/Development

## プロジェクト構造

```
SHOGUNTRADE/
├── app/                    # Next.js App Router
│   ├── admin/             # 管理画面
│   │   ├── analytics/     # 分析ダッシュボード
│   │   ├── users/         # ユーザー管理
│   │   ├── nfts/          # NFT管理
│   │   ├── rewards/       # 報酬管理
│   │   └── ...           # その他の管理機能
│   ├── api/              # API Routes
│   │   ├── calculate-rewards/
│   │   └── user-rank/
│   ├── dashboard/        # ユーザーダッシュボード
│   ├── login/           # ログインページ
│   ├── register/        # 登録ページ
│   └── ...             # その他のページ
├── components/          # Reactコンポーネント
│   ├── ui/             # UIコンポーネント（shadcn/ui）
│   └── ...            # カスタムコンポーネント
├── lib/               # ユーティリティ
│   ├── supabase/      # Supabaseクライアント
│   └── utils.ts       # ヘルパー関数
├── scripts/           # SQLスクリプト（779個）
└── public/           # 静的ファイル
```

## Supabaseデータベース構造

### 主要テーブル

#### 1. users
- ユーザー基本情報
- MLM紹介構造（referrer_id）
- ウォレット情報
- 投資総額・報酬総額

#### 2. nfts
- NFTカタログ
- 通常NFT（is_special: false）: ユーザー購入可能
- 特別NFT（is_special: true）: 管理者のみ付与可能
- 日利上限設定（0.5%〜2.0%）

#### 3. user_nfts
- ユーザーのNFT所有情報
- 1ユーザー1NFT制限
- 300%到達で自動無効化

#### 4. daily_rewards
- 日次報酬記録
- 平日のみ計算
- 週利から自動配分

#### 5. mlm_ranks
- 8段階のランクシステム
- 足軽→武将→代官→奉行→老中→大老→大名→将軍
- 組織ボリューム条件

#### 6. group_weekly_rates
- NFTグループ別週利設定
- 管理者が手動設定
- 月〜金に自動配分

### 重要な制約
1. **300%キャップ**: 投資額の300%まで報酬獲得可能
2. **1人1NFT制限**: 同時保有は1つまで
3. **平日のみ報酬**: 土日は報酬計算なし
4. **特別NFT**: 管理画面からのみ付与可能

## 環境変数設定

```env
# Supabase
NEXT_PUBLIC_SUPABASE_URL=your_supabase_url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_anon_key
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key

# App
NEXTAUTH_URL=http://localhost:3000
NEXTAUTH_SECRET=your_secret_key
```

## 開発コマンド

```bash
# 開発サーバー起動
npm run dev

# ビルド
npm run build

# Lint実行
npm run lint

# 本番サーバー起動
npm start
```

## 管理者機能

### アクセス方法
- URL: `/admin`
- 権限: `is_admin: true`のユーザーのみ

### 主要機能
1. **ユーザー管理**: 情報編集、NFT付与
2. **NFT管理**: 価格・日利設定
3. **週利設定**: グループ別週利入力
4. **報酬管理**: 申請承認、履歴確認
5. **分析**: 売上・ユーザー統計

## セキュリティ設定

### Row Level Security (RLS)
- 全テーブルでRLS有効
- ユーザーは自分のデータのみアクセス可能
- 管理者は全データアクセス可能

### 認証
- Supabase Auth使用
- メール/パスワード認証
- セッション管理

## バッチ処理

### 日次処理
- `calculate_daily_rewards()`: 日利計算
- `apply_300_percent_cap()`: 300%キャップ適用

### 週次処理
- MLMランク更新
- 天下統一ボーナス計算・分配
- 複利処理

## デプロイメント手順

### 1. Git設定
```bash
git init
git add .
git commit -m "Initial commit"
git remote add origin <your-github-repo>
git push -u origin main
```

### 2. Vercelデプロイ
1. Vercelアカウント作成
2. GitHubリポジトリ連携
3. 環境変数設定
4. デプロイ実行

### 3. Supabase設定
1. プロジェクト作成
2. SQLスクリプト実行（順番に）
3. RLS設定確認
4. 環境変数取得

## トラブルシューティング

### よくある問題
1. **ログインできない**: メールアドレスとauth.usersの同期確認
2. **報酬が計算されない**: 週利設定とNFTグループ確認
3. **300%キャップが機能しない**: トリガー有効化確認

### デバッグ方法
- Supabaseダッシュボードでクエリ実行
- ブラウザ開発者ツールでネットワーク確認
- Vercelログ確認

## 今後の改善点

### 必要な実装
1. **メール通知システム**: 報酬申請承認時の通知
2. **2FA認証**: セキュリティ強化
3. **APIレート制限**: 過度なリクエスト防止
4. **自動バックアップ**: 定期的なデータバックアップ

### パフォーマンス最適化
1. **キャッシュ戦略**: 頻繁にアクセスされるデータのキャッシュ
2. **画像最適化**: NFT画像の最適化
3. **クエリ最適化**: 複雑なSQLクエリの改善

## 連絡先・サポート

問題が発生した場合は、以下の情報を含めて報告してください：
- エラーメッセージ
- 再現手順
- ブラウザ・OS情報
- スクリーンショット

---

最終更新: 2025-07-29