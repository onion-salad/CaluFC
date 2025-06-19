# Supabase Edge Function 環境変数設定ガイド

## 必要な環境変数

Supabaseプロジェクトの **Settings > Edge Functions > Secrets** で以下の環境変数を設定してください：

### 1. OPENAI_API_KEY
- **説明**: OpenAI APIキー（GPT-4oを使用するため）
- **取得方法**: 
  1. https://platform.openai.com/ にアクセス
  2. API keys セクションで新しいAPIキーを生成
  3. GPT-4oモデルへのアクセス権があることを確認
- **例**: `sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`

### 2. SUPABASE_URL
- **説明**: Supabaseプロジェクトの公開URL（既に設定済みのはず）
- **値**: `https://hoxcaloztsuckrkyvlzy.supabase.co`
- **注意**: 通常は自動的に設定されているため、確認のみ

### 3. SUPABASE_SERVICE_ROLE_KEY
- **説明**: サービスロール用のシークレットキー（RLSをバイパスしてSigned URLを生成するため）
- **取得方法**:
  1. Supabaseダッシュボードの **Settings > API** へ移動
  2. **Service role key** の値をコピー（anonキーではないので注意）
- **例**: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...` (長い文字列)
- **重要**: このキーは秘密情報なので、クライアントアプリには含めないこと

## Edge Functionのデプロイ

### 1. Supabase CLIのインストール
```bash
# macOSの場合
brew install supabase/tap/supabase

# または npm
npm install -g supabase
```

### 2. プロジェクトの初期化
```bash
cd /Users/koki/Desktop/CaluFC
supabase init
```

### 3. プロジェクトとのリンク
```bash
supabase link --project-ref hoxcaloztsuckrkyvlzy
```

### 4. Edge Functionの作成
```bash
supabase functions new analyze-meal
```

### 5. 関数コードをコピー
```bash
cp analyze-meal-function.ts supabase/functions/analyze-meal/index.ts
```

### 6. デプロイ
```bash
supabase functions deploy analyze-meal
```

## ストレージの設定

Edge Functionが画像にアクセスできるように、Storageバケットを作成：

1. Supabaseダッシュボードの **Storage** へ移動
2. 新しいバケット `meals` を作成
3. RLS ポリシーを設定（必要に応じて）

## 使用例

```swift
// SwiftからEdge Functionを呼び出す例
let functionURL = "https://hoxcaloztsuckrkyvlzy.supabase.co/functions/v1/analyze-meal"
let headers = [
    "Authorization": "Bearer \(supabaseAnonKey)",
    "Content-Type": "application/json"
]

let body = [
    "image_path": "meal_images/2024/01/19/user123_meal.jpg",
    "user_id": "user123",
    "eaten_at": ISO8601DateFormatter().string(from: Date())
]

// POSTリクエストを送信
```

## セキュリティ注意事項

1. **Service Role Key** は絶対にクライアントアプリに含めない
2. OpenAI APIキーも同様にサーバーサイドのみで使用
3. Edge Functionは認証されたユーザーのみが呼び出せるように設定することを推奨
4. 画像のSigned URLは短い有効期限（60秒）で生成される