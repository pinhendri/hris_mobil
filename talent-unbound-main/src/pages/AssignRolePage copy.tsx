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
}

interface Permission {
  id: number;
  name: string;
}

export default function AssignRolePage() {
  const [users, setUsers] = useState<User[]>([]);
  const [roles, setRoles] = useState<Role[]>([]);
  const [permissions, setPermissions] = useState<Permission[]>([]);
  const [selectedUser, setSelectedUser] = useState<number | "">("");
  const [selectedRoles, setSelectedRoles] = useState<string[]>([]);
  const [selectedPermissions, setSelectedPermissions] = useState<string[]>([]);
  const [message, setMessage] = useState<string>("");
  const [loading, setLoading] = useState<boolean>(false);
  const [userRoles, setUserRoles] = useState<string[]>([]);
  const [userPermissions, setUserPermissions] = useState<string[]>([]);
  const [fetchingUserData, setFetchingUserData] = useState<boolean>(false);

  // 🔹 Ambil daftar user, role, permission
  useEffect(() => {
    const fetchData = async () => {
      try {
        const res = await api_laravel.get("/api/roles");
        console.log("API Response:", res.data);
        
        if (res.data.success && res.data.data) {
          setUsers(res.data.data.users || []);
          setRoles(res.data.data.roles || []);
          setPermissions(res.data.data.permissions || []);
        } else {
          setMessage("⚠️ Gagal mengambil data dari server");
        }
      } catch (error: any) {
        console.error("Gagal fetch data:", error);
        setMessage(`⚠️ Gagal mengambil data: ${error.response?.data?.message || error.message}`);
      }
    };

    fetchData();
  }, []);

  // 🔹 Ambil data user secara real-time ketika user dipilih
  useEffect(() => {
    const fetchUserData = async () => {
      if (!selectedUser) {
        setSelectedRoles([]);
        setSelectedPermissions([]);
        setUserRoles([]);
        setUserPermissions([]);
        return;
      }

      setFetchingUserData(true);
      try {
        // Ambil data user terbaru dari API
        const userResponse = await api_laravel.get(`/api/users/${selectedUser}`);
        console.log("User data from API:", userResponse.data);

        if (userResponse.data.success) {
          const userData = userResponse.data.data || userResponse.data.user;
          const currentRoles = userData?.roles || [];
          const currentPermissions = userData?.permissions || [];

          // Update semua state berdasarkan data terbaru
          setUserRoles(currentRoles);
          setUserPermissions(currentPermissions);
          setSelectedRoles(currentRoles);
          setSelectedPermissions(currentPermissions);

          // Update users list dengan data terbaru
          setUsers(prevUsers => 
            prevUsers.map(user => 
              user.id === selectedUser 
                ? { ...user, roles: currentRoles, permissions: currentPermissions }
                : user
            )
          );

          console.log("Updated selections - Roles:", currentRoles, "Permissions:", currentPermissions);
        }
      } catch (error: any) {
        console.error("Gagal mengambil data user:", error);
        setMessage(`⚠️ Gagal mengambil data user: ${error.response?.data?.message || error.message}`);
        
        // Fallback: gunakan data dari users list jika API gagal
        const user = users.find(u => u.id === selectedUser);
        if (user) {
          const fallbackRoles = user.roles || [];
          const fallbackPermissions = user.permissions || [];
          setUserRoles(fallbackRoles);
          setUserPermissions(fallbackPermissions);
          setSelectedRoles(fallbackRoles);
          setSelectedPermissions(fallbackPermissions);
        }
      } finally {
        setFetchingUserData(false);
      }
    };

    fetchUserData();
  }, [selectedUser]);

  // Checkbox handler role
  const handleRoleChange = (roleName: string) => {
    setSelectedRoles((prev) => {
      const newRoles = prev.includes(roleName)
        ? prev.filter((r) => r !== roleName)
        : [...prev, roleName];
      return newRoles;
    });
  };

  // Checkbox handler permission
  const handlePermissionChange = (permName: string) => {
    setSelectedPermissions((prev) => {
      const newPermissions = prev.includes(permName)
        ? prev.filter((p) => p !== permName)
        : [...prev, permName];
      return newPermissions;
    });
  };

  // 🔹 Submit form
  const handleAssign = async (e: FormEvent) => {
    e.preventDefault();

    if (!selectedUser) {
      setMessage("⚠️ Pilih user terlebih dahulu!");
      return;
    }

    // Validasi perubahan
    const noRoleChange = 
      JSON.stringify([...userRoles].sort()) === JSON.stringify([...selectedRoles].sort());
    const noPermissionChange = 
      JSON.stringify([...userPermissions].sort()) === JSON.stringify([...selectedPermissions].sort());
    
    if (noRoleChange && noPermissionChange) {
      setMessage("ℹ️ Tidak ada perubahan yang perlu disimpan");
      return;
    }

    setLoading(true);
    setMessage("");

    try {
      const response = await api_laravel.post("/api/roles/assign", {
        user_id: selectedUser,
        roles: selectedRoles,
        permissions: selectedPermissions,
      });

      if (response.data.success) {
        setMessage("✅ Roles dan Permissions berhasil diperbarui!");
        
        // Update local state dengan data terbaru
        const updatedUserData = response.data.user || response.data.data?.user;
        
        if (updatedUserData) {
          const updatedRoles = updatedUserData.roles || selectedRoles;
          const updatedPermissions = updatedUserData.permissions || selectedPermissions;
          
          setUserRoles(updatedRoles);
          setUserPermissions(updatedPermissions);
          
          // Juga update di users list
          setUsers(prevUsers => 
            prevUsers.map(user => 
              user.id === selectedUser 
                ? { 
                    ...user, 
                    roles: updatedRoles,
                    permissions: updatedPermissions
                  }
                : user
            )
          );
        }

      } else {
        setMessage(`❌ ${response.data.message || "Gagal memperbarui data"}`);
      }

    } catch (error: any) {
      console.error("Error:", error);
      const errorMessage = error.response?.data?.message || 
                          error.response?.data?.error || 
                          error.message || 
                          "Terjadi kesalahan saat menyimpan";
      setMessage(`❌ ${errorMessage}`);
    } finally {
      setLoading(false);
    }
  };

  // Reset form
  const handleReset = () => {
    setSelectedUser("");
    setSelectedRoles([]);
    setSelectedPermissions([]);
    setUserRoles([]);
    setUserPermissions([]);
    setMessage("");
  };

  // Clear message setelah beberapa detik
  useEffect(() => {
    if (message) {
      const timer = setTimeout(() => {
        setMessage("");
      }, 5000);
      return () => clearTimeout(timer);
    }
  }, [message]);

  return (
    <div className="max-w-4xl mx-auto mt-10 p-6 bg-white rounded-2xl shadow-lg">
      <h2 className="text-2xl font-semibold mb-6 text-center">
        Assign Role & Permission ke User
      </h2>

      {message && (
        <div
          className={`mb-4 p-3 rounded text-center font-medium ${
            message.includes("✅") 
              ? "bg-green-100 text-green-700 border border-green-300" 
              : message.includes("ℹ️")
              ? "bg-blue-100 text-blue-700 border border-blue-300"
              : "bg-red-100 text-red-700 border border-red-300"
          }`}
        >
          {message}
        </div>
      )}

      <form onSubmit={handleAssign}>
        {/* Select User */}
        <div className="mb-6">
          <label className="block mb-2 text-sm font-medium text-gray-700">
            Pilih User
          </label>
          <select
            value={selectedUser}
            onChange={(e) => setSelectedUser(e.target.value ? Number(e.target.value) : "")}
            className="w-full border p-3 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            disabled={fetchingUserData}
          >
            <option value="">-- Pilih User --</option>
            {users.map((user) => (
              <option key={user.id} value={user.id}>
                {user.name} ({user.email})
              </option>
            ))}
          </select>
          {fetchingUserData && (
            <p className="text-sm text-blue-500 mt-2">Memuat data user...</p>
          )}
          {users.length === 0 && (
            <p className="text-sm text-red-500 mt-2">Tidak ada user yang tersedia</p>
          )}
        </div>

        {/* Current Roles & Permissions */}
        {selectedUser && (
          <div className="mb-6 p-4 bg-gray-50 rounded-lg">
            <h3 className="font-semibold mb-2">Current Assignments:</h3>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <h4 className="text-sm font-medium text-gray-600">Roles:</h4>
                <div className="text-sm">
                  {userRoles.length > 0 ? userRoles.join(', ') : 'No roles assigned'}
                </div>
              </div>
              <div>
                <h4 className="text-sm font-medium text-gray-600">Permissions:</h4>
                <div className="text-sm">
                  {userPermissions.length > 0 ? userPermissions.join(', ') : 'No permissions assigned'}
                </div>
              </div>
            </div>
          </div>
        )}

        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          {/* Roles Section */}
          <div className="mb-4">
            <label className="block mb-3 text-sm font-medium text-gray-700">
              Pilih Role ({selectedRoles.length} terpilih)
              {fetchingUserData && <span className="text-blue-500 ml-2">Loading...</span>}
            </label>
            <div className="space-y-2 max-h-60 overflow-y-auto p-2 border rounded">
              {roles.map((role) => (
                <label
                  key={role.id}
                  className="flex items-center gap-3 cursor-pointer p-2 rounded hover:bg-gray-50"
                >
                  <input
                    type="checkbox"
                    value={role.name}
                    checked={selectedRoles.includes(role.name)}
                    onChange={() => handleRoleChange(role.name)}
                    className="accent-blue-600 w-4 h-4"
                    disabled={fetchingUserData}
                  />
                  <span className="text-sm font-medium">{role.name}</span>
                </label>
              ))}
              {roles.length === 0 && (
                <p className="text-sm text-gray-500 text-center py-4">No roles available</p>
              )}
            </div>
          </div>

          {/* Permissions Section */}
          <div className="mb-6">
            <label className="block mb-3 text-sm font-medium text-gray-700">
              Pilih Permission ({selectedPermissions.length} terpilih)
              {fetchingUserData && <span className="text-blue-500 ml-2">Loading...</span>}
            </label>
            <div className="space-y-2 max-h-60 overflow-y-auto p-2 border rounded">
              {permissions.map((perm) => (
                <label
                  key={perm.id}
                  className="flex items-center gap-3 cursor-pointer p-2 rounded hover:bg-gray-50"
                >
                  <input
                    type="checkbox"
                    value={perm.name}
                    checked={selectedPermissions.includes(perm.name)}
                    onChange={() => handlePermissionChange(perm.name)}
                    className="accent-green-600 w-4 h-4"
                    disabled={fetchingUserData}
                  />
                  <span className="text-sm font-medium">{perm.name}</span>
                </label>
              ))}
              {permissions.length === 0 && (
                <p className="text-sm text-gray-500 text-center py-4">No permissions available</p>
              )}
            </div>
          </div>
        </div>

        {/* Action Buttons */}
        <div className="flex gap-3 mt-6">
          <button
            type="button"
            onClick={handleReset}
            className="flex-1 py-3 rounded-lg text-gray-700 bg-gray-200 hover:bg-gray-300 transition-all duration-200"
            disabled={loading || fetchingUserData}
          >
            Reset Form
          </button>
          <button
            type="submit"
            disabled={loading || !selectedUser || fetchingUserData}
            className={`flex-1 py-3 rounded-lg text-white transition-all duration-200 ${
              loading || !selectedUser || fetchingUserData
                ? "bg-blue-400 cursor-not-allowed"
                : "bg-blue-600 hover:bg-blue-700"
            }`}
          >
            {loading ? "Menyimpan..." : "Simpan Perubahan"}
          </button>
        </div>
      </form>

      {/* Selected Info */}
      {selectedUser && (
        <div className="mt-6 p-4 bg-blue-50 rounded-lg">
          <h4 className="font-semibold mb-2 text-blue-800">Selected Assignments:</h4>
          <div className="grid grid-cols-2 gap-4 text-sm">
            <div>
              <span className="font-medium">Roles:</span> {selectedRoles.join(', ') || 'None'}
            </div>
            <div>
              <span className="font-medium">Permissions:</span> {selectedPermissions.join(', ') || 'None'}
            </div>
          </div>
        </div>
      )}

      {/* Debug Info */}
      <div className="mt-6 p-4 bg-gray-100 rounded-lg text-xs">
        <h4 className="font-semibold mb-2">Debug Info:</h4>
        <div>Selected User: {selectedUser || 'None'}</div>
        <div>Selected Roles: {selectedRoles.join(', ') || 'None'}</div>
        <div>Selected Permissions: {selectedPermissions.join(', ') || 'None'}</div>
        <div>Current User Roles: {userRoles.join(', ') || 'None'}</div>
        <div>Current User Permissions: {userPermissions.join(', ') || 'None'}</div>
        <div>Loading: {loading ? 'Yes' : 'No'}</div>
        <div>Fetching User Data: {fetchingUserData ? 'Yes' : 'No'}</div>
      </div>
    </div>
  );
}