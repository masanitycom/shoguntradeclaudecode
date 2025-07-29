import Link from "next/link"
import { Sheet, SheetContent, SheetHeader, SheetTitle, SheetTrigger } from "@/components/ui/sheet"
import { Menu } from "lucide-react"
import { SidebarMenu, SidebarMenuItem, SidebarMenuButton } from "./SidebarMenu"
import { useSession } from "next-auth/react"
import { ShoppingCart, Gift } from "lucide-react"

export function Sidebar() {
  const { data: session } = useSession()
  const user = session?.user

  return (
    <Sheet>
      <SheetTrigger asChild>
        <Menu className="h-6 w-6 md:hidden" />
      </SheetTrigger>
      <SheetContent side="left" className="w-full sm:max-w-xs p-0">
        <SheetHeader className="px-5 pt-5 pb-4">
          <SheetTitle>メニュー</SheetTitle>
        </SheetHeader>
        <SidebarMenu>
          <SidebarMenuItem>
            <SidebarMenuButton asChild>
              <Link href="/">
                <span>ホーム</span>
              </Link>
            </SidebarMenuButton>
          </SidebarMenuItem>
          {!user?.user_metadata?.is_admin && (
            <>
              <SidebarMenuItem>
                <SidebarMenuButton asChild>
                  <Link href="/nft/purchase">
                    <ShoppingCart className="h-4 w-4" />
                    <span>NFT購入</span>
                  </Link>
                </SidebarMenuButton>
              </SidebarMenuItem>
              <SidebarMenuItem>
                <SidebarMenuButton asChild>
                  <Link href="/rewards/claim">
                    <Gift className="h-4 w-4" />
                    <span>報酬申請</span>
                  </Link>
                </SidebarMenuButton>
              </SidebarMenuItem>
            </>
          )}
        </SidebarMenu>

        {user?.user_metadata?.is_admin && (
          <>
            <div className="px-5 pt-5 pb-4">
              <p className="text-sm font-medium">管理者メニュー</p>
            </div>
            <SidebarMenu>
              <SidebarMenuItem>
                <SidebarMenuButton asChild>
                  <Link href="/admin/applications">
                    <ShoppingCart className="h-4 w-4" />
                    <span>購入申請管理</span>
                  </Link>
                </SidebarMenuButton>
              </SidebarMenuItem>
              <SidebarMenuItem>
                <SidebarMenuButton asChild>
                  <Link href="/admin/tasks">
                    <Gift className="h-4 w-4" />
                    <span>タスク管理</span>
                  </Link>
                </SidebarMenuButton>
              </SidebarMenuItem>
            </SidebarMenu>
          </>
        )}
      </SheetContent>
    </Sheet>
  )
}
