"use client";

import { useEffect, useState } from "react";
import Swal from "sweetalert2";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Tabs, TabsList, TabsTrigger, TabsContent } from "@/components/ui/tabs";
import { Calendar as CalendarIcon, CheckCircle } from "lucide-react";
import api_laravel from "@/lib/utils";

interface Employee {
  uuid: string;
  name: string;
  avatar?: string;
  department_description?: string;
}

interface Attendance {
  id: number;
  employee_uuid: string;
  date: string;
  clock_in: string | null;
  clock_out: string | null;
  status?: string;
}

export function Corection() {
  const [employees, setEmployees] = useState<Employee[]>([]);
  const [selectedEmployee, setSelectedEmployee] = useState<string>("");
  const [selectedDate, setSelectedDate] = useState<string>("");
  const [attendance, setAttendance] = useState<Attendance | null>(null);
  const [loading, setLoading] = useState<boolean>(true);
  const [searchLoading, setSearchLoading] = useState<boolean>(false);
  const [submitting, setSubmitting] = useState<boolean>(false);

  // Form koreksi
  const [checkIn, setCheckIn] = useState<string>("");
  const [checkOut, setCheckOut] = useState<string>("");
  const [status, setStatus] = useState<string>("Present");

  // Fetch awal: employee list
  useEffect(() => {
    const fetchData = async () => {
      try {
        const resEmp = await api_laravel.get("/api/employees");
        const list = resEmp.data?.data?.data ?? [];
        setEmployees(list);
      } catch (err: any) {
        Swal.fire("Error", err.response?.data?.message || "Gagal memuat data karyawan", "error");
      } finally {
        setLoading(false);
      }
    };
    fetchData();
  }, []);

  // ✅ FUNGSI PERBAIKAN: Format waktu dari database untuk input time
// ✅ FUNGSI PERBAIKAN: Format waktu dari database untuk input time
const formatTimeFromDatabase = (timeStr: string | null): string => {
  console.log("🔄 Processing time from database:", timeStr);
  
  if (!timeStr || timeStr === "" || timeStr === "null") {
    return "";
  }
  
  // Jika waktu adalah "00:00:00", anggap sebagai tidak ada data
  if (timeStr === "00:00:00") {
    return "";
  }
  
  // Handle berbagai format waktu dari database
  const timeParts = timeStr.split(':');
  
  if (timeParts.length >= 2) {
    const hours = timeParts[0].padStart(2, '0');
    const minutes = timeParts[1].padStart(2, '0');
    const formattedTime = `${hours}:${minutes}`;
    
    console.log("✅ Formatted time for input:", formattedTime);
    return formattedTime;
  }
  
  console.log("❌ Could not format time:", timeStr);
  return "";
};

  // ✅ FUNGSI PERBAIKAN: Format untuk dikirim ke database
  const formatTimeForDatabase = (timeStr: string): string | null => {
    if (!timeStr || timeStr === "") {
      return null;
    }
    
    const timeParts = timeStr.split(':');
    if (timeParts.length >= 2) {
      const hours = timeParts[0].padStart(2, '0');
      const minutes = timeParts[1].padStart(2, '0');
      return `${hours}:${minutes}:00`;
    }
    
    return null;
  };

  const handleSearchAttendance = async () => {
  if (!selectedEmployee || !selectedDate) {
    return Swal.fire("Warning", "Pilih karyawan dan tanggal terlebih dahulu", "warning");
  }

  setSearchLoading(true);
  try {
    const res = await api_laravel.get("/api/attendances/getAttendanceForCorrection", {
      params: {
        employee_uuid: selectedEmployee,
        date: selectedDate,
      },
    });

    console.log("📊 Response API Koreksi:", res.data);

    if (!res.data.success) {
      Swal.fire("Error", res.data.message || "Gagal mengambil data absensi", "error");
      setAttendance(null);
      setCheckIn("");
      setCheckOut("");
      setStatus("Present");
      return;
    }

    const data = res.data.data;
    console.log("🎯 Data dari API Koreksi:", data);
    console.log("🎯 Clock In raw:", data.clock_in);
    console.log("🎯 Clock Out raw:", data.clock_out);

    // Format waktu dari database
    const formattedCheckIn = formatTimeFromDatabase(data.clock_in);
    const formattedCheckOut = formatTimeFromDatabase(data.clock_out);

    console.log("🕒 Check In formatted:", formattedCheckIn);
    console.log("🕒 Check Out formatted:", formattedCheckOut);

    // Buat objek attendance
    const attendanceData: Attendance = {
      id: data.id,
      employee_uuid: data.employee_uuid,
      date: data.date,
      clock_in: data.clock_in,
      clock_out: data.clock_out,
      status: data.status || "Present"
    };

    setAttendance(attendanceData);
    setCheckIn(formattedCheckIn);
    setCheckOut(formattedCheckOut);
    setStatus(data.status || "Present");

    // Tampilkan pesan sukses
    if (data.exists) {
      Swal.fire({
        title: "Data Ditemukan!",
        text: "Data absensi berhasil ditemukan",
        icon: "success",
        timer: 3000
      });
    } else {
      Swal.fire({
        title: "Data Baru",
        text: "Tidak ada data absensi. Silakan buat data baru.",
        icon: "info",
        timer: 3000
      });
    }

  } catch (err: any) {
    console.error("❌ Error fetching attendance:", err);
    console.error("❌ Error response:", err.response?.data);
    Swal.fire("Error", err.response?.data?.message || "Gagal mengambil data absensi", "error");
  } finally {
    setSearchLoading(false);
  }
};

const handleSubmitCorrection = async () => {
  if (!attendance) return;

  setSubmitting(true);
  try {
    // ✅ GUNAKAN API BARU untuk update
    const endpoint = `/api/attendances/attendance-correction/${attendance.id || attendance.employee_uuid}`;
    console.log("📤 Updating attendance at:", endpoint);
    
    const payload: any = {
      status,
      date: selectedDate,
    };

    // Hanya tambahkan clock_in/clock_out jika ada nilai
    if (checkIn) {
      payload.clock_in = formatTimeForDatabase(checkIn);
    }
    if (checkOut) {
      payload.clock_out = formatTimeForDatabase(checkOut);
    }

    // Jika tidak ada ID, kirim employee_uuid untuk membuat data baru
    if (!attendance.id) {
      payload.employee_uuid = attendance.employee_uuid;
    }

    console.log("📤 Payload untuk update:", payload);

    const response = await api_laravel.put(endpoint, payload);
    console.log("✅ Response from server:", response.data);

    Swal.fire("Success", response.data.message || "Absensi berhasil dikoreksi", "success");
    
    // Update local state
    const updatedAttendance: Attendance = { 
      ...attendance, 
      id: response.data.data.id || attendance.id,
      clock_in: payload.clock_in || null, 
      clock_out: payload.clock_out || null, 
      status 
    };
    setAttendance(updatedAttendance);
    
  } catch (err: any) {
    console.error("❌ Error updating attendance:", err);
    console.error("❌ Error response:", err.response?.data);
    Swal.fire("Error", err.response?.data?.message || "Gagal mengupdate absensi", "error");
  } finally {
    setSubmitting(false);
  }
};

  // ✅ FUNGSI TAMBAHAN: Reset form
  const handleResetForm = () => {
    setSelectedEmployee("");
    setSelectedDate("");
    setAttendance(null);
    setCheckIn("");
    setCheckOut("");
    setStatus("Present");
  };

  if (loading) return <p>Loading data karyawan...</p>;

  return (
    <div className="space-y-6 animate-fade-in">
      <Card className="card-dashboard">
        <CardHeader>
          <CardTitle>Koreksi Absensi</CardTitle>
          <p className="text-muted-foreground">
            Pilih karyawan dan tanggal untuk melihat atau memperbaiki absensi
          </p>
        </CardHeader>
      </Card>

      <Tabs defaultValue="correction">
        <TabsList className="grid w-full grid-cols-1 md:grid-cols-2">
          <TabsTrigger value="correction">Koreksi Absensi</TabsTrigger>
          <TabsTrigger value="history">Riwayat Absensi</TabsTrigger>
        </TabsList>

        {/* Koreksi Form */}
        <TabsContent value="correction">
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center">
                <CalendarIcon className="h-5 w-5 mr-2 text-primary" />
                Form Koreksi
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              {/* Pilih Employee */}
              <div>
                <label className="block text-sm font-medium mb-1">Pilih Karyawan</label>
                <Select
                  value={selectedEmployee}
                  onValueChange={(val) => setSelectedEmployee(val)}
                >
                  <SelectTrigger>
                    <SelectValue placeholder="Pilih karyawan" />
                  </SelectTrigger>
                  <SelectContent>
                    {employees.map((emp) => (
                      <SelectItem key={emp.uuid} value={String(emp.uuid)}>
                        {emp.name} {emp.department_description && `(${emp.department_description})`}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>

              {/* Pilih Tanggal */}
              <div>
                <label className="block text-sm font-medium mb-1">Tanggal</label>
                <Input
                  type="date"
                  value={selectedDate}
                  onChange={(e) => setSelectedDate(e.target.value)}
                  max={new Date().toISOString().split('T')[0]} // Tidak bisa memilih tanggal future
                />
              </div>

              <div className="flex gap-2">
                <Button 
                  onClick={handleSearchAttendance} 
                  className="bg-blue-600 hover:bg-blue-700 text-white flex-1"
                  type="button"
                  disabled={searchLoading || !selectedEmployee || !selectedDate}
                >
                  {searchLoading ? "Mencari..." : "Cari Absensi"}
                </Button>
                
                <Button 
                  onClick={handleResetForm}
                  variant="outline"
                  type="button"
                >
                  Reset
                </Button>
              </div>

              {attendance && (
                <div className="mt-6 space-y-4 border-t pt-4">
                  <div className="flex items-center justify-between">
                    <h3 className="font-semibold text-lg">Detail Absensi</h3>
                    <div className="flex items-center text-sm text-green-600">
                      <CheckCircle className="h-4 w-4 mr-1" />
                      Data Ditemukan
                    </div>
                  </div>
                  
                  {/* Info Karyawan dan Tanggal */}
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
                    <div>
                      <label className="text-sm font-medium text-gray-600">Karyawan</label>
                      <p className="font-semibold">
                        {employees.find(emp => emp.uuid === selectedEmployee)?.name}
                      </p>
                    </div>
                    <div>
                      <label className="text-sm font-medium text-gray-600">Tanggal</label>
                      <p className="font-semibold">
                        {new Date(selectedDate).toLocaleDateString('id-ID', {
                          weekday: 'long',
                          year: 'numeric',
                          month: 'long',
                          day: 'numeric'
                        })}
                      </p>
                    </div>
                  </div>

                  {/* Status Saat Ini */}
                  <div className="bg-blue-50 p-3 rounded-md">
                    <h4 className="font-medium text-sm text-blue-600 mb-2">Status Saat Ini:</h4>
                    <div className="flex items-center">
                      <span className={`px-3 py-1 rounded-full text-xs font-medium ${
                        attendance.status === 'Present' ? 'bg-green-100 text-green-800' :
                        attendance.status === 'Late' ? 'bg-yellow-100 text-yellow-800' :
                        attendance.status === 'Absent' ? 'bg-red-100 text-red-800' :
                        'bg-blue-100 text-blue-800'
                      }`}>
                        {attendance.status === 'Present' ? 'Hadir' :
                         attendance.status === 'Late' ? 'Terlambat' :
                         attendance.status === 'Absent' ? 'Tidak Hadir' :
                         attendance.status === 'Leave' ? 'Cuti' :
                         attendance.status === 'Sick' ? 'Sakit' : attendance.status}
                      </span>
                    </div>
                  </div>

                  {/* Data Asli dari Database */}
                  {/* // Di dalam JSX, ganti bagian yang menampilkan data asli: */}
                    <div className="bg-gray-50 p-3 rounded-md">
                    <h4 className="font-medium text-sm text-gray-600 mb-2">Data dari Database:</h4>
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-3 text-sm">
                        <div>
                        <span className="text-gray-500">Clock In: </span>
                        <span className="font-mono">
                            {attendance.clock_in && attendance.clock_in !== "00:00:00" ? (
                            <span className="text-green-600">{attendance.clock_in}</span>
                            ) : (
                            <span className="text-orange-500">Belum diisi</span>
                            )}
                        </span>
                        </div>
                        <div>
                        <span className="text-gray-500">Clock Out: </span>
                        <span className="font-mono">
                            {attendance.clock_out && attendance.clock_out !== "00:00:00" ? (
                            <span className="text-green-600">{attendance.clock_out}</span>
                            ) : (
                            <span className="text-orange-500">Belum diisi</span>
                            )}
                        </span>
                        </div>
                    </div>
                    </div>

                  {/* Form Koreksi */}
                  <div className="space-y-4">
                    <h4 className="font-medium text-lg">Form Koreksi</h4>
                    
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                      <div>
                        <label className="block text-sm font-medium mb-1">Jam Masuk</label>
                        <Input 
                          type="time" 
                          value={checkIn} 
                          onChange={(e) => setCheckIn(e.target.value)} 
                          placeholder="HH:MM"
                        />
                        {attendance.clock_in && attendance.clock_in !== "00:00:00" && (
                          <p className="text-xs text-green-600 mt-1">
                            Data saat ini: {attendance.clock_in}
                          </p>
                        )}
                      </div>
                      <div>
                        <label className="block text-sm font-medium mb-1">Jam Keluar</label>
                        <Input 
                          type="time" 
                          value={checkOut} 
                          onChange={(e) => setCheckOut(e.target.value)} 
                          placeholder="HH:MM"
                        />
                        {attendance.clock_out && attendance.clock_out !== "00:00:00" && (
                          <p className="text-xs text-green-600 mt-1">
                            Data saat ini: {attendance.clock_out}
                          </p>
                        )}
                      </div>
                    </div>
                    
                    <div>
                      <label className="block text-sm font-medium mb-1">Status</label>
                      <Select value={status} onValueChange={setStatus}>
                        <SelectTrigger>
                          <SelectValue placeholder="Pilih status" />
                        </SelectTrigger>
                        <SelectContent>
                          <SelectItem value="Present">Hadir</SelectItem>
                          <SelectItem value="Late">Terlambat</SelectItem>
                          <SelectItem value="Absent">Tidak Hadir</SelectItem>
                          <SelectItem value="Leave">Cuti</SelectItem>
                          <SelectItem value="Sick">Sakit</SelectItem>
                        </SelectContent>
                      </Select>
                    </div>

                    <Button
                      onClick={handleSubmitCorrection}
                      disabled={submitting}
                      className="bg-green-600 hover:bg-green-700 text-white w-full"
                      type="button"
                    >
                      {submitting ? "Menyimpan..." : "Simpan Koreksi"}
                    </Button>
                  </div>
                </div>
              )}
            </CardContent>
          </Card>
        </TabsContent>

        {/* Riwayat Absensi */}
        <TabsContent value="history">
          <Card>
            <CardHeader>
              <CardTitle>Riwayat Absensi</CardTitle>
            </CardHeader>
            <CardContent>
              <p className="text-muted-foreground">Fitur riwayat absensi akan segera tersedia.</p>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  );
}

export default Corection;