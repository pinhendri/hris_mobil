import React, { useEffect, useState } from "react";
import api_laravel from "@/lib/utils";
import Swal from "sweetalert2";

interface Employee {
  id: number;
  name: string;
  c_code?: string;
  ccode?: string; // Coba field alternatif
  department_code?: string;
}

interface KPI {
  employee_kpi_id: number;
  master_kpi_detail_id: number;
  goal_name: string;
  category: string;
  target: number | "";
  weight: number | "";
  actual: number | "";
  period?: string;
  year?: number;
}

export default function EvaluateKpi() {
  const [allEmployees, setAllEmployees] = useState<Employee[]>([]);
  const [filteredEmployees, setFilteredEmployees] = useState<Employee[]>([]);
  const [selectedEmployee, setSelectedEmployee] = useState("");
  const [selectedEmployeeName, setSelectedEmployeeName] = useState("");
  const [kpis, setKpis] = useState<KPI[]>([]);
  const [period, setPeriod] = useState("");
  const [saving, setSaving] = useState(false);
  const [history, setHistory] = useState<any[]>([]);
  const [userCcode, setUserCcode] = useState<string | null>(null);
  const [userData, setUserData] = useState<any>(null);

  /* ================= LOAD USER DATA FROM LOCALSTORAGE ================= */
  useEffect(() => {
    // Ambil semua user data dari localStorage untuk debugging
    const userDataStr = localStorage.getItem("user");
    if (userDataStr) {
      try {
        const user = JSON.parse(userDataStr);
        console.log("📋 User data dari localStorage:", user);
        setUserData(user);
        
        // Coba berbagai kemungkinan field untuk c_code
        const ccode = user.c_code || user.ccode || user.employee?.c_code || 
                     user.employee?.ccode || user.department_code || 
                     user.employee?.department_code;
        
        console.log("🔍 C-code ditemukan:", ccode);
        setUserCcode(ccode);
        
        // Debug: lihat semua key yang ada
        console.log("🗝️ Semua keys di user object:", Object.keys(user));
        if (user.employee) {
          console.log("👤 Employee keys:", Object.keys(user.employee));
        }
      } catch (error) {
        console.error("Error parsing user data from localStorage:", error);
      }
    } else {
      console.log("❌ Tidak ada user data di localStorage");
    }
  }, []);

  /* ================= LOAD EMPLOYEES ================= */
  useEffect(() => {
    api_laravel.get("/api/kpi/kpi-evaluation/employees").then((res) => {
      const employees = res.data.employees || [];
      console.log("👥 Semua employees dari API (dengan fields):", employees);
      
      // Debug: lihat struktur employee pertama
      if (employees.length > 0) {
        console.log("📊 Employee pertama:", employees[0]);
        console.log("🔑 Keys employee pertama:", Object.keys(employees[0]));
      }
      
      setAllEmployees(employees);
    }).catch(error => {
      console.error("Error loading employees:", error);
      Swal.fire("Error", "Gagal memuat data employees", "error");
    });
  }, []);

  /* ================= FILTER EMPLOYEES BY C_CODE ================= */
  useEffect(() => {
    if (userCcode && allEmployees.length > 0) {
      console.log("🔍 Filtering employees dengan c_code/userCcode:", userCcode);
      console.log("📊 Total employees sebelum filter:", allEmployees.length);
      
      // Filter employees berdasarkan berbagai kemungkinan field
      const filtered = allEmployees.filter(employee => {
        // Coba berbagai kemungkinan field untuk c_code
        const employeeCcode = employee.c_code || employee.ccode || 
                            employee.department_code || employee.department?.code;
        
        console.log(`Employee: ${employee.name}, c_code: ${employeeCcode}, userCcode: ${userCcode}`);
        
        // Jika employee tidak punya c_code, tidak difilter
        if (!employeeCcode) {
          console.log(`⚠️ Employee ${employee.name} tidak punya c_code`);
          return true; // Tampilkan semua jika tidak ada c_code
        }
        
        return employeeCcode === userCcode;
      });
      
      console.log("✅ Employees setelah filter:", filtered);
      console.log("📈 Jumlah setelah filter:", filtered.length);
      setFilteredEmployees(filtered);
    } else {
      // Jika tidak ada c_code, tampilkan semua
      console.log("⚠️ Tidak ada c_code atau employees kosong, tampilkan semua");
      setFilteredEmployees(allEmployees);
    }
  }, [allEmployees, userCcode]);

  /* ================= LOAD KPI ================= */
  const loadKPI = async (employeeId: string) => {
    if (!employeeId) {
      setKpis([]);
      return;
    }

    try {
      // Perbaiki endpoint sesuai route yang benar
      const res = await api_laravel.get(`/api/kpi/evaluation/employee/${employeeId}/kpi`);
      console.log("API Response KPI:", res.data);

      const data = Array.isArray(res.data) ? res.data : [];
      const selectedEmp = allEmployees.find(e => e.id.toString() === employeeId);
      if (selectedEmp) {
        setSelectedEmployeeName(selectedEmp.name);
      }

      const mapped: KPI[] = data.map((item: any): KPI => ({
        employee_kpi_id: Number(item.employee_kpi_id),
        master_kpi_detail_id: Number(item.master_kpi_detail_id),
        goal_name: item.goal_name || "No Goal Name",
        category: item.category || "Uncategorized",
        target: item.target !== null && item.target !== undefined && item.target !== "" 
                ? Number(item.target) 
                : "",
        weight: item.weight !== null && item.weight !== undefined && item.weight !== "" 
                ? Number(item.weight) 
                : "",
        actual: "",
        period: item.period,
        year: item.year
      }));

      console.log("Mapped KPIs:", mapped);
      setKpis(mapped);

      // Load existing evaluations
      if (period) {
        try {
          const evalRes = await api_laravel.post("/api/kpi/evaluation/check-existing", {
            employee_id: employeeId,
            period: period
          });
          
          if (evalRes.data.success && evalRes.data.evaluations) {
            const updatedKpis = [...mapped];
            evalRes.data.evaluations.forEach((evaluation: any) => {
              const index = updatedKpis.findIndex(
                k => k.employee_kpi_id === evaluation.employee_kpi_id
              );
              if (index !== -1) {
                updatedKpis[index] = {
                  ...updatedKpis[index],
                  target: evaluation.target !== null && evaluation.target !== undefined && evaluation.target !== "" 
                          ? Number(evaluation.target) 
                          : updatedKpis[index].target,
                  weight: evaluation.weight !== null && evaluation.weight !== undefined && evaluation.weight !== "" 
                          ? Number(evaluation.weight) 
                          : updatedKpis[index].weight,
                  actual: evaluation.actual !== null && evaluation.actual !== undefined && evaluation.actual !== "" 
                          ? Number(evaluation.actual) 
                          : ""
                };
              }
            });
            setKpis(updatedKpis);
          }
        } catch (error) {
          console.log("No existing evaluations found");
        }
      }

    } catch (error) {
      console.error("Error loading KPI:", error);
      Swal.fire("Error", "Gagal memuat data KPI", "error");
      setKpis([]);
    }
  };

  /* ================= DEBUG UI ================= */
  const DebugPanel = () => (
    <div className="mb-4 p-3 bg-gray-100 border border-gray-300 rounded-lg text-xs">
      <h4 className="font-bold mb-2">🔍 Debug Panel</h4>
      <div className="grid grid-cols-2 gap-2">
        <div>
          <p><strong>User C-Code:</strong> {userCcode || 'null'}</p>
          <p><strong>Total Employees:</strong> {allEmployees.length}</p>
          <p><strong>Filtered Employees:</strong> {filteredEmployees.length}</p>
        </div>
        <div>
          <p><strong>Selected Employee:</strong> {selectedEmployeeName || 'none'}</p>
          <p><strong>Period:</strong> {period || 'none'}</p>
          <p><strong>KPIs Loaded:</strong> {kpis.length}</p>
        </div>
      </div>
      {userData && (
        <div className="mt-2 p-2 bg-yellow-50 rounded">
          <p className="font-semibold">User Data Structure:</p>
          <pre className="text-xs overflow-auto max-h-20">
            {JSON.stringify(userData, null, 2)}
          </pre>
        </div>
      )}
      {filteredEmployees.length > 0 && (
        <div className="mt-2">
          <p className="font-semibold">Filtered Employees:</p>
          <ul className="text-xs">
            {filteredEmployees.slice(0, 5).map(emp => (
              <li key={emp.id}>
                {emp.name} (c_code: {emp.c_code || emp.ccode || 'N/A'})
              </li>
            ))}
            {filteredEmployees.length > 5 && (
              <li>... dan {filteredEmployees.length - 5} lainnya</li>
            )}
          </ul>
        </div>
      )}
    </div>
  );

  /* ================= SAVE ================= */
  const saveEvaluation = async () => {
    if (!period) {
      Swal.fire("Warning", "Pilih periode terlebih dahulu", "warning");
      return;
    }

    if (!selectedEmployee) {
      Swal.fire("Warning", "Pilih employee terlebih dahulu", "warning");
      return;
    }

    // Validasi
    for (const kpi of kpis) {
      if (kpi.target === "" || kpi.weight === "" || kpi.actual === "") {
        Swal.fire("Warning", "Harap isi semua field untuk setiap KPI", "warning");
        return;
      }
      
      if (kpi.weight !== "" && (kpi.weight < 0 || kpi.weight > 100)) {
        Swal.fire("Warning", `Weight harus antara 0-100% (KPI: ${kpi.goal_name})`, "warning");
        return;
      }
    }

    const totalWeight = kpis.reduce((sum, kpi) => sum + (kpi.weight === "" ? 0 : kpi.weight as number), 0);
    if (Math.abs(totalWeight - 100) > 0.01) {
      Swal.fire("Warning", `Total weight harus 100% (saat ini: ${totalWeight.toFixed(2)}%)`, "warning");
      return;
    }

    setSaving(true);

    try {
      const scores = kpis.map(kpi => ({
        employee_kpi_id: kpi.employee_kpi_id,
        master_kpi_detail_id: kpi.master_kpi_detail_id,
        target: kpi.target as number,
        weight: kpi.weight as number,
        actual: kpi.actual as number
      }));

      const res = await api_laravel.post("/api/kpi/evaluation/save", {
        employee_id: selectedEmployee,
        period,
        scores: scores,
      });

      if (res.data.success) {
        Swal.fire("Success", "Evaluasi berhasil disimpan", "success");
        await loadKPI(selectedEmployee);
      } else {
        Swal.fire("Error", res.data.message || "Gagal menyimpan evaluasi", "error");
      }
    } catch (e: any) {
      console.error("Save error:", e);
      Swal.fire("Error", e.response?.data?.message || "Terjadi kesalahan saat menyimpan", "error");
    } finally {
      setSaving(false);
    }
  };

  /* ================= HITUNG TOTAL SCORE ================= */
  const calculateTotalScore = () => {
    return kpis.reduce((total, kpi) => {
      if (kpi.actual === "" || kpi.target === "" || kpi.weight === "") return total;
      return total + ((kpi.actual as number) / (kpi.target as number)) * (kpi.weight as number);
    }, 0);
  };

  /* ================= GET GRADE ================= */
  const getGrade = (score: number) => {
    if (score >= 90) return "A";
    if (score >= 75) return "B";
    return "C";
  };

  const totalScore = calculateTotalScore();
  const grade = getGrade(totalScore);

  /* ================= RESET FORM ================= */
  const resetForm = () => {
    const resetKpis = kpis.map(kpi => ({
      ...kpi,
      target: "",
      weight: "",
      actual: ""
    }));
    setKpis(resetKpis);
  };

  return (
    <div className="p-6 bg-white rounded-lg shadow-xl max-w-6xl mx-auto">
      <h2 className="text-2xl font-bold mb-6 text-gray-800 border-b pb-3">Evaluasi KPI</h2>

      {/* DEBUG PANEL */}
      <DebugPanel />

      {/* USER INFO */}
      {userCcode && (
        <div className="mb-4 p-3 bg-blue-50 border border-blue-200 rounded-lg">
          <p className="text-sm text-blue-700">
            <span className="font-semibold">C-Code Anda:</span> {userCcode}
            <span className="ml-4 text-green-600">
              ({filteredEmployees.length} employees ditemukan)
            </span>
          </p>
        </div>
      )}

      {/* FILTER SECTION */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 mb-8">
        <div>
          <label className="block text-sm font-semibold text-gray-700 mb-2">
            <span className="text-red-500">*</span> Periode Evaluasi
          </label>
          <input
            type="month"
            className="border-2 border-gray-300 p-3 rounded-lg w-full focus:border-blue-500 focus:ring-2 focus:ring-blue-200 transition"
            value={period}
            onChange={(e) => setPeriod(e.target.value)}
            placeholder="YYYY-MM"
          />
          <p className="text-xs text-gray-500 mt-2">
            Format: Tahun-Bulan (contoh: 2025-01)
          </p>
        </div>
        
        <div>
          <label className="block text-sm font-semibold text-gray-700 mb-2">
            <span className="text-red-500">*</span> Pilih Employee
            {userCcode && (
              <span className="text-xs text-gray-500 ml-2">
                (Filter berdasarkan c-code: {userCcode})
              </span>
            )}
          </label>
          <select
            className="border-2 border-gray-300 p-3 rounded-lg w-full focus:border-blue-500 focus:ring-2 focus:ring-blue-200 transition"
            value={selectedEmployee}
            onChange={(e) => {
              setSelectedEmployee(e.target.value);
              if (e.target.value && period) {
                loadKPI(e.target.value);
              }
            }}
          >
            <option value="">-- Pilih Employee --</option>
            {filteredEmployees.map((e) => (
              <option key={e.id} value={e.id}>
                {e.name} {(e.c_code || e.ccode) ? `(C-Code: ${e.c_code || e.ccode})` : ''}
              </option>
            ))}
          </select>
          <p className="text-xs text-gray-500 mt-2">
            {filteredEmployees.length} employees tersedia
          </p>
        </div>

        <div className="flex items-end">
          <div className="w-full p-3 bg-blue-50 border border-blue-200 rounded-lg">
            <p className="text-sm text-blue-700">
              <span className="font-semibold">Status:</span> {period && selectedEmployee ? "Aktif" : "Belum lengkap"}
            </p>
            <p className="text-sm text-blue-600 mt-1">
              {selectedEmployeeName && `Employee: ${selectedEmployeeName}`}
            </p>
          </div>
        </div>
      </div>

      {/* KPI LIST */}
      {kpis.length > 0 && (
        <>
          {/* SUMMARY INFO */}
          <div className="mb-8 grid grid-cols-1 lg:grid-cols-4 gap-4">
            <div className="bg-gradient-to-r from-blue-50 to-blue-100 p-4 rounded-xl border border-blue-200">
              <p className="text-sm text-blue-600 font-medium">Total KPI</p>
              <p className="text-3xl font-bold text-blue-700">{kpis.length}</p>
            </div>
            <div className="bg-gradient-to-r from-green-50 to-green-100 p-4 rounded-xl border border-green-200">
              <p className="text-sm text-green-600 font-medium">Total Score</p>
              <p className="text-3xl font-bold text-green-700">{totalScore.toFixed(2)}</p>
            </div>
            <div className="bg-gradient-to-r from-purple-50 to-purple-100 p-4 rounded-xl border border-purple-200">
              <p className="text-sm text-purple-600 font-medium">Grade</p>
              <p className="text-3xl font-bold text-purple-700">{grade}</p>
            </div>
            <div className="bg-gradient-to-r from-amber-50 to-amber-100 p-4 rounded-xl border border-amber-200">
              <p className="text-sm text-amber-600 font-medium">Total Weight</p>
              <p className="text-3xl font-bold text-amber-700">
                {kpis.reduce((sum, kpi) => sum + (kpi.weight === "" ? 0 : kpi.weight as number), 0).toFixed(1)}%
              </p>
            </div>
          </div>

          {/* KPI FORM SECTION */}
          <div className="space-y-6 mb-8">
            {kpis.map((kpi, index) => {
              const score = kpi.actual !== "" && kpi.target !== "" && kpi.weight !== "" && (kpi.target as number) > 0
                ? ((kpi.actual as number) / (kpi.target as number)) * (kpi.weight as number)
                : 0;
              
              const progress = (kpi.target as number) > 0 && kpi.actual !== "" 
                ? Math.min(((kpi.actual as number) / (kpi.target as number)) * 100, 100)
                : 0;

              return (
                <div
                  key={`${kpi.employee_kpi_id}-${index}`}
                  className="border-2 border-gray-200 p-6 rounded-xl shadow-sm hover:shadow-md transition-shadow bg-white"
                >
                  {/* HEADER */}
                  <div className="mb-6 pb-4 border-b border-gray-100">
                    <div className="flex flex-col lg:flex-row lg:items-start lg:justify-between gap-4">
                      <div className="flex-1">
                        <div className="flex flex-wrap items-center gap-2 mb-3">
                          <span className="bg-gradient-to-r from-blue-500 to-blue-600 text-white text-xs font-semibold px-3 py-1.5 rounded-full">
                            KPI #{index + 1}
                          </span>
                          <span className="bg-gray-100 text-gray-700 text-xs font-medium px-3 py-1.5 rounded-full">
                            {kpi.category}
                          </span>
                          <span className="bg-green-100 text-green-700 text-xs font-medium px-3 py-1.5 rounded-full">
                            ID: {kpi.master_kpi_detail_id}
                          </span>
                        </div>
                        <h4 className="text-xl font-bold text-gray-800 mb-2">
                          {kpi.goal_name}
                        </h4>
                        <div className="text-sm text-gray-600 space-y-1">
                          <p>
                            <span className="font-medium">Employee KPI ID:</span> {kpi.employee_kpi_id}
                          </p>
                          <p>
                            <span className="font-medium">Period:</span> {kpi.period || period} {kpi.year || ""}
                          </p>
                        </div>
                      </div>
                      <div className="lg:text-right">
                        <div className="bg-gradient-to-r from-blue-50 to-indigo-50 p-4 rounded-xl border border-blue-200 min-w-[120px]">
                          <p className="text-3xl font-bold text-blue-600">
                            {score.toFixed(2)}
                          </p>
                          <p className="text-sm text-gray-500 font-medium">Individual Score</p>
                        </div>
                      </div>
                    </div>
                  </div>

                  {/* INPUT FIELDS - GRID LAYOUT */}
                  <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 mb-6">
                    {/* TARGET */}
                    <div>
                      <label className="block text-sm font-semibold text-gray-700 mb-3">
                        <span className="text-red-500">*</span> Target
                        <span className="text-xs text-gray-500 block font-normal mt-1">
                          Target yang diharapkan untuk "{kpi.goal_name}"
                        </span>
                      </label>
                      <input
                        type="number"
                        min="0"
                        step="0.01"
                        className="border-2 border-gray-300 p-3 rounded-lg w-full focus:border-blue-500 focus:ring-2 focus:ring-blue-200 transition"
                        placeholder="Contoh: 100"
                        value={kpi.target}
                        onChange={(e) => updateInput(index, 'target', e.target.value)}
                      />
                      {kpi.target !== "" && (
                        <p className="text-xs text-green-600 mt-2">
                          ✅ Target diisi: {kpi.target}
                        </p>
                      )}
                    </div>

                    {/* WEIGHT */}
                    <div>
                      <label className="block text-sm font-semibold text-gray-700 mb-3">
                        <span className="text-red-500">*</span> Bobot (%)
                        <span className="text-xs text-gray-500 block font-normal mt-1">
                          Kontribusi goal ini (0-100%)
                        </span>
                      </label>
                      <input
                        type="number"
                        min="0"
                        max="100"
                        step="0.01"
                        className="border-2 border-gray-300 p-3 rounded-lg w-full focus:border-green-500 focus:ring-2 focus:ring-green-200 transition"
                        placeholder="Contoh: 30"
                        value={kpi.weight}
                        onChange={(e) => updateInput(index, 'weight', e.target.value)}
                      />
                      {kpi.weight !== "" && (
                        <p className="text-xs text-green-600 mt-2">
                          ✅ Weight diisi: {kpi.weight}%
                        </p>
                      )}
                    </div>

                    {/* ACTUAL */}
                    <div>
                      <label className="block text-sm font-semibold text-gray-700 mb-3">
                        <span className="text-red-500">*</span> Actual
                        <span className="text-xs text-gray-500 block font-normal mt-1">
                          Pencapaian aktual untuk "{kpi.goal_name}"
                        </span>
                      </label>
                      <input
                        type="number"
                        min="0"
                        step="0.01"
                        className="border-2 border-gray-300 p-3 rounded-lg w-full focus:border-purple-500 focus:ring-2 focus:ring-purple-200 transition"
                        placeholder="Contoh: 85"
                        value={kpi.actual}
                        onChange={(e) => updateInput(index, 'actual', e.target.value)}
                      />
                      {kpi.actual !== "" && (
                        <p className="text-xs text-green-600 mt-2">
                          ✅ Actual diisi: {kpi.actual}
                        </p>
                      )}
                    </div>
                  </div>

                  {/* PROGRESS INFO */}
                  {kpi.target !== "" && kpi.actual !== "" && (kpi.target as number) > 0 && (
                    <div className="mt-6 p-4 bg-gradient-to-r from-gray-50 to-gray-100 rounded-xl border border-gray-200">
                      <div className="flex flex-col lg:flex-row lg:items-center lg:justify-between gap-4 mb-4">
                        <div>
                          <p className="font-medium text-gray-700">
                            Progress <span className="text-blue-600">{kpi.goal_name}</span>
                          </p>
                          <p className="text-sm text-gray-600">
                            {kpi.actual} / {kpi.target} = {progress.toFixed(1)}%
                          </p>
                        </div>
                        <div className="text-lg font-bold text-gray-700">
                          Kontribusi Score: {score.toFixed(2)}
                        </div>
                      </div>
                      
                      <div className="w-full bg-gray-200 h-3 rounded-full mb-2">
                        <div
                          className="h-3 rounded-full transition-all duration-500"
                          style={{ 
                            width: `${progress}%`,
                            backgroundColor: progress >= 100 ? '#10B981' : 
                                           progress >= 75 ? '#3B82F6' : 
                                           progress >= 50 ? '#F59E0B' : '#EF4444'
                          }}
                        />
                      </div>
                      <div className="flex justify-between text-xs text-gray-500 mt-1">
                        <span>0%</span>
                        <span className="font-medium">{progress.toFixed(1)}%</span>
                        <span>100%</span>
                      </div>
                    </div>
                  )}

                  {/* VALIDATION STATUS */}
                  <div className="mt-4">
                    {kpi.target !== "" && kpi.weight !== "" && kpi.actual !== "" ? (
                      <div className="flex items-center text-green-600">
                        <span className="text-lg mr-2">✅</span>
                        <span className="text-sm font-medium">Data KPI lengkap</span>
                      </div>
                    ) : (
                      <div className="flex items-center text-amber-600">
                        <span className="text-lg mr-2">⚠️</span>
                        <span className="text-sm font-medium">Data belum lengkap</span>
                      </div>
                    )}
                  </div>
                </div>
              );
            })}
          </div>

          {/* ACTION BUTTONS */}
          <div className="sticky bottom-6 bg-white/90 backdrop-blur-sm p-4 rounded-xl border-2 border-gray-200 shadow-lg">
            <div className="flex flex-col lg:flex-row gap-4">
              <button
                onClick={saveEvaluation}
                disabled={saving}
                className="flex-1 bg-gradient-to-r from-blue-600 to-blue-700 hover:from-blue-700 hover:to-blue-800 text-white px-6 py-4 rounded-xl font-semibold text-lg disabled:opacity-50 disabled:cursor-not-allowed transition-all flex items-center justify-center gap-3"
              >
                {saving ? (
                  <>
                    <svg className="animate-spin h-6 w-6 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                      <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                      <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                    </svg>
                    Menyimpan...
                  </>
                ) : (
                  <>
                    <span className="text-xl">💾</span>
                    Simpan Evaluasi KPI
                  </>
                )}
              </button>

              <button
                onClick={resetForm}
                className="lg:w-1/4 bg-gradient-to-r from-gray-600 to-gray-700 hover:from-gray-700 hover:to-gray-800 text-white px-6 py-4 rounded-xl font-semibold text-lg transition-all flex items-center justify-center gap-3"
              >
                <span className="text-xl">🔄</span>
                Reset Form
              </button>
            </div>
            
            <div className="mt-4 text-center">
              <p className="text-sm text-gray-600">
                Periode: <span className="font-semibold">{period}</span> | 
                Employee: <span className="font-semibold">{selectedEmployeeName}</span> | 
                Total KPI: <span className="font-semibold">{kpis.length}</span>
              </p>
            </div>
          </div>

          {/* HISTORY SECTION */}
          {history.length > 0 && (
            <div className="mt-12">
              <h3 className="text-xl font-bold text-gray-800 mb-4">📊 Riwayat Evaluasi</h3>
              <div className="overflow-x-auto rounded-xl border border-gray-200">
                <table className="w-full">
                  <thead className="bg-gradient-to-r from-gray-50 to-gray-100">
                    <tr>
                      <th className="p-4 text-left text-sm font-semibold text-gray-700 border-b">Periode</th>
                      <th className="p-4 text-left text-sm font-semibold text-gray-700 border-b">Final Score</th>
                      <th className="p-4 text-left text-sm font-semibold text-gray-700 border-b">Grade</th>
                      <th className="p-4 text-left text-sm font-semibold text-gray-700 border-b">Status</th>
                      <th className="p-4 text-left text-sm font-semibold text-gray-700 border-b">Aksi</th>
                    </tr>
                  </thead>
                  <tbody>
                    {history.map((item, index) => (
                      <tr 
                        key={index}
                        className={`hover:bg-gray-50 ${
                          item.period === period ? 'bg-blue-50' : ''
                        }`}
                      >
                        <td className="p-4 border-b">
                          <div className="flex items-center">
                            {item.period}
                            {item.period === period && (
                              <span className="ml-2 px-2 py-1 bg-blue-100 text-blue-800 text-xs font-medium rounded">
                                Aktif
                              </span>
                            )}
                          </div>
                        </td>
                        <td className="p-4 border-b font-medium">{item.final_score?.toFixed(2) || '0.00'}</td>
                        <td className="p-4 border-b">
                          <span className={`px-3 py-1 rounded-full text-sm font-medium ${
                            item.grade === 'A' ? 'bg-green-100 text-green-800' :
                            item.grade === 'B' ? 'bg-blue-100 text-blue-800' :
                            'bg-red-100 text-red-800'
                          }`}>
                            {item.grade || 'N/A'}
                          </span>
                        </td>
                        <td className="p-4 border-b">
                          <span className={`px-3 py-1 rounded-full text-sm font-medium ${
                            item.is_locked === 1 
                            ? 'bg-red-100 text-red-800' 
                            : 'bg-green-100 text-green-800'
                          }`}>
                            {item.is_locked === 1 ? '🔒 Terkunci' : '✏️ Draft'}
                          </span>
                        </td>
                        <td className="p-4 border-b">
                          <button
                            onClick={() => {
                              setPeriod(item.period);
                              loadKPI(selectedEmployee);
                            }}
                            className="text-blue-600 hover:text-blue-800 font-medium text-sm"
                          >
                            Lihat Detail
                          </button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          )}
        </>
      )}
    </div>
  );
}