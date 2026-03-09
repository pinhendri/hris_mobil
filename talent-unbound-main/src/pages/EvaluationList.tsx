import React, { useEffect, useState } from "react";
import api_laravel from "@/lib/utils";
import { useNavigate } from "react-router-dom";
import Swal from "sweetalert2";

interface Evaluation {
  id: number;
  employee_id: number;
  employee_name: string;
  period: string;
  final_score: number;
  grade: string;
  is_locked: number;
  created_at: string;
  updated_at: string;
}

interface EvaluationDetail {
  id: number;
  evaluation_id: number;
  employee_kpi_id: number;
  master_kpi_detail_id: number;
  goal_name: string;
  category: string;
  target: number;
  weight: number;
  actual: number;
  score: number;
}

export default function EvaluationList() {
  const [evaluations, setEvaluations] = useState<Evaluation[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedPeriod, setSelectedPeriod] = useState("");
  const [searchEmployee, setSearchEmployee] = useState("");
  const navigate = useNavigate();

  /* ================= LOAD EVALUATIONS ================= */
  useEffect(() => {
    loadEvaluations();
  }, []);

  const loadEvaluations = async () => {
    setLoading(true);
    try {
      const res = await api_laravel.get("/api/kpi/evaluation/list");
      console.log("Evaluations data:", res.data);
      const normalized = (res.data.evaluations || []).map((e: any) => ({
  ...e,
  final_score: Number(e.final_score) || 0
}));

setEvaluations(normalized);
    } catch (error) {
      console.error("Error loading evaluations:", error);
      Swal.fire("Error", "Gagal memuat data evaluasi", "error");
    } finally {
      setLoading(false);
    }
  };

  /* ================= FILTER EVALUATIONS ================= */
  const filteredEvaluations = evaluations.filter(evaluation => {
    const matchesPeriod = selectedPeriod 
      ? evaluation.period === selectedPeriod 
      : true;
    
    const matchesEmployee = searchEmployee 
      ? evaluation.employee_name.toLowerCase().includes(searchEmployee.toLowerCase())
      : true;
    
    return matchesPeriod && matchesEmployee;
  });

  /* ================= GET UNIQUE PERIODS ================= */
  const uniquePeriods = Array.from(
    new Set(evaluations.map(e => e.period))
  ).sort().reverse();

  /* ================= VIEW DETAIL ================= */
  const viewDetails = (evaluationId: number) => {
    navigate(`/kpi/kpi-evaluation/${evaluationId}`);
  };

  /* ================= DELETE EVALUATION ================= */
  const deleteEvaluation = async (evaluationId: number, employeeName: string, period: string) => {
    const confirm = await Swal.fire({
      title: "Hapus Evaluasi?",
      html: `Apakah Anda yakin ingin menghapus evaluasi untuk:<br/>
             <strong>${employeeName}</strong><br/>
             Periode: <strong>${period}</strong>`,
      icon: "warning",
      showCancelButton: true,
      confirmButtonText: "Ya, Hapus",
      cancelButtonText: "Batal",
      confirmButtonColor: "#dc2626"
    });

    if (!confirm.isConfirmed) return;

    try {
      const res = await api_laravel.delete(`/api/kpi/evaluation/${evaluationId}`);
      
      if (res.data.success) {
        Swal.fire("Success", "Evaluasi berhasil dihapus", "success");
        loadEvaluations();
      } else {
        Swal.fire("Error", res.data.message || "Gagal menghapus evaluasi", "error");
      }
    } catch (error: any) {
      console.error("Delete error:", error);
      Swal.fire("Error", error.response?.data?.message || "Terjadi kesalahan saat menghapus", "error");
    }
  };

  /* ================= LOCK/UNLOCK EVALUATION ================= */
  const toggleLock = async (evaluationId: number, isLocked: number) => {
    const action = isLocked ? "buka kunci" : "kunci";
    
    const confirm = await Swal.fire({
      title: `${isLocked ? "Buka Kunci" : "Kunci"} Evaluasi?`,
      text: `Evaluasi ini akan di${action}. ${isLocked ? "" : "Setelah dikunci, data tidak dapat diubah."}`,
      icon: "question",
      showCancelButton: true,
      confirmButtonText: `Ya, ${action}`,
      cancelButtonText: "Batal"
    });

    if (!confirm.isConfirmed) return;

    try {
      const res = await api_laravel.post(`/api/kpi/evaluation/${isLocked ? 'unlock' : 'lock'}/${evaluationId}`);
      
      if (res.data.success) {
        Swal.fire("Success", res.data.message, "success");
        loadEvaluations();
      } else {
        Swal.fire("Error", res.data.message || `Gagal ${action} evaluasi`, "error");
      }
    } catch (error: any) {
      console.error("Toggle lock error:", error);
      Swal.fire("Error", error.response?.data?.message || `Terjadi kesalahan saat ${action} evaluasi`, "error");
    }
  };

  /* ================= RENDER ================= */
  return (
    <div className="p-6 bg-white rounded-lg shadow-xl max-w-7xl mx-auto">
      {/* HEADER */}
      <div className="mb-8">
        <div className="flex flex-col lg:flex-row lg:items-center lg:justify-between gap-4 mb-6">
          <div>
            <h1 className="text-2xl font-bold text-gray-800">Daftar Evaluasi KPI</h1>
            <p className="text-gray-600 mt-1">Kelola dan lihat semua evaluasi KPI yang telah disimpan</p>
          </div>
          <button
            onClick={() => navigate("/kpi/kpi-evaluasi")}
            className="bg-gradient-to-r from-blue-600 to-blue-700 hover:from-blue-700 hover:to-blue-800 text-white px-6 py-3 rounded-lg font-semibold flex items-center gap-2"
          >
            <span className="text-lg">➕</span>
            Buat Evaluasi Baru
          </button>
        </div>

        {/* SUMMARY CARDS */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
          <div className="bg-gradient-to-r from-blue-50 to-blue-100 p-4 rounded-xl border border-blue-200">
            <p className="text-sm text-blue-600 font-medium">Total Evaluasi</p>
            <p className="text-3xl font-bold text-blue-700">{evaluations.length}</p>
          </div>
          <div className="bg-gradient-to-r from-green-50 to-green-100 p-4 rounded-xl border border-green-200">
            <p className="text-sm text-green-600 font-medium">Terkunci</p>
            <p className="text-3xl font-bold text-green-700">
              {evaluations.filter(e => e.is_locked === 1).length}
            </p>
          </div>
          <div className="bg-gradient-to-r from-purple-50 to-purple-100 p-4 rounded-xl border border-purple-200">
            <p className="text-sm text-purple-600 font-medium">Draft</p>
            <p className="text-3xl font-bold text-purple-700">
              {evaluations.filter(e => e.is_locked === 0).length}
            </p>
          </div>
          <div className="bg-gradient-to-r from-amber-50 to-amber-100 p-4 rounded-xl border border-amber-200">
            <p className="text-sm text-amber-600 font-medium">Periode Unik</p>
            <p className="text-3xl font-bold text-amber-700">
              {uniquePeriods.length}
            </p>
          </div>
        </div>
      </div>

      {/* FILTER SECTION */}
      <div className="mb-6 p-4 bg-gradient-to-r from-gray-50 to-gray-100 rounded-xl border border-gray-200">
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
          <div>
            <label className="block text-sm font-semibold text-gray-700 mb-2">
              Cari Nama Employee
            </label>
            <input
              type="text"
              className="border-2 border-gray-300 p-3 rounded-lg w-full focus:border-blue-500 focus:ring-2 focus:ring-blue-200 transition"
              placeholder="Masukkan nama employee..."
              value={searchEmployee}
              onChange={(e) => setSearchEmployee(e.target.value)}
            />
          </div>
          
          <div>
            <label className="block text-sm font-semibold text-gray-700 mb-2">
              Filter Periode
            </label>
            <select
              className="border-2 border-gray-300 p-3 rounded-lg w-full focus:border-blue-500 focus:ring-2 focus:ring-blue-200 transition"
              value={selectedPeriod}
              onChange={(e) => setSelectedPeriod(e.target.value)}
            >
              <option value="">Semua Periode</option>
              {uniquePeriods.map((period) => (
                <option key={period} value={period}>
                  {period}
                </option>
              ))}
            </select>
          </div>

          <div className="flex items-end">
            <button
              onClick={() => {
                setSearchEmployee("");
                setSelectedPeriod("");
              }}
              className="w-full bg-gray-600 hover:bg-gray-700 text-white px-4 py-3 rounded-lg font-semibold"
            >
              🔄 Reset Filter
            </button>
          </div>
        </div>
      </div>

      {/* LOADING STATE */}
      {loading && (
        <div className="text-center py-12">
          <div className="inline-block animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
          <p className="mt-4 text-gray-600">Memuat data evaluasi...</p>
        </div>
      )}

      {/* EVALUATIONS TABLE */}
      {!loading && (
        <>
          <div className="mb-4 flex justify-between items-center">
            <p className="text-sm text-gray-600">
              Menampilkan <span className="font-semibold">{filteredEvaluations.length}</span> dari{" "}
              <span className="font-semibold">{evaluations.length}</span> evaluasi
            </p>
            <button
              onClick={loadEvaluations}
              className="text-sm text-blue-600 hover:text-blue-800 font-medium"
            >
              🔄 Refresh Data
            </button>
          </div>

          {filteredEvaluations.length === 0 ? (
            <div className="p-8 bg-gradient-to-r from-gray-50 to-gray-100 rounded-xl text-center border-2 border-dashed border-gray-300">
              <div className="text-5xl mb-4 text-gray-400">📋</div>
              <h3 className="text-xl font-semibold text-gray-700 mb-2">
                Tidak Ada Evaluasi Ditemukan
              </h3>
              <p className="text-gray-600 mb-4">
                {evaluations.length === 0 
                  ? "Belum ada evaluasi KPI yang disimpan."
                  : "Tidak ada evaluasi yang sesuai dengan filter."}
              </p>
              {evaluations.length === 0 && (
                <button
                  onClick={() => navigate("/kpi/evaluation/create")}
                  className="bg-blue-600 hover:bg-blue-700 text-white px-6 py-3 rounded-lg font-semibold"
                >
                  Buat Evaluasi Pertama
                </button>
              )}
            </div>
          ) : (
            <div className="overflow-x-auto rounded-xl border border-gray-200 shadow">
              <table className="w-full">
                <thead className="bg-gradient-to-r from-gray-50 to-gray-100">
                  <tr>
                    <th className="p-4 text-left text-sm font-semibold text-gray-700 border-b">No</th>
                    <th className="p-4 text-left text-sm font-semibold text-gray-700 border-b">Employee</th>
                    <th className="p-4 text-left text-sm font-semibold text-gray-700 border-b">Periode</th>
                    <th className="p-4 text-left text-sm font-semibold text-gray-700 border-b">Final Score</th>
                    <th className="p-4 text-left text-sm font-semibold text-gray-700 border-b">Grade</th>
                    <th className="p-4 text-left text-sm font-semibold text-gray-700 border-b">Status</th>
                    <th className="p-4 text-left text-sm font-semibold text-gray-700 border-b">Tanggal</th>
                    <th className="p-4 text-left text-sm font-semibold text-gray-700 border-b">Aksi</th>
                  </tr>
                </thead>
                <tbody>
                  {filteredEvaluations.map((evaluation, index) => (
                    <tr 
                      key={evaluation.id}
                      className="hover:bg-gray-50 border-b border-gray-100"
                    >
                      <td className="p-4">
                        <div className="w-8 h-8 flex items-center justify-center bg-gray-100 text-gray-700 rounded-full text-sm font-medium">
                          {index + 1}
                        </div>
                      </td>
                      <td className="p-4">
                        <p className="font-medium text-gray-800">{evaluation.employee_name}</p>
                        <p className="text-xs text-gray-500">ID: {evaluation.employee_id}</p>
                      </td>
                      <td className="p-4">
                        <span className="px-3 py-1 bg-blue-100 text-blue-800 rounded-full text-sm font-medium">
                          {evaluation.period}
                        </span>
                      </td>
                      <td className="p-4">
                        <div className="text-center">
                          <p className="text-2xl font-bold text-gray-800">{evaluation.final_score.toFixed(2)}</p>
                          <p className="text-xs text-gray-500">Score</p>
                        </div>
                      </td>
                      <td className="p-4">
                        <span className={`px-3 py-2 rounded-lg text-sm font-bold inline-block min-w-[60px] text-center ${
                          evaluation.grade === 'A' 
                            ? 'bg-green-100 text-green-800' 
                            : evaluation.grade === 'B' 
                            ? 'bg-blue-100 text-blue-800' 
                            : 'bg-red-100 text-red-800'
                        }`}>
                          {evaluation.grade}
                        </span>
                      </td>
                      <td className="p-4">
                        <span className={`px-3 py-2 rounded-lg text-sm font-medium inline-block ${
                          evaluation.is_locked === 1 
                            ? 'bg-red-100 text-red-800' 
                            : 'bg-green-100 text-green-800'
                        }`}>
                          {evaluation.is_locked === 1 ? (
                            <span className="flex items-center gap-1">
                              <span>🔒</span> Terkunci
                            </span>
                          ) : (
                            <span className="flex items-center gap-1">
                              <span>✏️</span> Draft
                            </span>
                          )}
                        </span>
                      </td>
                      <td className="p-4">
                        <p className="text-sm text-gray-700">
                          {new Date(evaluation.created_at).toLocaleDateString('id-ID', {
                            day: 'numeric',
                            month: 'short',
                            year: 'numeric'
                          })}
                        </p>
                        <p className="text-xs text-gray-500">
                          {new Date(evaluation.created_at).toLocaleTimeString('id-ID', {
                            hour: '2-digit',
                            minute: '2-digit'
                          })}
                        </p>
                      </td>
                      <td className="p-4">
                        <div className="flex flex-col gap-2">
                          <button
                            onClick={() => viewDetails(evaluation.id)}
                            className="bg-blue-600 hover:bg-blue-700 text-white px-3 py-2 rounded text-sm font-medium"
                          >
                            👁️ Lihat Detail
                          </button>
                          
                          <div className="flex gap-2">
                            <button
                              onClick={() => toggleLock(evaluation.id, evaluation.is_locked)}
                              className={`flex-1 px-3 py-2 rounded text-sm font-medium ${
                                evaluation.is_locked === 1
                                  ? 'bg-green-600 hover:bg-green-700 text-white'
                                  : 'bg-yellow-600 hover:bg-yellow-700 text-white'
                              }`}
                            >
                              {evaluation.is_locked === 1 ? '🔓 Buka' : '🔒 Kunci'}
                            </button>
                            
                            {evaluation.is_locked === 0 && (
                              <button
                                onClick={() => deleteEvaluation(evaluation.id, evaluation.employee_name, evaluation.period)}
                                className="flex-1 bg-red-600 hover:bg-red-700 text-white px-3 py-2 rounded text-sm font-medium"
                              >
                                🗑️ Hapus
                              </button>
                            )}
                          </div>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}

          {/* PAGINATION (optional) */}
          {filteredEvaluations.length > 10 && (
            <div className="mt-6 flex justify-center">
              <nav className="flex items-center gap-2">
                <button className="px-4 py-2 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300">
                  ← Previous
                </button>
                <span className="px-4 py-2 bg-blue-600 text-white rounded-lg">1</span>
                <button className="px-4 py-2 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300">
                  2
                </button>
                <button className="px-4 py-2 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300">
                  3
                </button>
                <button className="px-4 py-2 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300">
                  Next →
                </button>
              </nav>
            </div>
          )}
        </>
      )}

      {/* STATISTICS SECTION */}
      {!loading && evaluations.length > 0 && (
        <div className="mt-8 p-6 bg-gradient-to-r from-gray-50 to-gray-100 rounded-xl border border-gray-200">
          <h3 className="text-lg font-semibold text-gray-800 mb-4">📈 Statistik Evaluasi</h3>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div className="bg-white p-4 rounded-lg border border-gray-200">
              <p className="text-sm text-gray-600 mb-2">Rata-rata Score</p>
              <p className="text-2xl font-bold text-gray-800">
                {(evaluations.reduce((sum, e) => sum + e.final_score, 0) / evaluations.length).toFixed(2)}
              </p>
            </div>
            <div className="bg-white p-4 rounded-lg border border-gray-200">
              <p className="text-sm text-gray-600 mb-2">Periode Terbaru</p>
              <p className="text-2xl font-bold text-gray-800">
                {uniquePeriods[0] || 'N/A'}
              </p>
            </div>
            <div className="bg-white p-4 rounded-lg border border-gray-200">
              <p className="text-sm text-gray-600 mb-2">Total Employee</p>
              <p className="text-2xl font-bold text-gray-800">
                {new Set(evaluations.map(e => e.employee_id)).size}
              </p>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}