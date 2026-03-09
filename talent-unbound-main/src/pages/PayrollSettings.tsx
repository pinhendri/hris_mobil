"use client";

import { useEffect, useState } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import {
  Select,
  SelectTrigger,
  SelectContent,
  SelectItem,
  SelectValue,
} from "@/components/ui/select";
import api_laravel from "@/lib/utils";
import Swal from "sweetalert2";

interface PayrollSettings {
  bpjs_kesehatan_percent: number;
  bpjs_ketenaga_percent: number;
  pajak_percent: number;
  bpjs_jpensiun_percent:number;
  thr_percent: number;
  bonus_percent: number;
  religion_id: number | null;
}

interface ApiResponse {
  success: boolean;
  data: PayrollSettings;
}

export default function PayrollSettingsPage() {
  const [settings, setSettings] = useState<PayrollSettings | null>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);

  // 🔹 Ambil data payroll settings
  useEffect(() => {
    const fetchSettings = async () => {
      try {
        const res = await api_laravel.get<ApiResponse>("/api/payroll/settings");

        if (res.data.success && res.data.data) {
          setSettings(res.data.data);
        } else {
          Swal.fire("Error", "Format response settings tidak valid", "error");
        }
      } catch (err: any) {
        console.error("Error fetch:", err);
        Swal.fire(
          "Error",
          err.response?.data?.message || "Gagal mengambil data payroll settings",
          "error"
        );
      } finally {
        setLoading(false);
      }
    };

    fetchSettings();
  }, []);

  const handleUpdate = async () => {
    if (!settings) return;
    setSaving(true);

    try {
      const res = await api_laravel.put<ApiResponse>(
        "/api/payroll/settings",
        settings
      );

      if (res.data.success) {
        Swal.fire({
          icon: "success",
          title: "Berhasil",
          text: "Payroll settings berhasil diupdate",
          timer: 2000,
          showConfirmButton: false,
        });
      } else {
        throw new Error("Update gagal");
      }
    } catch (err: any) {
      console.error("Update gagal:", err);
      Swal.fire(
        "Error",
        err.response?.data?.message || "Gagal update payroll settings",
        "error"
      );
    } finally {
      setSaving(false);
    }
  };

  const handleInputChange = (field: keyof PayrollSettings, value: string) => {
    const numValue = parseFloat(value);
    if (settings) {
      setSettings({
        ...settings,
        [field]: isNaN(numValue) ? 0 : numValue,
      });
    }
  };

  const handleReligionChange = (value: string) => {
    if (settings) {
      setSettings({
        ...settings,
        religion_id: value === "0" ? null : parseInt(value),
      });
    }
  };

  if (loading) {
    return (
      <div className="flex justify-center items-center min-h-64">
        <p className="text-lg">Loading payroll settings...</p>
      </div>
    );
  }

  if (!settings) {
    return (
      <div className="flex justify-center items-center min-h-64">
        <div className="text-center">
          <p className="text-red-500 text-lg mb-4">Tidak ada data settings.</p>
          <Button onClick={() => window.location.reload()}>Coba Lagi</Button>
        </div>
      </div>
    );
  }

  return (
    <div className="container mx-auto py-6">
      <Card className="max-w-xl mx-auto">
        <CardHeader>
          <CardTitle className="text-2xl">Payroll Settings</CardTitle>
          <p className="text-sm text-muted-foreground">
            Atur parameter perhitungan payroll perusahaan
          </p>
        </CardHeader>

        <CardContent className="space-y-6">
          <div className="space-y-4">
            {/* BPJS Kesehatan */}
            <div>
              <label className="block text-sm font-medium mb-2">
                BPJS Kesehatan (%)
              </label>
              <Input
                type="number"
                min="0"
                max="100"
                step="0.1"
                value={settings.bpjs_kesehatan_percent}
                onChange={(e) =>
                  handleInputChange("bpjs_kesehatan_percent", e.target.value)
                }
              />
            </div>

            {/* BPJS Ketenagakerjaan */}
            <div>
              <label className="block text-sm font-medium mb-2">
                BPJS Ketenagakerjaan (%)
              </label>
              <Input
                type="number"
                min="0"
                max="100"
                step="0.1"
                value={settings.bpjs_ketenaga_percent}
                onChange={(e) =>
                  handleInputChange("bpjs_ketenaga_percent", e.target.value)
                }
              />
            </div>

             {/* BPJS Jaminan Pensiun */}
           {/* BPJS Jaminan Pensiun */}
            <div>
              <label className="block text-sm font-medium mb-2">
                BPJS Jaminan Pensiun (%)
              </label>
              <Input
                type="number"
                min="0"
                max="100"
                step="0.1"
                value={settings.bpjs_jpensiun_percent} // pastikan nama field sesuai backend
                onChange={(e) =>
                  handleInputChange("bpjs_jpensiun_percent", e.target.value)
                }
              />
            </div>

            {/* Pajak */}
            <div>
              <label className="block text-sm font-medium mb-2">
                Pajak PPh 21 (%)
              </label>
              <Input
                type="number"
                min="0"
                max="100"
                step="0.1"
                value={settings.pajak_percent}
                onChange={(e) =>
                  handleInputChange("pajak_percent", e.target.value)
                }
              />
            </div>

         
<div>
  <label className="block text-sm font-medium mb-2">
    Bonus (%)
  </label>
  <Input
    type="number"
    min="0"
    max="1000"  // ✅ boleh lebih dari 100%
    step="0.1"
    value={settings.bonus_percent}
    onChange={(e) =>
      handleInputChange("bonus_percent", e.target.value)
    }
  />
  <p className="text-xs text-muted-foreground mt-1">
    Contoh: 100 = 1x gaji, 200 = 2x gaji
  </p>
</div>

{/* THR */}
<div>
  <label className="block text-sm font-medium mb-2">
    THR (%)
  </label>
  <Input
    type="number"
    min="0"
    max="100"  // ✅ ubah dari 100 jadi 1000 biar bisa lebih besar
    step="0.1"
    value={settings.thr_percent}
    onChange={(e) =>
      handleInputChange("thr_percent", e.target.value)
    }
  />
  <p className="text-xs text-muted-foreground mt-1">
    Contoh: 100 = 1x gaji, 200 = 2x gaji
  </p>
</div>

            {/* Religion (manual dropdown) */}
            <div>
              <label className="block text-sm font-medium mb-2">
                Agama (Religion)
              </label>
              <Select
                value={settings.religion_id ? settings.religion_id.toString() : "0"}
                onValueChange={handleReligionChange}
              >
                <SelectTrigger>
                  <SelectValue placeholder="Pilih agama" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="1">Islam</SelectItem>
                  <SelectItem value="2">Non-Islam</SelectItem>
                  <SelectItem value="3">All</SelectItem>
                  <SelectItem value="4">None</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>

          {/* Ringkasan */}
          <div className="bg-muted p-4 rounded-lg">
            <h4 className="font-medium mb-2">Ringkasan Pengaturan:</h4>
            <div className="text-sm space-y-1">
              <p>• BPJS Kesehatan: {settings.bpjs_kesehatan_percent}%</p>
              <p>• BPJS Ketenagakerjaan: {settings.bpjs_ketenaga_percent}%</p>
             <p>• BPJS Jaminan Pensiun: {settings.bpjs_jpensiun_percent}%</p>
              <p>• Pajak: {settings.pajak_percent}%</p>
              <p>• Bonus: {settings.bonus_percent}%</p>
              <p>• THR: {settings.thr_percent}%</p>
              <p className="font-medium mt-2">
                Total Potongan:{" "}
                {(
                  settings.bpjs_kesehatan_percent +
                  settings.bpjs_ketenaga_percent +
                  settings.pajak_percent
                ).toFixed(2)}
                %
              </p>
              <p className="font-medium">
                Total Tambahan (Bonus + THR):{" "}
                {(
                  settings.bonus_percent + settings.thr_percent
                ).toFixed(2)}
                %
              </p>
            </div>
          </div>

          <Button
            className="w-full"
            onClick={handleUpdate}
            disabled={saving}
            size="lg"
          >
            {saving ? "Menyimpan..." : "Update Settings"}
          </Button>
        </CardContent>
      </Card>
    </div>
  );
}
