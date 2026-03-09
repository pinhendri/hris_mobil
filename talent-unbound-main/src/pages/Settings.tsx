"use client";

import { useEffect, useState } from "react";
import { Settings as SettingsIcon, User, Shield } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { toast } from "sonner";
import api_laravel from "@/lib/utils";
import { MapContainer, TileLayer, Marker, useMapEvents } from "react-leaflet";
import "leaflet/dist/leaflet.css";
import L from "leaflet";

// 🗺️ Fix default icon leaflet
delete (L.Icon.Default as any).prototype._getIconUrl;
L.Icon.Default.mergeOptions({
  iconUrl: "https://unpkg.com/leaflet@1.9.3/dist/images/marker-icon.png",
  iconRetinaUrl: "https://unpkg.com/leaflet@1.9.3/dist/images/marker-icon-2x.png",
  shadowUrl: "https://unpkg.com/leaflet@1.9.3/dist/images/marker-shadow.png",
});

interface Setting {
  id: number;
  company_name: string;
  timezone: string;
  date_format: string;
  currency: string;
  latitude: number | null;
  longitude: number | null;
}

interface UserData {
  id: number;
  name: string;
  email: string;
  phone: string;
  position?: string | null;
  position_name?: string | null;
  department_description?: string | null;
  avatar?: string | null;
}

// 🗺️ Komponen terpisah untuk Location Marker
function LocationMarker({ onLocationSelect }: { onLocationSelect: (lat: number, lng: number) => void }) {
  useMapEvents({
    click(e) {
      onLocationSelect(e.latlng.lat, e.latlng.lng);
    },
  });
  return null;
}

