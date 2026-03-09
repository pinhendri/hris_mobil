// app/(dashboard)/master/CompanyAassign.tsx
"use client";

import { useEffect, useState, FormEvent } from "react";
import api_laravel from "@/lib/utils";

interface User {
  id: number;
  name: string;
  email: string;
  role?: string;
  companies: Company[];
}

interface Company {
  id: number;
  c_code: string;
  company_name: string;
}

export default function CompanyAssignPage() {
  const [users, setUsers] = useState<User[]>([]);
  const [allCompanies, setAllCompanies] = useState<Company[]>([]);
  const [selectedUser, setSelectedUser] = useState<User | null>(null);
  const [selectedCompanyIds, setSelectedCompanyIds] = useState<number[]>([]);
  const [loading, setLoading] = useState<boolean>(false);
  const [saving, setSaving] = useState<boolean>(false);
  const [message, setMessage] = useState<{ text: string; type: 'success' | 'error' }>({ text: "", type: 'success' });
  const [search, setSearch] = useState<string>("");
  const [currentPage, setCurrentPage] = useState<number>(1);
  const [totalPages, setTotalPages] = useState<number>(1);
  const [showAssignmentModal, setShowAssignmentModal] = useState<boolean>(false);

  // Ambil data users dengan companies mereka
  const fetchUsers = async (page = 1) => {
    try {
      setLoading(true);
      const res = await api_laravel.get(`/api/company-assignments?page=${page}&search=${search}`);
      
      if (res.data.success) {
        setUsers(res.data.data.users.data);
        setAllCompanies(res.data.data.all_companies || []);
        setCurrentPage(res.data.data.users.current_page);
        setTotalPages(res.data.data.users.last_page);
      } else {
        showMessage("Gagal mengambil data users", 'error');
      }
    } catch (error: any) {
      console.error("Error fetch users:", error);
      showMessage(error.response?.data?.message || "Terjadi kesalahan", 'error');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchUsers();
  }, []);

  const showMessage = (text: string, type: 'success' | 'error') => {
    setMessage({ text, type });
    setTimeout(() => setMessage({ text: "", type: 'success' }), 5000);
  };

  const handleOpenAssignment = (user: User) => {
    setSelectedUser(user);
    setSelectedCompanyIds(user.companies.map(company => company.id));
    setShowAssignmentModal(true);
  };

  const handleCompanyToggle = (companyId: number) => {
    setSelectedCompanyIds(prev => {
      if (prev.includes(companyId)) {
        return prev.filter(id => id !== companyId);
      } else {
        return [...prev, companyId];
      }
    });
  };

  const handleSelectAll = () => {
    if (selectedCompanyIds.length === allCompanies.length) {
      setSelectedCompanyIds([]);
    } else {
      setSelectedCompanyIds(allCompanies.map(company => company.id));
    }
  };

  const handleSaveAssignments = async () => {
    if (!selectedUser) return;

    setSaving(true);
    try {
      const res = await api_laravel.put(
        `/api/company-assignments/user/${selectedUser.id}`,
        { company_ids: selectedCompanyIds }
      );

      if (res.data.success) {
        showMessage("Assignments berhasil disimpan", 'success');
        
        // Update user data in list
        setUsers(prev => prev.map(user => 
          user.id === selectedUser.id 
            ? { ...user, companies: res.data.data.companies }
            : user
        ));
        
        setShowAssignmentModal(false);
        setSelectedUser(null);
      }
    } catch (error: any) {
      console.error("Error save assignments:", error);
      
      if (error.response?.data?.errors) {
        const errors = Object.values(error.response.data.errors).flat();
        showMessage(errors.join(', ') || "Gagal menyimpan assignments", 'error');
      } else {
        showMessage(error.response?.data?.message || "Gagal menyimpan assignments", 'error');
      }
    } finally {
      setSaving(false);
    }
  };

  const handleSearch = (e: FormEvent) => {
    e.preventDefault();
    fetchUsers(1);
  };

  // PERBAIKAN: Fungsi untuk handle pagination
  const handlePageChange = (page: number) => {
    if (page < 1 || page > totalPages) return;
    fetchUsers(page);
  };

  return (
    <div className="max-w-6xl mx-auto mt-10 p-6 bg-white rounded-2xl shadow-lg">
      <h2 className="text-2xl font-semibold mb-6 text-center">User Group - Company Assignment</h2>

      {message.text && (
        <div className={`mb-4 p-3 rounded text-center font-medium ${
          message.type === 'success' 
            ? 'bg-green-100 text-green-700 border border-green-300' 
            : 'bg-red-100 text-red-700 border border-red-300'
        }`}>
          {message.text}
        </div>
      )}

      {/* Search Form */}
      <form onSubmit={handleSearch} className="mb-6 flex gap-2">
        <input
          type="text"
          placeholder="Cari user..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          className="flex-1 border p-2 rounded focus:outline-none focus:ring-2 focus:ring-blue-500"
        />
        <button
          type="submit"
          disabled={loading}
          className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 disabled:bg-blue-400"
        >
          {loading ? "Mencari..." : "Cari"}
        </button>
        <button
          type="button"
          onClick={() => {
            setSearch("");
            fetchUsers(1);
          }}
          className="px-4 py-2 bg-gray-200 text-gray-700 rounded hover:bg-gray-300"
        >
          Reset
        </button>
      </form>

      {/* Tabel users */}
      <div className="overflow-x-auto">
        <table className="w-full border-collapse text-sm">
          <thead>
            <tr className="bg-gray-100">
              <th className="border px-4 py-2">ID</th>
              <th className="border px-4 py-2">Nama</th>
              <th className="border px-4 py-2">Email</th>
              <th className="border px-4 py-2">Perusahaan yang diakses</th>
              <th className="border px-4 py-2">Aksi</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr>
                <td colSpan={5} className="text-center py-4">
                  <div className="flex justify-center">
                    <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
                  </div>
                </td>
              </tr>
            ) : users.length > 0 ? (
              users.map((user) => (
                <tr key={user.id}>
                  <td className="border px-4 py-2">{user.id}</td>
                  <td className="border px-4 py-2 font-medium">{user.name}</td>
                  <td className="border px-4 py-2">{user.email}</td>
                  <td className="border px-4 py-2">
                    {user.companies.length > 0 ? (
                      <div className="flex flex-wrap gap-1">
                        {user.companies.map(company => (
                          <span 
                            key={company.id} 
                            className="px-2 py-1 bg-blue-100 text-blue-800 text-xs rounded"
                          >
                            {company.c_code}
                          </span>
                        ))}
                      </div>
                    ) : (
                      <span className="text-gray-500 text-sm">Belum ada perusahaan</span>
                    )}
                    <div className="text-xs text-gray-500 mt-1">
                      Total: {user.companies.length} perusahaan
                    </div>
                  </td>
                  <td className="border px-4 py-2">
                    <button
                      onClick={() => handleOpenAssignment(user)}
                      className="px-3 py-1 bg-blue-600 hover:bg-blue-700 text-white rounded text-xs"
                    >
                      Atur Akses
                    </button>
                  </td>
                </tr>
              ))
            ) : (
              <tr>
                <td colSpan={5} className="text-center py-4 text-gray-500">
                  Tidak ada data user
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      {/* Pagination */}
      {totalPages > 1 && (
  <div className="mt-6 flex justify-center items-center gap-4">
    <button
      onClick={() => {
        console.log('Previous clicked, currentPage:', currentPage);
        if (currentPage > 1 && !loading) {
          fetchUsers(currentPage - 1);
        }
      }}
      className={`px-4 py-2 border rounded ${
        currentPage === 1 ? 'opacity-50 cursor-not-allowed' : 'hover:bg-gray-50'
      }`}
    >
      Previous
    </button>
    
    <span className="text-gray-600">
      Page {currentPage} of {totalPages}
    </span>
    
    <button
      onClick={() => {
        console.log('Next clicked, currentPage:', currentPage);
        console.log('totalPages:', totalPages);
        console.log('loading:', loading);
        if (currentPage < totalPages && !loading) {
          fetchUsers(currentPage + 1);
        }
      }}
      className={`px-4 py-2 border rounded ${
        currentPage === totalPages ? 'opacity-50 cursor-not-allowed' : 'hover:bg-gray-50'
      }`}
    >
      Next
    </button>
  </div>
)}

      {/* Assignment Modal */}
      {showAssignmentModal && selectedUser && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-lg shadow-xl max-w-2xl w-full max-h-[90vh] overflow-y-auto">
            <div className="p-6">
              <div className="flex justify-between items-center mb-4">
                <h3 className="text-lg font-medium">
                  Atur Akses Perusahaan untuk {selectedUser.name}
                </h3>
                <button
                  onClick={() => {
                    setShowAssignmentModal(false);
                    setSelectedUser(null);
                  }}
                  className="text-gray-400 hover:text-gray-600"
                >
                  ✕
                </button>
              </div>
              
              <div className="mb-4">
                <p className="text-sm text-gray-600 mb-2">
                  Pilih perusahaan yang dapat diakses oleh user ini:
                </p>
                <div className="flex items-center gap-2 mb-3">
                  <button
                    onClick={handleSelectAll}
                    className="px-3 py-1 text-sm bg-gray-200 hover:bg-gray-300 rounded"
                  >
                    {selectedCompanyIds.length === allCompanies.length 
                      ? "Batal Pilih Semua" 
                      : "Pilih Semua"}
                  </button>
                  <span className="text-sm text-gray-600">
                    Terpilih: {selectedCompanyIds.length} dari {allCompanies.length}
                  </span>
                </div>
                
                <div className="border rounded-lg p-4 max-h-60 overflow-y-auto">
                  {allCompanies.length > 0 ? (
                    <div className="space-y-2">
                      {allCompanies.map(company => (
                        <div key={company.id} className="flex items-center">
                          <input
                            type="checkbox"
                            id={`company-${company.id}`}
                            checked={selectedCompanyIds.includes(company.id)}
                            onChange={() => handleCompanyToggle(company.id)}
                            className="h-4 w-4 text-blue-600 rounded"
                          />
                          <label 
                            htmlFor={`company-${company.id}`}
                            className="ml-2 cursor-pointer flex-1"
                          >
                            <div className="font-medium">{company.company_name}</div>
                            <div className="text-xs text-gray-500">Kode: {company.c_code}</div>
                          </label>
                        </div>
                      ))}
                    </div>
                  ) : (
                    <p className="text-gray-500 text-center py-4">
                      Tidak ada data perusahaan. Tambah perusahaan terlebih dahulu.
                    </p>
                  )}
                </div>
              </div>
              
              <div className="flex justify-end gap-3 pt-4 border-t">
                <button
                  onClick={() => {
                    setShowAssignmentModal(false);
                    setSelectedUser(null);
                  }}
                  className="px-4 py-2 text-gray-700 bg-gray-100 hover:bg-gray-200 rounded"
                  disabled={saving}
                >
                  Batal
                </button>
                <button
                  onClick={handleSaveAssignments}
                  disabled={saving}
                  className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 disabled:bg-blue-400"
                >
                  {saving ? "Menyimpan..." : "Simpan"}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}