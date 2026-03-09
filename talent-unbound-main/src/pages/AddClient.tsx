"use client";

import { useState } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { Textarea } from "@/components/ui/textarea";
import { Label } from "@/components/ui/label";
import { Switch } from "@/components/ui/switch";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import api_laravel from "@/lib/utils";
import Swal from "sweetalert2";
import { useNavigate } from "react-router-dom";
import { MapContainer, TileLayer, Marker, useMapEvents } from "react-leaflet";
import "leaflet/dist/leaflet.css";
import L from "leaflet";

// default marker fix for leaflet (karena path icon bawaan sering error di React + Vite)
delete (L.Icon.Default.prototype as any)._getIconUrl;
L.Icon.Default.mergeOptions({
  iconRetinaUrl: "https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon-2x.png",
  iconUrl: "https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png",
  shadowUrl: "https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png",
});

const LocationPicker = ({ setLocation }: { setLocation: (val: string) => void }) => {
  useMapEvents({
    click(e) {
      const coords = `${e.latlng.lat},${e.latlng.lng}`;
      setLocation(coords);
    },
  });
  return null;
};

const AddClientPage = () => {
  const navigate = useNavigate();

  const [form, setForm] = useState({
    name: "",
    address: "",
    contact_person: "",
    phone: "",
    pks_number: "",
    contract_start: "",
    contract_end: "",
    auto_renew: false,
    status: "pending",
    notes: "",
    location_map: "", // ✅ tambahkan kolom untuk lokasi
  });

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => {
    const { name, value } = e.target;
    setForm(prev => ({ ...prev, [name]: value }));
  };

  const handleSwitch = (checked: boolean) => {
    setForm(prev => ({ ...prev, auto_renew: checked }));
  };

  const handleSelect = (value: string) => {
    setForm(prev => ({ ...prev, status: value }));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      await api_laravel.post("/api/clients", form);
      Swal.fire({ icon: "success", title: "Client ditambahkan", timer: 1500, showConfirmButton: false });
      navigate("/clients");
    } catch (error: any) {
      Swal.fire("Error", error?.response?.data?.message || error.message || "Gagal tambah client", "error");
    }
  };

  return (
    <Card>
      <CardHeader>
        <CardTitle>Tambah Client</CardTitle>
      </CardHeader>
      <CardContent>
        <form className="space-y-4" onSubmit={handleSubmit}>
          <div>
            <Label>Nama Client</Label>
            <Input name="name" value={form.name} onChange={handleChange} required />
          </div>
          <div>
            <Label>Alamat</Label>
            <Textarea name="address" value={form.address} onChange={handleChange} />
          </div>
          <div>
            <Label>Contact Person</Label>
            <Input name="contact_person" value={form.contact_person} onChange={handleChange} />
          </div>
          <div>
            <Label>Phone</Label>
            <Input name="phone" value={form.phone} onChange={handleChange} />
          </div>
          <div>
            <Label>PKS Number</Label>
            <Input name="pks_number" value={form.pks_number} onChange={handleChange} />
          </div>
          <div className="flex gap-4">
            <div>
              <Label>Contract Start</Label>
              <Input type="date" name="contract_start" value={form.contract_start} onChange={handleChange} />
            </div>
            <div>
              <Label>Contract End</Label>
              <Input type="date" name="contract_end" value={form.contract_end} onChange={handleChange} />
            </div>
          </div>
          <div className="flex items-center gap-2">
            <Switch checked={form.auto_renew} onCheckedChange={handleSwitch} />
            <Label>Auto Renew</Label>
          </div>
          <div>
            <Label>Status</Label>
            <Select value={form.status} onValueChange={handleSelect}>
              <SelectTrigger>
                <SelectValue placeholder="Pilih status" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="active">Active</SelectItem>
                <SelectItem value="expired">Expired</SelectItem>
                <SelectItem value="pending">Pending</SelectItem>
              </SelectContent>
            </Select>
          </div>
          <div>
            <Label>Notes</Label>
            <Textarea name="notes" value={form.notes} onChange={handleChange} />
          </div>

          {/* ✅ Map picker */}
           {/* ✅ Map picker */}
          <div>
            <Label>Pilih Lokasi (klik pada peta)</Label>
            <div className="h-[300px] rounded border">
              <MapContainer
                center={[-6.200000, 106.816666]} // default Jakarta
                zoom={12}
                style={{ height: "100%", width: "100%" }}
              >
                <TileLayer url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png" />
                <LocationPicker setLocation={(val) => setForm((prev) => ({ ...prev, location_map: val }))} />
                {form.location_map && (
                  <Marker position={form.location_map.split(",").map(Number) as [number, number]} />
                )}
              </MapContainer>
            </div>
            {form.location_map && (
              <p className="text-sm mt-2 text-gray-600">Lokasi dipilih: {form.location_map}</p>
            )}
          </div>

          <Button type="submit">Simpan</Button>
        </form>
      </CardContent>
    </Card>
  );
};

export default AddClientPage;