export default function Settings() {
  const [settings, setSettings] = useState<Setting | null>(null);
  const [loadingSettings, setLoadingSettings] = useState(false);

  const [user, setUser] = useState<UserData | null>(null);
  const [loadingUser, setLoadingUser] = useState(true);
  const [savingUser, setSavingUser] = useState(false);

  const [avatarPreview, setAvatarPreview] = useState<string | null>(null);
  const [avatarFile, setAvatarFile] = useState<File | null>(null);

  const [oldPassword, setOldPassword] = useState("");
  const [newPassword, setNewPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [loadingPassword, setLoadingPassword] = useState(false);

  // ✅ Fix avatar URL function
  const getCorrectAvatarUrl = (avatarPath?: string | null) => {
    if (!avatarPath) return "/avatar.png";
    
    // Jika path sudah URL lengkap, perbaiki duplikasi storage/storage/
    if (avatarPath.startsWith('http')) {
      return avatarPath.replace('storage/storage/', 'storage/');
    }
    
    // Jika path relatif, perbaiki juga duplikasi
    const cleanPath = avatarPath.replace(/^\//, '');
    const fixedPath = cleanPath.replace('storage/storage/', 'storage/');
    
    const BASE_URL = api_laravel.defaults.baseURL?.replace(/\/$/, "") || "http://localhost:8000";
    return `${BASE_URL}/${fixedPath}`;
  };

  // ✅ Ambil data general settings
  useEffect(() => {
    const fetchSettings = async () => {
      setLoadingSettings(true);
      try {
        const res = await api_laravel.get("/api/settings");
        if (res.data.success && res.data.data) {
          const data = res.data.data;
          setSettings({
            ...data,
            latitude: data.latitude ?? -6.2,
            longitude: data.longitude ?? 106.816666,
          });
        } else {
          toast.error("Data pengaturan tidak ditemukan");
        }
      } catch (err) {
        console.error(err);
        toast.error("Gagal memuat pengaturan sistem");
      } finally {
        setLoadingSettings(false);
      }
    };
    fetchSettings();
  }, []);

  // ✅ Ambil data user (Profile) - DENGAN FIX AVATAR
  useEffect(() => {
    const fetchUser = async () => {
      try {
        const res = await api_laravel.get("/api/me/employee");

        const employee = res.data?.data;

        if (employee) {
          console.log("Raw avatar data:", employee.avatar);
          console.log("Fixed avatar URL:", getCorrectAvatarUrl(employee.avatar));
          
          setUser({
            id: employee.id,
            name: employee.name || "",
            email: employee.email || "",
            phone: employee.phone || "",
            position: employee.position_name || "", // <-- Ganti dengan position_name
            department_description: employee.department_description || "",
            position_name: employee.position_name || "", // <-- Tambahkan ini jika perlu
            avatar: employee.avatar || null,
          });
        } else {
          toast.error("Data karyawan tidak ditemukan");
        }
      } catch (err) {
        console.error(err);
        toast.error("Gagal memuat data pengguna");
      } finally {
        setLoadingUser(false);
      }
    };

    fetchUser();
  }, []);

  // 🗺️ Handle location selection
  const handleLocationSelect = (lat: number, lng: number) => {
    setSettings((prev) =>
      prev ? { ...prev, latitude: lat, longitude: lng } : prev
    );
  };

  // 🧩 Simpan pengaturan umum
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

  // 👤 Simpan Profile (nama, email, phone, avatar)
  const handleSaveProfile = async () => {
    if (!user) return;
    try {
      setSavingUser(true);

      const formData = new FormData();
      formData.append("name", user.name);
      formData.append("email", user.email);
      formData.append("phone", user.phone || "");
      if (avatarFile) formData.append("avatar", avatarFile);

      const res = await api_laravel.post("/api/me/update", formData, {
        headers: { "Content-Type": "multipart/form-data" },
      });

      toast.success(res.data.message || "Profil berhasil diperbarui!");
      if (res.data.data) {
        setUser(res.data.data);
        // Reset preview setelah berhasil update
        setAvatarPreview(null);
        setAvatarFile(null);
      }
    } catch (err) {
      console.error(err);
      toast.error("Gagal menyimpan perubahan profil");
    } finally {
      setSavingUser(false);
    }
  };

  // 🔐 Ubah password
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

  // 🖼️ Preview avatar sebelum upload
  const handleAvatarChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      setAvatarFile(file);
      setAvatarPreview(URL.createObjectURL(file));
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
              {loadingSettings ? (
                <p>Loading...</p>
              ) : settings ? (
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

                  <div>
                    <Label>Location (Click to set)</Label>
                    <div className="h-72 rounded-lg overflow-hidden border mt-2">
                      {settings.latitude && settings.longitude && (
                        <MapContainer
                          center={[settings.latitude, settings.longitude]}
                          zoom={13}
                          style={{ height: "100%", width: "100%" }}
                        >
                          <TileLayer url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png" />
                          <LocationMarker onLocationSelect={handleLocationSelect} />
                          <Marker position={[settings.latitude, settings.longitude]} />
                        </MapContainer>
                      )}
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
              ) : (
                <p className="text-sm text-gray-500">No settings data found.</p>
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
                  <div className="flex flex-col md:flex-row items-center gap-6">
                    <Avatar className="h-24 w-24">
                      <AvatarImage
                        src={avatarPreview || getCorrectAvatarUrl(user.avatar)}
                        alt="User"
                        onError={(e) => {
                          console.error("Avatar failed to load");
                          // Fallback ke placeholder
                          e.currentTarget.src = "/avatar.png";
                        }}
                      />
                      <AvatarFallback className="bg-primary/10 text-primary font-semibold">
                        {user.name?.[0]?.toUpperCase() || "U"}
                      </AvatarFallback>
                    </Avatar>

                    <div className="space-y-2">
                      <Label htmlFor="avatar">Change Avatar</Label>
                      <Input
                        id="avatar"
                        type="file"
                        accept="image/*"
                        onChange={handleAvatarChange}
                      />
                      <p className="text-xs text-muted-foreground">
                        Upload a new profile picture
                      </p>
                    </div>
                  </div>

                  <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                    <div>
                      <Label>Name</Label>
                      <Input
                        value={user.name}
                        onChange={(e) =>
                          setUser({ ...user, name: e.target.value })
                        }
                      />
                    </div>
                    
                    <div>
                      <Label>Email</Label>
                      <Input
                        value={user.email}
                        onChange={(e) =>
                          setUser({ ...user, email: e.target.value })
                        }
                      />
                    </div>
                    <div>
                      <Label>Phone</Label>
                      <Input
                        value={user.phone || ""}
                        onChange={(e) =>
                          setUser({ ...user, phone: e.target.value })
                        }
                      />
                    </div>
                    <div>
                      <Label>Position</Label>
                      <Input
                        value={user.position_name || ""}
                        disabled
                        className="bg-muted"
                      />
                    </div>
                    <div>
                      <Label>Department</Label>
                      <Input
                        value={user.department_description || ""}
                        disabled
                        className="bg-muted"
                      />
                    </div>
                  </div>

                  <Button
                    onClick={handleSaveProfile}
                    disabled={savingUser}
                    className="btn-gradient"
                  >
                    {savingUser ? "Saving..." : "Save Profile"}
                  </Button>
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