"use client";

import { useEffect, useState, FormEvent } from "react";
import api_laravel from "@/lib/utils";

interface Role {
  id: number;
  name: string;
  guard_name: string;
}

export default function MasterRolesPage() {
  const [roles, setRoles] = useState<Role[]>([]);
  const [roleName, setRoleName] = useState<string>("");
  const [editingRole, setEditingRole] = useState<Role | null>(null);
  const [loading, setLoading] = useState<boolean>(false);
  const [message, setMessage] = useState<string>("");

  const GUARD_NAME = "api"; // selalu api

  // Ambil data roles dari API
  const fetchRoles = async () => {
    try {
      const res = await api_laravel.get("/api/role-management/roles");
      if (res.data.success && Array.isArray(res.data.data)) {
        setRoles(res.data.data);
      } else {
        setMessage("⚠️ Gagal mengambil data roles");
      }
    } catch (error: any) {
      console.error("Error fetch roles:", error);
      setMessage(`⚠️ ${error.response?.data?.message || error.message}`);
    }
  };

  useEffect(() => {
    fetchRoles();
  }, []);

  // Tambah atau edit role
  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    if (!roleName.trim()) {
      setMessage("⚠️ Nama role tidak boleh kosong");
      return;
    }

    setLoading(true);
    try {
      let res;
      if (editingRole) {
        // Update role
        res = await api_laravel.put(`/api/role-management/roles/${editingRole.id}`, {
          name: roleName,
          guard_name: GUARD_NAME,
        });
      } else {
        // Create role baru
        res = await api_laravel.post("/api/role-management/roles", {
          name: roleName,
          guard_name: GUARD_NAME,
        });
      }

      if (res.data.success) {
        setMessage(editingRole ? "✅ Role berhasil diperbarui" : "✅ Role berhasil ditambahkan");
        setRoleName("");
        setEditingRole(null);
        fetchRoles();
      } else {
        setMessage(`❌ ${res.data.message || "Gagal menyimpan role"}`);
      }
    } catch (error: any) {
      console.error("Error save role:", error);
      setMessage(`❌ ${error.response?.data?.message || error.message}`);
    } finally {
      setLoading(false);
    }
  };

  // Edit role
  const handleEdit = (role: Role) => {
    setEditingRole(role);
    setRoleName(role.name);
  };

  // Hapus role
  const handleDelete = async (role: Role) => {
    if (!confirm(`Apakah Anda yakin ingin menghapus role "${role.name}"?`)) return;

    setLoading(true);
    try {
      const res = await api_laravel.delete(`/api/role-management/roles/${role.id}`);
      if (res.data.success) {
        setMessage("✅ Role berhasil dihapus");
        fetchRoles();
      } else {
        setMessage(`❌ ${res.data.message || "Gagal menghapus role"}`);
      }
    } catch (error: any) {
      console.error("Error delete role:", error);
      setMessage(`❌ ${error.response?.data?.message || error.message}`);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="max-w-3xl mx-auto mt-10 p-6 bg-white rounded-2xl shadow-lg">
      <h2 className="text-2xl font-semibold mb-6 text-center">Master Roles</h2>

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

      {/* Form tambah / edit role */}
      <form onSubmit={handleSubmit} className="mb-6 flex gap-2 flex-wrap">
        <input
          type="text"
          placeholder="Nama role"
          value={roleName}
          onChange={(e) => setRoleName(e.target.value)}
          className="flex-1 border p-2 rounded focus:outline-none focus:ring-2 focus:ring-blue-500"
          disabled={loading}
        />
        <input
          type="text"
          value={GUARD_NAME}
          disabled
          className="flex-1 border p-2 rounded bg-gray-100 cursor-not-allowed"
        />
        <button
          type="submit"
          className={`px-4 py-2 rounded text-white ${
            loading ? "bg-blue-400 cursor-not-allowed" : "bg-blue-600 hover:bg-blue-700"
          }`}
          disabled={loading}
        >
          {editingRole ? "Update" : "Tambah"}
        </button>
        {editingRole && (
          <button
            type="button"
            onClick={() => {
              setEditingRole(null);
              setRoleName("");
            }}
            className="px-4 py-2 rounded bg-gray-200 hover:bg-gray-300 text-gray-700"
          >
            Batal
          </button>
        )}
      </form>

      {/* Tabel roles */}
      <table className="w-full border-collapse text-sm">
        <thead>
          <tr>
            <th className="border px-2 py-1">ID</th>
            <th className="border px-2 py-1">Role Name</th>
            <th className="border px-2 py-1">Guard Name</th>
            <th className="border px-2 py-1">Actions</th>
          </tr>
        </thead>
        <tbody>
          {roles.length > 0 ? (
            roles.map((role) => (
              <tr key={role.id}>
                <td className="border px-2 py-1">{role.id}</td>
                <td className="border px-2 py-1">{role.name}</td>
                <td className="border px-2 py-1">{role.guard_name}</td>
                <td className="border px-2 py-1 flex gap-2">
                  <button
                    onClick={() => handleEdit(role)}
                    className="px-2 py-1 bg-yellow-400 hover:bg-yellow-500 text-white rounded"
                  >
                    Edit
                  </button>
                  <button
                    onClick={() => handleDelete(role)}
                    className="px-2 py-1 bg-red-500 hover:bg-red-600 text-white rounded"
                  >
                    Delete
                  </button>
                </td>
              </tr>
            ))
          ) : (
            <tr>
              <td colSpan={4} className="text-center py-4 text-gray-500">
                Tidak ada role
              </td>
            </tr>
          )}
        </tbody>
      </table>
    </div>
  );
}
