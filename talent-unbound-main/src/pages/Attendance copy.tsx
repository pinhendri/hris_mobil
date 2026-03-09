"use client";

import { useState, useEffect } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import api_laravel from "@/lib/utils";
import Swal from "sweetalert2";

interface Employee {
  uuid: string | null;
  name: string;
  position: string | null;
  nik_employee: string | null;
}

interface Attendance {
  uuid: string | null;
  employee: Employee;
  date: string;
  clock_in: string | null;
  clock_out: string | null;
  clock_in_photo: string | null;
  clock_in_location: string | null;
  clock_out_photo: string | null;
  clock_out_location: string | null;
}

interface Meta {
  current_page: number;
  last_page: number;
  per_page: number;
  total: number;
}

interface ApiResponse {
  success: boolean;
  message: string;
  data: {
    data: Attendance[];
    meta: Meta;
  };
}

const MAX_DISTANCE_METERS = 500;
const MAX_GPS_ACCURACY = 10000;
const DEFAULT_LOCATION = { lat: 0, lng: 0 };

// Generate unique key untuk setiap row
const generateRowKey = (att: Attendance, index: number) => {
  return att.employee?.uuid || att.employee?.name || `attendance-${index}`;
};

const getDistance = (lat1: number, lon1: number, lat2: number, lon2: number) => {
  const R = 6371e3;
  const φ1 = (lat1 * Math.PI) / 180;
  const φ2 = (lat2 * Math.PI) / 180;
  const Δφ = ((lat2 - lat1) * Math.PI) / 180;
  const Δλ = ((lon2 - lon1) * Math.PI) / 180;

  const a =
    Math.sin(Δφ / 2) ** 2 +
    Math.cos(φ1) * Math.cos(φ2) * Math.sin(Δλ / 2) ** 2;
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

  return R * c;
};

const formatTime = (datetime: string | null) => {
  if (!datetime) return "-";
  
  // Coba parse sebagai ISO string
  if (datetime.includes('T')) {
    const timePart = datetime.split('T')[1];
    if (timePart) return timePart.split('.')[0];
  }
  
  // Jika format lain, return as-is
  return datetime;
};

const getStablePosition = async (samples = 3, delayMs = 500) => {
  const positions: GeolocationCoordinates[] = [];

  for (let i = 0; i < samples; i++) {
    try {
      const pos = await new Promise<GeolocationPosition>((resolve, reject) =>
        navigator.geolocation.getCurrentPosition(resolve, reject, {
          enableHighAccuracy: true,
          timeout: 10000,
          maximumAge: 0
        })
      );
      positions.push(pos.coords);
      if (i < samples - 1) {
        await new Promise((res) => setTimeout(res, delayMs));
      }
    } catch (error) {
      throw new Error("Gagal mendapatkan lokasi GPS. Pastikan GPS aktif dan izin lokasi diberikan.");
    }
  }

  const avgLat = positions.reduce((a, c) => a + c.latitude, 0) / positions.length;
  const avgLng = positions.reduce((a, c) => a + c.longitude, 0) / positions.length;
  const avgAccuracy = positions.reduce((a, c) => a + c.accuracy, 0) / positions.length;

  if (avgAccuracy > MAX_GPS_ACCURACY) {
    Swal.fire({
      icon: "warning",
      title: "Akurasi GPS rendah",
      text: `Akurasi GPS: ${Math.round(avgAccuracy)} meter. Silakan cari lokasi dengan sinyal GPS yang lebih baik.`,
    });
  }

  return { latitude: avgLat, longitude: avgLng, accuracy: avgAccuracy };
};

