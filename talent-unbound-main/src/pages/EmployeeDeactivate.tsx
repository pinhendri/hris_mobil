// src/pages/EmployeeDeactivate.tsx
"use client";
import { useState } from "react";
import { useNavigate, useParams } from "react-router-dom";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import api_laravel from "@/lib/utils";
import Swal from "sweetalert2";

export default function EmployeeDeactivate() {
  const { uuid } = useParams();
  const navigate = useNavigate();
  const [deactiveDate, setDeactiveDate] = useState("");
  const [reason, setReason] = useState("");
  const [loading, setLoading] = useState(false);

  const handleSubmit = async () => {
    if (!deactiveDate || !reason) {
      Swal.fire("Error", "Tanggal dan alasan harus diisi", "error");
      return;
    }

    setLoading(true);
    try {
      await api_laravel.post(`/api/employees/${uuid}/deactivate`, {
        deactive_date: deactiveDate,
        reason,
      });
      Swal.fire("Success", "Employee berhasil dinonaktifkan", "success");
      navigate("/employees"); // kembali ke daftar employee
    } catch (err) {
      console.error(err);
      Swal.fire("Error", "Gagal menonaktifkan employee", "error");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="max-w-md mx-auto mt-10 p-6 bg-white shadow rounded">
      <h2 className="text-lg font-semibold mb-4">Deactivate Employee</h2>
      <div className="mb-4">
        <label className="block text-sm mb-1">Tanggal Nonactive</label>
        <Input
          type="date"
          value={deactiveDate}
          onChange={(e) => setDeactiveDate(e.target.value)}
        />
      </div>
      <div className="mb-4">
        <label className="block text-sm mb-1">Alasan</label>
        <Textarea
          value={reason}
          onChange={(e) => setReason(e.target.value)}
          rows={4}
        />
      </div>
      <Button onClick={handleSubmit} disabled={loading}>
        {loading ? "Processing..." : "Deactivate"}
      </Button>
    </div>
  );
}
