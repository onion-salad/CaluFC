// Follow this setup guide to integrate the Deno language server with your editor:
// https://deno.land/manual/getting_started/setup_your_environment
// This enables autocomplete, go to definition, etc.
// Setup type definitions for built-in Supabase Runtime APIs
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
// Updated: 2024-02-13 - Using gpt-4o model for better accuracy
import { serve } from "https://deno.land/std@0.208.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import OpenAI from "https://esm.sh/openai@4.28.0";

console.log("Hello from Functions! (analyze-meal)");

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type'
};

// 環境変数の取得と検証
const SUPABASE_URL = Deno.env.get('SUPABASE_URL');
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
const OPENAI_API_KEY = Deno.env.get('OPENAI_API_KEY');

if (!SUPABASE_URL) throw new Error('SUPABASE_URL is not configured');
if (!SUPABASE_SERVICE_ROLE_KEY) throw new Error('SUPABASE_SERVICE_ROLE_KEY is not configured');
if (!OPENAI_API_KEY) throw new Error('OPENAI_API_KEY is not configured');

// --- Supabase Admin Client (サービスロールキーを使用) ---
// ★ RLS をバイパスし、Signed URL を生成するために Admin Client を使用
const supabaseAdmin = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

serve(async (req)=>{
  // CORS対応
  if (req.method === 'OPTIONS') {
    return new Response('ok', {
      headers: corsHeaders
    });
  }

  try {
    console.log('🚀 Function started');
    
    // リクエストボディの取得と検証
    let body;
    try {
      const text = await req.text();
      if (!text) {
        throw new Error('Request body is empty');
      }
      body = JSON.parse(text);
    } catch (error) {
      console.error('❌ Failed to parse request body:', error);
      throw new Error(`Invalid request body: ${error.message}`);
    }

    // ★★★ Swiftアプリからは image_path (相対パス) を受け取る ★★★
    const { image_path, user_id, eaten_at } = body;
    if (!image_path || !user_id) {
      throw new Error(`Required parameters missing: ${!image_path ? 'image_path ' : ''}${!user_id ? 'user_id' : ''}`);
    }
    console.log('📅 Eaten at:', eaten_at || 'Not specified (will use current time)');

    // --- Signed URL の生成 ---
    // ★ 有効期限を 60 秒に設定 (画像取得とOpenAI処理に十分な時間と想定)
    const signedUrlExpireTime = 60;
    const { data: signedUrlData, error: signedUrlError } = await supabaseAdmin.storage.from('meals').createSignedUrl(image_path, signedUrlExpireTime);
    
    if (signedUrlError) {
      console.error('❌ Failed to create signed URL:', signedUrlError);
      throw new Error(`Signed URL の生成に失敗しました: ${signedUrlError.message}`);
    }
    
    const signedImageUrl = signedUrlData.signedUrl;
    
    // Validate image accessibility via Signed URL
    try {
      const imageResponse = await fetch(signedImageUrl, {
        method: 'GET'
      });
      if (!imageResponse.ok) {
        const errorText = await imageResponse.text();
        console.error('❌ Image fetch via Signed URL error response:', errorText);
        throw new Error(`Failed to fetch image via Signed URL: ${imageResponse.status} ${imageResponse.statusText}`);
      }
      await imageResponse.body?.cancel();
    } catch (error) {
      console.error('❌ Image validation via Signed URL error:', error);
      throw new Error(`Signed URL を使用した画像の取得/検証に失敗しました: ${error.message}`);
    }

    const openai = new OpenAI({
      apiKey: OPENAI_API_KEY
    });

    // GPT-4 Visionで分析
    let response;
    try {
      response = await openai.chat.completions.create({
        model: "gpt-4o",
        response_format: {
          type: "json_object"
        },
        messages: [
          {
            role: "system",
            content: `入力された画像から以下の情報を推定して、JSON形式で回答してください。
            - 料理の種類と推定量
            - 料理に使われている食材と推定量
            - 料理の栄養成分（全ての値は100gあたりではなく、写真に写っている料理全体の推定値を出力してください）
            - 使用食材の種類と推定量も出力して

            以下の形式で返答してください：
            {
                "name": "料理名",
                "calories": 推定カロリー[kcal],
                "protein": タンパク質[g],
                "fat": 脂質[g],
                "carbohydrates": 炭水化物[g],
                "calcium": カルシウム[mg],
                "iron": 鉄[mg],
                "vitamin_a": ビタミンA[μg],
                "vitamin_b1": ビタミンB1[mg],
                "vitamin_b2": ビタミンB2[mg],
                "vitamin_c": ビタミンC[mg],
                "vitamin_d": ビタミンD[μg],
                "vitamin_e": ビタミンE[mg],
                "fiber": 食物繊維[g],
                "sugar": 糖質[g],
                "sodium": ナトリウム[mg],
                "cholesterol": コレステロール[mg],
                "saturated_fat": 飽和脂肪酸[g],
                "trans_fat": トランス脂肪酸[g],
                "memo": "食材と量の詳細",
                "ingredients": [
                    {"name": "食材名", "amount": "推定量"},
                    {"name": "食材名", "amount": "推定量"}
                ]
            }
            
            注意事項：
            - カロリーは必ず0より大きい値にしてください
            - 各栄養素の値は日本の一般的な料理の栄養成分を参考に推定してください
            - ビタミンの単位に注意してください（A,Dはμg、B1,B2,C,Eはmg）
            - 分析できない栄養素がある場合は0を設定してください`
          },
          {
            role: "user",
            content: [
              {
                type: "image_url",
                image_url: {
                  url: signedImageUrl,
                  detail: "high"
                }
              },
              {
                type: "text",
                text: "この料理の情報を分析してください。"
              }
            ]
          }
        ],
        max_tokens: 1000
      });
      console.log('✅ OpenAI API response received');
    } catch (error) {
      console.error('❌ OpenAI API error:', error);
      if (error.response) {
        console.error('🔍 OpenAI API error details:', {
          status: error.response.status,
          statusText: error.response.statusText,
          data: error.response.data // エラーレスポンスボディ
        });
      }
      throw new Error(`OpenAI APIでエラーが発生しました: ${error.message}`);
    }

    // 分析結果をパース
    let analysis;
    try {
      analysis = JSON.parse(response.choices[0].message.content || '{}');
    } catch (error) {
      console.error('❌ JSON parse error:', error);
      console.error('Raw OpenAI response content:', response.choices[0].message.content);
      throw new Error(`分析結果のパースに失敗しました: ${error.message}`);
    }

    // ★ Edge Functionでのデータ保存を削除 - クライアント側で保存するように変更
    console.log('✅ Analysis completed successfully (data saving will be handled by client)');

    // --- 成功レスポンス ---
    // ★ image_pathを含めた解析結果を返す
    return new Response(JSON.stringify({
      success: true,
      data: {
        ...analysis,
        image_url: image_path,
        eaten_at: eaten_at || new Date().toISOString()
      }
    }), {
      headers: {
        ...corsHeaders,
        'Content-Type': 'application/json'
      }
    });
  } catch (error) {
    // --- エラーハンドリング ---
    console.error('❌ Top level error:', error);
    
    // エラーのスタックトレースもログに出力
    if (error instanceof Error) {
      console.error('❌ Error stack:', error.stack);
    }
    
    // クライアントにはエラーメッセージのみ返す（スタックトレースは返さない方が安全）
    return new Response(JSON.stringify({
      success: false,
      error: error.message
    }), {
      status: 500,
      headers: {
        ...corsHeaders,
        'Content-Type': 'application/json'
      }
    });
  }
});

// バイト数を読みやすい形式 (KB, MB, GB) に変換するヘルパー関数
function ByteLength(bytes) {
  const units = [
    'B',
    'KB',
    'MB',
    'GB'
  ];
  let size = bytes;
  let unitIndex = 0;
  while(size >= 1024 && unitIndex < units.length - 1){
    size /= 1024;
    unitIndex++;
  }
  return `${size.toFixed(2)} ${units[unitIndex]}`;
}

/* To invoke locally:

  1. Run `supabase start` (see: https://supabase.com/docs/reference/cli/supabase-start)
  2. Make an HTTP request:

  curl -i --location --request POST 'http://127.0.0.1:54321/functions/v1/analyze-meal' \
    --header 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0' \
    --header 'Content-Type: application/json' \
    --data '{"image_path":"meal_images/your_test_image.jpg", "user_id":"your_user_id"}'

*/