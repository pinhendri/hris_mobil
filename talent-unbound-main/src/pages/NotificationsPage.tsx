import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Loader2, Bell, Mail, Check, AlertCircle, Trash2 } from "lucide-react";
import { toast } from "@/components/ui/use-toast";
import api_laravel from "@/lib/utils";

interface Notification {
  id: string;
  type: string;
  data: {
    title: string;
    message: string;
    type: string;
    priority: string;
    broadcast_id: number;
    sent_at: string;
    sent_by: string;
    company_code?: string;
  };
  read_at: string | null;
  created_at: string;
}

export default function NotificationsPage() {
  const [notifications, setNotifications] = useState<Notification[]>([]);
  const [loading, setLoading] = useState(true);
  const [unreadCount, setUnreadCount] = useState(0);

  useEffect(() => {
    fetchNotifications();
    
    // Setup real-time updates (optional)
    const interval = setInterval(fetchNotifications, 30000); // Refresh every 30 seconds
    
    return () => clearInterval(interval);
  }, []);

  const fetchNotifications = async () => {
    try {
      setLoading(true);
      const res = await api_laravel.get('/api/notifications');
      
      if (res.data.success) {
        setNotifications(res.data.data);
        // Count unread notifications
        const unread = res.data.data.filter((n: Notification) => !n.read_at).length;
        setUnreadCount(unread);
      }
    } catch (error) {
      console.error('Error fetching notifications:', error);
      toast({
        title: "Error",
        description: "Failed to load notifications",
        variant: "destructive",
      });
    } finally {
      setLoading(false);
    }
  };

  const markAsRead = async (notificationId: string) => {
    try {
      await api_laravel.post(`/api/notifications/${notificationId}/read`);
      
      // Update local state
      setNotifications(prev => prev.map(n => 
        n.id === notificationId ? { ...n, read_at: new Date().toISOString() } : n
      ));
      
      setUnreadCount(prev => prev - 1);
      
      toast({
        title: "Success",
        description: "Notification marked as read",
      });
    } catch (error) {
      console.error('Error marking notification as read:', error);
      toast({
        title: "Error",
        description: "Failed to mark notification as read",
        variant: "destructive",
      });
    }
  };

  const markAllAsRead = async () => {
    try {
      await api_laravel.post('/api/notifications/mark-all-read');
      
      // Update local state
      setNotifications(prev => prev.map(n => ({ ...n, read_at: new Date().toISOString() })));
      setUnreadCount(0);
      
      toast({
        title: "Success",
        description: "All notifications marked as read",
      });
    } catch (error) {
      console.error('Error marking all notifications as read:', error);
      toast({
        title: "Error",
        description: "Failed to mark all notifications as read",
        variant: "destructive",
      });
    }
  };

  const deleteNotification = async (notificationId: string) => {
    try {
      await api_laravel.delete(`/api/notifications/${notificationId}`);
      
      // Update local state
      setNotifications(prev => prev.filter(n => n.id !== notificationId));
      
      // Update unread count if needed
      const deletedNotification = notifications.find(n => n.id === notificationId);
      if (deletedNotification && !deletedNotification.read_at) {
        setUnreadCount(prev => prev - 1);
      }
      
      toast({
        title: "Success",
        description: "Notification deleted",
      });
    } catch (error) {
      console.error('Error deleting notification:', error);
      toast({
        title: "Error",
        description: "Failed to delete notification",
        variant: "destructive",
      });
    }
  };

  const formatDate = (dateString: string) => {
    try {
      return new Date(dateString).toLocaleString('en-US', {
        year: 'numeric',
        month: 'short',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
      });
    } catch (error) {
      return dateString;
    }
  };

  const getPriorityBadge = (priority: string) => {
    const variants = {
      low: 'bg-green-100 text-green-800',
      medium: 'bg-yellow-100 text-yellow-800',
      high: 'bg-red-100 text-red-800'
    };
    return (
      <Badge className={`${variants[priority as keyof typeof variants]}`}>
        {priority.toUpperCase()}
      </Badge>
    );
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-screen">
        <Loader2 className="w-8 h-8 animate-spin text-muted-foreground" />
        <span className="ml-2">Loading notifications...</span>
      </div>
    );
  }

  return (
    <div className="container mx-auto p-6 space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Notifications</h1>
          <p className="text-muted-foreground">
            Stay updated with company announcements and messages
          </p>
        </div>
        
        <div className="flex items-center space-x-4">
          <Badge variant={unreadCount > 0 ? "destructive" : "outline"} className="px-3 py-1">
            <Bell className="w-4 h-4 mr-2" />
            {unreadCount} unread
          </Badge>
          
          {unreadCount > 0 && (
            <Button onClick={markAllAsRead} variant="outline" size="sm">
              <Check className="w-4 h-4 mr-2" />
              Mark all as read
            </Button>
          )}
        </div>
      </div>

      {notifications.length === 0 ? (
        <Card>
          <CardContent className="py-12 text-center">
            <Bell className="w-16 h-16 mx-auto mb-4 text-muted-foreground opacity-50" />
            <h3 className="text-lg font-medium mb-2">No notifications yet</h3>
            <p className="text-muted-foreground">
              You'll see notifications here when you receive broadcast messages
            </p>
          </CardContent>
        </Card>
      ) : (
        <div className="space-y-4">
          {notifications.map((notification) => (
            <Card 
              key={notification.id} 
              className={`overflow-hidden ${!notification.read_at ? 'border-l-4 border-l-blue-500' : ''}`}
            >
              <CardContent className="p-6">
                <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-4">
                  <div className="space-y-2 flex-1">
                    <div className="flex items-center gap-2">
                      {!notification.read_at && (
                        <span className="w-2 h-2 bg-blue-500 rounded-full"></span>
                      )}
                      <h3 className="font-semibold text-lg">{notification.data.title}</h3>
                      {getPriorityBadge(notification.data.priority)}
                      {notification.data.type === 'broadcast' && (
                        <Badge variant="outline">
                          <Bell className="w-3 h-3 mr-1" />
                          Broadcast
                        </Badge>
                      )}
                    </div>
                    
                    <p className="text-muted-foreground">{notification.data.message}</p>
                    
                    <div className="flex flex-wrap gap-2 text-sm text-muted-foreground">
                      <div className="flex items-center gap-1">
                        <Mail className="w-4 h-4" />
                        <span>From: {notification.data.sent_by}</span>
                      </div>
                      <span>•</span>
                      <div>
                        <span>{formatDate(notification.created_at)}</span>
                      </div>
                      {notification.data.company_code && (
                        <>
                          <span>•</span>
                          <Badge variant="secondary">
                            {notification.data.company_code}
                          </Badge>
                        </>
                      )}
                    </div>
                  </div>
                  
                  <div className="flex items-center space-x-2">
                    {!notification.read_at && (
                      <Button
                        onClick={() => markAsRead(notification.id)}
                        variant="outline"
                        size="sm"
                        className="h-8"
                      >
                        <Check className="w-4 h-4 mr-1" />
                        Mark as read
                      </Button>
                    )}
                    
                    <Button
                      onClick={() => deleteNotification(notification.id)}
                      variant="ghost"
                      size="sm"
                      className="h-8 text-muted-foreground hover:text-red-600"
                    >
                      <Trash2 className="w-4 h-4" />
                    </Button>
                  </div>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      )}
    </div>
  );
}