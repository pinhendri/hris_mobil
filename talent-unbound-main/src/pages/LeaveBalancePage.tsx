"use client";

import { useState, useEffect } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription } from "@/components/ui/dialog";
import { Label } from "@/components/ui/label";
import api_laravel from "@/lib/utils";
import Swal from "sweetalert2";

interface Employee {
  uuid: string;
  name: string;
  position_name: string | null;
  nik_employee: string | null;
  department_description: string | null;
}

interface LeaveBalance {
  id: number;
  uuid: string;
  employee_id: number;
  annual_total: number;
  annual_used: number;
  sick_total: number;
  sick_used: number;
  personal_total: number;
  personal_used: number;
  created_at: string;
  updated_at: string;
  employee?: Employee;
}

interface Meta {
  current_page: number;
  last_page: number;
  per_page: number;
  total: number;
}

interface LeaveBalancesResponse {
  success: boolean;
  message: string;
  data: {
    data: LeaveBalance[];
    meta: Meta;
  };
}

// Helper function untuk mendapatkan company code dari localStorage
const getCompanyCode = (): string => {
  try {
    const companyData = localStorage.getItem("selectedCompany");
    if (companyData) {
      const parsedData = JSON.parse(companyData);
      return parsedData.c_code || "";
    }
  } catch (error) {
    console.error("Error parsing company data:", error);
  }
  return "";
};

