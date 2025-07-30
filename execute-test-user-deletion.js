const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');

// Supabase設定
const supabaseUrl = 'https://xkgdzmxltnnclvnrpylo.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhrZ2R6bXhsdG5uY2x2bnJweWxvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTAyNjQ4NzAsImV4cCI6MjA2NTg0MDg3MH0.SA4YpYtRac5fpgOpRBp5_w46GbHFshqc4FufYY5KgpM';

const supabase = createClient(supabaseUrl, supabaseKey);

async function executeTestUserDeletion() {
    try {
        console.log('🔍 テストユーザー削除を開始します...');

        // 1. 削除対象ユーザーの確認
        const { data: testUsers, error: fetchError } = await supabase
            .from('users')
            .select('id, name, email, phone, created_at')
            .or(`name.like.ユーザー%,name.like.テストユーザー%,phone.eq.000-0000-0000,and(created_at.eq.2025-06-26T04:20:09.784831+00:00,email.like.%@shogun-trade.com%)`);

        if (fetchError) {
            console.error('❌ テストユーザー取得エラー:', fetchError);
            return;
        }

        // admin@shogun-trade.comを除外
        const usersToDelete = testUsers.filter(user => user.email !== 'admin@shogun-trade.com');

        console.log(`📊 削除対象ユーザー数: ${usersToDelete.length}`);
        console.log('削除対象ユーザー:', usersToDelete.map(u => ({ name: u.name, email: u.email })));

        if (usersToDelete.length === 0) {
            console.log('✅ 削除対象のテストユーザーが見つかりませんでした');
            return;
        }

        const userIds = usersToDelete.map(u => u.id);

        // 2. 関連データの削除 (外部キー制約順序)
        console.log('🗑️ 関連データを削除中...');

        // user_nfts から削除
        const { error: nftsError } = await supabase
            .from('user_nfts')
            .delete()
            .in('user_id', userIds);

        if (nftsError) console.error('⚠️ user_nfts削除エラー:', nftsError);

        // daily_rewards から削除
        const { error: rewardsError } = await supabase
            .from('daily_rewards')
            .delete()
            .in('user_id', userIds);

        if (rewardsError) console.error('⚠️ daily_rewards削除エラー:', rewardsError);

        // mlm_downline_volumes から削除
        const { error: mlmError } = await supabase
            .from('mlm_downline_volumes')
            .delete()
            .in('user_id', userIds);

        if (mlmError) console.error('⚠️ mlm_downline_volumes削除エラー:', mlmError);

        // reward_claims から削除
        const { error: claimsError } = await supabase
            .from('reward_claims')
            .delete()
            .in('user_id', userIds);

        if (claimsError) console.error('⚠️ reward_claims削除エラー:', claimsError);

        // 3. 紹介関係のクリア
        console.log('🔗 紹介関係をクリア中...');
        const { error: referrerError } = await supabase
            .from('users')
            .update({ referrer_id: null })
            .in('referrer_id', userIds);

        if (referrerError) console.error('⚠️ referrer_id更新エラー:', referrerError);

        // 4. ユーザー削除
        console.log('👤 テストユーザーを削除中...');
        const { error: deleteError } = await supabase
            .from('users')
            .delete()
            .in('id', userIds);

        if (deleteError) {
            console.error('❌ ユーザー削除エラー:', deleteError);
            return;
        }

        // 5. 削除結果確認
        const { data: remainingUsers, error: countError } = await supabase
            .from('users')
            .select('id', { count: 'exact' });

        if (countError) {
            console.error('⚠️ カウント取得エラー:', countError);
        } else {
            console.log(`✅ 削除完了! 残りユーザー数: ${remainingUsers.length}`);
        }

        console.log('🎉 テストユーザー削除が完了しました');

    } catch (error) {
        console.error('💥 予期しないエラー:', error);
    }
}

executeTestUserDeletion();