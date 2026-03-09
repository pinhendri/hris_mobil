"use client";

import { useState } from "react";
import Swal from "sweetalert2";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";
import api_laravel from "@/lib/utils";

interface PayrollHistory {
  id: string;
  employee_id: string;
  employee_name: string;
  name?: string; // Tambahkan ini
  position: string;
  year: number;
  month: number;
  basic_salary: number;
  gross_salary: number;
  allowance: number;
  meal_allowance: number;
  bpjs_tk: number;
  bpjs_ks: number;
  bpjs_jp: number;
  pph21: number;
  total_deduction: number;
  net_salary: number;
  thr: number;
  bonus: number;
  processed_at: string;
}

interface EmployeePayroll {
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
  ptkp_code: string;
  tax_number: string;
  thr: string;
  bonus: string;
  payrollProcessed: boolean;
}

export default function PayrollCorrection() {
  const [year, setYear] = useState<number>(new Date().getFullYear());
  const [month, setMonth] = useState<number>(new Date().getMonth() + 1);
  const [loading, setLoading] = useState<boolean>(false);
  const [employees, setEmployees] = useState<EmployeePayroll[]>([]);
  const [histories, setHistories] = useState<PayrollHistory[]>([]);

  // Fetch data payroll employees
  const fetchPayrollData = async () => {
    if (!year || !month) {
      Swal.fire("Warning", "Pilih tahun dan bulan terlebih dahulu", "warning");
      return;
    }

    setLoading(true);
    try {
      const response = await api_laravel.get("/api/payroll", {
        params: {
          year: year,
          month: month
        }
      });

      console.log("Response data:", response.data); // Debug log
    
      // PERBAIKAN DI SINI:
      if (response.data && response.data.data && response.data.data.length > 0) {
        setEmployees(response.data.data);
        Swal.fire("Success", `Data ditemukan: ${response.data.data.length} karyawan`, "success");
      } else {
        setEmployees([]);
        Swal.fire("Info", "Tidak ada data payroll untuk periode yang dipilih", "info");
      }
    } catch (error: any) {
      console.error("Error fetching payroll data:", error);
      Swal.fire("Error", error.response?.data?.message || "Gagal mengambil data payroll", "error");
      setEmployees([]);
    } finally {
      setLoading(false);
    }
  };

  // Fetch payroll histories
  const fetchPayrollHistories = async () => {
    if (!year || !month) {
      Swal.fire("Warning", "Pilih tahun dan bulan terlebih dahulu", "warning");
      return;
    }

    setLoading(true);
    try {
      const response = await api_laravel.get("/api/payroll/report", {
        params: {
          year: year,
          month: month
        }
      });

      console.log("History response:", response.data); // Debug log

      if (response.data && response.data.length > 0) {
        // Transform data dari API ke format yang diharapkan
        const transformedHistories = response.data.map((item: any) => ({
          id: item.id || '',
          employee_id: item.employee_id || '',
          employee_name: item.name || item.employee_name || '-', // Gunakan 'name' dari response
          name: item.name || '-', // Simpan juga sebagai name
          position: item.position || item.nama_jabatan || '-',
          year: Number(item.year) || 0,
          month: Number(item.month) || 0,
          basic_salary: Number(item.basic_salary) || 0,
          gross_salary: Number(item.gross_salary) || 0,
          allowance: Number(item.allowance) || 0,
          meal_allowance: Number(item.meal_allowance) || 0,
          bpjs_tk: Number(item.bpjs_tk) || 0,
          bpjs_ks: Number(item.bpjs_ks) || 0,
          bpjs_jp: Number(item.bpjs_jp) || 0,
          pph21: Number(item.pph21) || 0,
          total_deduction: Number(item.total_deduction) || 0,
          net_salary: Number(item.net_salary) || 0,
          thr: Number(item.thr) || 0,
          bonus: Number(item.bonus) || 0,
          processed_at: item.processed_at || new Date().toISOString()
        }));
        
        setHistories(transformedHistories);
      } else {
        setHistories([]);
      }
    } catch (error: any) {
      console.error("Error fetching payroll histories:", error);
      setHistories([]);
    } finally {
      setLoading(false);
    }
  };

  // Load semua data sekaligus
  const loadAllData = async () => {
    if (!year || !month) {
      Swal.fire("Warning", "Pilih tahun dan bulan terlebih dahulu", "warning");
      return;
    }

    setLoading(true);
    try {
      await Promise.all([
        fetchPayrollData(),
        fetchPayrollHistories()
      ]);
    } catch (error: any) {
      console.error("Error loading data:", error);
    } finally {
      setLoading(false);
    }
  };

  // Delete payroll histories untuk semua karyawan
  const deleteAllPayroll = async () => {
    if (!year || !month) {
      Swal.fire("Warning", "Pilih tahun dan bulan terlebih dahulu", "warning");
      return;
    }

    // Konfirmasi delete
    const result = await Swal.fire({
      title: 'Apakah Anda yakin?',
      text: `Data payroll periode ${getMonthName(month)} ${year} akan dihapus! Tindakan ini akan memungkinkan proses ulang payroll.`,
      icon: 'warning',
      showCancelButton: true,
      confirmButtonColor: '#d33',
      cancelButtonColor: '#3085d6',
      confirmButtonText: 'Ya, Hapus!',
      cancelButtonText: 'Batal'
    });

    if (!result.isConfirmed) {
      return;
    }

    setLoading(true);
    try {
      const response = await api_laravel.post("/api/payroll/delete-process-all", {
        year: year,
        month: month
      });

      if (response.data.status === "success") {
        Swal.fire({
          title: "Berhasil!",
          text: response.data.message,
          icon: "success",
          timer: 3000
        });
        
        // Refresh data setelah delete
        loadAllData();
      } else {
        Swal.fire("Error", response.data.message || "Gagal menghapus payroll", "error");
      }
    } catch (error: any) {
      console.error("Error deleting payroll:", error);
      Swal.fire("Error", error.response?.data?.message || "Gagal menghapus payroll", "error");
    } finally {
      setLoading(false);
    }
  };

  // Process payroll untuk semua karyawan
  const processAllPayroll = async () => {
    if (!year || !month) {
      Swal.fire("Warning", "Pilih tahun dan bulan terlebih dahulu", "warning");
      return;
    }

    setLoading(true);
    try {
      const response = await api_laravel.post("/api/payroll/generate", {
        year: year,
        month: month
      });

      if (response.data.status === "success") {
        Swal.fire("Success", "Payroll berhasil diproses untuk semua karyawan", "success");
        
        // Refresh data setelah proses
        loadAllData();
      } else {
        Swal.fire("Error", response.data.message || "Gagal memproses payroll", "error");
      }
    } catch (error: any) {
      console.error("Error processing payroll:", error);
      Swal.fire("Error", error.response?.data?.message || "Gagal memproses payroll", "error");
    } finally {
      setLoading(false);
    }
  };

  // Process payroll individu
  const processIndividualPayroll = async (employeeId: string) => {
    setLoading(true);
    try {
      const response = await api_laravel.post(`/api/payroll/${employeeId}/process`, {
        year: year,
        month: month
      });

      if (response.data.status === "success") {
        Swal.fire("Success", "Payroll berhasil diproses", "success");
        
        // Refresh data setelah proses
        loadAllData();
      } else {
        Swal.fire("Error", response.data.message || "Gagal memproses payroll", "error");
      }
    } catch (error: any) {
      console.error("Error processing individual payroll:", error);
      Swal.fire("Error", error.response?.data?.message || "Gagal memproses payroll", "error");
    } finally {
      setLoading(false);
    }
  };

  const formatCurrency = (amount: number) => {
    if (isNaN(amount) || amount === null || amount === undefined) {
      return 'Rp 0';
    }
    return new Intl.NumberFormat('id-ID', {
      style: 'currency',
      currency: 'IDR',
      minimumFractionDigits: 0
    }).format(amount);
  };

  const getMonthName = (monthNumber: number) => {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return months[monthNumber - 1] || '';
  };

  // Cek apakah ada data yang sudah diproses
  const hasProcessedData = employees.some(emp => emp.payrollProcessed) || histories.length > 0;

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader>
          <CardTitle>Koreksi Payroll</CardTitle>
          <p className="text-muted-foreground">
            Pilih periode tahun dan bulan untuk melihat, memproses, atau menghapus payroll
          </p>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
            <div>
              <label className="block text-sm font-medium mb-1">Tahun</label>
              <select
                value={year}
                onChange={(e) => setYear(Number(e.target.value))}
                className="w-full border rounded-md px-3 py-2 text-sm"
              >
                {Array.from({ length: 10 }, (_, i) => {
                  const yearOption = new Date().getFullYear() - 5 + i;
                  return (
                    <option key={yearOption} value={yearOption}>
                      {yearOption}
                    </option>
                  );
                })}
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium mb-1">Bulan</label>
              <select
                value={month}
                onChange={(e) => setMonth(Number(e.target.value))}
                className="w-full border rounded-md px-3 py-2 text-sm"
              >
                {Array.from({ length: 12 }, (_, i) => (
                  <option key={i + 1} value={i + 1}>
                    {getMonthName(i + 1)}
                  </option>
                ))}
              </select>
            </div>
            <div className="flex items-end">
              <Button 
                onClick={loadAllData}
                disabled={loading}
                variant="outline"
                className="w-full"
              >
                {loading ? "Loading..." : "Cari Data"}
              </Button>
            </div>
            <div className="flex items-end">
              <Button 
                onClick={processAllPayroll}
                disabled={loading || employees.length === 0}
                className="w-full bg-green-600 hover:bg-green-700 text-white"
              >
                {loading ? "Memproses..." : "Proses Semua"}
              </Button>
            </div>
          </div>

          {/* Tombol Delete - SELALU AKTIF selama ada data */}
          {employees.length > 0 && (
            <div className="mb-6 flex justify-end">
              <Button 
                onClick={deleteAllPayroll}
                disabled={loading || !hasProcessedData}
                className="bg-red-600 hover:bg-red-700 text-white"
              >
                {loading ? "Menghapus..." : "Hapus Payroll untuk Proses Ulang"}
              </Button>
            </div>
          )}

          {/* Data Karyawan */}
          {employees.length > 0 && (
            <div className="mt-6">
              <div className="flex justify-between items-center mb-4">
                <h3 className="text-lg font-semibold">
                  Data Payroll Karyawan ({employees.length} orang)
                </h3>
                <div className="flex gap-2">
                  <Badge className="bg-gray-100 text-gray-800">
                    Periode: {getMonthName(month)} {year}
                  </Badge>
                  <Badge className="bg-blue-100 text-blue-800">
                    Diproses: {employees.filter(emp => emp.payrollProcessed).length}
                  </Badge>
                  <Badge className="bg-yellow-100 text-yellow-800">
                    Belum: {employees.filter(emp => !emp.payrollProcessed).length}
                  </Badge>
                </div>
              </div>

              <div className="border rounded-lg">
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>Nama Karyawan</TableHead>
                      <TableHead>Jabatan</TableHead>
                      <TableHead>Gaji Pokok</TableHead>
                      <TableHead>Tunjangan</TableHead>
                      <TableHead>Meal Allowance</TableHead>
                      <TableHead>THR</TableHead>
                      <TableHead>Bonus</TableHead>
                      <TableHead>Status</TableHead>
                      <TableHead>Aksi</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {employees.map((employee) => (
                      <TableRow key={employee.id}>
                        <TableCell className="font-medium">{employee.name || '-'}</TableCell>
                        <TableCell>{employee.position || '-'}</TableCell>
                        <TableCell>{formatCurrency(parseFloat(employee.basic_salary || '0'))}</TableCell>
                        <TableCell>{formatCurrency(parseFloat(employee.allowance || '0'))}</TableCell>
                        <TableCell>{formatCurrency(parseFloat(employee.meal_allowance || '0'))}</TableCell>
                        <TableCell>{formatCurrency(parseFloat(employee.thr || '0'))}</TableCell>
                        <TableCell>{formatCurrency(parseFloat(employee.bonus || '0'))}</TableCell>
                        <TableCell>
                          <Badge className={employee.payrollProcessed ? "bg-green-100 text-green-800" : "bg-yellow-100 text-yellow-800"}>
                            {employee.payrollProcessed ? "Sudah Diproses" : "Belum Diproses"}
                          </Badge>
                        </TableCell>
                        <TableCell>
                          {!employee.payrollProcessed && (
                            <Button 
                              onClick={() => processIndividualPayroll(employee.id)}
                              disabled={loading}
                              size="sm"
                              className="bg-green-600 hover:bg-green-700 text-white"
                            >
                              Proses
                            </Button>
                          )}
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </div>
            </div>
          )}

          {/* Data History Payroll */}
          {histories.length > 0 && (
            <div className="mt-8">
              <div className="flex justify-between items-center mb-4">
                <h3 className="text-lg font-semibold">
                  History Payroll ({histories.length} record)
                </h3>
                <div className="flex gap-2">
                  <Button 
                    onClick={fetchPayrollHistories}
                    disabled={loading}
                    variant="outline"
                    size="sm"
                  >
                    Refresh History
                  </Button>
                  <Badge className="bg-red-100 text-red-800">
                    Total Bersih: {formatCurrency(histories.reduce((sum, history) => sum + (history.net_salary || 0), 0))}
                  </Badge>
                </div>
              </div>

              <div className="border rounded-lg">
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>Nama Karyawan</TableHead>
                      <TableHead>Gaji Kotor</TableHead>
                      <TableHead>Total Potongan</TableHead>
                      <TableHead>Gaji Bersih</TableHead>
                      <TableHead>BPJS TK</TableHead>
                      <TableHead>BPJS KS</TableHead>
                      <TableHead>BPJS JP</TableHead>
                      <TableHead>PPh21</TableHead>
                      <TableHead>Tanggal Proses</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {histories.map((history) => (
                      <TableRow key={history.id}>
                        <TableCell className="font-medium">
                          {history.employee_name || history.name || '-'}
                        </TableCell>
                        <TableCell className="font-semibold">
                          {formatCurrency(history.gross_salary)}
                        </TableCell>
                        <TableCell className="text-red-600">
                          {formatCurrency(history.total_deduction)}
                        </TableCell>
                        <TableCell className="text-green-600 font-semibold">
                          {formatCurrency(history.net_salary)}
                        </TableCell>
                        <TableCell>{formatCurrency(history.bpjs_tk)}</TableCell>
                        <TableCell>{formatCurrency(history.bpjs_ks)}</TableCell>
                        <TableCell>{formatCurrency(history.bpjs_jp)}</TableCell>
                        <TableCell>{formatCurrency(history.pph21)}</TableCell>
                        <TableCell>
                          {history.processed_at ? 
                            new Date(history.processed_at).toLocaleDateString('id-ID') : 
                            '-'
                          }
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </div>

              {/* Summary */}
              <div className="mt-4 p-4 bg-gray-50 rounded-lg">
                <h4 className="font-semibold mb-2">Summary Payroll</h4>
                <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-sm">
                  <div>
                    <span className="text-gray-600">Total Karyawan: </span>
                    <span className="font-semibold">{histories.length}</span>
                  </div>
                  <div>
                    <span className="text-gray-600">Total Gaji Kotor: </span>
                    <span className="font-semibold">
                      {formatCurrency(histories.reduce((sum, history) => sum + (history.gross_salary || 0), 0))}
                    </span>
                  </div>
                  <div>
                    <span className="text-gray-600">Total Potongan: </span>
                    <span className="font-semibold">
                      {formatCurrency(histories.reduce((sum, history) => sum + (history.total_deduction || 0), 0))}
                    </span>
                  </div>
                  <div>
                    <span className="text-gray-600">Total Gaji Bersih: </span>
                    <span className="font-semibold">
                      {formatCurrency(histories.reduce((sum, history) => sum + (history.net_salary || 0), 0))}
                    </span>
                  </div>
                </div>
              </div>
            </div>
          )}

          {employees.length === 0 && !loading && (
            <div className="text-center py-8 text-gray-500">
              <p>Pilih periode dan klik "Cari Data" untuk menampilkan data payroll</p>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}