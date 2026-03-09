"use client";

import { useState, useEffect } from "react";
import { useParams } from "react-router-dom";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import api_laravel from "@/lib/utils";
import Swal from "sweetalert2";
import dayjs from "dayjs";

interface Employee {
  uuid: string;
  name: string;
  assign_to?: string | null;
  status?: string | null;
}

const ClientAssign = () => {
  const { uuid: clientUuid } = useParams<{ uuid: string }>();
  const [employees, setEmployees] = useState<Employee[]>([]);
  const [selected, setSelected] = useState<string[]>([]);
  const [shiftDate, setShiftDate] = useState<string>(dayjs().format("YYYY-MM-DD"));
  const [role, setRole] = useState<string>("");
  const [assigned, setAssigned] = useState<string[]>([]);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (!clientUuid) return;
    fetchEmployees();
    fetchAssigned();
  }, [clientUuid]);

  /** ===========================
   *  FIX #1: Pastikan selalu array
   *  =========================== */
  const fetchEmployees = async () => {
    try {
      const res = await api_laravel.get("/api/employees");

      console.log("EMPLOYEE API RETURN =", res.data.data);

      const raw = res.data?.data?.data;   // ← ini yang bener

    const data = Array.isArray(raw) ? raw : [];
    setEmployees(data);
    
    } catch (err: any) {
      Swal.fire("Error", err?.response?.data?.message || err.message, "error");
    }
  };

  /** ===========================
   *  FIX #2: Assigned juga selalu array string
   *  =========================== */
  const fetchAssigned = async () => {
    if (!clientUuid) return;
    try {
      const res = await api_laravel.get(`/api/clients/${clientUuid}/employees`);

      const arr = Array.isArray(res.data.data) ? res.data.data : [];

      const assignedUuids = arr
        .map((emp: Employee) => String(emp.uuid || "").trim())
        .filter(Boolean);

      setAssigned(assignedUuids);
    } catch (err: any) {
      Swal.fire("Error", err?.response?.data?.message || err.message, "error");
    }
  };

  /** Helper: employee available */
  const isAvailable = (emp: Employee) => {
    const status = (emp.status || "").toLowerCase();
    const assignTo = emp.assign_to;
    return (!assignTo || assignTo === "null") && status !== "assigned";
  };

  /** ===========================
   *  FIX #3: Protect employees.filter
   *  =========================== */
  const availableEmployees = Array.isArray(employees)
    ? employees.filter((e) => {
        const uuid = String(e.uuid || "").trim();
        return uuid && !assigned.includes(uuid) && isAvailable(e);
      })
    : [];

  const toggleSelect = (uuid: string) => {
    setSelected((prev) =>
      prev.includes(uuid) ? prev.filter((e) => e !== uuid) : [...prev, uuid]
    );
  };

  const handleAssign = async () => {
    if (!clientUuid) {
      Swal.fire("Error", "Client UUID missing", "error");
      return;
    }
    if (selected.length === 0) {
      Swal.fire("Warning", "Pilih minimal 1 employee", "warning");
      return;
    }

    const employeesByUuid = new Map(employees.map((e) => [e.uuid, e]));
    const unavailable = selected.filter((s) => {
      const emp = employeesByUuid.get(s);
      return !emp || !isAvailable(emp) || assigned.includes(s);
    });

    if (unavailable.length > 0) {
      const names = unavailable
        .map((u) => employeesByUuid.get(u)?.name ?? u)
        .join(", ");
      Swal.fire({
        icon: "warning",
        title: "Beberapa employee tidak tersedia",
        html: `Employee berikut tidak tersedia dan dihapus dari pilihan: <b>${names}</b>`,
      });
      setSelected((prev) => prev.filter((s) => !unavailable.includes(s)));
      return;
    }

    try {
      setLoading(true);
      await api_laravel.post(`/api/clients/${clientUuid}/assign`, {
        employee_uuids: selected,
        shift_date: shiftDate,
        role,
      });

      Swal.fire({ icon: "success", title: "Assigned", timer: 1400, showConfirmButton: false });
      setSelected([]);

      await Promise.all([fetchAssigned(), fetchEmployees()]);
    } catch (err: any) {
      Swal.fire("Error", err?.response?.data?.message || err.message, "error");
    } finally {
      setLoading(false);
    }
  };

  if (!clientUuid) return <p>Client UUID not found in URL</p>;

  return (
    <Card>
      <CardHeader>
        <CardTitle>Assign Employees</CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        <div className="flex gap-4 items-end">
          <div>
            <Label>Tanggal Shift</Label>
            <Input type="date" value={shiftDate} onChange={(e) => setShiftDate(e.target.value)} />
          </div>
          <div>
            <Label>Role (optional)</Label>
            <Input placeholder="Cleaner / Supervisor" value={role} onChange={(e) => setRole(e.target.value)} />
          </div>
          <Button onClick={handleAssign} disabled={loading || selected.length === 0}>
            {loading ? "Processing..." : "Assign Selected"}
          </Button>
        </div>

        <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-3 max-h-96 overflow-y-auto">
          {availableEmployees.length === 0 ? (
            <div className="col-span-full text-sm text-muted-foreground">
              Tidak ada employee tersedia untuk assign.
            </div>
          ) : (
            availableEmployees.map((emp) => {
              const uuid = String(emp.uuid || "").trim();
              const isSelected = selected.includes(uuid);
              return (
                <div
                  key={uuid}
                  className={`p-3 rounded-lg border cursor-pointer transition select-none
                    ${isSelected ? "bg-blue-500 text-white border-blue-600" : "bg-gray-100 border-gray-300"}
                  `}
                  onClick={() => toggleSelect(uuid)}
                >
                  <div className="font-medium">{emp.name}</div>
                </div>
              );
            })
          )}
        </div>
      </CardContent>
    </Card>
  );
};

export default ClientAssign;
