"use client";

import { useEffect, useState, FormEvent } from "react";
import api_laravel from "@/lib/utils";

interface Role {
  id: number;
  name: string;
}

interface Permission {
  id: number;
  name: string;
}

export default function RolePermissionPage() {
  const [roles, setRoles] = useState<Role[]>([]);
  const [permissions, setPermissions] = useState<Permission[]>([]);
  const [selectedRole, setSelectedRole] = useState<number | "">("");
  const [selectedPermissions, setSelectedPermissions] = useState<string[]>([]);
  const [message, setMessage] = useState<string>("");
  const [loading, setLoading] = useState<boolean>(false);
  const [fetchingPermissions, setFetchingPermissions] = useState<boolean>(false);

  // 🔹 Ambil semua roles
  useEffect(() => {
    const fetchRoles = async () => {
      try {
        const res = await api_laravel.get("/api/role-management/group-roles");
        if (res.data.success) {
          setRoles(res.data.data.map((r: any) => ({ id: r.id, name: r.name })));
        } else {
          setMessage("⚠️ Gagal mengambil data roles");
        }
      } catch (error: any) {
        console.error(error);
        setMessage(`⚠️ ${error.response?.data?.message || error.message}`);
      }
    };
    fetchRoles();
  }, []);

  // 🔹 Ambil semua permissions untuk checkbox
  useEffect(() => {
    const fetchPermissions = async () => {
      try {
        const res = await api_laravel.get("/api/role-management/permissions");
        if (res.data.success) {
          setPermissions(res.data.data); // semua permissions
        } else {
          setMessage("⚠️ Gagal mengambil data permissions");
        }
      } catch (error: any) {
        console.error(error);
        setMessage(`⚠️ ${error.response?.data?.message || error.message}`);
      }
    };
    fetchPermissions();
  }, []);

  // 🔹 Ambil permission yang sudah dipilih untuk role tertentu
  useEffect(() => {
    if (!selectedRole) {
      setSelectedPermissions([]);
      return;
    }

    const fetchRolePermissions = async () => {
      setFetchingPermissions(true);
      try {
        const res = await api_laravel.get(`/api/role-management/roles/${selectedRole}`);
        if (res.data.success) {
          const rolePerms = res.data.data.permissions || [];
          setSelectedPermissions(rolePerms.map((p: any) => p.name));
        }
      } catch (error: any) {
        console.error(error);
        setSelectedPermissions([]);
      } finally {
        setFetchingPermissions(false);
      }
    };

    fetchRolePermissions();
  }, [selectedRole]);

  const handlePermissionChange = (permName: string) => {
    setSelectedPermissions(prev =>
      prev.includes(permName)
        ? prev.filter(p => p !== permName)
        : [...prev, permName]
    );
  };

  const handleSubmit = async (e: FormEvent) => {
  e.preventDefault();
  if (!selectedRole) {
    setMessage("⚠️ Pilih role terlebih dahulu!");
    return;
  }

  setLoading(true);
  try {
    const res = await api_laravel.post(`/api/role-management/roles/${selectedRole}/group`, {
      permissions: selectedPermissions, // kirim array nama permission
    });

    if (res.data.success) {
      setMessage("✅ Permissions berhasil diperbarui!");
    } else {
      setMessage(`❌ ${res.data.message || "Gagal memperbarui permissions"}`);
    }
  } catch (error: any) {
    console.error(error);
    setMessage(`❌ ${error.response?.data?.message || error.message}`);
  } finally {
    setLoading(false);
  }
};


  return (
    <div className="max-w-4xl mx-auto mt-10 p-6 bg-white rounded-2xl shadow-lg">
      <h2 className="text-2xl font-semibold mb-6 text-center">
        Assign Permission ke Role
      </h2>

      {message && (
        <div
          className={`mb-4 p-3 rounded text-center font-medium ${
            message.includes("✅") 
              ? "bg-green-100 text-green-700 border border-green-300" 
              : "bg-red-100 text-red-700 border border-red-300"
          }`}
        >
          {message}
        </div>
      )}

      <form onSubmit={handleSubmit}>
        {/* Select Role */}
        <div className="mb-6">
          <label className="block mb-2 text-sm font-medium text-gray-700">Pilih Role</label>
          <select
            value={selectedRole}
            onChange={(e) => setSelectedRole(e.target.value ? Number(e.target.value) : "")}
            className="w-full border p-3 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            disabled={loading || roles.length === 0}
          >
            <option value="">-- Pilih Role --</option>
            {roles.map(role => (
              <option key={role.id} value={role.id}>
                {role.name}
              </option>
            ))}
          </select>
        </div>

        {/* Permissions */}
        {selectedRole && (
          <div className="mb-6">
            <label className="block mb-3 text-sm font-medium text-gray-700">
              Pilih Permissions ({selectedPermissions.length} terpilih)
            </label>
            <div className="space-y-2 max-h-60 overflow-y-auto p-2 border rounded">
              {permissions.map(perm => (
                <label key={perm.id} className="flex items-center gap-3 cursor-pointer p-2 rounded hover:bg-gray-50">
                  <input
                    type="checkbox"
                    value={perm.name}
                    checked={selectedPermissions.includes(perm.name)}
                    onChange={() => handlePermissionChange(perm.name)}
                    className="accent-green-600 w-4 h-4"
                    disabled={fetchingPermissions}
                  />
                  <span className="text-sm font-medium">{perm.name}</span>
                </label>
              ))}
              {permissions.length === 0 && (
                <p className="text-sm text-gray-500 text-center py-4">No permissions available</p>
              )}
            </div>
          </div>
        )}

        <button
          type="submit"
          disabled={!selectedRole || loading || fetchingPermissions}
          className={`w-full py-3 rounded-lg text-white transition-all duration-200 ${
            !selectedRole || loading || fetchingPermissions
              ? "bg-blue-400 cursor-not-allowed"
              : "bg-blue-600 hover:bg-blue-700"
          }`}
        >
          {loading ? "Menyimpan..." : "Simpan Permissions"}
        </button>
      </form>
    </div>
  );
}
