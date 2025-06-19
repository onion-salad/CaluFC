# Supabase CaluFC プロジェクト設定サマリー

## プロジェクト情報
- **プロジェクト名**: calu_by_fc
- **プロジェクトID**: hoxcaloztsuckrkyvlzy
- **URL**: https://hoxcaloztsuckrkyvlzy.supabase.co
- **Anon Key**: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhveGNhbG96dHN1Y2tya3l2bHp5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTAzMDQwNTgsImV4cCI6MjA2NTg4MDA1OH0.m2PKtFTiw1Oxx42s_QBELvBkexO7-clGKQ6h-QbcRg4

## データベース構成

### 1. user_profiles テーブル
```sql
- id (UUID) - プライマリキー
- name (TEXT) - ユーザー名
- age (INTEGER) - 年齢
- weight (DECIMAL) - 体重(kg)
- height (DECIMAL) - 身長(cm)
- gender (TEXT) - 性別（Male/Female/Other）
- activity_level (TEXT) - 活動レベル
- daily_calorie_goal (INTEGER) - 1日のカロリー目標
- created_at (TIMESTAMP) - 作成日時
- updated_at (TIMESTAMP) - 更新日時
```

### 2. meals テーブル
```sql
- id (UUID) - プライマリキー
- user_id (UUID) - ユーザーID（外部キー）
- name (TEXT) - 食事名
- calories (INTEGER) - カロリー
- image_url (TEXT) - 画像URL
- nutrients (JSONB) - 栄養素データ
  - protein (タンパク質 g)
  - fat (脂質 g)
  - carbohydrates (炭水化物 g)
  - calcium (カルシウム mg)
  - iron (鉄 mg)
  - vitamin_a (ビタミンA μg)
  - vitamin_b1 (ビタミンB1 mg)
  - vitamin_b2 (ビタミンB2 mg)
  - vitamin_c (ビタミンC mg)
  - vitamin_d (ビタミンD μg)
  - vitamin_e (ビタミンE mg)
  - fiber (食物繊維 g)
  - sugar (糖質 g)
  - sodium (ナトリウム mg)
  - cholesterol (コレステロール mg)
  - saturated_fat (飽和脂肪酸 g)
  - trans_fat (トランス脂肪酸 g)
- created_at (TIMESTAMP) - 作成日時
- updated_at (TIMESTAMP) - 更新日時
```

### 3. daily_nutrition_stats ビュー
日ごとの栄養摂取統計を集計するビュー

## Edge Function

### analyze-meal
- **エンドポイント**: https://hoxcaloztsuckrkyvlzy.supabase.co/functions/v1/analyze-meal
- **機能**: 食事画像をGPT-4oで分析し、栄養情報を返す
- **パラメータ**:
  - image_path: Storageの画像パス
  - user_id: ユーザーID
  - eaten_at: 食事日時（オプション）

## 必要な環境変数設定

Supabaseダッシュボードの **Settings > Edge Functions > Secrets** で設定:

1. **OPENAI_API_KEY**
   - OpenAI APIキー（GPT-4oアクセス権必要）

2. **SUPABASE_SERVICE_ROLE_KEY**
   - Settings > API から取得（通常は自動設定済み）

## Storage設定

1. **バケット名**: meals
   - Edge Functionが画像にアクセスするために必要
   - ダッシュボードのStorageセクションで作成

## セキュリティ設定

- すべてのテーブルでRLS（Row Level Security）有効
- ユーザーは自分のデータのみアクセス可能
- ポリシー設定済み：
  - user_profiles: SELECT/UPDATE/INSERT（自分のデータのみ）
  - meals: SELECT/INSERT/UPDATE/DELETE（自分のデータのみ）

## 今後の実装事項

1. **認証機能**
   - Supabase Authを使用したユーザー認証
   - ソーシャルログイン（Google, Apple等）

2. **画像アップロード**
   - Storage APIを使用した画像保存
   - 画像URLの管理

3. **リアルタイム同期**
   - Supabase Realtimeを使用したデータ同期

## アプリ側の実装

```swift
// SupabaseManagerの設定（完了済み）
let supabaseURL = URL(string: "https://hoxcaloztsuckrkyvlzy.supabase.co")!
let supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."

// Edge Function呼び出し例
let functionURL = "https://hoxcaloztsuckrkyvlzy.supabase.co/functions/v1/analyze-meal"
```