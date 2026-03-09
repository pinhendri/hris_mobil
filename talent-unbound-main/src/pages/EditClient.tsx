"use client";

import { useState, useEffect } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { Textarea } from "@/components/ui/textarea";
import { Label } from "@/components/ui/label";
import { Switch } from "@/components/ui/switch";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import api_laravel from "@/lib/utils";
import Swal from "sweetalert2";

const EditClientPage = () => {
  const { uuid } = useParams();
  const navigate = useNavigate();

  const [form, setForm] = useState<any>({
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
  });

  const fetchClient = async () => {
    try {
      const res = await api_laravel.get(`/api/clients/${uuid}`);
      setForm(res.data.data);
    } catch (error: any) {
      Swal.fire("Error", error?.response?.data?.message || error.message || "Gagal ambil data client", "error");
    }
  };

  useEffect(() => {
    if (uuid) fetchClient();
  }, [uuid]);

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => {
    const { name, value } = e.target;
    setForm((prev: any) => ({ ...prev, [name]: value }));
  };

  const handleSwitch = (checked: boolean) => {
    setForm((prev: any) => ({ ...prev, auto_renew: checked }));
  };

  const handleSelect = (value: string) => {
    setForm((prev: any) => ({ ...prev, status: value }));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      await api_laravel.put(`/api/clients/${uuid}`, form);
      Swal.fire({ icon: "success", title: "Client diperbarui", timer: 1500, showConfirmButton: false });
      navigate("/clients");
    } catch (error: any) {
      Swal.fire("Error", error?.response?.data?.message || error.message || "Gagal update client", "error");
    }
  };

  return (
    <Card>
      <CardHeader>
        <CardTitle>Edit Client</CardTitle>
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
          <Button type="submit">Simpan Perubahan</Button>
        </form>
      </CardContent>
    </Card>
  );
};

export default EditClientPage;
