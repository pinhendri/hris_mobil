import React, { useEffect, useState } from "react";
import api_laravel from "@/lib/utils";
import Swal from "sweetalert2";
import { useNavigate } from "react-router-dom";

export default function MasterKpiList() {
  const [data, setData] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [departments, setDepartments] = useState<any[]>([]);
  const navigate = useNavigate();

  /** =====================
   * Load Master KPI
   ====================== */
  const loadKpi = async () => {
    setLoading(true);
    try {
      const res = await api_laravel.get("/api/kpi/master-kpi");
      console.log("API Response:", res.data); // Debug log
      
      if (res.data.success) {
        // Data sekarang ada di res.data.master_kpis
        setData(res.data.master_kpis || []);
      } else {
        Swal.fire("Error", res.data.message || "Gagal load Master KPI", "error");
        setData([]);
      }
    } catch (error: any) {
      console.error("Error loading Master KPI:", error);
      
      // Handle error jika perlu memilih company
      if (error.response?.status === 400 && error.response?.data?.message === 'Please select a company first') {
        Swal.fire({
          title: "Pilih Company",
          text: "Silakan pilih company terlebih dahulu",
          icon: "info",
          confirmButtonText: "OK"
        }).then(() => {
          // Redirect ke company selector jika ada
          // navigate("/select-company");
        });
      } else {
        Swal.fire("Error", "Gagal load Master KPI", "error");
      }
      setData([]);
    } finally {
      setLoading(false);
    }
  };

  /** =====================
   * Load Departments
   ====================== */
  const loadDepartments = async () => {
    try {
      const res = await api_laravel.get("/api/departments");
      setDepartments(res.data || []);
    } catch (error) {
      console.error("Error loading departments:", error);
    }
  };

  useEffect(() => {
    loadKpi();
    loadDepartments();
  }, []);

  /** =====================
   * Helper: get department name
   ====================== */
  const getDepartmentName = (row: any) => {
    // Jika sudah ada data department di response
    if (row.department && row.department.name) {
      return row.department.name;
    }
    
    // Fallback ke departments state
    const dept = departments.find((d) => d.id === row.department_id);
    return dept ? dept.name : "-";
  };

  /** =====================
   * DELETE Master KPI
   ====================== */
  const handleDelete = async (id: number, masterName: string) => {
    const confirm = await Swal.fire({
      title: "Hapus Master KPI?",
      html: `Apakah Anda yakin ingin menghapus<br/><strong>${masterName}</strong>?`,
      icon: "warning",
      showCancelButton: true,
      confirmButtonText: "Ya, Hapus",
      cancelButtonText: "Batal",
      confirmButtonColor: "#dc2626"
    });

    if (!confirm.isConfirmed) return;

    try {
      const res = await api_laravel.delete(`/api/kpi/master-kpi/${id}`);
      
      if (res.data.success) {
        Swal.fire("Success", "Master KPI berhasil dihapus", "success");
        loadKpi(); // Reload data
      } else {
        Swal.fire("Error", res.data.message || "Gagal menghapus Master KPI", "error");
      }
    } catch (error: any) {
      console.error("Delete error:", error);
      Swal.fire("Error", error.response?.data?.message || "Terjadi kesalahan saat menghapus", "error");
    }
  };

  /** =====================
   * RENDER LOADING
   ====================== */
  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <div className="inline-block animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
          <p className="mt-4 text-gray-600">Memuat data Master KPI...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="p-6 bg-white rounded-lg shadow-xl max-w-7xl mx-auto">
      {/* HEADER */}
      <div className="mb-8">
        <div className="flex flex-col lg:flex-row lg:items-center lg:justify-between gap-4 mb-6">
          <div>
            <h1 className="text-2xl font-bold text-gray-800">Master KPI</h1>
            <p className="text-gray-600 mt-1">Kelola dan lihat semua Master KPI yang telah dibuat</p>
          </div>
          <button
            onClick={() => navigate("/kpi/master-kpi/create")}
            className="bg-gradient-to-r from-blue-600 to-blue-700 hover:from-blue-700 hover:to-blue-800 text-white px-6 py-3 rounded-lg font-semibold flex items-center gap-2"
          >
            <span className="text-lg">➕</span>
            Buat Master KPI Baru
          </button>
        </div>

        {/* SUMMARY */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
          <div className="bg-gradient-to-r from-blue-50 to-blue-100 p-4 rounded-xl border border-blue-200">
            <p className="text-sm text-blue-600 font-medium">Total Master KPI</p>
            <p className="text-3xl font-bold text-blue-700">{data.length}</p>
          </div>
          <div className="bg-gradient-to-r from-green-50 to-green-100 p-4 rounded-xl border border-green-200">
            <p className="text-sm text-green-600 font-medium">Total Details</p>
            <p className="text-3xl font-bold text-green-700">
              {data.reduce((sum, row) => sum + (row.details?.length || 0), 0)}
            </p>
          </div>
          <div className="bg-gradient-to-r from-purple-50 to-purple-100 p-4 rounded-xl border border-purple-200">
            <p className="text-sm text-purple-600 font-medium">Departments</p>
            <p className="text-3xl font-bold text-purple-700">
              {[...new Set(data.map(row => row.department_id))].length}
            </p>
          </div>
          <div className="bg-gradient-to-r from-amber-50 to-amber-100 p-4 rounded-xl border border-amber-200">
            <p className="text-sm text-amber-600 font-medium">Years</p>
            <p className="text-3xl font-bold text-amber-700">
              {[...new Set(data.map(row => row.year))].length}
            </p>
          </div>
        </div>
      </div>

      {/* LOADING & EMPTY STATE */}
      {data.length === 0 ? (
        <div className="p-8 bg-gradient-to-r from-gray-50 to-gray-100 rounded-xl text-center border-2 border-dashed border-gray-300">
          <div className="text-5xl mb-4 text-gray-400">📊</div>
          <h3 className="text-xl font-semibold text-gray-700 mb-2">
            Tidak Ada Master KPI
          </h3>
          <p className="text-gray-600 mb-4">
            Belum ada Master KPI yang dibuat. Mulai buat Master KPI pertama Anda.
          </p>
          <button
            onClick={() => navigate("/kpi/master-kpi/create")}
            className="bg-blue-600 hover:bg-blue-700 text-white px-6 py-3 rounded-lg font-semibold"
          >
            Buat Master KPI Pertama
          </button>
        </div>
      ) : (
        <>
          {/* TABLE */}
          <div className="overflow-x-auto rounded-xl border border-gray-200 shadow">
            <table className="w-full">
              <thead className="bg-gradient-to-r from-gray-50 to-gray-100">
                <tr>
                  <th className="p-4 text-left text-sm font-semibold text-gray-700 border-b">No</th>
                  <th className="p-4 text-left text-sm font-semibold text-gray-700 border-b">Department</th>
                  <th className="p-4 text-left text-sm font-semibold text-gray-700 border-b">Year</th>
                  <th className="p-4 text-left text-sm font-semibold text-gray-700 border-b">Period</th>
                  <th className="p-4 text-left text-sm font-semibold text-gray-700 border-b">Category</th>
                  <th className="p-4 text-left text-sm font-semibold text-gray-700 border-b">Details Count</th>
                  <th className="p-4 text-left text-sm font-semibold text-gray-700 border-b">Actions</th>
                </tr>
              </thead>
              <tbody>
                {data.map((row: any, index: number) => (
                  <tr 
                    key={row.id}
                    className="hover:bg-gray-50 border-b border-gray-100"
                  >
                    <td className="p-4">
                      <div className="w-8 h-8 flex items-center justify-center bg-gray-100 text-gray-700 rounded-full text-sm font-medium">
                        {index + 1}
                      </div>
                    </td>
                    <td className="p-4">
                      <p className="font-medium text-gray-800">{getDepartmentName(row)}</p>
                      {row.department && (
                        <p className="text-xs text-gray-500 mt-1">
                          {row.department.description}
                        </p>
                      )}
                    </td>
                    <td className="p-4">
                      <span className="px-3 py-1 bg-blue-100 text-blue-800 rounded-full text-sm font-medium">
                        {row.year}
                      </span>
                    </td>
                    <td className="p-4">
                      <span className={`px-3 py-1 rounded-full text-sm font-medium ${
                        row.period === 'yearly' ? 'bg-green-100 text-green-800' :
                        row.period === 'quarterly' ? 'bg-yellow-100 text-yellow-800' :
                        row.period === 'monthly' ? 'bg-purple-100 text-purple-800' :
                        'bg-gray-100 text-gray-800'
                      }`}>
                        {row.period || '-'}
                      </span>
                    </td>
                    <td className="p-4">
                      <div className="flex flex-wrap gap-1">
                        {row.details?.length > 0 ? (
                          [...new Set(row.details.map((d: any) => d.category))].map((category: string) => (
                            <span 
                              key={category}
                              className="px-2 py-1 bg-gray-100 text-gray-700 rounded text-xs"
                            >
                              {category}
                            </span>
                          ))
                        ) : (
                          <span className="text-gray-400 text-sm">-</span>
                        )}
                      </div>
                    </td>
                    <td className="p-4">
                      <div className="text-center">
                        <p className="text-xl font-bold text-gray-800">{row.details?.length || 0}</p>
                        <p className="text-xs text-gray-500">items</p>
                      </div>
                    </td>
                    <td className="p-4">
                      <div className="flex flex-col gap-2">
                        <button
                          onClick={() => navigate(`/kpi/master-kpi/edit/${row.id}`)}
                          className="bg-blue-600 hover:bg-blue-700 text-white px-3 py-2 rounded text-sm font-medium"
                        >
                          ✏️ Edit
                        </button>
                        
                        <div className="flex gap-2">
                          <button
                            onClick={() => navigate(`/kpi/master-kpi/assign/${row.id}`)}
                            className="flex-1 bg-green-600 hover:bg-green-700 text-white px-3 py-2 rounded text-sm font-medium"
                          >
                            👥 Assign
                          </button>
                          
                          <button
                            onClick={() => handleDelete(row.id, `Master KPI ${row.year} - ${getDepartmentName(row)}`)}
                            className="flex-1 bg-red-600 hover:bg-red-700 text-white px-3 py-2 rounded text-sm font-medium"
                          >
                            🗑️ Hapus
                          </button>
                        </div>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          {/* FOOTER INFO */}
          <div className="mt-6 flex justify-between items-center">
            <p className="text-sm text-gray-600">
              Menampilkan <span className="font-semibold">{data.length}</span> Master KPI
            </p>
            <button
              onClick={loadKpi}
              className="text-sm text-blue-600 hover:text-blue-800 font-medium"
            >
              🔄 Refresh Data
            </button>
          </div>

          {/* STATISTICS */}
          <div className="mt-8 p-6 bg-gradient-to-r from-gray-50 to-gray-100 rounded-xl border border-gray-200">
            <h3 className="text-lg font-semibold text-gray-800 mb-4">📈 Statistik</h3>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div className="bg-white p-4 rounded-lg border border-gray-200">
                <p className="text-sm text-gray-600 mb-2">Kategori Unik</p>
                <p className="text-2xl font-bold text-gray-800">
                  {[...new Set(data.flatMap(row => 
                    row.details?.map((d: any) => d.category) || []
                  ))].length}
                </p>
              </div>
              <div className="bg-white p-4 rounded-lg border border-gray-200">
                <p className="text-sm text-gray-600 mb-2">Rata-rata Details/Master</p>
                <p className="text-2xl font-bold text-gray-800">
                  {(data.reduce((sum, row) => sum + (row.details?.length || 0), 0) / data.length).toFixed(1)}
                </p>
              </div>
              <div className="bg-white p-4 rounded-lg border border-gray-200">
                <p className="text-sm text-gray-600 mb-2">Tahun Terbaru</p>
                <p className="text-2xl font-bold text-gray-800">
                  {Math.max(...data.map(row => row.year))}
                </p>
              </div>
            </div>
          </div>
        </>
      )}
    </div>
  );
}