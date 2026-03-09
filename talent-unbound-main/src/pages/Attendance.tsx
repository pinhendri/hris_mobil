"use client";

import { useState, useEffect } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription } from "@/components/ui/dialog";
import { ScrollArea } from "@/components/ui/scroll-area";
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

const MAX_DISTANCE_METERS = 5000;
const MAX_GPS_ACCURACY = 10000;
const DEFAULT_LOCATION = { lat: 0, lng: 0 };
const MAX_PHOTO_SIZE_KB = 100;

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
  
  if (datetime.includes('T')) {
    const timePart = datetime.split('T')[1];
    if (timePart) return timePart.split('.')[0];
  }
  
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

// Fungsi kompresi foto
const compressImage = async (dataUrl: string, maxWidth = 160, maxHeight = 120, maxQuality = 0.4): Promise<string> => {
  return new Promise((resolve, reject) => {
    const img = new Image();
    img.src = dataUrl;
    
    img.onload = () => {
      const canvas = document.createElement('canvas');
      let { width, height } = img;
      
      // Calculate new dimensions maintaining aspect ratio
      const ratio = Math.min(maxWidth / width, maxHeight / height);
      width = Math.round(width * ratio);
      height = Math.round(height * ratio);
      
      canvas.width = width;
      canvas.height = height;
      
      const ctx = canvas.getContext('2d');
      if (!ctx) {
        reject(new Error("Gagal mengkompresi foto"));
        return;
      }
      
      // Set background putih untuk JPEG
      ctx.fillStyle = 'white';
      ctx.fillRect(0, 0, canvas.width, canvas.height);
      ctx.drawImage(img, 0, 0, width, height);
      
      // Coba berbagai level kualitas
      let quality = maxQuality;
      let compressedDataUrl = canvas.toDataURL('image/jpeg', quality);
      let sizeInKB = Math.round((compressedDataUrl.length * 3) / 4 / 1024);
      
      console.log(`Kompresi awal: ${sizeInKB} KB dengan kualitas ${quality}`);
      
      // Jika masih terlalu besar, kurangi kualitas secara bertahap
      while (sizeInKB > MAX_PHOTO_SIZE_KB && quality > 0.1) {
        quality -= 0.1;
        compressedDataUrl = canvas.toDataURL('image/jpeg', quality);
        sizeInKB = Math.round((compressedDataUrl.length * 3) / 4 / 1024);
        console.log(`Kompresi ulang: ${sizeInKB} KB dengan kualitas ${quality}`);
      }
      
      // Jika masih terlalu besar, kurangi ukuran lagi
      if (sizeInKB > MAX_PHOTO_SIZE_KB) {
        const smallerCanvas = document.createElement('canvas');
        smallerCanvas.width = Math.round(width * 0.7);
        smallerCanvas.height = Math.round(height * 0.7);
        const smallerCtx = smallerCanvas.getContext('2d');
        if (smallerCtx) {
          smallerCtx.fillStyle = 'white';
          smallerCtx.fillRect(0, 0, smallerCanvas.width, smallerCanvas.height);
          smallerCtx.drawImage(img, 0, 0, smallerCanvas.width, smallerCanvas.height);
          compressedDataUrl = smallerCanvas.toDataURL('image/jpeg', 0.2);
          sizeInKB = Math.round((compressedDataUrl.length * 3) / 4 / 1024);
          console.log(`Kompresi ekstrem: ${sizeInKB} KB`);
        }
      }
      
      if (sizeInKB > MAX_PHOTO_SIZE_KB) {
        reject(new Error(`Foto masih terlalu besar: ${sizeInKB} KB`));
        return;
      }
      
      console.log(`Foto berhasil dikompresi: ${sizeInKB} KB`);
      resolve(compressedDataUrl);
    };
    
    img.onerror = () => reject(new Error("Gagal memuat gambar"));
  });
};

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

