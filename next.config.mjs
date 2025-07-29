/** @type {import('next').NextConfig} */
const nextConfig = {
  eslint: {
    // 一時的に有効化（本番環境では false に変更推奨）
    ignoreDuringBuilds: true,
  },
  typescript: {
    // 一時的に有効化（本番環境では false に変更推奨）
    ignoreBuildErrors: true,
  },
  images: {
    unoptimized: true,
  },
}

export default nextConfig
