"use client";

import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import api_laravel from "@/lib/utils";
import { useRouter } from "next/navigation";

export default function AddEmployee() {
  const router = useRouter();
  const [form, setForm] = useState({
    name: "",
    email: "",
    phone: "",
    position: "",
    department: "",
    status: "Active",
    salary: "",
    join_date: "",
  });
  const [loading, setLoading] = useState(false);

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setForm({ ...form, [e.target.name]: e.target.value });
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    try {
      await api_laravel.post("/api/employees", form);
      alert("Employee berhasil ditambahkan!");
      router.push("/employees"); // balik ke list
    } catch (err: any) {
      console.error("Gagal tambah employee:", err.response?.data || err);
      alert("Gagal tambah employee");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="max-w-2xl mx-auto mt-8">
      <Card>
        <CardHeader>
          <CardTitle>Add Employee</CardTitle>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleSubmit} className="space-y-4">
            <Input placeholder="Name" name="name" value={form.name} onChange={handleChange} required />
            <Input placeholder="Email" name="email" type="email" value={form.email} onChange={handleChange} required />
            <Input placeholder="Phone" name="phone" value={form.phone} onChange={handleChange} />
            <Input placeholder="Position" name="position" value={form.position} onChange={handleChange} required />
            <Input placeholder="Department" name="department" value={form.department} onChange={handleChange} required />
            <Select
              value={form.status}
              onValueChange={(val) => setForm({ ...form, status: val })}
            >
              <SelectTrigger>
                <SelectValue placeholder="Select status" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="Active">Active</SelectItem>
                <SelectItem value="On Leave">On Leave</SelectItem>
                <SelectItem value="Inactive">Inactive</SelectItem>
              </SelectContent>
            </Select>
            <Input placeholder="Salary" name="salary" value={form.salary} onChange={handleChange} />
            <Input placeholder="Join Date" name="join_date" type="date" value={form.join_date} onChange={handleChange} required />

            <Button type="submit" disabled={loading}>
              {loading ? "Saving..." : "Save Employee"}
            </Button>
          </form>
        </CardContent>
      </Card>
    </div>
  );
}
