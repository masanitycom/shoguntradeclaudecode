#!/bin/bash

# Supabase設定
SUPABASE_URL="https://xkgdzmxltnnclvnrpylo.supabase.co"
SUPABASE_ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhrZ2R6bXhsdG5uY2x2bnJweWxvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTAyNjQ4NzAsImV4cCI6MjA2NTg0MDg3MH0.SA4YpYtRac5fpgOpRBp5_w46GbHFshqc4FufYY5KgpM"

echo "🔍 テストユーザーを確認中..."

# 1. テストユーザーの確認
curl -X GET "${SUPABASE_URL}/rest/v1/users?select=id,name,email,phone,created_at&or=(name.like.ユーザー*,name.like.テストユーザー*,phone.eq.000-0000-0000)" \
  -H "apikey: ${SUPABASE_ANON_KEY}" \
  -H "Authorization: Bearer ${SUPABASE_ANON_KEY}" \
  -H "Content-Type: application/json"

echo -e "\n\n⚠️  テストユーザーの削除は手動で行ってください。"
echo "上記のリストを確認して、削除が必要なユーザーがいる場合は管理画面から削除してください。"