const Attendance = () => {
  const [attendances, setAttendances] = useState<Attendance[]>([]);
  const [meta, setMeta] = useState<Meta | null>(null);
  const [loading, setLoading] = useState(false);
  const [page, setPage] = useState(1);

  const fetchAttendance = async (pageNumber = 1) => {
    try {
      setLoading(true);
      const res = await api_laravel.get<ApiResponse>(`/api/attendances?page=${pageNumber}`);

      if (res.data?.success) {
        setAttendances(res.data.data.data || []);
        setMeta(res.data.data.meta || null);
        setPage(res.data.data.meta?.current_page || 1);
      } else {
        Swal.fire("Error", "Gagal memuat data attendance", "error");
      }
    } catch (error: any) {
      console.error("Fetch attendance error:", error);
      Swal.fire("Error", error.response?.data?.message || "Gagal mengambil data attendance", "error");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchAttendance(page);
  }, []);

 // Di frontend, update fetchClientLocation
const fetchClientLocation = async (employee_uuid: string | null) => {
  if (!employee_uuid) {
    return DEFAULT_LOCATION;
  }
  
  try {
    const res = await api_laravel.get(`/api/employees/${employee_uuid}/client-location`);
    
    if (res.data?.success) {
      console.log(`Lokasi diambil dari: ${res.data.data.source}`);
      return res.data.data;
    } else {
      console.warn('Gagal mengambil lokasi client, menggunakan default');
      return DEFAULT_LOCATION;
    }
  } catch (error) {
    console.error('Error fetching client location:', error);
    return DEFAULT_LOCATION;
  }
};

  const handleClockIn = async (employee_uuid: string | null) => {
    if (!employee_uuid) {
      Swal.fire("Error", "Employee UUID tidak valid", "error");
      return;
    }

    try {
      // Cek izin kamera dan lokasi
      await navigator.mediaDevices.getUserMedia({ video: true });
      
      const clientLocation = await fetchClientLocation(employee_uuid);
      const { latitude, longitude, accuracy } = await getStablePosition();

      // Validasi lokasi hanya jika client location tersedia
      if (clientLocation.lat && clientLocation.lng && clientLocation.lat !== 0 && clientLocation.lng !== 0) {
        const distance = getDistance(latitude, longitude, clientLocation.lat, clientLocation.lng);
        
        if (distance > MAX_DISTANCE_METERS) {
          Swal.fire({
            icon: "warning",
            title: "Di luar lokasi yang diizinkan",
            html: `Anda berada <b>${Math.round(distance)} meter</b> dari lokasi client.<br>
                  Maksimal jarak: ${MAX_DISTANCE_METERS} meter.<br>
                  Akurasi GPS: ${Math.round(accuracy)} meter.`,
            confirmButtonText: "Tetap Clock In",
            showCancelButton: true,
            cancelButtonText: "Batal"
          }).then((result) => {
            if (!result.isConfirmed) return;
            proceedWithClockIn(employee_uuid, latitude, longitude);
          });
          return;
        }
      }

      await proceedWithClockIn(employee_uuid, latitude, longitude);
      
    } catch (error: any) {
      if (error.name === 'NotAllowedError') {
        Swal.fire("Error", "Izin kamera atau lokasi ditolak. Silakan berikan izin untuk melanjutkan.", "error");
      } else {
        Swal.fire("Error", error.message || "Clock In gagal", "error");
      }
    }
  };

  const proceedWithClockIn = async (employee_uuid: string, latitude: number, longitude: number) => {
    try {
      // Capture foto
      const stream = await navigator.mediaDevices.getUserMedia({ 
        video: { width: 640, height: 480 } 
      });
      
      const video = document.createElement("video");
      video.srcObject = stream;
      
      await new Promise((resolve) => {
        video.onloadedmetadata = () => {
          video.play();
          resolve(true);
        };
      });

      // Tunggu beberapa detik untuk kamerastabil
      await new Promise(resolve => setTimeout(resolve, 1000));

      const canvas = document.createElement("canvas");
      canvas.width = 320;
      canvas.height = 240;
      const ctx = canvas.getContext("2d");
      if (!ctx) throw new Error("Gagal mengambil foto");
      
      ctx.drawImage(video, 0, 0, canvas.width, canvas.height);
      const photo = canvas.toDataURL("image/jpeg", 0.8);
      
      // Stop stream
      stream.getTracks().forEach((track) => track.stop());

      // Kirim data ke server
      await api_laravel.post("/api/attendances/clock-in", {
        employee_uuid,
        photo,
        location: `${latitude},${longitude}`,
        latitude,
        longitude
      });

      Swal.fire({
        icon: "success",
        title: "Clock In Berhasil",
        timer: 2000,
        showConfirmButton: false,
      });

      fetchAttendance(page);
    } catch (error: any) {
      throw new Error(error.message || "Gagal proses Clock In");
    }
  };

  const handleClockOut = async (employee_uuid: string | null) => {
    if (!employee_uuid) {
      Swal.fire("Error", "Employee UUID tidak valid", "error");
      return;
    }

    try {
      await api_laravel.post("/api/attendances/clock-out", { 
        employee_uuid 
      });

      Swal.fire({
        icon: "success",
        title: "Clock Out Berhasil",
        timer: 2000,
        showConfirmButton: false,
      });

      fetchAttendance(page);
    } catch (error: any) {
      Swal.fire("Error", error.response?.data?.message || "Clock Out gagal", "error");
    }
  };

  const checkMyLocation = async () => {
    try {
      const { latitude, longitude, accuracy } = await getStablePosition();
      const mapUrl = `https://maps.google.com/maps?q=${latitude},${longitude}&z=17&hl=id&output=embed`;

      Swal.fire({
        icon: "info",
        title: "Lokasi Anda Saat Ini",
        html: `
          <div style="text-align: left; margin-bottom: 15px;">
            <b>Latitude:</b> ${latitude.toFixed(6)}<br>
            <b>Longitude:</b> ${longitude.toFixed(6)}<br>
            <b>Akurasi:</b> ${Math.round(accuracy)} meter
          </div>
          <iframe 
            width="100%" 
            height="300" 
            frameborder="0" 
            style="border: 1px solid #ddd; border-radius: 8px;" 
            src="${mapUrl}" 
            allowfullscreen>
          </iframe>
        `,
        width: 600,
        confirmButtonText: "Tutup"
      });
    } catch (error: any) {
      Swal.fire("Error", error.message || "Gagal mengambil lokasi", "error");
    }
  };

  return (
    <Card>
      <CardHeader className="flex flex-row items-center justify-between">
        <CardTitle>Attendance / Time Tracking</CardTitle>
        <Button onClick={checkMyLocation} variant="outline">
          📍 Cek Lokasi Saya
        </Button>
      </CardHeader>
      <CardContent>
        {loading ? (
          <div className="text-center py-8">
            <p>Loading data attendance...</p>
          </div>
        ) : (
          <>
            <div className="rounded-md border">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Nama Karyawan</TableHead>
                    <TableHead>Posisi</TableHead>
                    <TableHead>Tanggal</TableHead>
                    <TableHead>Clock In</TableHead>
                    <TableHead>Clock Out</TableHead>
                    <TableHead>Foto</TableHead>
                    <TableHead>Lokasi</TableHead>
                    <TableHead>Aksi</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {attendances.length === 0 ? (
                    <TableRow>
                      <TableCell colSpan={8} className="text-center py-8 text-muted-foreground">
                        Tidak ada data attendance
                      </TableCell>
                    </TableRow>
                  ) : (
                    attendances.map((att, index) => (
                      <TableRow key={generateRowKey(att, index)}>
                        <TableCell className="font-medium">
                          {att.employee?.name || "Unknown"}
                        </TableCell>
                        <TableCell>{att.employee?.position || "-"}</TableCell>
                        <TableCell>{att.date}</TableCell>
                        <TableCell>{formatTime(att.clock_in)}</TableCell>
                        <TableCell>{formatTime(att.clock_out)}</TableCell>
                        <TableCell>
                          {att.clock_in_photo ? (
                            <img 
                              src={att.clock_in_photo} 
                              width={50} 
                              height={50}
                              alt="Clock In" 
                              className="rounded border"
                            />
                          ) : (
                            "-"
                          )}
                        </TableCell>
                        <TableCell className="text-xs">
                          {att.clock_in_location || "-"}
                        </TableCell>
                        <TableCell>
                          <div className="flex gap-2">
                            {!att.clock_in && (
                              <Button
                                size="sm"
                                onClick={() => handleClockIn(att.employee?.uuid)}
                                disabled={!att.employee?.uuid}
                              >
                                🟢 Clock In
                              </Button>
                            )}
                            {att.clock_in && !att.clock_out && (
                              <Button
                                size="sm"
                                variant="outline"
                                onClick={() => handleClockOut(att.employee?.uuid)}
                                disabled={!att.employee?.uuid}
                              >
                                🔴 Clock Out
                              </Button>
                            )}
                            {att.clock_in && att.clock_out && (
                              <span className="text-sm text-muted-foreground">Selesai</span>
                            )}
                          </div>
                        </TableCell>
                      </TableRow>
                    ))
                  )}
                </TableBody>
              </Table>
            </div>

            {meta && meta.last_page > 1 && (
              <div className="flex justify-between items-center mt-4">
                <Button
                  variant="outline"
                  disabled={meta.current_page === 1}
                  onClick={() => fetchAttendance(meta.current_page - 1)}
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
                  onClick={() => fetchAttendance(meta.current_page + 1)}
                >
                  Next →
                </Button>
              </div>
            )}
          </>
        )}
      </CardContent>
    </Card>
  );
};

export default Attendance;