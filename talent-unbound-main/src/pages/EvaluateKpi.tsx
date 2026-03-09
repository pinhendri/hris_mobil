import React, { useEffect, useState } from "react";
import api_laravel from "@/lib/utils";
import Swal from "sweetalert2";

interface Employee {
  id: number;
  name: string;
}

interface KPI {
  employee_kpi_id: number;
  master_kpi_detail_id: number;
  goal_name: string;
  category: string;
  target: number | null;
  weight: number | null;
  period?: string;
  year?: number;
}

interface KPIInput {
  target: number | "";
  weight: number | "";
  actual: number | "";
}

interface History {
  period: string;
  final_score: number;
  grade: string;
  is_locked: number;
}

export default function EvaluateKpi() {
  const [employees, setEmployees] = useState<Employee[]>([]);
  const [selectedEmployee, setSelectedEmployee] = useState<number | null>(null);
  const [period, setPeriod] = useState("");
  const [kpis, setKpis] = useState<KPI[]>([]);
  const [history, setHistory] = useState<History[]>([]);
  const [loading, setLoading] = useState(false);
  const [locked, setLocked] = useState(false);
  
  const [kpiInputs, setKpiInputs] = useState<Record<string, KPIInput>>({});

  /* ================= LOAD EMPLOYEES ================= */
  useEffect(() => {
    api_laravel.get("/api/kpi/evaluation/employees").then(res => {
      setEmployees(res.data.employees ?? []);
    });
  }, []);

  /* ================= LOAD KPI DAN HISTORY ================= */
  const loadEmployeeData = async (employeeId: number, period: string) => {
    if (!employeeId || !period) return;

    setLoading(true);
    try {
      // 1. Load KPI data - SIMPLIFIED APPROACH
      const kpiRes = await api_laravel.get(`/api/kpi/evaluation/${employeeId}`);
      console.log("RAW KPI Response:", kpiRes);
      console.log("RAW KPI Data:", kpiRes.data);
      
      // Debug: Log semua keys dari data pertama
      if (kpiRes.data && Array.isArray(kpiRes.data) && kpiRes.data.length > 0) {
        const firstItem = kpiRes.data[0];
        console.log("First item keys:", Object.keys(firstItem));
        console.log("First item values:", firstItem);
      }

      let kpiData: KPI[] = [];
      if (Array.isArray(kpiRes.data)) {
        kpiData = kpiRes.data.map((item: any, index: number) => {
          console.log(`Item ${index}:`, item);
          
          // Coba semua kemungkinan nama field untuk goal_name
          const goalName = item.goal_name || item.goalName || item.goal || 
                          item.name || item.description || `Goal ${index + 1}`;
          
          console.log(`Found goal name for item ${index}:`, goalName);
          
          return {
            employee_kpi_id: item.employee_kpi_id || item.id || 0,
            master_kpi_detail_id: item.master_kpi_detail_id || 0,
            goal_name: goalName,
            category: item.category || "Uncategorized",
            target: item.target !== null && item.target !== undefined && item.target !== "" 
                    ? parseFloat(item.target) 
                    : null,
            weight: item.weight !== null && item.weight !== undefined && item.weight !== "" 
                    ? parseFloat(item.weight) 
                    : null,
            period: item.period,
            year: item.year
          };
        });
      }
      
      console.log("Processed KPI Data:", kpiData);
      setKpis(kpiData);

      // 2. Inisialisasi input values
      const initialInputs: Record<string, KPIInput> = {};
      kpiData.forEach((kpi, index) => {
        const uniqueKey = `kpi-${index}-${kpi.master_kpi_detail_id}-${kpi.employee_kpi_id}`;
        
        initialInputs[uniqueKey] = {
          target: (kpi.target !== null && kpi.target !== 0) ? kpi.target : "",
          weight: (kpi.weight !== null && kpi.weight !== 0) ? kpi.weight : "",
          actual: ""
        };
      });
      setKpiInputs(initialInputs);
      console.log("Initial inputs set:", initialInputs);

      // 3. Load existing evaluations
      try {
        const evalRes = await api_laravel.post("/api/kpi/evaluation/check-existing", {
          employee_id: employeeId,
          period: period
        });
        
        if (evalRes.data.success && evalRes.data.evaluations) {
          const updatedInputs = { ...initialInputs };
          evalRes.data.evaluations.forEach((eval: any) => {
            const matchingKpi = kpiData.find(
              k => k.employee_kpi_id === eval.employee_kpi_id
            );
            
            if (matchingKpi) {
              const index = kpiData.findIndex(k => 
                k.master_kpi_detail_id === matchingKpi.master_kpi_detail_id
              );
              if (index !== -1) {
                const uniqueKey = `kpi-${index}-${matchingKpi.master_kpi_detail_id}-${matchingKpi.employee_kpi_id}`;
                if (updatedInputs[uniqueKey]) {
                  updatedInputs[uniqueKey] = {
                    target: eval.target && eval.target !== 0 ? parseFloat(eval.target) : "",
                    weight: eval.weight && eval.weight !== 0 ? parseFloat(eval.weight) : "",
                    actual: eval.actual && eval.actual !== 0 ? parseFloat(eval.actual) : ""
                  };
                }
              }
            }
          });
          setKpiInputs(updatedInputs);
        }
      } catch (error) {
        console.log("No existing evaluations found");
      }

      // 4. Load history
      const historyRes = await api_laravel.get(`/api/kpi/evaluation/history/${employeeId}`);
      setHistory(historyRes.data || []);
      
      const periodHistory = historyRes.data.find((h: History) => h.period === period);
      setLocked(periodHistory?.is_locked === 1);

    } catch (error: any) {
      console.error("Error loading employee data:", error);
      Swal.fire("Error", error.response?.data?.message || "Gagal memuat data", "error");
      setKpis([]);
      setHistory([]);
      setKpiInputs({});
    } finally {
      setLoading(false);
    }
  };

  /* ================= UPDATE INPUT VALUE ================= */
  const updateInput = (kpiIndex: number, masterKpiDetailId: number, employeeKpiId: number, field: keyof KPIInput, value: string) => {
    const uniqueKey = `kpi-${kpiIndex}-${masterKpiDetailId}-${employeeKpiId}`;
    const numValue = value === "" ? "" : Number(value);
    
    if (numValue !== "" && (isNaN(numValue) || numValue < 0)) return;

    setKpiInputs(prev => ({
      ...prev,
      [uniqueKey]: {
        ...prev[uniqueKey],
        [field]: numValue
      }
    }));
  };

  /* ================= HITUNG SCORE INDIVIDUAL ================= */
  const calculateScore = (kpiInput: KPIInput): number => {
    if (kpiInput.actual === "" || kpiInput.target === "" || kpiInput.weight === "") return 0;
    
    const target = kpiInput.target as number;
    const weight = kpiInput.weight as number;
    const actual = kpiInput.actual as number;
    
    if (target === 0 || weight === 0) return 0;
    
    return (actual / target) * weight;
  };

  /* ================= HITUNG TOTAL SCORE ================= */
  const calculateTotalScore = (): number => {
    return Object.values(kpiInputs).reduce((total, input) => {
      return total + calculateScore(input);
    }, 0);
  };

  /* ================= GET GRADE ================= */
  const getGrade = (score: number): string => {
    if (score >= 90) return "A";
    if (score >= 75) return "B";
    return "C";
  };

  /* ================= VALIDASI INPUT ================= */
  const validateInputs = (): boolean => {
    let totalWeight = 0;
    
    for (const input of Object.values(kpiInputs)) {
      if (input.target === "" || input.weight === "" || input.actual === "") {
        Swal.fire("Warning", "Harap isi semua field (Target, Weight, Actual) untuk setiap KPI", "warning");
        return false;
      }
      
      if (input.weight !== "" && (input.weight < 0 || input.weight > 100)) {
        Swal.fire("Warning", `Weight harus antara 0-100% (saat ini ${input.weight}%)`, "warning");
        return false;
      }
      
      totalWeight += input.weight as number;
    }
    
    if (Math.abs(totalWeight - 100) > 0.01) {
      Swal.fire("Warning", `Total weight semua KPI harus 100% (saat ini ${totalWeight.toFixed(2)}%)`, "warning");
      return false;
    }
    
    return true;
  };

  /* ================= SAVE EVALUATION ================= */
  const saveEvaluation = async () => {
    if (!period) {
      Swal.fire("Warning", "Pilih periode terlebih dahulu", "warning");
      return;
    }
    
    if (!selectedEmployee) {
      Swal.fire("Warning", "Pilih employee terlebih dahulu", "warning");
      return;
    }

    if (kpis.length === 0) {
      Swal.fire("Warning", "Tidak ada KPI untuk dievaluasi", "warning");
      return;
    }

    if (!validateInputs()) {
      return;
    }

    const confirm = await Swal.fire({
      title: "Simpan Evaluasi?",
      text: `Data evaluasi untuk periode ${period} akan disimpan`,
      icon: "question",
      showCancelButton: true,
      confirmButtonText: "Ya, Simpan",
      cancelButtonText: "Batal"
    });

    if (!confirm.isConfirmed) return;

    try {
      const scores = kpis.map((kpi, index) => {
        const uniqueKey = `kpi-${index}-${kpi.master_kpi_detail_id}-${kpi.employee_kpi_id}`;
        const input = kpiInputs[uniqueKey] || { target: "", weight: "", actual: "" };
        
        return {
          employee_kpi_id: kpi.employee_kpi_id,
          master_kpi_detail_id: kpi.master_kpi_detail_id,
          target: input.target as number,
          weight: input.weight as number,
          actual: input.actual as number
        };
      });

      const payload = {
        employee_id: selectedEmployee,
        period: period,
        scores: scores
      };

      const res = await api_laravel.post("/api/kpi/evaluation/save", payload);

      if (res.data.success) {
        Swal.fire("Success", res.data.message, "success");
        await loadEmployeeData(selectedEmployee, period);
      } else {
        Swal.fire("Error", res.data.message || "Gagal menyimpan", "error");
      }
    } catch (err: any) {
      console.error(err);
      Swal.fire(
        "Error", 
        err.response?.data?.message || "Terjadi kesalahan saat menyimpan", 
        "error"
      );
    }
  };

  /* ================= LOCK EVALUATION ================= */
  const lockEvaluation = async () => {
    if (!selectedEmployee || !period) {
      Swal.fire("Warning", "Pilih employee dan periode terlebih dahulu", "warning");
      return;
    }

    if (!validateInputs()) {
      return;
    }

    const confirm = await Swal.fire({
      title: "Kunci Evaluasi?",
      text: "Data tidak bisa diubah setelah dikunci",
      icon: "warning",
      showCancelButton: true,
      confirmButtonText: "Ya, Kunci",
      cancelButtonText: "Batal"
    });

    if (!confirm.isConfirmed) return;

    try {
      const res = await api_laravel.post("/api/kpi/evaluation/lock", {
        employee_id: selectedEmployee,
        period: period,
      });

      if (res.data.success) {
        Swal.fire("Success", res.data.message, "success");
        setLocked(true);
      } else {
        Swal.fire("Error", res.data.message || "Gagal mengunci", "error");
      }
    } catch (err: any) {
      Swal.fire("Error", err.response?.data?.message || "Terjadi kesalahan", "error");
    }
  };

  /* ================= RESET FORM ================= */
  const resetForm = () => {
    const resetInputs: Record<string, KPIInput> = {};
    kpis.forEach((kpi, index) => {
      const uniqueKey = `kpi-${index}-${kpi.master_kpi_detail_id}-${kpi.employee_kpi_id}`;
      resetInputs[uniqueKey] = {
        target: (kpi.target !== null && kpi.target !== 0) ? kpi.target : "",
        weight: (kpi.weight !== null && kpi.weight !== 0) ? kpi.weight : "",
        actual: ""
      };
    });
    setKpiInputs(resetInputs);
  };

  /* ================= EFFECTS ================= */
  useEffect(() => {
    if (selectedEmployee && period) {
      loadEmployeeData(selectedEmployee, period);
    } else {
      setKpis([]);
      setHistory([]);
      setKpiInputs({});
      setLocked(false);
    }
  }, [selectedEmployee, period]);

  const totalScore = calculateTotalScore();
  const grade = getGrade(totalScore);

  /* ================= RENDER ================= */
  return (
    <div className="p-6 bg-white rounded shadow max-w-4xl mx-auto">
      <h2 className="text-xl font-bold mb-6">Evaluasi KPI</h2>

      {/* FILTER SECTION */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-6">
        <div>
          <label className="block text-sm font-medium mb-2">Periode Evaluasi</label>
          <input
            type="month"
            className="border p-2 rounded w-full"
            value={period}
            onChange={e => setPeriod(e.target.value)}
          />
          <p className="text-xs text-gray-500 mt-1">
            Periode: {period || "Belum dipilih"}
          </p>
        </div>
        
        <div>
          <label className="block text-sm font-medium mb-2">Pilih Employee</label>
          <select
            className="border p-2 rounded w-full"
            value={selectedEmployee ?? ""}
            onChange={e => setSelectedEmployee(e.target.value ? Number(e.target.value) : null)}
          >
            <option value="">-- Pilih Employee --</option>
            {employees.map(e => (
              <option key={e.id} value={e.id}>
                {e.name}
              </option>
            ))}
          </select>
        </div>
      </div>

      {/* INFO SECTION */}
      {period && selectedEmployee && (
        <div className="mb-4 p-3 bg-blue-50 border border-blue-200 rounded">
          <p className="font-semibold text-blue-700">
            Evaluasi untuk periode: <span className="font-normal">{period}</span>
          </p>
          <p className="text-sm text-blue-600">
            Employee: {employees.find(e => e.id === selectedEmployee)?.name}
          </p>
        </div>
      )}

      {/* LOCKED WARNING */}
      {locked && (
        <div className="mb-4 p-3 bg-yellow-100 border-l-4 border-yellow-500 text-yellow-700">
          <p className="font-semibold">⚠️ Evaluasi Terkunci</p>
          <p>Evaluasi periode {period} sudah dikunci dan tidak dapat diubah.</p>
        </div>
      )}

      {/* LOADING STATE */}
      {loading && (
        <div className="text-center py-8">
          <div className="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
          <p className="mt-2">Memuat data...</p>
        </div>
      )}

      {/* DEBUG INFO */}
      {!loading && kpis.length > 0 && (
        <div className="mb-4 p-3 bg-red-50 border border-red-200 rounded">
          <p className="font-semibold text-red-700">🔍 DEBUG INFO:</p>
          <p className="text-sm">Total KPI: {kpis.length}</p>
          {kpis.map((kpi, index) => (
            <div key={`debug-${index}`} className="mt-1 p-2 bg-white rounded">
              <p className="text-xs font-mono">
                KPI {index}: goal_name = "{kpi.goal_name}"<br/>
                target = {kpi.target}, weight = {kpi.weight}
              </p>
            </div>
          ))}
        </div>
      )}

      {/* KPI LIST */}
      {!loading && selectedEmployee && kpis.length > 0 && (
        <>
          <div className="mb-6">
            <div className="flex justify-between items-center mb-4">
              <h3 className="font-bold">Form Evaluasi KPI</h3>
              <div className="text-sm text-gray-600">
                Total {kpis.length} KPI ditemukan
              </div>
            </div>
            
            {/* SIMPLE KPI DISPLAY */}
            <div className="mb-4 p-3 bg-green-50 border border-green-200 rounded">
              <p className="font-semibold text-green-700">✅ Daftar KPI yang Ditemukan:</p>
              <div className="mt-2 space-y-2">
                {kpis.map((kpi, index) => (
                  <div key={`simple-${index}`} className="bg-white p-3 rounded border">
                    <div className="flex items-center">
                      <div className="w-8 h-8 flex items-center justify-center bg-blue-100 text-blue-800 rounded-full mr-3">
                        {index + 1}
                      </div>
                      <div>
                        <p className="font-bold text-lg text-gray-800">{kpi.goal_name}</p>
                        <div className="flex gap-4 mt-1">
                          <span className="text-sm text-gray-600">Kategori: {kpi.category}</span>
                          <span className="text-sm text-gray-600">Target: {kpi.target || "0"}</span>
                          <span className="text-sm text-gray-600">Weight: {kpi.weight || "0"}%</span>
                        </div>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </div>
            
            <div className="space-y-4">
              {kpis.map((kpi, index) => {
                const uniqueKey = `kpi-${index}-${kpi.master_kpi_detail_id}-${kpi.employee_kpi_id}`;
                const input = kpiInputs[uniqueKey] || { target: "", weight: "", actual: "" };
                const score = calculateScore(input);
                const progress = input.target !== "" && input.actual !== "" && (input.target as number) > 0 
                  ? Math.min(((input.actual as number) / (input.target as number)) * 100, 100) 
                  : 0;

                return (
                  <div
                    key={`kpi-${index}`}
                    className={`border p-4 rounded-lg shadow-sm ${
                      input.actual !== "" ? 'bg-green-50 border-green-200' : 'bg-white'
                    }`}
                  >
                    {/* SIMPLE HEADER */}
                    <div className="mb-4">
                      <div className="flex items-center justify-between">
                        <div className="flex items-center">
                          <div className="w-10 h-10 flex items-center justify-center bg-blue-600 text-white rounded-full mr-3">
                            {index + 1}
                          </div>
                          <div>
                            <h4 className="text-xl font-bold text-gray-800">
                              {kpi.goal_name || `KPI ${index + 1}`}
                            </h4>
                            <div className="flex gap-3 mt-1">
                              <span className="bg-gray-100 text-gray-800 text-xs px-3 py-1 rounded">
                                {kpi.category}
                              </span>
                              <span className="text-xs text-gray-500">
                                ID: {kpi.master_kpi_detail_id}
                              </span>
                            </div>
                          </div>
                        </div>
                        <div className="text-right">
                          <div className="bg-blue-50 p-3 rounded-lg">
                            <p className="text-2xl font-bold text-blue-600">
                              {score.toFixed(2)}
                            </p>
                            <p className="text-sm text-gray-500">Score</p>
                          </div>
                        </div>
                      </div>
                    </div>

                    {/* INPUT FIELDS - SIMPLIFIED */}
                    <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-4">
                      <div>
                        <label className="block text-sm font-medium mb-2">
                          <span className="text-blue-600">🎯 Target</span>
                          <div className="text-xs text-gray-500 mt-1">
                            Untuk: {kpi.goal_name}
                          </div>
                        </label>
                        <input
                          type="number"
                          min="0"
                          step="0.01"
                          className="border p-3 rounded-lg w-full focus:ring-2 focus:ring-blue-500"
                          value={input.target}
                          onChange={e => updateInput(index, kpi.master_kpi_detail_id, kpi.employee_kpi_id, 'target', e.target.value)}
                          disabled={locked}
                          placeholder="Masukkan target"
                        />
                      </div>

                      <div>
                        <label className="block text-sm font-medium mb-2">
                          <span className="text-green-600">⚖️ Bobot (%)</span>
                          <div className="text-xs font-bold text-gray-700 mt-1 bg-yellow-50 p-2 rounded">
                            Goal: <span className="text-blue-600">{kpi.goal_name}</span>
                          </div>
                        </label>
                        <input
                          type="number"
                          min="0"
                          max="100"
                          step="0.01"
                          className="border p-3 rounded-lg w-full focus:ring-2 focus:ring-green-500"
                          value={input.weight}
                          onChange={e => updateInput(index, kpi.master_kpi_detail_id, kpi.employee_kpi_id, 'weight', e.target.value)}
                          disabled={locked}
                          placeholder="0-100%"
                        />
                        <div className="mt-2 p-2 bg-green-50 border border-green-200 rounded">
                          <p className="text-xs">
                            <span className="font-bold">📝 Goal Name:</span> {kpi.goal_name}
                          </p>
                        </div>
                      </div>

                      <div>
                        <label className="block text-sm font-medium mb-2">
                          <span className="text-purple-600">📊 Actual</span>
                          <div className="text-xs text-gray-500 mt-1">
                            Pencapaian: {kpi.goal_name}
                          </div>
                        </label>
                        <input
                          type="number"
                          min="0"
                          step="0.01"
                          className="border p-3 rounded-lg w-full focus:ring-2 focus:ring-purple-500"
                          value={input.actual}
                          onChange={e => updateInput(index, kpi.master_kpi_detail_id, kpi.employee_kpi_id, 'actual', e.target.value)}
                          disabled={locked}
                          placeholder="Masukkan actual"
                        />
                      </div>
                    </div>

                    {/* PROGRESS SECTION */}
                    <div className="mt-4 p-3 bg-gray-50 rounded-lg">
                      <div className="flex justify-between items-center mb-3">
                        <div>
                          <p className="font-medium text-gray-700">
                            Progress: <span className="text-blue-600">{kpi.goal_name}</span>
                          </p>
                          <p className="text-sm text-gray-500">
                            {input.target && input.actual 
                              ? `${input.actual} / ${input.target} = ${progress.toFixed(1)}%`
                              : "Isi target dan actual untuk melihat progress"}
                          </p>
                        </div>
                        <div className="text-lg font-bold text-gray-700">
                          Score: {score.toFixed(2)}
                        </div>
                      </div>
                      
                      {input.target !== "" && input.actual !== "" && (input.target as number) > 0 && (
                        <>
                          <div className="w-full bg-gray-200 h-3 rounded-full mb-2">
                            <div
                              className="h-3 rounded-full transition-all duration-300"
                              style={{ 
                                width: `${progress}%`,
                                backgroundColor: progress >= 100 ? '#10B981' : 
                                               progress >= 75 ? '#3B82F6' : 
                                               progress >= 50 ? '#F59E0B' : '#EF4444'
                              }}
                            />
                          </div>
                          <div className="text-center text-sm text-gray-600">
                            Weight: {input.weight}% untuk goal "{kpi.goal_name}"
                          </div>
                        </>
                      )}
                    </div>
                  </div>
                );
              })}
            </div>
          </div>

          {/* SUMMARY */}
          <div className="mb-6 p-6 bg-gradient-to-r from-blue-50 to-gray-50 rounded-xl border">
            <h3 className="font-bold text-xl mb-4 text-gray-800">Ringkasan Evaluasi</h3>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
              <div className="text-center p-4 bg-white rounded-lg shadow">
                <p className="text-gray-600 mb-2">Total Score</p>
                <p className="text-4xl font-bold text-blue-600">{totalScore.toFixed(2)}</p>
              </div>
              <div className="text-center p-4 bg-white rounded-lg shadow">
                <p className="text-gray-600 mb-2">Grade</p>
                <p className="text-4xl font-bold text-green-600">{grade}</p>
              </div>
              <div className="text-center p-4 bg-white rounded-lg shadow">
                <p className="text-gray-600 mb-2">Total KPI</p>
                <p className="text-4xl font-bold text-purple-600">{kpis.length}</p>
              </div>
            </div>
            <div className="mt-6 p-4 bg-white rounded-lg">
              <div className="text-sm text-gray-600 space-y-2">
                <p>
                  <span className="font-medium">Status:</span> {locked ? '🔒 Terkunci' : '✏️ Draft'}
                </p>
                <p>
                  <span className="font-medium">Periode:</span> {period}
                </p>
                <p>
                  <span className="font-medium">Total Weight:</span> {Object.values(kpiInputs).reduce((sum, input) => 
                    sum + (input.weight === "" ? 0 : input.weight as number), 0
                  ).toFixed(2)}%
                </p>
              </div>
            </div>
          </div>

          {/* ACTION BUTTONS */}
          {!locked && (
            <div className="flex flex-wrap gap-3 mt-6">
              <button
                onClick={saveEvaluation}
                className="flex-1 bg-blue-600 hover:bg-blue-700 text-white px-6 py-3 rounded-lg flex items-center justify-center gap-2"
              >
                <span className="text-lg">💾</span>
                Simpan Evaluasi
              </button>

              <button
                onClick={resetForm}
                className="flex-1 bg-gray-600 hover:bg-gray-700 text-white px-6 py-3 rounded-lg flex items-center justify-center gap-2"
              >
                <span className="text-lg">🔄</span>
                Reset Form
              </button>

              <button
                onClick={lockEvaluation}
                className="flex-1 bg-red-600 hover:bg-red-700 text-white px-6 py-3 rounded-lg flex items-center justify-center gap-2"
              >
                <span className="text-lg">🔒</span>
                Kunci Evaluasi
              </button>
            </div>
          )}

          {/* DETAIL KPI */}
          <div className="mt-6 p-4 bg-gray-50 rounded-lg">
            <h4 className="font-bold text-lg mb-3">📋 Detail Semua KPI</h4>
            <div className="space-y-3">
              {kpis.map((kpi, index) => (
                <div key={`detail-${index}`} className="p-3 bg-white rounded border">
                  <div className="flex items-center">
                    <div className="w-6 h-6 flex items-center justify-center bg-blue-100 text-blue-800 rounded-full text-xs mr-3">
                      {index + 1}
                    </div>
                    <div>
                      <p className="font-bold text-gray-800">{kpi.goal_name}</p>
                      <div className="flex gap-4 text-sm text-gray-600">
                        <span>Kategori: {kpi.category}</span>
                        <span>•</span>
                        <span>Target DB: {kpi.target || "0"}</span>
                        <span>•</span>
                        <span>Weight DB: {kpi.weight || "0"}%</span>
                      </div>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </>
      )}

      {/* NO KPI MESSAGE */}
      {!loading && selectedEmployee && kpis.length === 0 && (
        <div className="p-8 bg-gray-50 rounded-xl text-center">
          <div className="text-6xl mb-4">📊</div>
          <p className="text-gray-700 text-lg font-medium">
            Employee ini belum memiliki KPI yang di-assign.
          </p>
          <p className="text-sm text-gray-500 mt-2">
            Hubungi administrator untuk menetapkan KPI terlebih dahulu.
          </p>
        </div>
      )}

      {/* HISTORY SECTION */}
      {!loading && history.length > 0 && (
        <div className="mt-8">
          <h3 className="font-bold text-lg mb-4">📈 Riwayat Evaluasi</h3>
          <div className="overflow-x-auto">
            <table className="w-full border">
              <thead className="bg-gray-100">
                <tr>
                  <th className="border p-3 text-left">Periode</th>
                  <th className="border p-3 text-left">Score</th>
                  <th className="border p-3 text-left">Grade</th>
                  <th className="border p-3 text-left">Status</th>
                  <th className="border p-3 text-left">Aksi</th>
                </tr>
              </thead>
              <tbody>
                {history.map((h, i) => (
                  <tr 
                    key={`history-${i}`}
                    className={`hover:bg-gray-50 ${
                      h.period === period ? 'bg-blue-50 font-medium' : ''
                    }`}
                  >
                    <td className="border p-3">
                      {h.period}
                      {h.period === period && (
                        <span className="ml-2 text-xs px-2 py-1 bg-blue-100 text-blue-800 rounded">
                          Sedang dilihat
                        </span>
                      )}
                    </td>
                    <td className="border p-3">{h.final_score.toFixed(2)}</td>
                    <td className="border p-3">
                      <span className={`px-3 py-1 rounded text-sm ${
                        h.grade === 'A' ? 'bg-green-100 text-green-800' :
                        h.grade === 'B' ? 'bg-blue-100 text-blue-800' :
                        'bg-red-100 text-red-800'
                      }`}>
                        {h.grade}
                      </span>
                    </td>
                    <td className="border p-3">
                      {h.is_locked ? (
                        <span className="text-red-600 font-medium">🔒 Locked</span>
                      ) : (
                        <span className="text-blue-600">✏️ Draft</span>
                      )}
                    </td>
                    <td className="border p-3">
                      <button
                        onClick={() => setPeriod(h.period)}
                        className="text-blue-600 hover:text-blue-800 font-medium"
                      >
                        Lihat
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}
    </div>
  );
}