// Komponen untuk menampilkan peta sederhana
const SimpleLocationMap = ({ 
  currentLocation, 
  clientLocation, 
  distance,
  modalType
}: { 
  currentLocation: { lat: number; lng: number; accuracy: number } | null;
  clientLocation: ClientLocation | null;
  distance: number | null;
  modalType: 'clockin' | 'clockout';
}) => {
  const openInGoogleMaps = () => {
    if (!currentLocation) return;
    
    const url = `https://www.google.com/maps?q=${currentLocation.latitude},${currentLocation.longitude}&z=17`;
    window.open(url, '_blank');
  };

  const openClientInGoogleMaps = () => {
    if (!clientLocation) return;
    
    const url = `https://www.google.com/maps?q=${clientLocation.lat},${clientLocation.lng}&z=17`;
    window.open(url, '_blank');
  };

  return (
    <div className="space-y-4">
      {/* Visualisasi Lokasi Sederhana */}
      <div className="relative h-40 bg-gradient-to-br from-blue-50 to-green-50 rounded-lg border-2 border-gray-200 p-4">
        {/* Client Location */}
        {clientLocation && (
          <div className="absolute left-1/4 top-1/3 text-center">
            <div className={`w-5 h-5 rounded-full border-3 ${
              distance && distance <= MAX_DISTANCE_METERS 
                ? 'border-green-500 bg-green-100' 
                : 'border-red-500 bg-red-100'
            }`}></div>
            <span className="text-xs font-semibold mt-1 block">Lokasi Client</span>
          </div>
        )}
        
        {/* Current Location */}
        {currentLocation && (
          <div className="absolute left-3/4 top-2/3 text-center">
            <div className={`w-5 h-5 rounded-full border-3 ${
              modalType === 'clockout' ? 'border-orange-500 bg-orange-100' : 'border-blue-500 bg-blue-100'
            }`}></div>
            <span className="text-xs font-semibold mt-1 block">
              {modalType === 'clockout' ? 'Clock Out' : 'Anda'}
            </span>
          </div>
        )}
        
        {/* Radius Area */}
        {clientLocation && (
          <div className="absolute left-1/4 top-1/3 transform -translate-x-1/2 -translate-y-1/2">
            <div className={`w-24 h-24 rounded-full border-2 ${
              distance && distance <= MAX_DISTANCE_METERS 
                ? 'border-green-300 bg-green-50' 
                : 'border-red-300 bg-red-50'
            } opacity-60`}></div>
          </div>
        )}
        
        {/* Distance Line */}
        {clientLocation && currentLocation && (
          <div className="absolute inset-0 flex items-center justify-center">
            <div className={`h-0.5 w-1/2 ${
              distance && distance <= MAX_DISTANCE_METERS ? 'bg-green-400' : 'bg-red-400'
            } transform rotate-12`}></div>
          </div>
        )}
      </div>

      {/* Tombol Aksi */}
      <div className="flex flex-col sm:flex-row gap-2 justify-center">
        <Button variant="outline" size="sm" onClick={openInGoogleMaps} className="text-xs">
          📍 Buka Lokasi Saya
        </Button>
        {clientLocation && (
          <Button variant="outline" size="sm" onClick={openClientInGoogleMaps} className="text-xs">
            🏢 Buka Lokasi Client
          </Button>
        )}
      </div>

      {/* Legenda */}
      <div className="flex flex-wrap justify-center gap-3 text-xs">
        <div className="flex items-center gap-1">
          <div className={`w-3 h-3 rounded-full ${
            modalType === 'clockout' ? 'bg-orange-500' : 'bg-blue-500'
          }`}></div>
          <span>{modalType === 'clockout' ? 'Lokasi Clock Out' : 'Lokasi Anda'}</span>
        </div>
        {clientLocation && (
          <div className="flex items-center gap-1">
            <div className={`w-3 h-3 rounded-full ${
              distance && distance <= MAX_DISTANCE_METERS ? 'bg-green-500' : 'bg-red-500'
            }`}></div>
            <span>Lokasi Client</span>
          </div>
        )}
        {clientLocation && (
          <div className="flex items-center gap-1">
            <div className={`w-3 h-3 rounded-full border ${
              distance && distance <= MAX_DISTANCE_METERS ? 'border-green-300' : 'border-red-300'
            } bg-transparent`}></div>
            <span>Radius {MAX_DISTANCE_METERS}m</span>
          </div>
        )}
      </div>
    </div>
  );
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
      // Ukuran kamera sangat kecil untuk mengurangi size
      const stream = await navigator.mediaDevices.getUserMedia({ 
        video: { 
          width: 160, 
          height: 120, 
          facingMode: "user",
          aspectRatio: 1.333 
        } 
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

  const capturePhoto = async () => {
    if (!cameraStream) return;

    try {
      setIsProcessing(true);
      const video = document.createElement("video");
      video.srcObject = cameraStream;
      
      video.onloadedmetadata = () => {
        video.play();
        
        setTimeout(async () => {
          try {
            const canvas = document.createElement("canvas");
            // Ukuran sangat kecil
            canvas.width = 160;
            canvas.height = 120;
            const ctx = canvas.getContext("2d");
            if (!ctx) throw new Error("Gagal mengambil foto");
            
            // Set background putih
            ctx.fillStyle = 'white';
            ctx.fillRect(0, 0, canvas.width, canvas.height);
            ctx.drawImage(video, 0, 0, canvas.width, canvas.height);
            
            const originalPhoto = canvas.toDataURL("image/jpeg", 0.3);
            console.log(`Ukuran foto asli: ${Math.round((originalPhoto.length * 3) / 4 / 1024)} KB`);
            
            // Kompresi foto dengan agresif
            const compressedPhoto = await compressImage(originalPhoto);
            setCapturedPhoto(compressedPhoto);
            closeCamera();
            
          } catch (error) {
            console.error("Error capturing photo:", error);
            Swal.fire("Error", error instanceof Error ? error.message : "Gagal mengambil foto", "error");
          } finally {
            setIsProcessing(false);
          }
        }, 500);
      };
    } catch (error) {
      console.error("Error capturing photo:", error);
      Swal.fire("Error", "Gagal mengambil foto", "error");
      setIsProcessing(false);
    }
  };

  const retakePhoto = () => {
    setCapturedPhoto(null);
    openCamera();
  };

  const closeModal = () => {
    console.log("Closing modal...");
    
    // Hentikan kamera terlebih dahulu
    closeCamera();
    
    // Reset semua state modal
    setModalOpen(false);
    
    // Gunakan setTimeout untuk memastikan state sudah di-update
    setTimeout(() => {
      setSelectedEmployee(null);
      setCurrentLocation(null);
      setClientLocation(null);
      setDistance(null);
      setCapturedPhoto(null);
      setIsProcessing(false);
      setModalType('clockin');
    }, 100);
  };

  const handleModalOpenChange = (open: boolean) => {
    if (!open) {
      closeModal();
    } else {
      setModalOpen(true);
    }
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
      
      const [clientLoc, currentPos] = await Promise.all([
        fetchClientLocation(employee.uuid),
        getStablePosition()
      ]);

      setClientLocation(clientLoc);
      setCurrentLocation(currentPos);
      
      const dist = getDistance(
        currentPos.latitude, 
        currentPos.longitude, 
        clientLoc.lat, 
        clientLoc.lng
      );
      setDistance(dist);

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

      const [clientLoc, currentPos] = await Promise.all([
        fetchClientLocation(employee.uuid),
        getStablePosition()
      ]);

      setClientLocation(clientLoc);
      setCurrentLocation(currentPos);
      
      const dist = getDistance(
        currentPos.latitude, 
        currentPos.longitude, 
        clientLoc.lat, 
        clientLoc.lng
      );
      setDistance(dist);

      await openCamera();

    } catch (error: any) {
      Swal.fire("Error", error.message || "Gagal mempersiapkan clock out", "error");
      closeModal();
    } finally {
      setIsProcessing(false);
    }
  };

  const validatePhotoSize = (photo: string): boolean => {
    const base64Length = photo.length;
    const sizeInKB = Math.round((base64Length * 3) / 4 / 1024);
    console.log(`Validating photo size: ${sizeInKB} KB`);
    
    if (sizeInKB > MAX_PHOTO_SIZE_KB) {
      Swal.fire({
        icon: "error",
        title: "Foto Terlalu Besar",
        html: `Ukuran foto: <b>${sizeInKB} KB</b><br>Maksimal: ${MAX_PHOTO_SIZE_KB} KB<br>Silakan ambil foto ulang.`,
      });
      return false;
    }
    return true;
  };

  const submitClockIn = async () => {
    if (!selectedEmployee?.uuid || !currentLocation || !capturedPhoto) {
      Swal.fire("Error", "Data tidak lengkap untuk clock in", "error");
      return;
    }

    // Validasi ukuran foto
    if (!validatePhotoSize(capturedPhoto)) {
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
            setIsProcessing(false);
            return;
          }
        }
      }

      // Ambil company code dari localStorage
      const companyCode = getCompanyCode();
      if (!companyCode) {
        Swal.fire("Error", "Company code tidak ditemukan. Silakan login ulang.", "error");
        setIsProcessing(false);
        return;
      }

      await api_laravel.post("/api/attendances/clock-in", {
        employee_uuid: selectedEmployee.uuid,
        photo: capturedPhoto,
        location: `${currentLocation.latitude},${currentLocation.longitude}`,
        latitude: currentLocation.latitude,
        longitude: currentLocation.longitude,
        c_code: companyCode
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
      console.error("Clock In error:", error);
      
      // Handle specific error for photo size
      if (error.response?.data?.message?.includes('foto terlalu besar') || 
          error.response?.data?.message?.includes('Ukuran foto')) {
        Swal.fire({
          icon: "error",
          title: "Foto Terlalu Besar",
          text: "Foto yang diambil terlalu besar. Silakan ambil foto ulang dengan kualitas lebih rendah.",
        });
        setCapturedPhoto(null);
        await openCamera();
      } else {
        Swal.fire("Error", error.response?.data?.message || "Clock In gagal", "error");
      }
    } finally {
      setIsProcessing(false);
    }
  };

  const submitClockOut = async () => {
    if (!selectedEmployee?.uuid || !currentLocation || !capturedPhoto) {
      Swal.fire("Error", "Data tidak lengkap untuk clock out", "error");
      return;
    }

    // Validasi ukuran foto
    if (!validatePhotoSize(capturedPhoto)) {
      return;
    }

    try {
      setIsProcessing(true);

      // Validasi jarak untuk clock out juga
      if (clientLocation && clientLocation.lat !== 0 && clientLocation.lng !== 0 && distance) {
        if (distance > MAX_DISTANCE_METERS) {
          const shouldProceed = await Swal.fire({
            icon: "warning",
            title: "Di luar lokasi yang diizinkan",
            html: `Anda berada <b>${Math.round(distance)} meter</b> dari lokasi client.<br>
                  Maksimal jarak: ${MAX_DISTANCE_METERS} meter.<br>
                  Akurasi GPS: ${Math.round(currentLocation.accuracy)} meter.`,
            confirmButtonText: "Tetap Clock Out",
            showCancelButton: true,
            cancelButtonText: "Batal"
          });

          if (!shouldProceed.isConfirmed) {
            setIsProcessing(false);
            return;
          }
        }
      }

      // Ambil company code dari localStorage
      const companyCode = getCompanyCode();
      if (!companyCode) {
        Swal.fire("Error", "Company code tidak ditemukan. Silakan login ulang.", "error");
        setIsProcessing(false);
        return;
      }

      await api_laravel.post("/api/attendances/clock-out", {
        employee_uuid: selectedEmployee.uuid,
        photo: capturedPhoto,
        location: `${currentLocation.latitude},${currentLocation.longitude}`,
        latitude: currentLocation.latitude,
        longitude: currentLocation.longitude,
        c_code: companyCode
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
      console.error("Clock Out error:", error);
      
      // Handle specific error for photo size
      if (error.response?.data?.message?.includes('foto terlalu besar') || 
          error.response?.data?.message?.includes('Ukuran foto')) {
        Swal.fire({
          icon: "error",
          title: "Foto Terlalu Besar",
          text: "Foto yang diambil terlalu besar. Silakan ambil foto ulang dengan kualitas lebih rendah.",
        });
        setCapturedPhoto(null);
        await openCamera();
      } else {
        Swal.fire("Error", error.response?.data?.message || "Clock Out gagal", "error");
      }
    } finally {
      setIsProcessing(false);
    }
  };

  const checkMyLocation = async () => {
    try {
      const { latitude, longitude, accuracy } = await getStablePosition();
      
      Swal.fire({
        icon: "info",
        title: "Lokasi Anda Saat Ini",
        html: `
          <div style="text-align: left; margin-bottom: 15px;">
            <b>Latitude:</b> ${latitude.toFixed(6)}<br>
            <b>Longitude:</b> ${longitude.toFixed(6)}<br>
            <b>Akurasi:</b> ${Math.round(accuracy)} meter
          </div>
          <div class="text-center">
            <a href="https://www.google.com/maps?q=${latitude},${longitude}" 
               target="_blank" 
               class="inline-block mt-2 px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600">
              📍 Buka di Google Maps
            </a>
          </div>
        `,
        width: 400,
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

      <Dialog open={modalOpen} onOpenChange={handleModalOpenChange}>
        <DialogContent className="max-w-[95vw] max-h-[90vh] sm:max-w-2xl md:max-w-4xl flex flex-col p-4 sm:p-6">
          <DialogHeader className="px-0 py-0">
            <DialogTitle className="text-lg sm:text-xl">
              {modalType === 'clockin' ? '🟢 Clock In' : '🔴 Clock Out'} - {selectedEmployee?.name}
            </DialogTitle>
            <DialogDescription className="text-sm">
              {modalType === 'clockin' 
                ? 'Ambil foto dan konfirmasi lokasi untuk clock in' 
                : 'Ambil foto dan konfirmasi lokasi untuk clock out'}
            </DialogDescription>
          </DialogHeader>

          <ScrollArea className="flex-1 pr-4 -mr-4">
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-4 sm:gap-6 pb-4">
              <div className="space-y-4">
                <h3 className="font-semibold text-sm sm:text-base">Kamera</h3>
                
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
                      className="w-full h-40 sm:h-48 object-cover rounded border"
                    />
                    <Button 
                      onClick={capturePhoto}
                      className="absolute bottom-2 right-2 text-xs sm:text-sm"
                      size="sm"
                      disabled={isProcessing}
                    >
                      {isProcessing ? 'Mengkompresi...' : '📸 Ambil Foto'}
                    </Button>
                  </div>
                )}

                {capturedPhoto && (
                  <div className="space-y-2">
                    <img 
                      src={capturedPhoto} 
                      alt="Foto yang diambil" 
                      className="w-full h-40 sm:h-48 object-cover rounded border"
                    />
                    <div className="flex gap-2">
                      <Button onClick={retakePhoto} variant="outline" size="sm" className="text-xs sm:text-sm">
                        🔁 Ambil Ulang
                      </Button>
                    </div>
                    {capturedPhoto && (
                      <div className="text-xs text-center text-gray-600">
                        Ukuran foto: {Math.round((capturedPhoto.length * 3) / 4 / 1024)} KB
                        (Maksimal: {MAX_PHOTO_SIZE_KB} KB)
                      </div>
                    )}
                  </div>
                )}

                {!cameraStream && !capturedPhoto && (
                  <div className="border-2 border-dashed rounded p-4 sm:p-8 text-center">
                    <p className="text-sm">Kamera tidak tersedia</p>
                  </div>
                )}
              </div>

              <div className="space-y-4">
                <h3 className="font-semibold text-sm sm:text-base">Visualisasi Lokasi</h3>
                
                <SimpleLocationMap 
                  currentLocation={currentLocation}
                  clientLocation={clientLocation}
                  distance={distance}
                  modalType={modalType}
                />

                <div className="space-y-3">
                  {currentLocation && (
                    <div className="p-3 bg-gray-50 rounded text-xs sm:text-sm">
                      <h4 className="font-semibold mb-1 sm:mb-2">
                        {modalType === 'clockout' ? '📍 Lokasi Clock Out Anda' : '📍 Lokasi Anda Saat Ini'}
                      </h4>
                      <div className="grid grid-cols-2 gap-1 sm:gap-2">
                        <div className="truncate">
                          <strong>Lat:</strong> {currentLocation.latitude.toFixed(6)}
                        </div>
                        <div className="truncate">
                          <strong>Lng:</strong> {currentLocation.longitude.toFixed(6)}
                        </div>
                        <div>
                          <strong>Akurasi:</strong> {Math.round(currentLocation.accuracy)}m
                        </div>
                        <div>
                          <strong>Waktu:</strong> {new Date().toLocaleTimeString('id-ID')}
                        </div>
                      </div>
                    </div>
                  )}

                  {clientLocation && distance !== null && (
                    <div className={`p-3 rounded text-xs sm:text-sm ${
                      distance <= MAX_DISTANCE_METERS 
                        ? 'bg-green-50 border border-green-200' 
                        : 'bg-yellow-50 border border-yellow-200'
                    }`}>
                      <h4 className="font-semibold mb-1">
                        {distance <= MAX_DISTANCE_METERS ? '✅ Dalam Radius' : '⚠️ Di Luar Radius'}
                      </h4>
                      <p>
                        Jarak ke lokasi client: <strong>{Math.round(distance)} meter</strong><br/>
                        Batas maksimal: {MAX_DISTANCE_METERS} meter
                      </p>
                      {clientLocation.address && (
                        <p className="mt-1 text-xs truncate">
                          <strong>Alamat Client:</strong> {clientLocation.address}
                        </p>
                      )}
                    </div>
                  )}

                  {modalType === 'clockout' && (
                    <div className="p-3 bg-orange-50 rounded text-xs sm:text-sm border border-orange-200">
                      <strong>Perhatian:</strong> Pastikan Anda telah menyelesaikan pekerjaan sebelum melakukan clock out.
                      {distance && distance > MAX_DISTANCE_METERS && (
                        <span className="block mt-1 text-orange-700 text-xs">
                          ⚠️ Anda berada di luar radius yang diizinkan untuk clock out.
                        </span>
                      )}
                    </div>
                  )}
                </div>
              </div>
            </div>
          </ScrollArea>

          <div className="flex flex-col sm:flex-row gap-2 pt-4 mt-4 border-t">
            <Button 
              onClick={closeModal} 
              variant="outline" 
              disabled={isProcessing}
              className="flex-1"
            >
              Batal
            </Button>
            <Button 
              onClick={modalType === 'clockin' ? submitClockIn : submitClockOut}
              disabled={!capturedPhoto || isProcessing}
              className="flex-1"
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