const LeaveBalancePage = () => {
  const [leaveBalances, setLeaveBalances] = useState<LeaveBalance[]>([]);
  const [meta, setMeta] = useState<Meta | null>(null);
  const [loading, setLoading] = useState(false);
  const [page, setPage] = useState(1);
  const [search, setSearch] = useState("");
  const [companyCode, setCompanyCode] = useState<string>("");
  
  // Modal states
  const [balanceEditModalOpen, setBalanceEditModalOpen] = useState(false);
  const [selectedBalance, setSelectedBalance] = useState<LeaveBalance | null>(null);
  
  // Balance form state
  const [balanceFormData, setBalanceFormData] = useState({
    annual_total: 25,
    annual_used: 0,
    sick_total: 10,
    sick_used: 0,
    personal_total: 5,
    personal_used: 0,
  });

  const [isProcessing, setIsProcessing] = useState(false);

  // Load company code saat komponen pertama kali render
  useEffect(() => {
    const code = getCompanyCode();
    setCompanyCode(code);
    console.log(`Company Code loaded: ${code}`);
  }, []);

  const fetchLeaveBalances = async (pageNumber = 1, searchQuery = "") => {
    try {
      setLoading(true);
      const params = new URLSearchParams({
        page: pageNumber.toString(),
        search: searchQuery
      });

      // Tambahkan company code ke params jika tersedia
      const companyCode = getCompanyCode();
      if (companyCode) {
        params.append('c_code', companyCode);
      }

      const res = await api_laravel.get<LeaveBalancesResponse>(`/api/leave-balance/leave-balances?${params}`);

      if (res.data?.success) {
        setLeaveBalances(res.data.data.data || []);
        setMeta(res.data.data.meta || null);
        setPage(res.data.data.meta?.current_page || 1);
      } else {
        Swal.fire("Error", "Gagal memuat data saldo cuti", "error");
      }
    } catch (error: any) {
      console.error("Fetch leave balances error:", error);
      if (error.response?.status === 404 || error.response?.data?.message?.includes('tidak ditemukan')) {
        setLeaveBalances([]);
        Swal.fire("Info", "Belum ada data saldo cuti. Silakan inisialisasi terlebih dahulu.", "info");
      } else {
        Swal.fire("Error", error.response?.data?.message || "Gagal mengambil data saldo cuti", "error");
      }
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchLeaveBalances(page, search);
  }, []);

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault();
    fetchLeaveBalances(1, search);
  };

  const resetBalanceForm = () => {
    setBalanceFormData({
      annual_total: 25,
      annual_used: 0,
      sick_total: 10,
      sick_used: 0,
      personal_total: 5,
      personal_used: 0,
    });
  };

  const openEditBalanceModal = (balance: LeaveBalance) => {
    setBalanceFormData({
      annual_total: balance.annual_total,
      annual_used: balance.annual_used,
      sick_total: balance.sick_total,
      sick_used: balance.sick_used,
      personal_total: balance.personal_total,
      personal_used: balance.personal_used,
    });
    setSelectedBalance(balance);
    setBalanceEditModalOpen(true);
  };

  const handleBalanceSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!selectedBalance) {
      Swal.fire("Error", "Tidak ada data saldo yang dipilih", "error");
      return;
    }

    // Validasi company code
    const companyCode = getCompanyCode();
    if (!companyCode) {
      Swal.fire("Error", "Company code tidak ditemukan. Silakan login ulang.", "error");
      return;
    }

    setIsProcessing(true);

    try {
      // Tambahkan company code ke data yang dikirim
      const requestData = {
        ...balanceFormData,
        c_code: companyCode
      };

      await api_laravel.put(`/api/leave-balance/leave-balances/${selectedBalance.uuid}`, requestData);
      Swal.fire("Success", "Saldo cuti berhasil diupdate", "success");
      
      setBalanceEditModalOpen(false);
      resetBalanceForm();
      setSelectedBalance(null);
      fetchLeaveBalances(page, search);
    } catch (error: any) {
      console.error("Update balance error:", error);
      Swal.fire("Error", error.response?.data?.message || "Gagal mengupdate saldo", "error");
    } finally {
      setIsProcessing(false);
    }
  };

  const handleResetBalance = async (balanceUuid: string) => {
    const result = await Swal.fire({
      title: "Reset Saldo Cuti?",
      text: "Saldo cuti akan direset ke nilai default. Tindakan ini tidak dapat dibatalkan!",
      icon: "warning",
      showCancelButton: true,
      confirmButtonColor: "#d33",
      cancelButtonColor: "#3085d6",
      confirmButtonText: "Ya, Reset!",
      cancelButtonText: "Batal"
    });

    if (result.isConfirmed) {
      try {
        // Ambil company code
        const companyCode = getCompanyCode();
        if (!companyCode) {
          Swal.fire("Error", "Company code tidak ditemukan. Silakan login ulang.", "error");
          return;
        }

        await api_laravel.post(`/api/leave-balance/leave-balances/${balanceUuid}/reset`, {
          c_code: companyCode
        });
        Swal.fire("Success", "Saldo cuti berhasil direset", "success");
        fetchLeaveBalances(page, search);
      } catch (error: any) {
        Swal.fire("Error", error.response?.data?.message || "Gagal mereset saldo", "error");
      }
    }
  };

  const handleInitializeAll = async () => {
    const result = await Swal.fire({
      title: "Inisialisasi Saldo Cuti?",
      text: "Saldo cuti akan dibuat untuk semua karyawan yang belum memiliki saldo. Tindakan ini tidak dapat dibatalkan!",
      icon: "warning",
      showCancelButton: true,
      confirmButtonColor: "#3085d6",
      cancelButtonColor: "#d33",
      confirmButtonText: "Ya, Inisialisasi!",
      cancelButtonText: "Batal"
    });

    if (result.isConfirmed) {
      try {
        // Ambil company code
        const companyCode = getCompanyCode();
        if (!companyCode) {
          Swal.fire("Error", "Company code tidak ditemukan. Silakan login ulang.", "error");
          return;
        }

        const res = await api_laravel.post("/api/leave-balance/leave-balances/initialize", {
          c_code: companyCode
        });
        if (res.data?.success) {
          Swal.fire("Success", res.data.message, "success");
          fetchLeaveBalances(page, search);
        } else {
          Swal.fire("Error", "Gagal menginisialisasi saldo cuti", "error");
        }
      } catch (error: any) {
        Swal.fire("Error", error.response?.data?.message || "Gagal menginisialisasi saldo", "error");
      }
    }
  };

  const calculateRemaining = (total: number, used: number) => {
    return total - used;
  };

  const getBalanceStatus = (remaining: number) => {
    if (remaining <= 0) return "danger";
    if (remaining <= 5) return "warning";
    return "success";
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case "danger": return "text-red-600 font-bold";
      case "warning": return "text-orange-600 font-semibold";
      case "success": return "text-green-600";
      default: return "text-gray-600";
    }
  };

  return (
    <div className="container mx-auto py-6">
      <Card>
        <CardHeader className="flex flex-row items-center justify-between">
          <CardTitle>Manajemen Saldo Cuti Karyawan</CardTitle>
          <div className="flex flex-col sm:flex-row gap-2">
            <div className="text-xs text-gray-500 bg-gray-100 px-3 py-1 rounded">
              Company: {companyCode || "Belum dipilih"}
            </div>
            <Button onClick={handleInitializeAll} variant="outline">
              🔄 Inisialisasi Semua
            </Button>
          </div>
        </CardHeader>
        <CardContent>
          {/* Search Form */}
          <form onSubmit={handleSearch} className="mb-6">
            <div className="flex gap-2">
              <Input
                placeholder="Cari berdasarkan nama atau NIK..."
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                className="flex-1"
              />
              <Button type="submit" variant="outline">
                🔍 Cari
              </Button>
            </div>
          </form>

          {loading ? (
            <div className="text-center py-8">
              <p>Loading data saldo cuti...</p>
            </div>
          ) : (
            <>
              {/* Saldo Cuti Table */}
              <div className="rounded-md border">
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>Nama Karyawan</TableHead>
                      <TableHead>NIK</TableHead>
                      <TableHead>Posisi</TableHead>
                      <TableHead>Departemen</TableHead>
                      <TableHead>Cuti Tahunan</TableHead>
                      <TableHead>Cuti Sakit</TableHead>
                      <TableHead>Cuti Pribadi</TableHead>
                      <TableHead>Total Sisa</TableHead>
                      <TableHead>Status</TableHead>
                      <TableHead>Aksi</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {leaveBalances.length === 0 ? (
                      <TableRow>
                        <TableCell colSpan={10} className="text-center py-8 text-muted-foreground">
                          {search ? "Tidak ada data saldo cuti yang sesuai dengan pencarian" : "Belum ada data saldo cuti. Silakan inisialisasi terlebih dahulu."}
                        </TableCell>
                      </TableRow>
                    ) : (
                      leaveBalances.map((balance) => {
                        const annualRemaining = calculateRemaining(balance.annual_total, balance.annual_used);
                        const sickRemaining = calculateRemaining(balance.sick_total, balance.sick_used);
                        const personalRemaining = calculateRemaining(balance.personal_total, balance.personal_used);
                        const totalRemaining = annualRemaining + sickRemaining + personalRemaining;

                        return (
                          <TableRow key={balance.uuid}>
                            <TableCell className="font-medium">
                              {balance.employee?.name || "N/A"}
                            </TableCell>
                            <TableCell>{balance.employee?.nik_employee || "-"}</TableCell>
                            <TableCell>{balance.employee?.position_name || "-"}</TableCell>
                            <TableCell>{balance.employee?.department_description || "-"}</TableCell>
                            
                            <TableCell>
                              <div className="text-sm">
                                <div className="flex justify-between">
                                  <span>Total:</span>
                                  <span>{balance.annual_total} hari</span>
                                </div>
                                <div className="flex justify-between">
                                  <span>Terpakai:</span>
                                  <span>{balance.annual_used} hari</span>
                                </div>
                                <div className={`flex justify-between ${getStatusColor(getBalanceStatus(annualRemaining))}`}>
                                  <span>Sisa:</span>
                                  <span>{annualRemaining} hari</span>
                                </div>
                              </div>
                            </TableCell>
                            <TableCell>
                              <div className="text-sm">
                                <div className="flex justify-between">
                                  <span>Total:</span>
                                  <span>{balance.sick_total} hari</span>
                                </div>
                                <div className="flex justify-between">
                                  <span>Terpakai:</span>
                                  <span>{balance.sick_used} hari</span>
                                </div>
                                <div className={`flex justify-between ${getStatusColor(getBalanceStatus(sickRemaining))}`}>
                                  <span>Sisa:</span>
                                  <span>{sickRemaining} hari</span>
                                </div>
                              </div>
                            </TableCell>
                            <TableCell>
                              <div className="text-sm">
                                <div className="flex justify-between">
                                  <span>Total:</span>
                                  <span>{balance.personal_total} hari</span>
                                </div>
                                <div className="flex justify-between">
                                  <span>Terpakai:</span>
                                  <span>{balance.personal_used} hari</span>
                                </div>
                                <div className={`flex justify-between ${getStatusColor(getBalanceStatus(personalRemaining))}`}>
                                  <span>Sisa:</span>
                                  <span>{personalRemaining} hari</span>
                                </div>
                              </div>
                            </TableCell>
                            <TableCell>
                              <div className={`text-center font-bold text-lg ${getStatusColor(getBalanceStatus(totalRemaining))}`}>
                                {totalRemaining} hari
                              </div>
                            </TableCell>
                            <TableCell>
                              <Badge className={
                                totalRemaining <= 0 ? "bg-red-500" : 
                                totalRemaining <= 5 ? "bg-orange-500" : 
                                "bg-green-500"
                              }>
                                {totalRemaining <= 0 ? "Habis" : 
                                 totalRemaining <= 5 ? "Menipis" : 
                                 "Aman"}
                              </Badge>
                            </TableCell>
                            <TableCell>
                              <div className="flex gap-2">
                                <Button
                                  size="sm"
                                  variant="outline"
                                  onClick={() => openEditBalanceModal(balance)}
                                >
                                  ✏️ Koreksi
                                </Button>
                                <Button
                                  size="sm"
                                  variant="outline"
                                  onClick={() => handleResetBalance(balance.uuid)}
                                >
                                  🔄 Reset
                                </Button>
                              </div>
                            </TableCell>
                          </TableRow>
                        );
                      })
                    )}
                  </TableBody>
                </Table>
              </div>

              {meta && meta.last_page > 1 && (
                <div className="flex justify-between items-center mt-4">
                  <Button
                    variant="outline"
                    disabled={meta.current_page === 1}
                    onClick={() => fetchLeaveBalances(meta.current_page - 1, search)}
                  >
                    ← Previous
                  </Button>
                  <span className="text-sm">
                    Page {meta.current_page} of {meta.last_page} 
                    ({meta.total} total records)
                  </span>
                  <Button
                    variant="outline"
                    disabled={meta.current_page === meta.last_page}
                    onClick={() => fetchLeaveBalances(meta.current_page + 1, search)}
                  >
                    Next →
                  </Button>
                </div>
              )}
            </>
          )}
        </CardContent>
      </Card>

      {/* Modal untuk Edit Saldo Cuti */}
      <Dialog open={balanceEditModalOpen} onOpenChange={setBalanceEditModalOpen}>
        <DialogContent className="max-w-[95vw] sm:max-w-2xl">
          <DialogHeader>
            <DialogTitle>Koreksi Saldo Cuti</DialogTitle>
            <DialogDescription>
              Edit saldo cuti untuk {selectedBalance?.employee?.name}
            </DialogDescription>
          </DialogHeader>

          <form onSubmit={handleBalanceSubmit} className="space-y-6">
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
              {/* Cuti Tahunan */}
              <Card>
                <CardHeader className="pb-3">
                  <CardTitle className="text-sm">Cuti Tahunan</CardTitle>
                </CardHeader>
                <CardContent className="space-y-2">
                  <div className="space-y-1">
                    <Label htmlFor="annual_total">Total</Label>
                    <Input
                      type="number"
                      id="annual_total"
                      value={balanceFormData.annual_total}
                      onChange={(e) => setBalanceFormData(prev => ({
                        ...prev,
                        annual_total: parseInt(e.target.value) || 0
                      }))}
                      min="0"
                      className="text-sm"
                    />
                  </div>
                  <div className="space-y-1">
                    <Label htmlFor="annual_used">Terpakai</Label>
                    <Input
                      type="number"
                      id="annual_used"
                      value={balanceFormData.annual_used}
                      onChange={(e) => setBalanceFormData(prev => ({
                        ...prev,
                        annual_used: parseInt(e.target.value) || 0
                      }))}
                      min="0"
                      max={balanceFormData.annual_total}
                      className="text-sm"
                    />
                  </div>
                  <div className="pt-2 border-t">
                    <Label className="font-semibold text-sm">
                      Sisa: {calculateRemaining(balanceFormData.annual_total, balanceFormData.annual_used)} hari
                    </Label>
                  </div>
                </CardContent>
              </Card>

              {/* Cuti Sakit */}
              <Card>
                <CardHeader className="pb-3">
                  <CardTitle className="text-sm">Cuti Sakit</CardTitle>
                </CardHeader>
                <CardContent className="space-y-2">
                  <div className="space-y-1">
                    <Label htmlFor="sick_total">Total</Label>
                    <Input
                      type="number"
                      id="sick_total"
                      value={balanceFormData.sick_total}
                      onChange={(e) => setBalanceFormData(prev => ({
                        ...prev,
                        sick_total: parseInt(e.target.value) || 0
                      }))}
                      min="0"
                      className="text-sm"
                    />
                  </div>
                  <div className="space-y-1">
                    <Label htmlFor="sick_used">Terpakai</Label>
                    <Input
                      type="number"
                      id="sick_used"
                      value={balanceFormData.sick_used}
                      onChange={(e) => setBalanceFormData(prev => ({
                        ...prev,
                        sick_used: parseInt(e.target.value) || 0
                      }))}
                      min="0"
                      max={balanceFormData.sick_total}
                      className="text-sm"
                    />
                  </div>
                  <div className="pt-2 border-t">
                    <Label className="font-semibold text-sm">
                      Sisa: {calculateRemaining(balanceFormData.sick_total, balanceFormData.sick_used)} hari
                    </Label>
                  </div>
                </CardContent>
              </Card>

              {/* Cuti Pribadi */}
              <Card>
                <CardHeader className="pb-3">
                  <CardTitle className="text-sm">Cuti Pribadi</CardTitle>
                </CardHeader>
                <CardContent className="space-y-2">
                  <div className="space-y-1">
                    <Label htmlFor="personal_total">Total</Label>
                    <Input
                      type="number"
                      id="personal_total"
                      value={balanceFormData.personal_total}
                      onChange={(e) => setBalanceFormData(prev => ({
                        ...prev,
                        personal_total: parseInt(e.target.value) || 0
                      }))}
                      min="0"
                      className="text-sm"
                    />
                  </div>
                  <div className="space-y-1">
                    <Label htmlFor="personal_used">Terpakai</Label>
                    <Input
                      type="number"
                      id="personal_used"
                      value={balanceFormData.personal_used}
                      onChange={(e) => setBalanceFormData(prev => ({
                        ...prev,
                        personal_used: parseInt(e.target.value) || 0
                      }))}
                      min="0"
                      max={balanceFormData.personal_total}
                      className="text-sm"
                    />
                  </div>
                  <div className="pt-2 border-t">
                    <Label className="font-semibold text-sm">
                      Sisa: {calculateRemaining(balanceFormData.personal_total, balanceFormData.personal_used)} hari
                    </Label>
                  </div>
                </CardContent>
              </Card>
            </div>

            {/* Summary */}
            <Card>
              <CardHeader>
                <CardTitle className="text-sm">Summary Total</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 text-center">
                  <div>
                    <Label className="text-sm text-gray-500">Total Hak Cuti</Label>
                    <p className="text-lg sm:text-xl font-bold text-blue-600">
                      {balanceFormData.annual_total + balanceFormData.sick_total + balanceFormData.personal_total} hari
                    </p>
                  </div>
                  <div>
                    <Label className="text-sm text-gray-500">Total Terpakai</Label>
                    <p className="text-lg sm:text-xl font-bold text-orange-600">
                      {balanceFormData.annual_used + balanceFormData.sick_used + balanceFormData.personal_used} hari
                    </p>
                  </div>
                  <div>
                    <Label className="text-sm text-gray-500">Total Sisa</Label>
                    <p className="text-lg sm:text-xl font-bold text-green-600">
                      {calculateRemaining(balanceFormData.annual_total, balanceFormData.annual_used) +
                       calculateRemaining(balanceFormData.sick_total, balanceFormData.sick_used) +
                       calculateRemaining(balanceFormData.personal_total, balanceFormData.personal_used)} hari
                    </p>
                  </div>
                </div>
              </CardContent>
            </Card>

            <div className="flex flex-col sm:flex-row gap-2 pt-4">
              <Button 
                type="button" 
                variant="outline" 
                onClick={() => setBalanceEditModalOpen(false)}
                disabled={isProcessing}
                className="flex-1"
              >
                Batal
              </Button>
              <Button 
                type="submit" 
                disabled={isProcessing}
                className="flex-1"
              >
                {isProcessing ? 'Menyimpan...' : 'Update Saldo'}
              </Button>
            </div>
          </form>
        </DialogContent>
      </Dialog>
    </div>
  );
};

export default LeaveBalancePage;