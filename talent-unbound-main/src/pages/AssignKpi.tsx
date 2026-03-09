import React, { useEffect, useState } from "react";
import api_laravel from "@/lib/utils";
import Swal from "sweetalert2";
import { useParams, useNavigate } from "react-router-dom";

interface Employee {
  id: number;
  name: string;
}

export default function AssignKpi() {
  const { masterKpiId } = useParams();
  const navigate = useNavigate();

  const [employees, setEmployees] = useState<Employee[]>([]);
  const [selectedEmployees, setSelectedEmployees] = useState<number[]>([]);

  /* ================= LOAD EMPLOYEE ================= */
  const loadEmployees = async () => {
    try {
      const res = await api_laravel.get("/api/kpi/employee-kpi/data");
      setEmployees(Array.isArray(res.data) ? res.data : []);
    } catch {
      Swal.fire("Error", "Gagal load employee", "error");
    }
  };

  /* ================= TOGGLE EMPLOYEE ================= */
  const toggleEmployee = (id: number) => {
    setSelectedEmployees((prev) =>
      prev.includes(id)
        ? prev.filter((x) => x !== id)
        : [...prev, id]
    );
  };

  /* ================= ASSIGN KPI ================= */
  const assignKpi = async () => {
    if (selectedEmployees.length === 0) {
      Swal.fire("Warning", "Pilih minimal 1 employee", "warning");
      return;
    }

    try {
      await api_laravel.post("/api/kpi/employee-kpi/assign", {
        master_kpi_id: masterKpiId,
        employee_ids: selectedEmployees,
      });

      Swal.fire("Success", "KPI berhasil di-assign", "success");
      navigate("/kpi/master-kpi");
    } catch {
      Swal.fire("Error", "Gagal assign KPI", "error");
    }
  };

  useEffect(() => {
    loadEmployees();
  }, []);

  return (
    <div className="p-6 bg-white rounded shadow">
      <h2 className="text-xl font-bold mb-4">Assign KPI ke Employee22</h2>

      {employees.map((emp) => (
        <div
          key={emp.id}
          className="border rounded p-3 mb-2 flex items-center gap-3"
        >
          <input
            type="checkbox"
            checked={selectedEmployees.includes(emp.id)}
            onChange={() => toggleEmployee(emp.id)}
          />
          <span>{emp.name}</span>
        </div>
      ))}

      <button
        onClick={assignKpi}
        className="bg-blue-700 text-white px-5 py-2 rounded mt-4"
      >
        Assign KPI
      </button>
    </div>
  );
}
