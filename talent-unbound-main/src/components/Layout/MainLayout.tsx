"use client";

import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { SidebarProvider, SidebarTrigger } from "@/components/ui/sidebar";
import { AppSidebar } from "@/components/AppSidebar";
import { Bell, Search, User, Check, Settings, Calendar, Clock } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import api_laravel from "@/lib/utils";

interface MainLayoutProps {
  children: React.ReactNode;
}

export function MainLayout({ children }: MainLayoutProps) {
  const [user, setUser] = useState<any>(null);
  const [notifications, setNotifications] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [currentTime, setCurrentTime] = useState<string>("");
  const [currentDate, setCurrentDate] = useState<string>("");
  const [currentDay, setCurrentDay] = useState<string>("");
  const navigate = useNavigate();

  // Update waktu dan tanggal real-time
  useEffect(() => {
    const updateDateTime = () => {
      const now = new Date();
      
      // Format waktu: HH:MM:SS
      const timeString = now.toLocaleTimeString("id-ID", {
        hour: "2-digit",
        minute: "2-digit",
        second: "2-digit",
      });
      
      // Format tanggal: DD Month YYYY
      const dateString = now.toLocaleDateString("id-ID", {
        day: "2-digit",
        month: "short", // Gunakan "short" untuk lebih compact
        year: "numeric",
      });
      
      // Format hari: Senin, Selasa, etc
      const dayString = now.toLocaleDateString("id-ID", {
        weekday: "short", // Gunakan "short" untuk lebih compact
      });
      
      setCurrentTime(timeString);
      setCurrentDate(dateString);
      setCurrentDay(dayString);
    };
    
    // Update segera
    updateDateTime();
    
    // Update setiap detik
    const intervalId = setInterval(updateDateTime, 1000);
    
    return () => clearInterval(intervalId);
  }, []);

  // ambil data user login
  useEffect(() => {
    const fetchUser = async () => {
      const token = localStorage.getItem("token");
      if (!token) {
        window.location.href = "/login";
        return;
      }

      try {
        const res = await api_laravel.get("/api/me");
        console.log("User API Response:", res.data);

        let userData = null;
        if (res.data.data && res.data.data.user) userData = res.data.data.user;
        else if (res.data.data) userData = res.data.data;
        else if (res.data.user) userData = res.data.user;
        else if (res.data) userData = res.data;

        if (userData) setUser(userData);
        else throw new Error("User data tidak valid");
      } catch (err: any) {
        console.error("Gagal fetch user:", err);
        localStorage.removeItem("token");
        window.location.href = "/login";
      } finally {
        setLoading(false);
      }
    };
    fetchUser();
  }, []);

  // ambil notifikasi
  useEffect(() => {
    const fetchNotifications = async () => {
      try {
        const res = await api_laravel.get("/api/notifications");
        let notificationsData: any[] = [];

        if (res.data.data && Array.isArray(res.data.data)) {
          notificationsData = res.data.data;
        } else if (Array.isArray(res.data)) {
          notificationsData = res.data;
        } else if (res.data.notifications) {
          notificationsData = res.data.notifications;
        }

        setNotifications(notificationsData);
      } catch (err: any) {
        console.error("Gagal fetch notifikasi:", err);
      }
    };

    if (user) fetchNotifications();
  }, [user]);

  // tandai notifikasi sebagai read
  const markAsRead = async (id: number) => {
    try {
      await api_laravel.post(`/api/notifications/${id}/read`);
      setNotifications((prev) =>
        prev.map((n) => (n.id === id ? { ...n, is_read: true } : n))
      );
    } catch (err) {
      console.error("Gagal tandai notifikasi sebagai read:", err);
    }
  };

  // logout
  const handleLogout = async () => {
    try {
      await api_laravel.post("/api/logout");
    } catch (err) {
      console.error("Logout gagal:", err);
    } finally {
      localStorage.removeItem("token");
      window.location.href = "/login";
    }
  };

  // helper
  const getUserName = () => {
    if (!user || loading) return "Loading...";
    return user.name || user.username || user.email?.split("@")[0] || "User";
  };

  const getUserEmail = () => user?.email || "";
  const getUserAvatar = () => user?.avatar || user?.profile_picture || "/api/placeholder/32/32";
  const getAvatarFallback = () =>
    getUserName()
      .split(" ")
      .map((n: string) => n[0])
      .join("")
      .toUpperCase()
      .substring(0, 2);

  // handle profile & settings click
  const handleProfileClick = () => navigate("/profile");

  return (
    <SidebarProvider>
      <div className="min-h-screen flex w-full bg-background">
        <AppSidebar />
        <div className="flex-1 flex flex-col">
          {/* Header */}
          <header className="border-b bg-background/95 backdrop-blur sticky top-0 z-50">
            <div className="flex h-16 items-center px-6">
              <SidebarTrigger className="mr-4" />
              <div className="flex-1 flex items-center justify-between">
                {/* Search box */}
                <div className="relative w-64">
                  <Search className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
                  <Input placeholder="Search..." className="pl-10 bg-muted/50" />
                </div>

                {/* Right section */}
                <div className="flex items-center space-x-4">
                  {/* Date & Time Display - Versi Rapih */}
<div className="hidden md:flex items-center space-x-2">
  <div className="inline-flex items-center rounded-md border px-3 py-1.5 text-xs font-medium transition-colors bg-card text-card-foreground hover:bg-accent hover:text-accent-foreground">
    <Calendar className="mr-2 h-3.5 w-3.5" />
    <span>{currentDay}, {currentDate}</span>
  </div>
  <div className="inline-flex items-center rounded-md border px-3 py-1.5 text-xs font-medium font-mono transition-colors bg-primary/10 text-primary hover:bg-primary/20">
    <Clock className="mr-2 h-3.5 w-3.5" />
    <span>{currentTime}</span>
  </div>
</div>

                  {/* Avatar dropdown */}
                  <DropdownMenu>
                    <DropdownMenuTrigger asChild>
                      <Button variant="ghost" className="relative h-8 w-8 rounded-full">
                        <Avatar className="h-8 w-8">
                          <AvatarImage src={getUserAvatar()} alt={getUserName()} />
                          <AvatarFallback>{getAvatarFallback()}</AvatarFallback>
                        </Avatar>
                      </Button>
                    </DropdownMenuTrigger>
                    <DropdownMenuContent className="w-56" align="end" forceMount>
                      <div className="flex items-center gap-2 p-2">
                        <div className="flex flex-col space-y-1 leading-none">
                          <p className="font-medium">{getUserName()}</p>
                          <p className="w-[200px] truncate text-sm text-muted-foreground">
                            {getUserEmail()}
                          </p>
                        </div>
                      </div>
                      <DropdownMenuSeparator />
                      <DropdownMenuItem onClick={handleProfileClick}>
                        <User className="mr-2 h-4 w-4" />
                        Profile
                      </DropdownMenuItem>
                      <DropdownMenuItem onClick={() => navigate("/change-password")}>
                        <Settings className="mr-2 h-4 w-4" />
                        Change Password
                      </DropdownMenuItem>
                      <DropdownMenuSeparator />
                      <DropdownMenuItem onClick={handleLogout}>Log out</DropdownMenuItem>
                    </DropdownMenuContent>
                  </DropdownMenu>
                </div>
              </div>
            </div>
          </header>

          <main className="flex-1 p-6">{children}</main>
        </div>
      </div>
    </SidebarProvider>
  );
}