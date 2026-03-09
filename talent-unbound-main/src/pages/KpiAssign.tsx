import React, { useEffect, useState } from "react";
import api_laravel from "@/lib/utils";
import Swal from "sweetalert2";
import { useParams, useNavigate } from "react-router-dom";

interface Employee {
  id: number;
  name: string;
  department_id?: number;
}

interface Department {
  id: number;
  name: string;
}

export default function AssignKpi() {
  const { masterKpiId } = useParams();
  const navigate = useNavigate();

  const [employees, setEmployees] = useState<Employee[]>([]);
  const [departments, setDepartments] = useState<Department[]>([]);
  const [selectedEmployees, setSelectedEmployees] = useState<number[]>([]);
  const [selectedDepartment, setSelectedDepartment] = useState<number | "">("");

  /* ================= LOAD DATA ================= */
 const loadEmployees = async () => {
  const res = await api_laravel.get("/api/kpi/employee-kpi/data");

  const normalized = Array.isArray(res.data.employees)
    ? res.data.employees.map((e: any) => ({
        ...e,
        department_id: e.department_id ? Number(e.department_id) : null,
      }))
    : [];

  setEmployees(normalized);
};
  const loadDepartments = async () => {
    const res = await api_laravel.get("/api/departments");
    setDepartments(Array.isArray(res.data) ? res.data : []);
  };

  /* ================= TOGGLE ================= */
  const toggleEmployee = (id: number) => {
    setSelectedEmployees((prev) =>
      prev.includes(id) ? prev.filter((x) => x !== id) : [...prev, id]
    );
  };

  /* ================= ASSIGN ================= */
  const assignKpi = async () => {
    if (selectedEmployees.length === 0) {
      Swal.fire("Warning", "Pilih minimal 1 employee", "warning");
      return;
    }

    await api_laravel.post("/api/kpi/employee-kpi/assign", {
      master_kpi_id: masterKpiId,
      employee_ids: selectedEmployees,
    });

    Swal.fire("Success", "KPI berhasil di-assign", "success");
    navigate("/kpi/kpi-list");
  };

  /* ================= HELPER ================= */
  const getDepartmentName = (id?: number) => {
    const dept = departments.find((d) => d.id === id);
    return dept ? dept.name : "-";
  };

  const filteredEmployees = selectedDepartment
    ? employees.filter((e) => e.department_id === selectedDepartment)
    : employees;

  useEffect(() => {
    loadEmployees();
    loadDepartments();
  }, []);

  return (
    <div className="p-6 bg-white rounded shadow">
      <h2 className="text-xl font-bold mb-4">Assign KPI ke Employee11</h2>

      {/* ================= FILTER ================= */}
      <label className="block font-semibold mb-1">Filter Department</label>
      <select
        className="border p-2 rounded w-full mb-4"
        value={selectedDepartment}
        onChange={(e) =>
          setSelectedDepartment(
            e.target.value ? Number(e.target.value) : ""
          )
        }
      >
        <option value="">Semua Department</option>
        {departments.map((d) => (
          <option key={d.id} value={d.id}>
            {d.name}
          </option>
        ))}
      </select>

      {/* ================= EMPLOYEE LIST ================= */}
      {filteredEmployees.length === 0 && (
        <p className="text-gray-500">Tidak ada employee</p>
      )}

      {filteredEmployees.map((emp) => (
        <div
          key={emp.id}
          className="border rounded p-3 mb-2 flex items-center gap-3"
        >
          <input
            type="checkbox"
            checked={selectedEmployees.includes(emp.id)}
            onChange={() => toggleEmployee(emp.id)}
          />
          <div>
            <p className="font-medium">{emp.name}</p>
            <p className="text-sm text-gray-500">
              Department: {getDepartmentName(emp.department_id)}
            </p>
          </div>
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
