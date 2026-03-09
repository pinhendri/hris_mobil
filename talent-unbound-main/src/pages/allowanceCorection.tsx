"use client";

import { useState } from "react";
import Swal from "sweetalert2";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";
import api_laravel from "@/lib/utils";

interface MealAllowanceRecord {
  employee_id: string;
  name: string;
  total: number;
  workDays: number;
  attendanceCount: number;
  absentCount: number;
  lateCount: number;
  sickCount: number;
  izinCount: number;
}

interface ApiResponse {
  data: MealAllowanceRecord[];
  cutoff: [string, string];
  source: string;
}

export default function AllowanceCorrection() {
  const [cutoffStart, setCutoffStart] = useState<string>("");
  const [cutoffEnd, setCutoffEnd] = useState<string>("");
  const [loading, setLoading] = useState<boolean>(false);
  const [records, setRecords] = useState<MealAllowanceRecord[]>([]);

  const fetchAllowanceRecords = async () => {
    if (!cutoffStart || !cutoffEnd) {
      Swal.fire("Warning", "Pilih tanggal awal dan akhir terlebih dahulu", "warning");
      return;
    }

    setLoading(true);
    try {
      const response = await api_laravel.get<ApiResponse>("/api/payroll/meal-allowance", {
        params: {
          cutoff_start: cutoffStart,
          cutoff_end: cutoffEnd
        }
      });

      if (response.data.data && response.data.data.length > 0) {
        setRecords(response.data.data);
        Swal.fire("Success", `Data ditemukan: ${response.data.data.length} record`, "success");
      } else {
        setRecords([]);
        Swal.fire("Info", "Tidak ada data untuk periode yang dipilih", "info");
      }
    } catch (error: any) {
      console.error("Error fetching allowance records:", error);
      Swal.fire("Error", error.response?.data?.message || "Gagal mengambil data allowance", "error");
      setRecords([]);
    } finally {
      setLoading(false);
    }
  };

  const deleteAllowance = async () => {
    if (!cutoffStart || !cutoffEnd) {
      Swal.fire("Warning", "Pilih tanggal awal dan akhir terlebih dahulu", "warning");
      return;
    }

    // Konfirmasi delete
    const result = await Swal.fire({
      title: 'Apakah Anda yakin?',
      text: `Data meal allowance periode ${formatDate(cutoffStart)} - ${formatDate(cutoffEnd)} akan dihapus!`,
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
      const response = await api_laravel.post("/api/payroll/delete-meal-allowance-all", {
        cutoff_start: cutoffStart,
        cutoff_end: cutoffEnd
      });

      if (response.data.status === "success") {
        Swal.fire({
          title: "Berhasil!",
          text: response.data.message,
          icon: "success",
          timer: 3000
        });
        
        // Refresh data setelah delete
        setRecords([]);
      } else {
        Swal.fire("Error", response.data.message || "Gagal menghapus allowance", "error");
      }
    } catch (error: any) {
      console.error("Error deleting allowance:", error);
      Swal.fire("Error", error.response?.data?.message || "Gagal menghapus allowance", "error");
    } finally {
      setLoading(false);
    }
  };

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('id-ID', {
      style: 'currency',
      currency: 'IDR',
      minimumFractionDigits: 0
    }).format(amount);
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('id-ID', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric'
    });
  };

  // Fungsi untuk menentukan status berdasarkan data
  const getStatus = (record: MealAllowanceRecord) => {
    return record.total > 0 ? "Tersimpan" : "Belum Diproses";
  };

  const getStatusBadgeClass = (record: MealAllowanceRecord) => {
    return record.total > 0 ? "bg-green-100 text-green-800" : "bg-yellow-100 text-yellow-800";
  };

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader>
          <CardTitle>Koreksi Meal Allowance</CardTitle>
          <p className="text-muted-foreground">
            Pilih periode cutoff untuk melihat atau menghapus meal allowance
          </p>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
            <div>
              <label className="block text-sm font-medium mb-1">Tanggal Awal</label>
              <input
                type="date"
                value={cutoffStart}
                onChange={(e) => setCutoffStart(e.target.value)}
                className="w-full border rounded-md px-3 py-2 text-sm"
              />
            </div>
            <div>
              <label className="block text-sm font-medium mb-1">Tanggal Akhir</label>
              <input
                type="date"
                value={cutoffEnd}
                onChange={(e) => setCutoffEnd(e.target.value)}
                className="w-full border rounded-md px-3 py-2 text-sm"
              />
            </div>
            <div className="flex items-end">
              <Button 
                onClick={fetchAllowanceRecords}
                disabled={loading}
                variant="outline"
                className="w-full"
              >
                {loading ? "Loading..." : "Cari Data"}
              </Button>
            </div>
            <div className="flex items-end">
              <Button 
                onClick={deleteAllowance}
                disabled={loading || records.length === 0}
                className="w-full bg-red-600 hover:bg-red-700 text-white"
              >
                {loading ? "Menghapus..." : "Hapus Allowance"}
              </Button>
            </div>
          </div>

          {records.length > 0 && (
            <div className="mt-6">
              <div className="flex justify-between items-center mb-4">
                <h3 className="text-lg font-semibold">
                  Data Meal Allowance ({records.length} record)
                </h3>
                <div className="flex gap-2">
                  <Badge className="bg-gray-100 text-gray-800">
                    Periode: {formatDate(cutoffStart)} - {formatDate(cutoffEnd)}
                  </Badge>
                  <Badge className="bg-blue-100 text-blue-800">
                    Total: {formatCurrency(records.reduce((sum, record) => sum + record.total, 0))}
                  </Badge>
                </div>
              </div>

              <div className="border rounded-lg">
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>Nama Karyawan</TableHead>
                      <TableHead>Total Allowance</TableHead>
                      <TableHead>Workdays</TableHead>
                      <TableHead>Attendance</TableHead>
                      <TableHead>Absent</TableHead>
                      <TableHead>Late</TableHead>
                      <TableHead>Sick</TableHead>
                      <TableHead>Izin</TableHead>
                      <TableHead>Status</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {records.map((record, index) => (
                      <TableRow key={`${record.employee_id}-${index}`}>
                        <TableCell className="font-medium">{record.name}</TableCell>
                        <TableCell className="font-semibold">
                          {formatCurrency(record.total)}
                        </TableCell>
                        <TableCell>{record.workDays}</TableCell>
                        <TableCell className="text-green-600">
                          {record.attendanceCount}
                        </TableCell>
                        <TableCell className="text-red-600">
                          {record.absentCount}
                        </TableCell>
                        <TableCell className="text-orange-600">
                          {record.lateCount}
                        </TableCell>
                        <TableCell className="text-blue-600">
                          {record.sickCount}
                        </TableCell>
                        <TableCell className="text-purple-600">
                          {record.izinCount}
                        </TableCell>
                        <TableCell>
                          <Badge className={getStatusBadgeClass(record)}>
                            {getStatus(record)}
                          </Badge>
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </div>

              {/* Summary */}
              <div className="mt-4 p-4 bg-gray-50 rounded-lg">
                <h4 className="font-semibold mb-2">Summary Periode</h4>
                <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-sm">
                  <div>
                    <span className="text-gray-600">Total Records: </span>
                    <span className="font-semibold">{records.length}</span>
                  </div>
                  <div>
                    <span className="text-gray-600">Total Allowance: </span>
                    <span className="font-semibold">
                      {formatCurrency(records.reduce((sum, record) => sum + record.total, 0))}
                    </span>
                  </div>
                  <div>
                    <span className="text-gray-600">Total Attendance: </span>
                    <span className="font-semibold">
                      {records.reduce((sum, record) => sum + record.attendanceCount, 0)}
                    </span>
                  </div>
                  <div>
                    <span className="text-gray-600">Total Workdays: </span>
                    <span className="font-semibold">
                      {records.reduce((sum, record) => sum + record.workDays, 0)}
                    </span>
                  </div>
                </div>
              </div>
            </div>
          )}

          {records.length === 0 && !loading && (
            <div className="text-center py-8 text-gray-500">
              <p>Pilih periode dan klik "Cari Data" untuk menampilkan records meal allowance</p>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}