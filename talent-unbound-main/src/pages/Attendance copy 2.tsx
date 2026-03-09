"use client";

import { useState, useEffect } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription } from "@/components/ui/dialog";
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

interface ClientLocation {
  lat: number;
  lng: number;
  address?: string;
  source?: string;
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
  
  // State untuk modal
  const [modalOpen, setModalOpen] = useState(false);
  const [modalType, setModalType] = useState<'clockin' | 'clockout'>('clockin');
  const [selectedEmployee, setSelectedEmployee] = useState<Employee | null>(null);
  const [currentLocation, setCurrentLocation] = useState<{lat: number; lng: number; accuracy: number} | null>(null);
  const [clientLocation, setClientLocation] = useState<ClientLocation | null>(null);
  const [distance, setDistance] = useState<number | null>(null);
  const [cameraStream, setCameraStream] = useState<MediaStream | null>(null);
  const [capturedPhoto, setCapturedPhoto] = useState<string | null>(null);
  const [isProcessing, setIsProcessing] = useState(false);

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

  const fetchClientLocation = async (employee_uuid: string | null): Promise<ClientLocation> => {
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

  const openCamera = async () => {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ 
        video: { width: 640, height: 480, facingMode: "user" } 
      });
      setCameraStream(stream);
    } catch (error) {
      throw new Error("Gagal mengakses kamera. Pastikan izin kamera diberikan.");
    }
  };

  const closeCamera = () => {
    if (cameraStream) {
      cameraStream.getTracks().forEach(track => track.stop());
      setCameraStream(null);
    }
  };

  const capturePhoto = () => {
    if (!cameraStream) return;

    const video = document.createElement("video");
    video.srcObject = cameraStream;
    
    video.onloadedmetadata = () => {
      video.play();
      
      // Tunggu sebentar untuk memastikan video siap
      setTimeout(() => {
        const canvas = document.createElement("canvas");
        canvas.width = 320;
        canvas.height = 240;
        const ctx = canvas.getContext("2d");
        if (!ctx) throw new Error("Gagal mengambil foto");
        
        ctx.drawImage(video, 0, 0, canvas.width, canvas.height);
        const photo = canvas.toDataURL("image/jpeg", 0.8);
        setCapturedPhoto(photo);
        closeCamera();
      }, 500);
    };
  };

  const retakePhoto = () => {
    setCapturedPhoto(null);
    openCamera();
  };

  const openClockInModal = async (employee: Employee) => {
    if (!employee.uuid) {
      Swal.fire("Error", "Employee UUID tidak valid", "error");
      return;
    }

    try {
      setIsProcessing(true);
      setSelectedEmployee(employee);
      setModalType('clockin');
      setModalOpen(true);
      
      // Ambil lokasi client dan current position
      const [clientLoc, currentPos] = await Promise.all([
        fetchClientLocation(employee.uuid),
        getStablePosition()
      ]);

      setClientLocation(clientLoc);
      setCurrentLocation(currentPos);
      
      // Hitung jarak
      const dist = getDistance(
        currentPos.latitude, 
        currentPos.longitude, 
        clientLoc.lat, 
        clientLoc.lng
      );
      setDistance(dist);

      // Buka kamera
      await openCamera();

    } catch (error: any) {
      Swal.fire("Error", error.message || "Gagal mempersiapkan clock in", "error");
      closeModal();
    } finally {
      setIsProcessing(false);
    }
  };

  const openClockOutModal = async (employee: Employee) => {
    if (!employee.uuid) {
      Swal.fire("Error", "Employee UUID tidak valid", "error");
      return;
    }

    try {
      setIsProcessing(true);
      setSelectedEmployee(employee);
      setModalType('clockout');
      setModalOpen(true);

      // Untuk clock out, kita hanya perlu lokasi saat ini
      const currentPos = await getStablePosition();
      setCurrentLocation(currentPos);

      // Buka kamera untuk clock out
      await openCamera();

    } catch (error: any) {
      Swal.fire("Error", error.message || "Gagal mempersiapkan clock out", "error");
      closeModal();
    } finally {
      setIsProcessing(false);
    }
  };

  const closeModal = () => {
    closeCamera();
    setModalOpen(false);
    setSelectedEmployee(null);
    setCurrentLocation(null);
    setClientLocation(null);
    setDistance(null);
    setCapturedPhoto(null);
    setIsProcessing(false);
  };

  const submitClockIn = async () => {
    if (!selectedEmployee?.uuid || !currentLocation || !capturedPhoto) {
      Swal.fire("Error", "Data tidak lengkap untuk clock in", "error");
      return;
    }

    try {
      setIsProcessing(true);

      // Validasi jarak hanya jika client location tersedia
      if (clientLocation && clientLocation.lat !== 0 && clientLocation.lng !== 0 && distance) {
        if (distance > MAX_DISTANCE_METERS) {
          const shouldProceed = await Swal.fire({
            icon: "warning",
            title: "Di luar lokasi yang diizinkan",
            html: `Anda berada <b>${Math.round(distance)} meter</b> dari lokasi client.<br>
                  Maksimal jarak: ${MAX_DISTANCE_METERS} meter.<br>
                  Akurasi GPS: ${Math.round(currentLocation.accuracy)} meter.`,
            confirmButtonText: "Tetap Clock In",
            showCancelButton: true,
            cancelButtonText: "Batal"
          });

          if (!shouldProceed.isConfirmed) {
            return;
          }
        }
      }

      // Kirim data ke server
      await api_laravel.post("/api/attendances/clock-in", {
        employee_uuid: selectedEmployee.uuid,
        photo: capturedPhoto,
        location: `${currentLocation.latitude},${currentLocation.longitude}`,
        latitude: currentLocation.latitude,
        longitude: currentLocation.longitude
      });

      Swal.fire({
        icon: "success",
        title: "Clock In Berhasil",
        timer: 2000,
        showConfirmButton: false,
      });

      closeModal();
      fetchAttendance(page);

    } catch (error: any) {
      Swal.fire("Error", error.response?.data?.message || "Clock In gagal", "error");
    } finally {
      setIsProcessing(false);
    }
  };

  const submitClockOut = async () => {
    if (!selectedEmployee?.uuid || !capturedPhoto) {
      Swal.fire("Error", "Data tidak lengkap untuk clock out", "error");
      return;
    }

    try {
      setIsProcessing(true);

      // Untuk clock out, kita tetap kirim foto dan lokasi
      const locationData = currentLocation ? {
        location: `${currentLocation.latitude},${currentLocation.longitude}`,
        latitude: currentLocation.latitude,
        longitude: currentLocation.longitude,
        photo: capturedPhoto
      } : {};

      await api_laravel.post("/api/attendances/clock-out", {
        employee_uuid: selectedEmployee.uuid,
        ...locationData
      });

      Swal.fire({
        icon: "success",
        title: "Clock Out Berhasil",
        timer: 2000,
        showConfirmButton: false,
      });

      closeModal();
      fetchAttendance(page);

    } catch (error: any) {
      Swal.fire("Error", error.response?.data?.message || "Clock Out gagal", "error");
    } finally {
      setIsProcessing(false);
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
    <>
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
                                  onClick={() => openClockInModal(att.employee)}
                                  disabled={!att.employee?.uuid}
                                >
                                  🟢 Clock In
                                </Button>
                              )}
                              {att.clock_in && !att.clock_out && (
                                <Button
                                  size="sm"
                                  variant="outline"
                                  onClick={() => openClockOutModal(att.employee)}
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

      {/* Modal untuk Clock In/Out */}
      <Dialog open={modalOpen} onOpenChange={closeModal}>
        <DialogContent className="max-w-2xl">
          <DialogHeader>
            <DialogTitle>
              {modalType === 'clockin' ? '🟢 Clock In' : '🔴 Clock Out'} - {selectedEmployee?.name}
            </DialogTitle>
            <DialogDescription>
              {modalType === 'clockin' 
                ? 'Ambil foto dan konfirmasi lokasi untuk clock in' 
                : 'Ambil foto untuk clock out'}
            </DialogDescription>
          </DialogHeader>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {/* Bagian Kamera */}
            <div className="space-y-4">
              <h3 className="font-semibold">Kamera</h3>
              
              {cameraStream && !capturedPhoto && (
                <div className="relative">
                  <video 
                    ref={(video) => {
                      if (video && cameraStream) {
                        video.srcObject = cameraStream;
                        video.play();
                      }
                    }}
                    autoPlay
                    playsInline
                    className="w-full h-48 object-cover rounded border"
                  />
                  <Button 
                    onClick={capturePhoto}
                    className="absolute bottom-2 right-2"
                    size="sm"
                  >
                    📸 Ambil Foto
                  </Button>
                </div>
              )}

              {capturedPhoto && (
                <div className="space-y-2">
                  <img 
                    src={capturedPhoto} 
                    alt="Foto yang diambil" 
                    className="w-full h-48 object-cover rounded border"
                  />
                  <div className="flex gap-2">
                    <Button onClick={retakePhoto} variant="outline" size="sm">
                      🔁 Ambil Ulang
                    </Button>
                  </div>
                </div>
              )}

              {!cameraStream && !capturedPhoto && (
                <div className="border-2 border-dashed rounded p-8 text-center">
                  <p>Kamera tidak tersedia</p>
                </div>
              )}
            </div>

            {/* Bagian Informasi Lokasi */}
            <div className="space-y-4">
              <h3 className="font-semibold">Informasi Lokasi</h3>
              
              {currentLocation && (
                <div className="space-y-2 p-3 bg-gray-50 rounded">
                  <div className="grid grid-cols-2 gap-2 text-sm">
                    <div>
                      <strong>Latitude:</strong><br />
                      {currentLocation.latitude.toFixed(6)}
                    </div>
                    <div>
                      <strong>Longitude:</strong><br />
                      {currentLocation.longitude.toFixed(6)}
                    </div>
                    <div>
                      <strong>Akurasi GPS:</strong><br />
                      {Math.round(currentLocation.accuracy)} meter
                    </div>
                    <div>
                      <strong>Waktu:</strong><br />
                      {new Date().toLocaleTimeString('id-ID')}
                    </div>
                  </div>
                </div>
              )}

              {modalType === 'clockin' && clientLocation && (
                <div className="space-y-2 p-3 bg-blue-50 rounded">
                  <h4 className="font-semibold">Lokasi Client</h4>
                  <div className="grid grid-cols-2 gap-2 text-sm">
                    <div>
                      <strong>Latitude:</strong><br />
                      {clientLocation.lat.toFixed(6)}
                    </div>
                    <div>
                      <strong>Longitude:</strong><br />
                      {clientLocation.lng.toFixed(6)}
                    </div>
                    {clientLocation.address && (
                      <div className="col-span-2">
                        <strong>Alamat:</strong><br />
                        {clientLocation.address}
                      </div>
                    )}
                  </div>

                  {distance !== null && (
                    <div className={`p-2 rounded text-center font-semibold ${
                      distance <= MAX_DISTANCE_METERS 
                        ? 'bg-green-100 text-green-800' 
                        : 'bg-yellow-100 text-yellow-800'
                    }`}>
                      Jarak: {Math.round(distance)} meter
                      {distance > MAX_DISTANCE_METERS && (
                        <div className="text-xs mt-1">
                          (Melebihi batas {MAX_DISTANCE_METERS}m)
                        </div>
                      )}
                    </div>
                  )}
                </div>
              )}

              {modalType === 'clockout' && (
                <div className="p-3 bg-yellow-50 rounded text-sm">
                  <strong>Perhatian:</strong> Pastikan Anda telah menyelesaikan pekerjaan sebelum melakukan clock out.
                </div>
              )}
            </div>
          </div>

          <div className="flex justify-end gap-2 pt-4">
            <Button onClick={closeModal} variant="outline" disabled={isProcessing}>
              Batal
            </Button>
            <Button 
              onClick={modalType === 'clockin' ? submitClockIn : submitClockOut}
              disabled={!capturedPhoto || isProcessing}
            >
              {isProcessing ? 'Memproses...' : 
               modalType === 'clockin' ? '🟢 Konfirmasi Clock In' : '🔴 Konfirmasi Clock Out'}
            </Button>
          </div>
        </DialogContent>
      </Dialog>
    </>
  );
};

export default Attendance;