# SHOGUN TRADE

NFT投資とMLMを組み合わせたWeb3プラットフォーム

## 🚀 クイックスタート

### 必要な環境
- Node.js 18以上
- npm または pnpm
- Supabaseアカウント
- Gitアカウント（バージョン管理用）
- Vercelアカウント（デプロイ用）

### セットアップ手順

1. **環境変数の設定**
   ```bash
   cp .env.example .env
   ```
   `.env`ファイルを編集して、Supabaseの認証情報を設定

2. **依存関係のインストール**
   ```bash
   npm install
   ```

3. **開発サーバーの起動**
   ```bash
   npm run dev
   ```

4. **アクセス**
   - http://localhost:3000

## 📦 デプロイ

### Vercelへのデプロイ

1. **GitHubにプッシュ**
   ```bash
   git add .
   git commit -m "Deploy to Vercel"
   git push origin main
   ```

2. **Vercelでプロジェクト作成**
   - https://vercel.com にアクセス
   - "Import Project"をクリック
   - GitHubリポジトリを選択

3. **環境変数の設定**
   Vercelのプロジェクト設定で以下の環境変数を追加：
   - `NEXT_PUBLIC_SUPABASE_URL`
   - `NEXT_PUBLIC_SUPABASE_ANON_KEY`

4. **デプロイ**
   - "Deploy"ボタンをクリック
   - 自動的にビルド・デプロイが実行される

## 🗄️ データベースセットアップ

1. **Supabaseプロジェクト作成**
   - https://supabase.com でプロジェクト作成

2. **SQLスクリプトの実行**
   - `scripts/`フォルダ内のSQLファイルを番号順に実行
   - Supabase SQLエディタで実行

## 🔐 管理者アカウント

管理者アカウントは、Supabaseのusersテーブルで`is_admin: true`を設定

## 📚 詳細ドキュメント

- [CLAUDE.md](./CLAUDE.md) - システム詳細ドキュメント
- [仕様書](./docs/SHOGUN_TRADE_SPECIFICATION.md) - ビジネス仕様書

## 🛠️ 開発コマンド

```bash
# 開発サーバー
npm run dev

# ビルド
npm run build

# 本番サーバー
npm start

# Lint実行
npm run lint
```

## 📧 サポート

問題が発生した場合は、以下の情報と共に報告してください：
- エラーメッセージ
- 再現手順
- 環境情報