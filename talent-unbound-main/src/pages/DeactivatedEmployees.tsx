// src/pages/DeactivatedEmployees.tsx
"use client";
import { useState, useEffect } from "react";
import api_laravel from "@/lib/utils";

export default function DeactivatedEmployees() {
  const [data, setData] = useState<any[]>([]);

  useEffect(() => {
    const fetchData = async () => {
      const res = await api_laravel.get("/api/employees/deactivated");
      setData(res.data.data || []);
    };
    fetchData();
  }, []);

  return (
    <div className="p-6">
      <h2 className="text-lg font-semibold mb-4">Deactivated Employees</h2>
      <table className="w-full border-collapse border border-gray-300">
        <thead>
          <tr className="bg-gray-100">
            <th className="border px-3 py-2">Name</th>
            <th className="border px-3 py-2">Department</th>
            <th className="border px-3 py-2">Deactive Date</th>
            <th className="border px-3 py-2">Reason</th>
          </tr>
        </thead>
        <tbody>
          {data.map((d) => (
            <tr key={d.id}>
              <td className="border px-3 py-2">{d.employee?.name}</td>
              <td className="border px-3 py-2">{d.employee?.department_description}</td>
              <td className="border px-3 py-2">{d.deactive_date}</td>
              <td className="border px-3 py-2">{d.reason}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
