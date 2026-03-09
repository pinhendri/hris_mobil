"use client";

import { useEffect, useState } from "react";
import { useParams } from "react-router-dom";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import api_laravel from "@/lib/utils";

interface AttendanceItem {
  date: string;
  clock_in: string | null;
  clock_out: string | null;
  status: string | null; // ✅ Tambahkan status ke interface
}

export default function EmployeeAttendanceHistory() {
  const { uuid } = useParams();
  const [attendance, setAttendance] = useState<AttendanceItem[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchAttendance = async () => {
      try {
        const res = await api_laravel.get(`/api/employees/${uuid}/attendance-history`);
        setAttendance(res.data.data || []);
      } catch (err) {
        console.error(err);
      } finally {
        setLoading(false);
      }
    };

    fetchAttendance();
  }, [uuid]);

  // FUNGSI: Format waktu untuk display
  const formatTime = (timeStr: string | null): string => {
    if (!timeStr) return "-";
    
    // Jika sudah dalam format HH:mm:ss, langsung return
    if (timeStr.match(/^\d{2}:\d{2}:\d{2}$/)) {
      return timeStr;
    }
    
    // Jika dalam format datetime, extract time saja
    if (timeStr.includes('T')) {
      const timePart = timeStr.split('T')[1]?.split('.')[0];
      return timePart || "-";
    }
    
    return timeStr;
  };

  // FUNGSI: Format tanggal
  const formatDate = (dateStr: string): string => {
    return new Date(dateStr).toLocaleDateString('id-ID', {
      weekday: 'long',
      year: 'numeric',
      month: 'long',
      day: 'numeric'
    });
  };

  // ✅ FUNGSI: Tentukan style untuk status yang berbeda
  const getStatusStyle = (status: string | null) => {
    if (!status) return "bg-gray-100 text-gray-800";
    
    const statusLower = status.toLowerCase();
    
    if (statusLower.includes('cuti') || statusLower.includes('leave')) {
      return "bg-blue-100 text-blue-800";
    } else if (statusLower.includes('sakit') || statusLower.includes('sick')) {
      return "bg-yellow-100 text-yellow-800";
    } else if (statusLower.includes('alpha') || statusLower.includes('absent')) {
      return "bg-red-100 text-red-800";
    } else if (statusLower.includes('terlambat') || statusLower.includes('late')) {
      return "bg-orange-100 text-orange-800";
    } else if (statusLower.includes('hadir') || statusLower.includes('present')) {
      return "bg-green-100 text-green-800";
    } else {
      return "bg-gray-100 text-gray-800";
    }
  };

  // ✅ FUNGSI: Translate status ke Bahasa Indonesia
  const translateStatus = (status: string | null): string => {
    if (!status) return "-";
    
    const statusLower = status.toLowerCase();
    
    const statusMap: { [key: string]: string } = {
      'present': 'Hadir',
      'late': 'Terlambat',
      'absent': 'Tidak Hadir',
      'leave': 'Cuti',
      'sick': 'Sakit',
      'cuti': 'Cuti',
      'sakit': 'Sakit',
      'alpha': 'Alpha'
    };
    
    return statusMap[statusLower] || status;
  };

  if (loading) return <p>Loading attendance...</p>;

  return (
    <div className="space-y-4">
      <Card>
        <CardHeader>
          <CardTitle>Riwayat Absensi (14 Hari Terakhir)</CardTitle>
        </CardHeader>
        <CardContent>
          {attendance.length > 0 ? (
            <div className="overflow-x-auto">
              <table className="w-full border-collapse text-sm">
                <thead>
                  <tr className="bg-gray-50">
                    <th className="border px-4 py-2 text-left">Tanggal</th>
                    <th className="border px-4 py-2 text-left">Clock In</th>
                    <th className="border px-4 py-2 text-left">Clock Out</th>
                    <th className="border px-4 py-2 text-left">Status</th>
                  </tr>
                </thead>
                <tbody>
                  {attendance.map((att: AttendanceItem) => (
                    <tr key={att.date} className="hover:bg-gray-50">
                      <td className="border px-4 py-2">
                        {formatDate(att.date)}
                      </td>
                      <td className="border px-4 py-2 font-mono">
                        {formatTime(att.clock_in)}
                      </td>
                      <td className="border px-4 py-2 font-mono">
                        {formatTime(att.clock_out)}
                      </td>
                      <td className="border px-4 py-2">
                        {/* ✅ Tampilkan status dengan style yang sesuai */}
                        {att.status ? (
                          <span className={`${getStatusStyle(att.status)} px-2 py-1 rounded text-xs font-medium`}>
                            {translateStatus(att.status)}
                          </span>
                        ) : (
                          <span className="text-gray-500">-</span>
                        )}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          ) : (
            <p>Tidak ada data absensi.</p>
          )}
        </CardContent>
      </Card>
    </div>
  );
}