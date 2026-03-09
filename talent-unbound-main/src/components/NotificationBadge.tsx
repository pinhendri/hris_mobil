// components/NotificationBadge.tsx
import React, { useState, useEffect } from 'react';
import { Bell } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import {
  Popover,
  PopoverContent,
  PopoverTrigger,
} from "@/components/ui/popover";
import { ScrollArea } from "@/components/ui/scroll-area";
import { Separator } from "@/components/ui/separator";
import api_laravel from "@/lib/utils";
import { format } from "date-fns";

interface Notification {
  id: number;
  user_id: string;
  type: string;
  message: string;
  data: any;
  is_read: boolean;
  created_at: string;
  c_code?: string;
}

export default function NotificationBadge() {
  const [notifications, setNotifications] = useState<Notification[]>([]);
  const [unreadCount, setUnreadCount] = useState(0);
  const [loading, setLoading] = useState(false);
  const [open, setOpen] = useState(false);

  const fetchNotifications = async () => {
    try {
      setLoading(true);
      const res = await api_laravel.get('/api/notifications');
      if (res.data.data) {
        setNotifications(res.data.data);
        const unread = res.data.data.filter((n: Notification) => !n.is_read).length;
        setUnreadCount(unread);
      }
    } catch (error) {
      console.error('Error fetching notifications:', error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchNotifications();
    // Poll for new notifications every 30 seconds
    const interval = setInterval(fetchNotifications, 30000);
    return () => clearInterval(interval);
  }, []);

  const markAsRead = async (id: number) => {
    try {
      await api_laravel.post(`/api/notifications/${id}/read`);
      setNotifications(prev =>
        prev.map(n => n.id === id ? { ...n, is_read: true } : n)
      );
      setUnreadCount(prev => prev - 1);
    } catch (error) {
      console.error('Error marking notification as read:', error);
    }
  };

  const markAllAsRead = async () => {
    try {
      // Mark all unread as read
      const unreadIds = notifications.filter(n => !n.is_read).map(n => n.id);
      for (const id of unreadIds) {
        await api_laravel.post(`/api/notifications/${id}/read`);
      }
      
      setNotifications(prev =>
        prev.map(n => ({ ...n, is_read: true }))
      );
      setUnreadCount(0);
    } catch (error) {
      console.error('Error marking all as read:', error);
    }
  };

  const formatDate = (dateString: string) => {
    try {
      return format(new Date(dateString), 'MMM dd, HH:mm');
    } catch (error) {
      return dateString;
    }
  };

  const getNotificationColor = (type: string) => {
    switch (type) {
      case 'broadcast':
        return 'bg-blue-100 text-blue-800';
      case 'alert':
        return 'bg-red-100 text-red-800';
      case 'info':
        return 'bg-green-100 text-green-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  };

  return (
    <Popover open={open} onOpenChange={setOpen}>
      <PopoverTrigger asChild>
        <Button variant="ghost" size="icon" className="relative">
          <Bell className="h-5 w-5" />
          {unreadCount > 0 && (
            <Badge 
              variant="destructive" 
              className="absolute -top-1 -right-1 h-5 w-5 flex items-center justify-center p-0 text-xs"
            >
              {unreadCount}
            </Badge>
          )}
        </Button>
      </PopoverTrigger>
      <PopoverContent className="w-96 p-0" align="end">
        <div className="p-4">
          <div className="flex items-center justify-between mb-4">
            <h4 className="font-semibold">Notifications</h4>
            {unreadCount > 0 && (
              <Button
                variant="ghost"
                size="sm"
                onClick={markAllAsRead}
                className="h-8 text-xs"
              >
                Mark all as read
              </Button>
            )}
          </div>
          
          <ScrollArea className="h-[400px]">
            {loading ? (
              <div className="text-center py-8 text-muted-foreground">
                Loading notifications...
              </div>
            ) : notifications.length === 0 ? (
              <div className="text-center py-8 text-muted-foreground">
                No notifications
              </div>
            ) : (
              <div className="space-y-2">
                {notifications.map((notification) => (
                  <div
                    key={notification.id}
                    className={`p-3 rounded-lg border ${!notification.is_read ? 'bg-blue-50 border-blue-200' : 'bg-white'}`}
                    onClick={() => !notification.is_read && markAsRead(notification.id)}
                  >
                    <div className="flex items-start justify-between">
                      <div className="flex-1">
                        <div className="flex items-center gap-2 mb-1">
                          <Badge className={`text-xs ${getNotificationColor(notification.type)}`}>
                            {notification.type}
                          </Badge>
                          {!notification.is_read && (
                            <span className="w-2 h-2 bg-blue-500 rounded-full"></span>
                          )}
                        </div>
                        <p className="text-sm font-medium">{notification.message}</p>
                        {notification.data?.message && (
                          <p className="text-sm text-muted-foreground mt-1 line-clamp-2">
                            {notification.data.message}
                          </p>
                        )}
                        <div className="flex items-center justify-between mt-2">
                          <span className="text-xs text-muted-foreground">
                            {formatDate(notification.created_at)}
                          </span>
                          {notification.data?.sent_by && (
                            <span className="text-xs text-muted-foreground">
                              By: {notification.data.sent_by}
                            </span>
                          )}
                        </div>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </ScrollArea>
          
          <Separator className="my-4" />
          
          <div className="text-center">
            <Button
              variant="ghost"
              size="sm"
              className="w-full"
              onClick={() => window.location.href = '/notifications'}
            >
              View all notifications
            </Button>
          </div>
        </div>
      </PopoverContent>
    </Popover>
  );
}