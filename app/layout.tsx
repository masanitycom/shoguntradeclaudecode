import type React from "react"
import type { Metadata } from "next"
import "./globals.css"
import { Toaster } from "@/components/ui/toaster"

export const metadata: Metadata = {
  title: "SHOGUN TRADE",
  description: "NFT投資とMLMを組み合わせたWeb3プラットフォーム",
  keywords: "NFT, 投資, MLM, Web3, SHOGUN TRADE",
  authors: [{ name: "SHOGUN TRADE Team" }],
  openGraph: {
    title: "SHOGUN TRADE",
    description: "NFT投資とMLMを組み合わせたWeb3プラットフォーム",
    type: "website",
  },
}

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode
}>) {
  return (
    <html lang="en">
      <body>
        {children}
        <Toaster />
      </body>
    </html>
  )
}
