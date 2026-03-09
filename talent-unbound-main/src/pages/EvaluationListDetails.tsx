import React, { useEffect, useState, useRef } from "react";
import { useParams, useNavigate, useLocation } from "react-router-dom";
import api_laravel from "@/lib/utils";
import Swal from "sweetalert2";

interface EvaluationDetail {
  id: number;
  employee_id: number;
  employee_name: string;
  period: string;
  target: number;
  weight: number;
  actual: number;
  score: number;
  final_score: number;
  grade: string;
  is_locked: number;
  created_at: string;
  updated_at: string;
}

export default function EvaluationDetail() {
  const params = useParams();
  const navigate = useNavigate();
  const location = useLocation();
  
  // Debug: Lihat semua params dan location
  console.log("🔍 useParams():", params);
  console.log("📍 useLocation():", location);
  console.log("📌 Pathname:", location.pathname);
  
  const { id } = useParams<{ id: string }>();
  const [evaluation, setEvaluation] = useState<EvaluationDetail | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  
  // Tambahkan ref untuk debugging
  const renderCount = useRef(0);

  /* ================= LOAD EVALUATION DETAIL ================= */
  useEffect(() => {
    renderCount.current++;
    console.log(`🔄 useEffect triggered. ID: ${id}, Render count: ${renderCount.current}`);
    
    // Coba ekstrak ID dari URL jika useParams tidak bekerja
    const extractIdFromPath = () => {
      const pathParts = location.pathname.split('/');
      console.log("🔗 Path parts:", pathParts);
      
      // Cari bagian yang berisi angka (ID)
      for (let i = pathParts.length - 1; i >= 0; i--) {
        const part = pathParts[i];
        if (part && !isNaN(Number(part)) && part !== '') {
          console.log("🎯 Extracted ID from path:", part);
          return part;
        }
      }
      return null;
    };
    
    const effectiveId = id || extractIdFromPath();
    console.log("🎯 Effective ID to use:", effectiveId);
    
    if (effectiveId) {
      loadEvaluationDetail(effectiveId);
    } else {
      console.log("❌ No valid ID found");
      setError("ID evaluasi tidak ditemukan di URL");
      setLoading(false);
    }
  }, [id, location.pathname]);

  const loadEvaluationDetail = async (evaluationId: string) => {
    console.log(`🚀 loadEvaluationDetail called for ID: ${evaluationId}`);
    
    setLoading(true);
    setError(null);
    
    try {
      // Gunakan endpoint yang sudah ada
      const response = await api_laravel.get(`/api/kpi/evaluation/${evaluationId}`);
      console.log("📦 API Response:", response.data);
      
      if (response.data?.success) {
        // Set evaluation data
        console.log("✅ Setting evaluation data:", response.data.evaluation);
        setEvaluation(response.data.evaluation);
      } else {
        console.log("❌ API returned false success");
        const errorMsg = response.data?.message || "Data evaluasi tidak ditemukan";
        setError(errorMsg);
        Swal.fire("Error", errorMsg, "error");
      }
      
    } catch (error: any) {
      console.error("❌ Error loading evaluation detail:", error);
      
      const errorMessage = error.response?.data?.message || 
                          error.message || 
                          "Gagal memuat detail evaluasi";
      setError(errorMessage);
      Swal.fire("Error", errorMessage, "error");
    } finally {
      console.log("🏁 Setting loading to false");
      setLoading(false);
    }
  };

  /* ================= PRINT REPORT ================= */
  const printReport = () => {
    window.print();
  };

  /* ================= EXPORT TO PDF ================= */
  const exportToPDF = () => {
    Swal.fire("Info", "Fitur ekspor PDF akan segera tersedia", "info");
  };

  /* ================= GO BACK ================= */
  const goBack = () => {
    navigate("/kpi/kpi-evaluation-list");
  };

  /* ================= REFRESH ================= */
  const refreshData = () => {
    console.log("🔄 Refresh data clicked");
    const effectiveId = id || extractIdFromPath();
    if (effectiveId) {
      loadEvaluationDetail(effectiveId);
    }
  };

  /* ================= HELPER: Extract ID from path ================= */
  const extractIdFromPath = () => {
    const pathParts = location.pathname.split('/');
    for (let i = pathParts.length - 1; i >= 0; i--) {
      const part = pathParts[i];
      if (part && !isNaN(Number(part)) && part !== '') {
        return part;
      }
    }
    return null;
  };

  /* ================= DEBUG LOG ================= */
  console.log(`🔍 Component render #${renderCount.current}:`, {
    id,
    loading,
    error,
    evaluation: evaluation ? `✅ Loaded (ID: ${evaluation.id})` : '❌ Not loaded',
    params: params,
    pathname: location.pathname
  });

  /* ================= RENDER LOADING ================= */
  if (loading) {
    console.log("🔄 Rendering loading state");
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <div className="inline-block animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
          <p className="mt-4 text-gray-600">Memuat detail evaluasi...</p>
          <p className="text-sm text-gray-500">ID dari URL: {id || extractIdFromPath() || 'tidak ditemukan'}</p>
          <p className="text-xs text-gray-400 mt-2">Render count: {renderCount.current}</p>
          <div className="mt-4 text-left text-xs bg-gray-100 p-2 rounded">
            <p>Debug info:</p>
            <p>Pathname: {location.pathname}</p>
            <p>Params: {JSON.stringify(params)}</p>
          </div>
        </div>
      </div>
    );
  }

  /* ================= RENDER ERROR ================= */
  if (error) {
    console.log("❌ Rendering error state:", error);
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center max-w-md">
          <div className="text-5xl mb-4 text-red-400">⚠️</div>
          <h3 className="text-xl font-semibold text-gray-700 mb-2">
            Terjadi Kesalahan
          </h3>
          <p className="text-gray-600 mb-4">{error}</p>
          <div className="mb-4 p-3 bg-yellow-50 border border-yellow-200 rounded text-sm text-yellow-800">
            <p className="font-semibold">Debug Info:</p>
            <p>URL Path: {location.pathname}</p>
            <p>Extracted ID: {extractIdFromPath() || 'tidak ditemukan'}</p>
          </div>
          <div className="flex gap-3 justify-center">
            <button
              onClick={goBack}
              className="bg-blue-600 hover:bg-blue-700 text-white px-6 py-3 rounded-lg font-semibold"
            >
              Kembali ke Daftar
            </button>
            <button
              onClick={refreshData}
              className="bg-green-600 hover:bg-green-700 text-white px-6 py-3 rounded-lg font-semibold"
            >
              🔄 Refresh
            </button>
          </div>
        </div>
      </div>
    );
  }

  /* ================= RENDER NOT FOUND ================= */
  if (!evaluation) {
    console.log("❌ Rendering not found state");
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <div className="text-5xl mb-4 text-gray-400">❌</div>
          <h3 className="text-xl font-semibold text-gray-700 mb-2">
            Evaluasi Tidak Ditemukan
          </h3>
          <p className="text-gray-600 mb-4">
            Evaluasi dengan ID <strong>{id || extractIdFromPath() || 'N/A'}</strong> tidak ditemukan.
          </p>
          <div className="mb-4 p-3 bg-gray-100 rounded text-sm">
            <p>Current URL: {window.location.href}</p>
            <p>Pathname: {location.pathname}</p>
          </div>
          <button
            onClick={goBack}
            className="bg-blue-600 hover:bg-blue-700 text-white px-6 py-3 rounded-lg font-semibold"
          >
            ← Kembali ke Daftar
          </button>
        </div>
      </div>
    );
  }

  /* ================= CALCULATE PERCENTAGE ================= */
  const calculatePercentage = () => {
    if (!evaluation || evaluation.target <= 0) return 0;
    return (evaluation.actual / evaluation.target) * 100;
  };

  const percentage = calculatePercentage();

  console.log("✅ Rendering main content with evaluation data:", evaluation);

  /* ================= RENDER MAIN CONTENT ================= */
  return (
    <div className="p-6 bg-white rounded-lg shadow-xl max-w-4xl mx-auto print:p-0 print:shadow-none">
      {/* DEBUG BAR */}
      <div className="mb-4 p-2 bg-blue-50 border border-blue-200 rounded text-xs text-blue-800 no-print">
        <p>🔍 Debug: Render #{renderCount.current} | Evaluation ID: {evaluation.id}</p>
        <p>URL ID Parameter: {id || 'undefined'} | Extracted ID: {extractIdFromPath()}</p>
      </div>

      {/* HEADER */}
      <div className="mb-8 no-print">
        <div className="flex flex-col lg:flex-row lg:items-center lg:justify-between gap-4 mb-6">
          <div>
            <button
              onClick={goBack}
              className="text-blue-600 hover:text-blue-800 mb-4 flex items-center gap-2"
            >
              ← Kembali ke Daftar
            </button>
            <h1 className="text-2xl font-bold text-gray-800">Detail Evaluasi KPI</h1>
            <p className="text-gray-600 mt-1">
              ID Evaluasi: <span className="font-semibold">#{evaluation.id}</span>
            </p>
          </div>
          <div className="flex gap-3">
            <button
              onClick={printReport}
              className="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg font-semibold flex items-center gap-2"
            >
              🖨️ Cetak Laporan
            </button>
            <button
              onClick={exportToPDF}
              className="bg-green-600 hover:bg-green-700 text-white px-4 py-2 rounded-lg font-semibold flex items-center gap-2"
            >
              📥 Export PDF
            </button>
            <button
              onClick={refreshData}
              className="bg-gray-600 hover:bg-gray-700 text-white px=4 py-2 rounded-lg font-semibold flex items-center gap-2"
            >
              🔄 Refresh
            </button>
          </div>
        </div>
      </div>

      {/* EVALUATION DETAIL CARD */}
      <div className="mb-8 p-6 bg-gradient-to-r from-blue-50 to-indigo-50 rounded-xl border border-blue-200">
        <h2 className="text-xl font-bold text-gray-800 mb-6">Informasi Evaluasi KPI</h2>
        
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {/* Left Column - Employee Info */}
          <div>
            <div className="space-y-4">
              <div>
                <p className="text-sm text-gray-500">Employee</p>
                <p className="text-lg font-semibold text-gray-800">{evaluation.employee_name}</p>
              </div>
              
              <div>
                <p className="text-sm text-gray-500">Periode</p>
                <p className="text-lg font-semibold text-gray-800">{evaluation.period}</p>
              </div>
              
              <div>
                <p className="text-sm text-gray-500">Tanggal Evaluasi</p>
                <p className="text-lg font-semibold text-gray-800">
                  {new Date(evaluation.created_at).toLocaleDateString('id-ID', {
                    day: 'numeric',
                    month: 'long',
                    year: 'numeric'
                  })}
                </p>
              </div>
              
              <div>
                <p className="text-sm text-gray-500">Status</p>
                <span className={`px-3 py-1 rounded text-sm font-medium ${
                  evaluation.is_locked === 1 
                    ? 'bg-red-100 text-red-800' 
                    : 'bg-green-100 text-green-800'
                }`}>
                  {evaluation.is_locked === 1 ? '🔒 Terkunci' : '✏️ Draft'}
                </span>
              </div>
            </div>
          </div>
          
          {/* Right Column - KPI Scores */}
          <div>
            <div className="grid grid-cols-2 gap-4">
              {/* Target */}
              <div className="bg-white p-4 rounded-lg border border-gray-200">
                <p className="text-sm text-gray-600 mb-1">Target</p>
                <p className="text-2xl font-bold text-blue-600">
                  {evaluation.target > 0 ? evaluation.target.toFixed(2) : "0.00"}
                </p>
              </div>
              
              {/* Actual */}
              <div className="bg-white p-4 rounded-lg border border-gray-200">
                <p className="text-sm text-gray-600 mb-1">Actual</p>
                <p className="text-2xl font-bold text-green-600">{evaluation.actual.toFixed(2)}</p>
              </div>
              
              {/* Weight */}
              <div className="bg-white p-4 rounded-lg border border-gray-200">
                <p className="text-sm text-gray-600 mb-1">Weight</p>
                <p className="text-2xl font-bold text-purple-600">{evaluation.weight}%</p>
              </div>
              
              {/* Score */}
              <div className="bg-white p-4 rounded-lg border border-gray-200">
                <p className="text-sm text-gray-600 mb-1">Score</p>
                <p className="text-2xl font-bold text-amber-600">{evaluation.score.toFixed(2)}</p>
              </div>
            </div>
            
            {/* Percentage Progress Bar - Simplified */}
            <div className="mt-6">
              <p className="text-sm text-gray-600 mb-2">Pencapaian Target</p>
              {evaluation.target > 0 ? (
                <div className="relative pt-1">
                  <div className="overflow-hidden h-3 text-xs flex rounded bg-gray-200">
                    <div
                      style={{ width: `${Math.min(percentage, 100)}%` }}
                      className={`shadow-none flex flex-col text-center whitespace-nowrap text-white justify-center ${
                        percentage >= 100 ? 'bg-green-500' :
                        percentage >= 75 ? 'bg-blue-500' :
                        percentage >= 50 ? 'bg-yellow-500' : 'bg-red-500'
                      }`}
                    />
                  </div>
                  <div className="flex justify-between text-xs text-gray-600 mt-1">
                    <span>0%</span>
                    <span className="font-medium">{percentage.toFixed(1)}%</span>
                    <span>100%</span>
                  </div>
                </div>
              ) : (
                <p className="text-sm text-gray-500 italic">Target belum ditetapkan</p>
              )}
            </div>
          </div>
        </div>
        
        {/* FINAL SCORE & GRADE */}
        <div className="mt-8 grid grid-cols-1 md:grid-cols-2 gap-6">
          <div className="text-center p-6 bg-gradient-to-r from-blue-100 to-blue-200 rounded-xl border border-blue-300">
            <p className="text-sm text-blue-800 mb-2">Final Score</p>
            <p className="text-5xl font-bold text-blue-900">{evaluation.final_score.toFixed(2)}</p>
            <p className="text-sm text-blue-700 mt-2">Total Nilai Evaluasi</p>
          </div>
          
          <div className="text-center p-6 bg-gradient-to-r from-green-100 to-green-200 rounded-xl border border-green-300">
            <p className="text-sm text-green-800 mb-2">Grade</p>
            <p className={`text-5xl font-bold ${
              evaluation.grade === 'A' ? 'text-green-900' :
              evaluation.grade === 'B' ? 'text-blue-900' :
              'text-red-900'
            }`}>
              {evaluation.grade}
            </p>
            <p className="text-sm text-green-700 mt-2">
              {evaluation.grade === 'A' ? 'Excellent' :
               evaluation.grade === 'B' ? 'Good' : 'Needs Improvement'}
            </p>
          </div>
        </div>
      </div>

      {/* FOOTER ACTIONS */}
      <div className="no-print">
        <div className="flex justify-between items-center pt-6 border-t border-gray-200">
          <button
            onClick={goBack}
            className="text-gray-600 hover:text-gray-800 font-medium"
          >
            ← Kembali ke Daftar
          </button>
          <div className="flex gap-3">
            <button
              onClick={printReport}
              className="bg-blue-600 hover:bg-blue-700 text-white px-6 py-3 rounded-lg font-semibold"
            >
              🖨️ Cetak Laporan
            </button>
            <button
              onClick={refreshData}
              className="bg-gray-600 hover:bg-gray-700 text-white px-6 py-3 rounded-lg font-semibold"
            >
              🔄 Refresh Data
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}