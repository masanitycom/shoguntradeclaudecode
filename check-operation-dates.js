// 運用開始日の確認用スクリプト
console.log('=== 運用開始日の確認 ===');

// サンプル日付での確認
const testDate = '2025-02-10T00:00:00.000000Z'; // Monday in UTC
const date = new Date(testDate);

console.log('Database stored date (UTC):', testDate);
console.log('JavaScript Date object:', date);
console.log('toLocaleDateString("ja-JP"):', date.toLocaleDateString('ja-JP'));
console.log('toLocaleDateString("ja-JP", {timeZone: "Asia/Tokyo"}):', date.toLocaleDateString('ja-JP', {timeZone: 'Asia/Tokyo'}));
console.log('Date only (UTC):', date.toISOString().split('T')[0]);

// 曜日確認
const days = ['日', '月', '火', '水', '木', '金', '土'];
console.log('Day of week:', days[date.getDay()]);

// JST timezone で確認
const jstDate = new Date(date.toLocaleString("en-US", {timeZone: "Asia/Tokyo"}));
console.log('JST converted:', jstDate);
console.log('JST day of week:', days[jstDate.getDay()]);

console.log('\n=== 現在時刻での確認 ===');
console.log('現在のタイムゾーン:', Intl.DateTimeFormat().resolvedOptions().timeZone);

// 2025/2/11 が火曜日問題の検証
const problemDate = '2025-02-11T00:00:00.000000Z';
const pDate = new Date(problemDate);
console.log('\n問題の日付:', problemDate);
console.log('JavaScript:', pDate.toLocaleDateString('ja-JP'));
console.log('曜日:', days[pDate.getDay()]);