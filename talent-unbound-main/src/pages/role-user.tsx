"use client";

import { useEffect, useState, FormEvent } from "react";
import api_laravel from "@/lib/utils";

interface User {
  id: number;
  name: string;
  email: string;
  roles?: string[];
  permissions?: string[];
}

interface Role {
  id: number;
  name: string;
  permissions?: string[]; // setiap role bisa punya permission
}

export default function AssignRolePage() {
  const [users, setUsers] = useState<User[]>([]);
  const [roles, setRoles] = useState<Role[]>([]);
  const [selectedUser, setSelectedUser] = useState<number | "">("");
  const [selectedRoles, setSelectedRoles] = useState<string[]>([]);
  const [userPermissions, setUserPermissions] = useState<string[]>([]);
  const [message, setMessage] = useState<string>("");
  const [loading, setLoading] = useState<boolean>(false);
  const [fetchingUserData, setFetchingUserData] = useState<boolean>(false);

  // Ambil daftar user + roles + permission info
  useEffect(() => {
    const fetchData = async () => {
      try {
        const res = await api_laravel.get("/api/roles"); 
        if (res.data.success && res.data.data) {
          setUsers(res.data.data.users || []);
          setRoles(res.data.data.roles || []);
        } else {
          setMessage("⚠️ Gagal mengambil data dari server");
        }
      } catch (error: any) {
        console.error(error);
        setMessage(`⚠️ Gagal mengambil data: ${error.response?.data?.message || error.message}`);
      }
    };
    fetchData();
  }, []);

  // Ambil roles & permissions saat user dipilih
  useEffect(() => {
    if (!selectedUser) {
      setSelectedRoles([]);
      setUserPermissions([]);
      return;
    }

    const fetchUserRoles = async () => {
      setFetchingUserData(true);
      try {
        const res = await api_laravel.get(`/api/users/${selectedUser}`);
        if (res.data.success) {
          const userData = res.data.data;
          const userRoles = userData.roles || [];
          const permissionsFromRoles = userData.permissions || [];
          setSelectedRoles(userRoles);
          setUserPermissions(permissionsFromRoles);

          setUsers(prev => prev.map(u => 
            u.id === selectedUser ? { ...u, roles: userRoles, permissions: permissionsFromRoles } : u
          ));
        }
      } catch (error: any) {
        console.error(error);
      } finally {
        setFetchingUserData(false);
      }
    };

    fetchUserRoles();
  }, [selectedUser]);

  // Checkbox handler role
  const handleRoleChange = (roleName: string) => {
    setSelectedRoles(prev => {
      const newRoles = prev.includes(roleName) ? prev.filter(r => r !== roleName) : [...prev, roleName];

      // Update permissions otomatis sesuai role
      const permissionsFromSelectedRoles = roles
        .filter(r => newRoles.includes(r.name))
        .flatMap(r => r.permissions || [])
        .filter((v, i, a) => a.indexOf(v) === i); // unique

      setUserPermissions(permissionsFromSelectedRoles);

      return newRoles;
    });
  };

  const handleAssign = async (e: FormEvent) => {
  e.preventDefault();
  if (!selectedUser) return setMessage("⚠️ Pilih user terlebih dahulu!");

  setLoading(true);
  try {
    const res = await api_laravel.post(`/api/role-management/roles/${selectedUser}/permissions`, {
         user_id: selectedUser, // tambahkan ini
      roles: selectedRoles,
    });
    if (res.data.success) {
      setMessage("✅ Roles berhasil diperbarui!");
      const updatedUser = res.data.data.user;
      setUserPermissions(updatedUser.permissions || []);
      setUsers(prev => prev.map(u => 
        u.id === selectedUser ? { ...u, roles: selectedRoles, permissions: updatedUser.permissions } : u
      ));
    } else {
      setMessage(`❌ ${res.data.message || "Gagal memperbarui data"}`);
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
      <h2 className="text-2xl font-semibold mb-6 text-center">Assign Role ke User</h2>

      {message && (
        <div className={`mb-4 p-3 rounded text-center font-medium ${
          message.includes("✅") ? "bg-green-100 text-green-700 border border-green-300" : "bg-red-100 text-red-700 border border-red-300"
        }`}>{message}</div>
      )}

      <form onSubmit={handleAssign}>
        {/* Select User */}
        <div className="mb-6">
          <label className="block mb-2 text-sm font-medium text-gray-700">Pilih User</label>
          <select
            value={selectedUser}
            onChange={e => setSelectedUser(e.target.value ? Number(e.target.value) : "")}
            className="w-full border p-3 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            disabled={fetchingUserData}
          >
            <option value="">-- Pilih User --</option>
            {users.map(u => <option key={u.id} value={u.id}>{u.name} ({u.email})</option>)}
          </select>
        </div>

        {/* Roles */}
        {selectedUser && (
          <div className="mb-6">
            <label className="block mb-2 text-sm font-medium text-gray-700">
              Roles ({selectedRoles.length} terpilih)
              {fetchingUserData && <span className="text-blue-500 ml-2">Loading...</span>}
            </label>
            <div className="space-y-2 max-h-60 overflow-y-auto p-2 border rounded">
              {roles.map(r => (
                <label key={r.id} className="flex flex-col p-2 border rounded hover:bg-gray-50">
                  <div className="flex items-center gap-3">
                    <input
                      type="checkbox"
                      value={r.name}
                      checked={selectedRoles.includes(r.name)}
                      onChange={() => handleRoleChange(r.name)}
                      className="accent-blue-600 w-4 h-4"
                      disabled={fetchingUserData}
                    />
                    <span className="text-sm font-medium">{r.name}</span>
                  </div>
                  {/* Tampilkan permissions role sebagai info */}
                  {r.permissions && r.permissions.length > 0 && (
                    <div className="text-xs text-gray-500 mt-1 ml-6">
                      Permissions: {r.permissions.join(", ")}
                    </div>
                  )}
                </label>
              ))}
            </div>
          </div>
        )}

        {/* Permissions read-only */}
        {selectedUser && (
          <div className="mb-6 p-4 bg-gray-50 rounded-lg">
            <h4 className="text-sm font-medium text-gray-700 mb-2">Permissions yang dimiliki user (otomatis dari role):</h4>
            <div className="text-sm">{userPermissions.length > 0 ? userPermissions.join(", ") : "Tidak ada permission"}</div>
          </div>
        )}

        <button
          type="submit"
          disabled={loading || !selectedUser}
          className={`w-full py-3 rounded-lg text-white ${loading || !selectedUser ? "bg-blue-400 cursor-not-allowed" : "bg-blue-600 hover:bg-blue-700"}`}
        >
          {loading ? "Menyimpan..." : "Simpan Perubahan"}
        </button>
      </form>
    </div>
  );
}
