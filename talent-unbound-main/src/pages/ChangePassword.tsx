"use client";

import { useEffect, useState } from "react";
import {
  Settings as SettingsIcon,
  User,
  Bell,
  Shield,
  Database,
} from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Switch } from "@/components/ui/switch";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { toast } from "sonner";
import api_laravel from "@/lib/utils";

// 🗺️ Untuk peta
import { MapContainer, TileLayer, Marker, useMapEvents } from "react-leaflet";
import "leaflet/dist/leaflet.css";
import L from "leaflet";

// Default icon fix
delete (L.Icon.Default as any).prototype._getIconUrl;
L.Icon.Default.mergeOptions({
  iconUrl: "https://unpkg.com/leaflet@1.9.3/dist/images/marker-icon.png",
  iconRetinaUrl: "https://unpkg.com/leaflet@1.9.3/dist/images/marker-icon-2x.png",
  shadowUrl: "https://unpkg.com/leaflet@1.9.3/dist/images/marker-shadow.png",
});

interface Setting {
  company_name: string;
  timezone: string;
  date_format: string;
  currency: string;
  latitude: number;
  longitude: number;
}

interface UserData {
  id: number;
  first_name: string;
  last_name: string;
  email: string;
  phone: string;
  avatar?: string;
}

export default function Settings() {
  // 🔹 General State
  const [settings, setSettings] = useState<Setting | null>(null);
  const [loadingSettings, setLoadingSettings] = useState(false);

  // 🔹 Profile State
  const [user, setUser] = useState<UserData | null>(null);
  const [loadingUser, setLoadingUser] = useState(true);

  // 🔹 Security State
  const [oldPassword, setOldPassword] = useState("");
  const [newPassword, setNewPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [loadingPassword, setLoadingPassword] = useState(false);

  // ✅ Ambil data setting (General)
  useEffect(() => {
    const fetchSettings = async () => {
      setLoadingSettings(true);
      try {
        const res = await api_laravel.get("/api/settings");
        setSettings(res.data.data);
      } catch (err) {
        console.error(err);
        toast.error("Gagal memuat pengaturan sistem");
      } finally {
        setLoadingSettings(false);
      }
    };
    fetchSettings();
  }, []);

  // ✅ Ambil data user (Profile)
  useEffect(() => {
    const fetchUser = async () => {
      const token = localStorage.getItem("token");
      if (!token) {
        window.location.href = "/login";
        return;
      }
      try {
        const res = await api_laravel.get("/api/me");
        const data = res.data?.data?.user || res.data?.data || res.data;
        if (data) setUser(data);
      } catch (err) {
        console.error(err);
        localStorage.removeItem("token");
        window.location.href = "/login";
      } finally {
        setLoadingUser(false);
      }
    };
    fetchUser();
  }, []);

  // 📍 Fungsi peta klik
  function LocationMarker() {
    useMapEvents({
      click(e) {
        setSettings((prev) =>
          prev ? { ...prev, latitude: e.latlng.lat, longitude: e.latlng.lng } : prev
        );
      },
    });
    return settings ? (
      <Marker position={[settings.latitude, settings.longitude]} />
    ) : null;
  }

  // 🧩 Simpan General Settings
  const handleSaveSettings = async () => {
    if (!settings) return;
    try {
      setLoadingSettings(true);
      const res = await api_laravel.post("/api/settings/update", settings);
      toast.success(res.data.message || "Pengaturan berhasil disimpan!");
    } catch (err) {
      console.error(err);
      toast.error("Gagal menyimpan pengaturan");
    } finally {
      setLoadingSettings(false);
    }
  };

  // 🔐 Ganti password
  const handleChangePassword = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!oldPassword || !newPassword || !confirmPassword)
      return toast.error("Isi semua kolom password.");
    if (newPassword !== confirmPassword)
      return toast.error("Password baru tidak sama.");

    try {
      setLoadingPassword(true);
      const res = await api_laravel.post("/api/change-password", {
        current_password: oldPassword,
        new_password: newPassword,
        new_password_confirmation: confirmPassword,
      });
      toast.success(res.data.message || "Password berhasil diubah!");
      setOldPassword("");
      setNewPassword("");
      setConfirmPassword("");
    } catch (err: any) {
      toast.error(err.response?.data?.message || "Gagal mengubah password");
    } finally {
      setLoadingPassword(false);
    }
  };

  return (
    <div className="space-y-6 animate-fade-in">
      <div>
        <h1 className="text-3xl font-bold tracking-tight">Settings</h1>
        <p className="text-muted-foreground">
          Manage your system preferences and configurations.
        </p>
      </div>

      <Tabs defaultValue="general" className="space-y-6">
        <TabsList className="grid w-full grid-cols-3 md:grid-cols-6">
          <TabsTrigger value="general">General</TabsTrigger>
          <TabsTrigger value="profile">Profile</TabsTrigger>
          <TabsTrigger value="security">Security</TabsTrigger>
        </TabsList>

        {/* 🧩 GENERAL SETTINGS */}
        <TabsContent value="general" className="space-y-6">
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center">
                <SettingsIcon className="h-5 w-5 mr-2 text-primary" />
                General Settings
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-6">
              {settings && (
                <>
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                    <div>
                      <Label>Company Name</Label>
                      <Input
                        value={settings.company_name}
                        onChange={(e) =>
                          setSettings({ ...settings, company_name: e.target.value })
                        }
                      />
                    </div>
                    <div>
                      <Label>Time Zone</Label>
                      <Input
                        value={settings.timezone}
                        onChange={(e) =>
                          setSettings({ ...settings, timezone: e.target.value })
                        }
                      />
                    </div>
                    <div>
                      <Label>Date Format</Label>
                      <Input
                        value={settings.date_format}
                        onChange={(e) =>
                          setSettings({ ...settings, date_format: e.target.value })
                        }
                      />
                    </div>
                    <div>
                      <Label>Currency</Label>
                      <Input
                        value={settings.currency}
                        onChange={(e) =>
                          setSettings({ ...settings, currency: e.target.value })
                        }
                      />
                    </div>
                  </div>

                  {/* PETA */}
                  <div>
                    <Label>Location (Click to set)</Label>
                    <div className="h-72 rounded-lg overflow-hidden border mt-2">
                      <MapContainer
                        center={
                          settings.latitude && settings.longitude
                            ? [settings.latitude, settings.longitude]
                            : [-6.2, 106.816666]
                        }
                        zoom={13}
                        style={{ height: "100%", width: "100%" }}
                      >
                        <TileLayer url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png" />
                        <LocationMarker />
                      </MapContainer>
                    </div>
                  </div>

                  <Button
                    onClick={handleSaveSettings}
                    disabled={loadingSettings}
                    className="btn-gradient"
                  >
                    {loadingSettings ? "Saving..." : "Save Changes"}
                  </Button>
                </>
              )}
            </CardContent>
          </Card>
        </TabsContent>

        {/* 👤 PROFILE SETTINGS */}
        <TabsContent value="profile" className="space-y-6">
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center">
                <User className="h-5 w-5 mr-2 text-primary" />
                Profile Settings
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-6">
              {user && (
                <>
                  <div className="flex items-center space-x-6">
                    <Avatar className="h-20 w-20">
                      <AvatarImage src={user.avatar || "/avatar.png"} alt="User" />
                      <AvatarFallback>
                        {user.first_name?.[0]}
                        {user.last_name?.[0]}
                      </AvatarFallback>
                    </Avatar>
                    <div className="space-y-2">
                      <p className="text-lg font-semibold">
                        {user.first_name} {user.last_name}
                      </p>
                      <p className="text-sm text-gray-500">{user.email}</p>
                    </div>
                  </div>

                  <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                    <div>
                      <Label>Phone</Label>
                      <Input value={user.phone || ""} disabled />
                    </div>
                    <div>
                      <Label>Email</Label>
                      <Input value={user.email} disabled />
                    </div>
                  </div>
                </>
              )}
            </CardContent>
          </Card>
        </TabsContent>

        {/* 🔐 SECURITY SETTINGS */}
        <TabsContent value="security" className="space-y-6">
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center">
                <Shield className="h-5 w-5 mr-2 text-primary" />
                Security Settings
              </CardTitle>
            </CardHeader>
            <CardContent>
              <form onSubmit={handleChangePassword} className="space-y-5">
                <div>
                  <Label>Current Password</Label>
                  <Input
                    type="password"
                    value={oldPassword}
                    onChange={(e) => setOldPassword(e.target.value)}
                  />
                </div>
                <div>
                  <Label>New Password</Label>
                  <Input
                    type="password"
                    value={newPassword}
                    onChange={(e) => setNewPassword(e.target.value)}
                  />
                </div>
                <div>
                  <Label>Confirm New Password</Label>
                  <Input
                    type="password"
                    value={confirmPassword}
                    onChange={(e) => setConfirmPassword(e.target.value)}
                  />
                </div>
                <Button
                  type="submit"
                  disabled={loadingPassword}
                  className="btn-gradient w-full"
                >
                  {loadingPassword ? "Saving..." : "Change Password"}
                </Button>
              </form>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  );
}
