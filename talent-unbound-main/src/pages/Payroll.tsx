"use client";

import { useState, useEffect } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Button } from "@/components/ui/button";
import api_laravel from "@/lib/utils";
import Swal from "sweetalert2";
import { Badge } from "@/components/ui/badge";

interface Employee {
  id: string;
  name: string;
  position: string;
  basic_salary: string;
  allowance: string;
  meal_allowance: string;
  overtime_rate: string;
  bpjs_kesehatan: string;
  bpjs_ketenagakerjaan: string;
  bpjs_jp: string;
  pkp: string;
  tax_number: string;
  payrollProcessed?: boolean;
  ptkp_code?: string;
  thr: string;
  bonus: string;
}

interface PTKP {
  code: string;
  description: string;
  ptkp_annual: number;
}

interface EmployeeAllowance {
  employee_id: string;
  name: string;
  total: number;
  lateCount: number;
  sickCount: number;
  izinCount: number;
  absentCount: number;
  workDays: number;
  attendanceCount: number;
}

export default function Payroll() {
  const [employees, setEmployees] = useState<Employee[]>([]);
  const [ptkpMaster, setPtkpMaster] = useState<PTKP[]>([]);
  const [year, setYear] = useState(new Date().getFullYear());
  const [month, setMonth] = useState(new Date().getMonth() + 1);
  const [allowances, setAllowances] = useState<EmployeeAllowance[]>([]);
  const [cutoffStart, setCutoffStart] = useState<string>("");
  const [cutoffEnd, setCutoffEnd] = useState<string>("");
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Ambil data payroll dengan error handling
  useEffect(() => {
    const fetchPayroll = async () => {
      setLoading(true);
      setError(null);
      try {
        console.log("📊 Fetching payroll data...");
        const res = await api_laravel.get(`/api/payroll?year=${year}&month=${month}`);
        console.log("📦 Payroll API Response:", res.data);
        
        // Handle berbagai struktur response
        let employeesData: Employee[] = [];
        
        if (res.data) {
          if (Array.isArray(res.data)) {
            employeesData = res.data;
          } else if (res.data.data && Array.isArray(res.data.data)) {
            employeesData = res.data.data;
          } else if (res.data.success && Array.isArray(res.data.data)) {
            employeesData = res.data.data;
          } else if (typeof res.data === 'object' && !Array.isArray(res.data)) {
            // Jika respons adalah object tunggal, ubah menjadi array
            employeesData = [res.data];
          } else {
            console.warn("⚠️ Unexpected response structure:", res.data);
            employeesData = [];
          }
        }
        
        console.log("✅ Processed employees data:", employeesData);
        setEmployees(employeesData);
        
      } catch (err: any) {
        console.error("❌ Error fetching payroll:", err);
        setError(err.response?.data?.message || "Failed to fetch payroll data");
        Swal.fire("Error", "Gagal ambil data payroll", "error");
        setEmployees([]); // Set empty array on error
      } finally {
        setLoading(false);
      }
    };

    fetchPayroll();
  }, [year, month]);

  // Ambil master PTKP
  useEffect(() => {
    const fetchPTKP = async () => {
      try {
        console.log("📊 Fetching PTKP master...");
        const res = await api_laravel.get("/api/master-ptkp");
        console.log("📦 PTKP API Response:", res.data);
        
        let ptkpData: PTKP[] = [];
        
        if (res.data) {
          if (Array.isArray(res.data)) {
            ptkpData = res.data;
          } else if (res.data.data && Array.isArray(res.data.data)) {
            ptkpData = res.data.data;
          } else if (res.data.success && Array.isArray(res.data.data)) {
            ptkpData = res.data.data;
          }
        }
        
        console.log("✅ Processed PTKP data:", ptkpData);
        setPtkpMaster(ptkpData);
        
      } catch (err: any) {
        console.error("❌ Error fetching PTKP:", err);
        Swal.fire("Error", "Gagal ambil master PTKP", "error");
        setPtkpMaster([]);
      }
    };

    fetchPTKP();
  }, []);

  const getPtkpAnnual = (code?: string) => {
    if (!code) return 0;
    const ptkp = ptkpMaster.find((p) => p.code === code);
    return ptkp ? Number(ptkp.ptkp_annual) : 0;
  };

  const calculateNetSalary = (emp: Employee) => {
    try {
      const basicSalary = parseFloat(emp.basic_salary ?? "0") || 0;
      const allowance = parseFloat(emp.allowance ?? "0") || 0;
      const mealAllowance = parseFloat(emp.meal_allowance ?? "0") || 0;
      const thr = parseFloat(emp.thr ?? "0") || 0;
      const bonus = parseFloat(emp.bonus ?? "0") || 0;
      const bpjsKesehatan = ((parseFloat(emp.bpjs_kesehatan ?? "0") || 0) / 100) * basicSalary;
      const bpjsKetenagakerjaan = ((parseFloat(emp.bpjs_ketenagakerjaan ?? "0") || 0) / 100) * basicSalary;
      const bpjsJp = ((parseFloat(emp.bpjs_jp ?? "0") || 0) / 100) * basicSalary;

      const grossSalary = basicSalary + allowance + mealAllowance;
      const grossSalaryNet = basicSalary + allowance + mealAllowance + thr + bonus;
      const annualIncome = ((grossSalary - (bpjsKesehatan + bpjsKetenagakerjaan + bpjsJp)) * 12) + (thr + bonus);
      const ptkpAnnual = getPtkpAnnual(emp.ptkp_code);

      let pkpDeduction = 0;
      if (annualIncome > ptkpAnnual) {
        const pkpRate = (parseFloat(emp.pkp ?? "0") || 0) / 100;
        pkpDeduction = (((annualIncome - ptkpAnnual) * pkpRate) / 12);
      }

      const totalDeduction = bpjsKesehatan + bpjsKetenagakerjaan + bpjsJp + pkpDeduction;
      const netSalary = grossSalaryNet - totalDeduction;

      return {
        grossSalary,
        totalDeduction,
        netSalary,
        bpjsKesehatan,
        bpjsKetenagakerjaan,
        bpjsJp,
        pkpDeduction,
        grossSalaryNet
      };
    } catch (error) {
      console.error("Error calculating net salary:", error);
      return {
        grossSalary: 0,
        totalDeduction: 0,
        netSalary: 0,
        bpjsKesehatan: 0,
        bpjsKetenagakerjaan: 0,
        bpjsJp: 0,
        pkpDeduction: 0,
        grossSalaryNet: 0
      };
    }
  };

  const processPayroll = async (id: string) => {
    try {
      await api_laravel.post(`/api/payroll/${id}/process`, { year, month });
      Swal.fire("Berhasil", "Payroll berhasil diproses", "success");
      
      // Refresh data
      const res = await api_laravel.get(`/api/payroll?year=${year}&month=${month}`);
      let employeesData: Employee[] = [];
      
      if (res.data && Array.isArray(res.data)) {
        employeesData = res.data;
      } else if (res.data && res.data.data && Array.isArray(res.data.data)) {
        employeesData = res.data.data;
      }
      
      setEmployees(employeesData);
    } catch (err: any) {
      console.error("Error processing payroll:", err);
      Swal.fire("Error", "Gagal proses payroll", "error");
    }
  };

  const generateSlip = (emp: Employee) => {
    const {
      grossSalary,
      totalDeduction,
      netSalary,
      bpjsKesehatan,
      bpjsKetenagakerjaan,
      bpjsJp,
      pkpDeduction,
      grossSalaryNet,
    } = calculateNetSalary(emp);

    const slipHtml = `
      <div style="max-width: 500px;">
        <h3 style="text-align: center; margin-bottom: 20px;">Slip Gaji</h3>
        <p><b>Nama:</b> ${emp.name || "-"}</p>
        <p><b>Jabatan:</b> ${emp.position || "-"}</p>
        <p><b>Gaji Pokok:</b> Rp ${parseFloat(emp.basic_salary ?? "0").toLocaleString("id-ID")}</p>
        <p><b>Tunjangan:</b> Rp ${parseFloat(emp.allowance ?? "0").toLocaleString("id-ID")}</p>
        <p><b>Uang Makan:</b> Rp ${parseFloat(emp.meal_allowance ?? "0").toLocaleString("id-ID")}</p>
        <p><b>THR:</b> Rp ${parseFloat(emp.thr ?? "0").toLocaleString("id-ID")}</p>
        <p><b>Bonus:</b> Rp ${parseFloat(emp.bonus ?? "0").toLocaleString("id-ID")}</p>
        <h4>Potongan:</h4>
        <ul>
          <li>BPJS Kesehatan (${parseFloat(emp.bpjs_kesehatan || "0").toFixed(2)}%): Rp ${bpjsKesehatan.toLocaleString("id-ID")}</li>
          <li>BPJS Ketenagakerjaan (${parseFloat(emp.bpjs_ketenagakerjaan || "0").toFixed(2)}%): Rp ${bpjsKetenagakerjaan.toLocaleString("id-ID")}</li>
          <li>BPJS Jaminan Pensiun (${parseFloat(emp.bpjs_jp || "0").toFixed(2)}%): Rp ${bpjsJp.toLocaleString("id-ID")}</li>
          <li>PPh 21: Rp ${pkpDeduction.toLocaleString("id-ID")}</li>
        </ul>
        <hr/>
        <p><b>Gaji Kotor:</b> Rp ${grossSalaryNet.toLocaleString("id-ID")}</p>
        <p><b>Total Potongan:</b> Rp ${totalDeduction.toLocaleString("id-ID")}</p>
        <p><b>Gaji Bersih:</b> Rp ${netSalary.toLocaleString("id-ID")}</p>
      </div>
    `;

    Swal.fire({
      title: "Slip Gaji",
      html: slipHtml,
      confirmButtonText: "Tutup",
      width: 550,
    });
  };

  const fetchMealAllowance = async () => {
    if (!cutoffStart || !cutoffEnd) {
      Swal.fire("Info", "Harap pilih tanggal cutoff", "info");
      return;
    }

    try {
      console.log("🍽️ Fetching meal allowance...");
      const res = await api_laravel.get("/api/payroll/meal-allowance-all", {
        params: { cutoff_start: cutoffStart, cutoff_end: cutoffEnd },
      });
      
      console.log("📦 Meal allowance response:", res.data);
      
      let allowancesData: EmployeeAllowance[] = [];
      
      if (res.data) {
        if (Array.isArray(res.data)) {
          allowancesData = res.data;
        } else if (res.data.processed && Array.isArray(res.data.processed)) {
          allowancesData = res.data.processed;
        } else if (res.data.data && Array.isArray(res.data.data)) {
          allowancesData = res.data.data;
        }
      }
      
      console.log("✅ Processed allowances data:", allowancesData);
      setAllowances(allowancesData);
      
      if (res.data.skipped && res.data.skipped.length > 0) {
        Swal.fire(
          "Info",
          `${res.data.skipped.length} karyawan sudah pernah digenerate`,
          "info"
        );
      } else {
        Swal.fire("Sukses", "Meal allowance berhasil dihitung", "success");
      }
    } catch (error: any) {
      console.error("❌ Error fetching meal allowance:", error);
      if (error.response && error.response.data) {
        Swal.fire("Error", error.response.data.message, "error");
      } else {
        Swal.fire("Error", "Gagal hitung meal allowance", "error");
      }
      setAllowances([]);
    }
  };

  const generateMealAllowanceReport = async () => {
    if (!cutoffStart || !cutoffEnd) {
      Swal.fire("Info", "Harap pilih tanggal cutoff", "info");
      return;
    }

    try {
      const res = await api_laravel.get("/api/payroll/meal-allowance", {
        params: { cutoff_start: cutoffStart, cutoff_end: cutoffEnd },
      });
      
      console.log("📊 Meal allowance report response:", res.data);
      
      const data: EmployeeAllowance[] = res.data?.data || [];
      
      if (data.length === 0) {
        Swal.fire("Info", "Belum ada data meal allowance", "info");
        return;
      }

      let htmlContent = `
        <h2 style="text-align:center;">Laporan Meal Allowance</h2>
        <p><b>Periode:</b> ${cutoffStart} s/d ${cutoffEnd}</p>
        <hr/>
        <table border="1" cellspacing="0" cellpadding="5" width="100%">
          <thead>
            <tr>
              <th>No</th>
              <th>Nama</th>
              <th>Total Allowance</th>
              <th>Workdays</th>
              <th>Absensi</th>
              <th>Absen</th>
              <th>Telat</th>
              <th>Sakit</th>
              <th>Izin</th>
            </tr>
          </thead>
          <tbody>
      `;

      let no = 1;
      data.forEach((emp) => {
        htmlContent += `
          <tr>
            <td>${no++}</td>
            <td>${emp.name || "-"}</td>
            <td>Rp ${(emp.total || 0).toLocaleString("id-ID")}</td>
            <td>${emp.workDays || 0}</td>
            <td>${emp.attendanceCount || 0}</td>
            <td>${emp.absentCount || 0}</td>
            <td>${emp.lateCount || 0}</td>
            <td>${emp.sickCount || 0}</td>
            <td>${emp.izinCount || 0}</td>
          </tr>
        `;
      });

      htmlContent += `</tbody></table>`;

      const printWindow = window.open("", "_blank");
      if (printWindow) {
        printWindow.document.write(`
          <html>
            <head>
              <title>Meal Allowance Report</title>
              <style>
                body { font-family: Arial; font-size: 12px; }
                table { border-collapse: collapse; margin-top: 10px; width: 100%; }
                th, td { border: 1px solid #333; padding: 5px; text-align: left; }
                th { background: #f0f0f0; }
              </style>
            </head>
            <body>
              ${htmlContent}
              <script>
                window.onload = function() { window.print(); window.close(); }
              </script>
            </body>
          </html>
        `);
        printWindow.document.close();
      }
    } catch (error: any) {
      console.error("❌ Error generating meal allowance report:", error);
      Swal.fire("Error", "Gagal ambil data meal allowance", "error");
    }
  };

  const handleGenerateAllPayroll = async () => {
    try {
      console.log("🚀 Generating all payroll...");
      const res = await api_laravel.post("/api/payroll/generate", { year, month });
      console.log("✅ Generate all payroll response:", res.data);
      
      Swal.fire("Berhasil", "Semua payroll berhasil diproses", "success");
      
      // Refresh data
      const refreshRes = await api_laravel.get(`/api/payroll?year=${year}&month=${month}`);
      console.log("🔄 Refresh response:", refreshRes.data);
      
      let employeesData: Employee[] = [];
      
      if (refreshRes.data) {
        if (Array.isArray(refreshRes.data)) {
          employeesData = refreshRes.data;
        } else if (refreshRes.data.data && Array.isArray(refreshRes.data.data)) {
          employeesData = refreshRes.data.data;
        }
      }
      
      setEmployees(employeesData);
    } catch (error: any) {
      console.error("❌ Error generating all payroll:", error);
      Swal.fire("Error", "Gagal proses semua payroll", "error");
    }
  };

  const handlePrintPayroll = async () => {
    try {
      console.log("🖨️ Printing payroll report...");
      const res = await api_laravel.get("/api/payroll/report", { params: { year, month } });
      console.log("📄 Payroll report response:", res.data);
      
      const data = Array.isArray(res.data) ? res.data : (res.data?.data || []);
      
      if (data.length === 0) {
        Swal.fire("Info", "Belum ada data payroll", "info");
        return;
      }
      
      let htmlContent = `
        <h2 style="text-align:center;">Laporan Payroll</h2>
        <p><b>Periode:</b> ${month}/${year}</p>
        <hr/>
        <table border="1" cellspacing="0" cellpadding="5" width="100%">
          <thead>
            <tr>
              <th>No</th>
              <th>Nama</th>
              <th>Jabatan</th>
              <th>Gaji Pokok</th>
              <th>Tunjangan</th>
              <th>Meal Allowance</th>
              <th>BPJS Kes</th>
              <th>BPJS TK</th>
              <th>BPJS JP</th>
              <th>PPh21</th>
              <th>Total Potongan</th>
              <th>Gaji Bersih</th>
            </tr>
          </thead>
          <tbody>
      `;
      
      let no = 1;
      data.forEach((emp: any) => {
        const basic = parseFloat(emp.basic_salary ?? "0") || 0;
        const allowance = parseFloat(emp.allowance ?? "0") || 0;
        const meal = parseFloat(emp.meal_allowance ?? "0") || 0;
        const bpjsKes = parseFloat(emp.bpjs_tk ?? "0") || 0;
        const bpjsTK = parseFloat(emp.bpjs_ks ?? "0") || 0;
        const bpjsJP = parseFloat(emp.bpjs_jp ?? "0") || 0;
        const pph21 = parseFloat(emp.pph21 ?? "0") || 0;
        const gross = basic + allowance + meal;
        const totalDeduction = bpjsKes + bpjsTK + bpjsJP + pph21;
        const net = gross - totalDeduction;

        htmlContent += `
          <tr>
            <td>${no++}</td>
            <td>${emp.name || "-"}</td>
            <td>${emp.position || "-"}</td>
            <td>Rp ${basic.toLocaleString("id-ID")}</td>
            <td>Rp ${allowance.toLocaleString("id-ID")}</td>
            <td>Rp ${meal.toLocaleString("id-ID")}</td>
            <td>Rp ${bpjsKes.toLocaleString("id-ID")}</td>
            <td>Rp ${bpjsTK.toLocaleString("id-ID")}</td>
            <td>Rp ${bpjsJP.toLocaleString("id-ID")}</td>
            <td>Rp ${pph21.toLocaleString("id-ID")}</td>
            <td>Rp ${totalDeduction.toLocaleString("id-ID")}</td>
            <td>Rp ${net.toLocaleString("id-ID")}</td>
          </tr>
        `;
      });

      htmlContent += `</tbody></table>`;
      
      const printWindow = window.open("", "_blank");
      if (printWindow) {
        printWindow.document.write(`
          <html>
            <head>
              <title>Payroll Report</title>
              <style>
                body { font-family: Arial; font-size: 12px; }
                table { border-collapse: collapse; margin-top: 10px; width: 100%; }
                th, td { border: 1px solid #333; padding: 5px; text-align: left; }
                th { background: #f0f0f0; }
              </style>
            </head>
            <body>
              ${htmlContent}
              <script>
                window.onload = function() { window.print(); window.close(); }
              </script>
            </body>
          </html>
        `);
        printWindow.document.close();
      }
    } catch (error: any) {
      console.error("❌ Error printing payroll:", error);
      Swal.fire("Error", "Gagal ambil data payroll", "error");
    }
  };

  // Set default cutoff dates
  useEffect(() => {
    const today = new Date();
    const startDate = new Date(today.getFullYear(), today.getMonth() - 1, 25);
    const endDate = new Date(today.getFullYear(), today.getMonth(), 24);
    
    setCutoffStart(startDate.toISOString().split('T')[0]);
    setCutoffEnd(endDate.toISOString().split('T')[0]);
  }, []);

  if (loading) {
    return (
      <div className="flex justify-center items-center min-h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
        <p className="ml-2 text-lg">Loading payroll data...</p>
      </div>
    );
  }

  if (error) {
    return (
      <div className="text-center py-8">
        <p className="text-red-500 mb-2">Error: {error}</p>
        <Button onClick={() => window.location.reload()}>Retry</Button>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Bagian Meal Allowance */}
      <Card>
        <CardHeader className="flex justify-between items-center">
          <CardTitle>Payroll - Meal Allowance (25 - 24)</CardTitle>
          <div className="flex gap-2">
            <input
              type="date"
              value={cutoffStart}
              onChange={(e) => setCutoffStart(e.target.value)}
              className="border rounded px-2 py-1"
            />
            <input
              type="date"
              value={cutoffEnd}
              onChange={(e) => setCutoffEnd(e.target.value)}
              className="border rounded px-2 py-1"
            />
            <Button onClick={fetchMealAllowance}>Hitung Meal Allowance</Button>
            <Button variant="secondary" onClick={generateMealAllowanceReport}>
              Report
            </Button>
          </div>
        </CardHeader>
        <CardContent>
          {allowances.length > 0 ? (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Nama</TableHead>
                  <TableHead>Total Meal Allowance</TableHead>
                  <TableHead>Workdays</TableHead>
                  <TableHead>Absensi</TableHead>
                  <TableHead>Absen</TableHead>
                  <TableHead>Telat</TableHead>
                  <TableHead>Sakit</TableHead>
                  <TableHead>Izin</TableHead>
                  <TableHead>Status</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {allowances.map((emp, index) => (
                  <TableRow key={emp.employee_id || index}>
                    <TableCell>{emp.name || "-"}</TableCell>
                    <TableCell>Rp {(emp.total || 0).toLocaleString("id-ID")}</TableCell>
                    <TableCell>{emp.workDays || 0}</TableCell>
                    <TableCell>{emp.attendanceCount || 0}</TableCell>
                    <TableCell>{emp.absentCount || 0}</TableCell>
                    <TableCell>{emp.lateCount || 0}</TableCell>
                    <TableCell>{emp.sickCount || 0}</TableCell>
                    <TableCell>{emp.izinCount || 0}</TableCell>
                    <TableCell>
                      <Badge className="bg-green-100 text-green-800">Tersimpan</Badge>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          ) : (
            <div className="text-center py-8">
              <p className="text-muted-foreground">No meal allowance data found. Please calculate first.</p>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Bagian Slip Gaji */}
      <Card>
        <CardHeader className="flex justify-between items-center">
          <CardTitle>Payroll - Slip Gaji</CardTitle>
          <div className="flex gap-2">
            <select 
              value={month} 
              onChange={(e) => setMonth(Number(e.target.value))}
              className="border rounded px-2 py-1"
            >
              {[...Array(12)].map((_, i) => (
                <option key={i + 1} value={i + 1}>
                  {i + 1}
                </option>
              ))}
            </select>
            <input
              type="number"
              value={year}
              onChange={(e) => setYear(Number(e.target.value))}
              className="border rounded px-2 py-1 w-20"
            />

            <Button variant="default" onClick={handleGenerateAllPayroll}>
              Generate Payroll
            </Button>

            <Button variant="secondary" onClick={handlePrintPayroll}>
              Print Payroll
            </Button>
          </div>
        </CardHeader>

        <CardContent>
          {employees && employees.length > 0 ? (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Status</TableHead>
                  <TableHead>Nama</TableHead>
                  <TableHead>Jabatan</TableHead>
                  <TableHead>Basic Salary</TableHead>
                  <TableHead>Allowance</TableHead>
                  <TableHead>Meal Allowance</TableHead>
                  <TableHead>THR</TableHead>
                  <TableHead>Deduction</TableHead>
                  <TableHead>Aksi</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {employees.map((emp) => {
                  const { totalDeduction } = calculateNetSalary(emp);
                  return (
                    <TableRow key={emp.id || emp.name}>
                      <TableCell>
                        {emp.payrollProcessed ? (
                          <Badge className="bg-green-100 text-green-800">Sudah Diproses</Badge>
                        ) : (
                          <Badge className="bg-yellow-100 text-yellow-800">Belum Diproses</Badge>
                        )}
                      </TableCell>
                      <TableCell>{emp.name || "-"}</TableCell>
                      <TableCell>{emp.position || "-"}</TableCell>
                      <TableCell>
                        Rp {parseFloat(emp.basic_salary || "0").toLocaleString("id-ID")}
                      </TableCell>
                      <TableCell>
                        Rp {parseFloat(emp.allowance || "0").toLocaleString("id-ID")}
                      </TableCell>
                      <TableCell>
                        Rp {parseFloat(emp.meal_allowance || "0").toLocaleString("id-ID")}
                      </TableCell>
                      <TableCell>
                        Rp {parseFloat(emp.thr || "0").toLocaleString("id-ID")}
                      </TableCell>
                      <TableCell>Rp {(totalDeduction || 0).toLocaleString("id-ID")}</TableCell>
                      <TableCell>
                        {emp.payrollProcessed ? (
                          <Button onClick={() => generateSlip(emp)}>Slip Individu</Button>
                        ) : (
                          <Button onClick={() => processPayroll(emp.id)}>Proses Payroll</Button>
                        )}
                      </TableCell>
                    </TableRow>
                  );
                })}
              </TableBody>
            </Table>
          ) : (
            <div className="text-center py-8">
              <p className="text-muted-foreground">No employee data found for payroll.</p>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}