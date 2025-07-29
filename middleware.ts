import { createServerClient } from '@supabase/ssr'
import { NextResponse, type NextRequest } from 'next/server'

export async function middleware(request: NextRequest) {
  let response = NextResponse.next({
    request: {
      headers: request.headers,
    },
  })

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        get(name: string) {
          return request.cookies.get(name)?.value
        },
        set(name: string, value: string, options: any) {
          request.cookies.set({
            name,
            value,
            ...options,
          })
          response = NextResponse.next({
            request: {
              headers: request.headers,
            },
          })
          response.cookies.set({
            name,
            value,
            ...options,
          })
        },
        remove(name: string, options: any) {
          request.cookies.set({
            name,
            value: '',
            ...options,
          })
          response = NextResponse.next({
            request: {
              headers: request.headers,
            },
          })
          response.cookies.set({
            name,
            value: '',
            ...options,
          })
        },
      },
    }
  )

  // 認証が必要なパスのチェック
  const protectedPaths = ['/dashboard', '/profile', '/rewards', '/referrals', '/nft']
  const adminPaths = ['/admin']
  const authPaths = ['/login', '/register']
  
  const path = request.nextUrl.pathname
  const isProtectedPath = protectedPaths.some(p => path.startsWith(p))
  const isAdminPath = adminPaths.some(p => path.startsWith(p))
  const isAuthPath = authPaths.some(p => path.startsWith(p))

  // セッションチェック
  const { data: { session } } = await supabase.auth.getSession()

  // 認証ページにログイン済みユーザーがアクセスした場合
  if (isAuthPath && session) {
    return NextResponse.redirect(new URL('/dashboard', request.url))
  }

  // 保護されたページに未認証ユーザーがアクセスした場合
  if ((isProtectedPath || isAdminPath) && !session) {
    return NextResponse.redirect(new URL('/login', request.url))
  }

  // 管理画面へのアクセスチェック
  if (isAdminPath && session) {
    // ユーザー情報を取得して管理者権限をチェック
    const { data: user } = await supabase
      .from('users')
      .select('is_admin')
      .eq('id', session.user.id)
      .single()

    if (!user?.is_admin) {
      return NextResponse.redirect(new URL('/dashboard', request.url))
    }
  }

  return response
}

export const config = {
  matcher: [
    /*
     * Match all request paths except for the ones starting with:
     * - api (API routes)
     * - _next/static (static files)
     * - _next/image (image optimization files)
     * - favicon.ico (favicon file)
     * - public files
     */
    '/((?!api|_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)',
  ],
}