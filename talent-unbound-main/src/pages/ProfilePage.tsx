"use client";

import { useEffect, useState } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Separator } from "@/components/ui/separator";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import api_laravel from "@/lib/utils";
import { toast } from "sonner";

interface User {
  id: number;
  name?: string;
  username?: string;
  email?: string;
  phone?: string;
  role?: string;
  avatar?: string;
  profile_picture?: string;
  created_at?: string;
  position?: string;
  department_description?: string;
}

export default function ProfilePage() {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);
  const [editMode, setEditMode] = useState(false);
  const [form, setForm] = useState<Partial<User>>({});
  const [avatarPreview, setAvatarPreview] = useState<string | null>(null);
  const [avatarFile, setAvatarFile] = useState<File | null>(null);
  const [avatarError, setAvatarError] = useState(false);

  const BASE_URL = api_laravel.defaults.baseURL?.replace(/\/$/, "") || "http://localhost:8000";

  // ✅ FIXED: Debug fungsi avatar URL
  // ✅ FIXED: Handle both relative paths and full URLs with duplication
const getCorrectAvatarUrl = (path?: string) => {
  console.group("🔄 Avatar URL Debug");
  console.log("Input path:", path);
  
  if (!path || path === "null" || path === "undefined") {
    console.log("❌ No path provided");
    console.groupEnd();
    setAvatarError(true);
    return `/api/placeholder/80/80?text=${encodeURIComponent(user?.name?.charAt(0) || 'U')}`;
  }
  
  // Jika path sudah merupakan URL lengkap
  if (path.startsWith("http")) {
    console.log("🔗 Already a full URL");
    
    // Perbaiki duplikasi storage/storage/ dalam URL
    if (path.includes('storage/storage/')) {
      const fixedUrl = path.replace('storage/storage/', 'storage/');
      console.log("🛠️ Fixed duplicated storage in URL:", fixedUrl);
      console.groupEnd();
      return fixedUrl;
    }
    
    console.log("✅ URL is correct");
    console.groupEnd();
    return path;
  }

  // Untuk path relatif (jika ada)
  let cleanPath = path.replace(/^\//, '');
  console.log("Cleaned path:", cleanPath);

  // Handle path relatif dengan duplikasi
  if (cleanPath.startsWith('storage/storage/')) {
    cleanPath = cleanPath.replace('storage/storage/', 'storage/');
  }

  const finalUrl = `${BASE_URL}/${cleanPath}`;
  console.log("Final URL:", finalUrl);
  console.groupEnd();

  return finalUrl;
};

  // ✅ Test if image exists
  const testImageUrl = (url: string): Promise<boolean> => {
    return new Promise((resolve) => {
      const img = new Image();
      img.onload = () => resolve(true);
      img.onerror = () => resolve(false);
      img.src = url;
    });
  };

  useEffect(() => {
    const fetchUser = async () => {
      try {
        const res = await api_laravel.get("/api/me/employee");
        const userData = res.data?.data || res.data || {};

        console.log("📦 Full user data:", userData);
        console.log("🖼️ Raw avatar field:", userData.avatar);
        console.log("🖼️ Raw profile_picture field:", userData.profile_picture);

        setUser(userData);
        setForm({
          name: userData.name || "",
          email: userData.email || "",
          phone: userData.phone || "",
          role: userData.position_name || userData.position || "",
          avatar: userData.avatar || "",
          profile_picture: userData.profile_picture || "",
          created_at: userData.created_at || "",
        });

        // Test the avatar URL
        const avatarUrl = getCorrectAvatarUrl(userData.avatar || userData.profile_picture);
        if (avatarUrl && !avatarUrl.includes('placeholder')) {
          const exists = await testImageUrl(avatarUrl);
          console.log("🖼️ Avatar URL test result:", exists ? "✅ EXISTS" : "❌ NOT FOUND", avatarUrl);
          setAvatarError(!exists);
        } else {
          setAvatarError(true);
        }

      } catch (err: any) {
        console.error("❌ Failed to fetch profile:", err);
        toast.error("Failed to fetch user profile");
      } finally {
        setLoading(false);
      }
    };
    fetchUser();
  }, []);

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setForm({ ...form, [e.target.name]: e.target.value });
  };

  const handleAvatarChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      setAvatarFile(file);
      setAvatarPreview(URL.createObjectURL(file));
      setAvatarError(false);
    }
  };

  const handleSave = async () => {
    try {
      const formData = new FormData();
      if (form.name) formData.append("name", form.name);
      if (form.email) formData.append("email", form.email);
      if (form.phone) formData.append("phone", form.phone);
      if (avatarFile) formData.append("avatar", avatarFile);

      const res = await api_laravel.post("/api/me/update", formData, {
        headers: { "Content-Type": "multipart/form-data" },
      });

      toast.success("Profile updated successfully");
      setUser(res.data.data);
      setEditMode(false);
      setAvatarFile(null);
      setAvatarPreview(null);
      setAvatarError(false);
    } catch (err: any) {
      console.error("Failed to update profile:", err);
      toast.error("Failed to update profile");
    }
  };

  if (loading)
    return (
      <div className="flex items-center justify-center h-[60vh] text-muted-foreground">
        Loading profile...
      </div>
    );

  if (!user)
    return (
      <div className="flex items-center justify-center h-[60vh] text-destructive">
        User data not found
      </div>
    );

  // Determine what to show for avatar
  const getAvatarSource = () => {
    if (avatarPreview) return avatarPreview;
    
    const avatarUrl = getCorrectAvatarUrl(user.avatar || user.profile_picture);
    console.log("🎯 Rendering avatar with URL:", avatarUrl);
    
    return avatarUrl;
  };

  return (
    <div className="max-w-3xl mx-auto space-y-8 animate-fadeIn">
      {/* Header */}
      <div className="flex items-center gap-4">
        <Avatar className="h-20 w-20 border">
          <AvatarImage
            src={getAvatarSource()}
            alt={user.name || "User Avatar"}
            onError={(e) => {
              console.error("❌ Avatar image failed to load");
              console.log("Failed URL:", e.currentTarget.src);
              setAvatarError(true);
            }}
          />
          <AvatarFallback className="bg-primary/10 text-primary">
            {user.name?.split(" ").map((n) => n[0]).join("") || "U"}
          </AvatarFallback>
        </Avatar>

        <div>
          <h1 className="text-2xl font-bold">{user.name || user.username}</h1>
          <p className="text-muted-foreground">{user.email}</p>
          <p className="text-sm text-primary mt-1">
            {form.role ? form.role.toUpperCase() : "USER"}
          </p>
          {avatarError && (
            <p className="text-xs text-orange-600 mt-1">
              ⚠️ Avatar image not available
            </p>
          )}
        </div>
      </div>

      {/* Debug Info - Hanya di development */}
      {process.env.NODE_ENV === 'development' && (
        <div className="p-4 bg-gray-100 border border-gray-300 rounded text-xs">
          <h3 className="font-bold mb-2">🛠️ Debug Information:</h3>
          <p><strong>Avatar Field:</strong> {user.avatar || 'NULL'}</p>
          <p><strong>Profile Picture Field:</strong> {user.profile_picture || 'NULL'}</p>
          <p><strong>Generated URL:</strong> {getCorrectAvatarUrl(user.avatar || user.profile_picture)}</p>
          <p><strong>Avatar Error:</strong> {avatarError ? 'YES' : 'NO'}</p>
          <p><strong>BASE_URL:</strong> {BASE_URL}</p>
        </div>
      )}

      <Separator />

      {/* Profile Info */}
      <Card className="shadow-md border border-border/60 bg-card/70 backdrop-blur">
        <CardHeader className="flex justify-between items-center">
          <CardTitle>Profile Information</CardTitle>
          <Button
            variant="outline"
            onClick={() => setEditMode((prev) => !prev)}
          >
            {editMode ? "Cancel" : "Edit"}
          </Button>
        </CardHeader>

        <CardContent className="space-y-4">
          {/* Avatar Upload */}
          <div className="flex flex-col space-y-2">
            <Label>Avatar</Label>

            {avatarPreview ? (
              <img
                src={avatarPreview}
                alt="Preview"
                className="w-24 h-24 rounded-lg object-cover mt-1 border"
              />
            ) : (
              <div className="flex items-center gap-4">
                <img
                  src={getCorrectAvatarUrl(user.avatar || user.profile_picture)}
                  alt="Current Avatar"
                  className="w-24 h-24 rounded-lg object-cover mt-1 border"
                  onError={(e) => {
                    console.error("❌ Large avatar image failed to load");
                    setAvatarError(true);
                    e.currentTarget.style.display = 'none';
                  }}
                />
                {avatarError && (
                  <div className="w-24 h-24 rounded-lg bg-gray-100 border flex items-center justify-center">
                    <span className="text-2xl text-gray-400">
                      {user.name?.charAt(0) || 'U'}
                    </span>
                  </div>
                )}
              </div>
            )}

            {editMode && (
              <div>
                <Input
                  type="file"
                  accept="image/*"
                  onChange={handleAvatarChange}
                />
                <p className="text-xs text-muted-foreground mt-1">
                  Choose a new picture to update your avatar.
                </p>
              </div>
            )}
          </div>

          {/* Basic Info */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <Label htmlFor="name">Full Name</Label>
              <Input
                id="name"
                name="name"
                value={form.name || ""}
                disabled={!editMode}
                onChange={handleChange}
              />
            </div>

            <div>
              <Label htmlFor="email">Email</Label>
              <Input
                id="email"
                name="email"
                value={form.email || ""}
                disabled={!editMode}
                onChange={handleChange}
              />
            </div>
          </div>

          <div>
            <Label htmlFor="phone">Phone</Label>
            <Input
              id="phone"
              name="phone"
              value={form.phone || ""}
              disabled={!editMode}
              onChange={handleChange}
            />
          </div>

          <div>
            <Label>Member Since</Label>
            <p className="text-muted-foreground">
              {new Date(user.created_at || "").toLocaleDateString()}
            </p>
          </div>

          {editMode && (
            <div className="pt-4">
              <Button onClick={handleSave} className="w-full">
                Save Changes
              </Button>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}