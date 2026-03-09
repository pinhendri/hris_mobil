"use client";

import { useEffect, useState, FormEvent } from "react";
import api_laravel from "@/lib/utils";

interface Company {
  id: number;
  c_code: string;
  company_name: string;
  address_1?: string;
  address_2?: string;
  city?: string;
  SIUP?: string;
  phone?: string;
}

export default function MasterCompaniesPage() {
  const [companies, setCompanies] = useState<Company[]>([]);
  const [formData, setFormData] = useState<Company>({
    id: 0,
    c_code: "",
    company_name: "",
    address_1: "",
    address_2: "",
    city: "",
    SIUP: "",
    phone: "",
  });
  const [editingId, setEditingId] = useState<number | null>(null);
  const [loading, setLoading] = useState<boolean>(false);
  const [message, setMessage] = useState<{ text: string; type: 'success' | 'error' }>({ text: "", type: 'success' });
  const [search, setSearch] = useState<string>("");
  const [currentPage, setCurrentPage] = useState<number>(1);
  const [totalPages, setTotalPages] = useState<number>(1);

  // Ambil data companies
  const fetchCompanies = async (page = 1) => {
    try {
      const res = await api_laravel.get(`/api/company-master?page=${page}&search=${search}`);
      if (res.data.success) {
        setCompanies(res.data.data.data);
        setCurrentPage(res.data.data.current_page);
        setTotalPages(res.data.data.last_page);
      } else {
        showMessage("Gagal mengambil data perusahaan", 'error');
      }
    } catch (error: any) {
      console.error("Error fetch companies:", error);
      showMessage(error.response?.data?.message || "Terjadi kesalahan", 'error');
    }
  };

  useEffect(() => {
    fetchCompanies();
  }, []);

  const showMessage = (text: string, type: 'success' | 'error') => {
    setMessage({ text, type });
    setTimeout(() => setMessage({ text: "", type: 'success' }), 5000);
  };

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    
    // Validation
    if (!formData.c_code.trim()) {
      showMessage("Kode perusahaan wajib diisi", 'error');
      return;
    }
    if (!formData.company_name.trim()) {
      showMessage("Nama perusahaan wajib diisi", 'error');
      return;
    }

    setLoading(true);
    try {
      // Gunakan endpoint /save untuk CREATE dan UPDATE
      const res = await api_laravel.post("/api/company-master/save", formData);
      
      if (res.data.success) {
        showMessage(
          editingId ? "Perusahaan berhasil diperbarui" : "Perusahaan berhasil ditambahkan", 
          'success'
        );
        resetForm();
        fetchCompanies(currentPage);
      }
    } catch (error: any) {
      console.error("Error save company:", error);
      
      // Tampilkan error validasi jika ada
      if (error.response?.data?.errors) {
        const errors = Object.values(error.response.data.errors).flat();
        showMessage(errors.join(', ') || "Gagal menyimpan data", 'error');
      } else {
        showMessage(error.response?.data?.message || "Gagal menyimpan data", 'error');
      }
    } finally {
      setLoading(false);
    }
  };

  const handleEdit = (company: Company) => {
    setFormData(company);
    setEditingId(company.id);
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };

  const handleDelete = async (id: number, name: string) => {
    if (!confirm(`Apakah Anda yakin ingin menghapus perusahaan "${name}"?`)) return;

    setLoading(true);
    try {
      const res = await api_laravel.delete(`/api/company-master/${id}`);
      if (res.data.success) {
        showMessage("Perusahaan berhasil dihapus", 'success');
        fetchCompanies(currentPage);
      }
    } catch (error: any) {
      console.error("Error delete company:", error);
      showMessage(error.response?.data?.message || "Gagal menghapus data", 'error');
    } finally {
      setLoading(false);
    }
  };

  const resetForm = () => {
    setFormData({
      id: 0,
      c_code: "",
      company_name: "",
      address_1: "",
      address_2: "",
      city: "",
      SIUP: "",
      phone: "",
    });
    setEditingId(null);
  };

  const handleSearch = (e: FormEvent) => {
    e.preventDefault();
    fetchCompanies(1);
  };

  return (
    <div className="max-w-6xl mx-auto mt-10 p-6 bg-white rounded-2xl shadow-lg">
      <h2 className="text-2xl font-semibold mb-6 text-center">Company Master File</h2>

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
          placeholder="Cari perusahaan..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          className="flex-1 border p-2 rounded focus:outline-none focus:ring-2 focus:ring-blue-500"
        />
        <button
          type="submit"
          className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
        >
          Cari
        </button>
        <button
          type="button"
          onClick={() => {
            setSearch("");
            fetchCompanies(1);
          }}
          className="px-4 py-2 bg-gray-200 text-gray-700 rounded hover:bg-gray-300"
        >
          Reset
        </button>
      </form>

      {/* Form tambah/edit */}
      <form onSubmit={handleSubmit} className="mb-8 p-4 border rounded-lg bg-gray-50">
        <h3 className="text-lg font-medium mb-4">
          {editingId ? "Edit Perusahaan" : "Tambah Perusahaan Baru"}
        </h3>
        
        {/* Hidden input untuk ID (jika edit) */}
        {editingId && (
          <input type="hidden" name="id" value={editingId} />
        )}
        
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label className="block text-sm font-medium mb-1">Kode Perusahaan *</label>
            <input
              type="text"
              name="c_code"
              value={formData.c_code}
              onChange={(e) => setFormData({...formData, c_code: e.target.value})}
              className="w-full border p-2 rounded focus:outline-none focus:ring-2 focus:ring-blue-500"
              placeholder="Contoh: CMP001"
              disabled={loading}
            />
          </div>
          
          <div>
            <label className="block text-sm font-medium mb-1">Nama Perusahaan *</label>
            <input
              type="text"
              name="company_name"
              value={formData.company_name}
              onChange={(e) => setFormData({...formData, company_name: e.target.value})}
              className="w-full border p-2 rounded focus:outline-none focus:ring-2 focus:ring-blue-500"
              placeholder="Nama perusahaan lengkap"
              disabled={loading}
            />
          </div>
          
          <div>
            <label className="block text-sm font-medium mb-1">Alamat 1</label>
            <input
              type="text"
              name="address_1"
              value={formData.address_1}
              onChange={(e) => setFormData({...formData, address_1: e.target.value})}
              className="w-full border p-2 rounded focus:outline-none focus:ring-2 focus:ring-blue-500"
              disabled={loading}
            />
          </div>
          
          <div>
            <label className="block text-sm font-medium mb-1">Alamat 2</label>
            <input
              type="text"
              name="address_2"
              value={formData.address_2}
              onChange={(e) => setFormData({...formData, address_2: e.target.value})}
              className="w-full border p-2 rounded focus:outline-none focus:ring-2 focus:ring-blue-500"
              disabled={loading}
            />
          </div>
          
          <div>
            <label className="block text-sm font-medium mb-1">Kota</label>
            <input
              type="text"
              name="city"
              value={formData.city}
              onChange={(e) => setFormData({...formData, city: e.target.value})}
              className="w-full border p-2 rounded focus:outline-none focus:ring-2 focus:ring-blue-500"
              disabled={loading}
            />
          </div>
          
          <div>
            <label className="block text-sm font-medium mb-1">SIUP</label>
            <input
              type="text"
              name="SIUP"
              value={formData.SIUP}
              onChange={(e) => setFormData({...formData, SIUP: e.target.value})}
              className="w-full border p-2 rounded focus:outline-none focus:ring-2 focus:ring-blue-500"
              disabled={loading}
            />
          </div>
          
          <div>
            <label className="block text-sm font-medium mb-1">Telepon</label>
            <input
              type="text"
              name="phone"
              value={formData.phone}
              onChange={(e) => setFormData({...formData, phone: e.target.value})}
              className="w-full border p-2 rounded focus:outline-none focus:ring-2 focus:ring-blue-500"
              disabled={loading}
            />
          </div>
        </div>
        
        <div className="mt-4 flex gap-2">
          <button
            type="submit"
            disabled={loading}
            className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 disabled:bg-blue-400 disabled:cursor-not-allowed"
          >
            {loading ? "Menyimpan..." : editingId ? "Update" : "Simpan"}
          </button>
          {editingId && (
            <button
              type="button"
              onClick={resetForm}
              className="px-4 py-2 bg-gray-200 text-gray-700 rounded hover:bg-gray-300"
            >
              Batal
            </button>
          )}
        </div>
      </form>

      {/* Tabel companies */}
      <div className="overflow-x-auto">
        <table className="w-full border-collapse text-sm">
          <thead>
            <tr className="bg-gray-100">
              <th className="border px-4 py-2">Kode</th>
              <th className="border px-4 py-2">Nama Perusahaan</th>
              <th className="border px-4 py-2">Kota</th>
              <th className="border px-4 py-2">Telepon</th>
              <th className="border px-4 py-2">SIUP</th>
              <th className="border px-4 py-2">Aksi</th>
            </tr>
          </thead>
          <tbody>
            {companies.length > 0 ? (
              companies.map((company) => (
                <tr key={company.id}>
                  <td className="border px-4 py-2 font-medium">{company.c_code}</td>
                  <td className="border px-4 py-2">{company.company_name}</td>
                  <td className="border px-4 py-2">{company.city || '-'}</td>
                  <td className="border px-4 py-2">{company.phone || '-'}</td>
                  <td className="border px-4 py-2">{company.SIUP || '-'}</td>
                  <td className="border px-4 py-2">
                    <div className="flex gap-2">
                      <button
                        onClick={() => handleEdit(company)}
                        className="px-3 py-1 bg-yellow-400 hover:bg-yellow-500 text-white rounded text-xs"
                        disabled={loading}
                      >
                        Edit
                      </button>
                      <button
                        onClick={() => handleDelete(company.id, company.company_name)}
                        className="px-3 py-1 bg-red-500 hover:bg-red-600 text-white rounded text-xs"
                        disabled={loading}
                      >
                        Hapus
                      </button>
                    </div>
                  </td>
                </tr>
              ))
            ) : (
              <tr>
                <td colSpan={6} className="text-center py-4 text-gray-500">
                  Tidak ada data perusahaan
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      {/* Pagination */}
      {totalPages > 1 && (
        <div className="mt-6 flex justify-center gap-2">
          <button
            onClick={() => fetchCompanies(currentPage - 1)}
            disabled={currentPage === 1 || loading}
            className="px-3 py-1 border rounded disabled:opacity-50 disabled:cursor-not-allowed"
          >
            Previous
          </button>
          
          <span className="px-3 py-1">
            Halaman {currentPage} dari {totalPages}
          </span>
          
          <button
            onClick={() => fetchCompanies(currentPage + 1)}
            disabled={currentPage === totalPages || loading}
            className="px-3 py-1 border rounded disabled:opacity-50 disabled:cursor-not-allowed"
          >
            Next
          </button>
        </div>
      )}
    </div>
  );
}