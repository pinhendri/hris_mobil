import React, { useState } from "react";
import api_laravel from "@/lib/utils";
import Swal from "sweetalert2";

interface KPIItem {
  goal_name: string;
  target_value: string;
  weight: string;
  period: "monthly" | "quarterly" | "semester" | "yearly";
  month?: number | "";
  quarter?: string | "";
  semester?: string | "";
}

interface FormData {
  department_id: string;
  year: number;
  items: KPIItem[];
}

export default function KpiComplexForm() {
  const [formData, setFormData] = useState<FormData>({
    department_id: "",
    year: new Date().getFullYear(),
    items: [
      {
        goal_name: "",
        target_value: "",
        weight: "",
        period: "monthly",
        month: "",
        quarter: "",
      },
    ],
  });

  const addRow = () => {
    setFormData((prev) => ({
      ...prev,
      items: [
        ...prev.items,
        {
          goal_name: "",
          target_value: "",
          weight: "",
          period: "monthly",
          month: "",
          quarter: "",
        },
      ],
    }));
  };

  const removeRow = (index: number) => {
    setFormData((prev) => ({
      ...prev,
      items: prev.items.filter((_, i) => i !== index),
    }));
  };

  const handleChange =
    (index: number, field: string) =>
    (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => {
      const value = e.target.value;

      setFormData((prev) => {
        const updated = [...prev.items];
        updated[index] = {
          ...updated[index],
          [field]:
            field === "month" ? (value === "" ? "" : Number(value)) : value,
        };
        return { ...prev, items: updated };
      });
    };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    // ubah items menjadi details
    const payload = {
        department_id: formData.department_id,
        year: formData.year,

        // Ambil period header dari baris pertama (boleh disesuaikan)
        period: formData.items[0].period,

        // Jika monthly
        month: formData.items[0].period === "monthly" ? formData.items[0].month : null,

        semester: formData.items[0].period === "semester" ? formData.items[0].semester : null,

        // Jika quarterly
        quarter: formData.items[0].period === "quarterly" ? formData.items[0].quarter : null,

        // Semua baris KPI masuk ke details
        details: formData.items.map((item) => ({
            goal_name: item.goal_name,
            target_value: item.target_value,
            weight: item.weight,
        })),
    };

    try {
        await api_laravel.post("/api/kpi/master-kpi", payload);

        Swal.fire({
            icon: "success",
            title: "Success!",
            text: "Semua KPI berhasil disimpan!",
        });

    } catch (error) {
        Swal.fire({
            icon: "error",
            title: "Oops!",
            text: "Gagal menyimpan data.",
        });
    }
};


  return (
    <div className="p-4 bg-white shadow rounded border">
      <h2 className="text-xl font-semibold mb-4">Master KPI – Complex Input</h2>

      <form onSubmit={handleSubmit} className="space-y-4">

        {/* Department */}
        <div>
          <label className="font-medium">Department</label>
          <select
            className="border p-2 w-full rounded"
            value={formData.department_id}
            onChange={(e) =>
              setFormData({ ...formData, department_id: e.target.value })
            }
          >
            <option value="">-- Select Department --</option>
            <option value="1">IT</option>
            <option value="2">HR</option>
            <option value="3">Finance</option>
            <option value="4">Sales</option>
            <option value="5">Operational</option>
          </select>
        </div>

        {/* Year */}
        <div>
          <label className="font-medium">Year</label>
          <input
            type="number"
            className="border p-2 w-full rounded"
            value={formData.year}
            onChange={(e) =>
              setFormData({ ...formData, year: Number(e.target.value) })
            }
          />
        </div>

        {/* KPI LIST */}
        <div className="border rounded p-3 space-y-4 bg-gray-50">
          {formData.items.map((item, index) => (
            <div key={index} className="border p-3 rounded bg-white">
              <div className="flex justify-between">
                <h3 className="font-semibold">KPI #{index + 1}</h3>
                {index > 0 && (
                  <button
                    type="button"
                    className="text-red-600"
                    onClick={() => removeRow(index)}
                  >
                    Remove
                  </button>
                )}
              </div>

              {/* Goal */}
              <input
                className="border p-2 mt-2 w-full rounded"
                placeholder="Goal name"
                value={item.goal_name}
                onChange={handleChange(index, "goal_name")}
              />

              {/* Target */}
              <input
                className="border p-2 mt-2 w-full rounded"
                placeholder="Target value"
                value={item.target_value}
                onChange={handleChange(index, "target_value")}
              />

              {/* Weight */}
              <input
                type="number"
                className="border p-2 mt-2 w-full rounded"
                placeholder="Weight (%)"
                min={1}
                max={100}
                value={item.weight}
                onChange={handleChange(index, "weight")}
              />

              {/* Period */}
              <select
                className="border p-2 mt-2 w-full rounded"
                value={item.period}
                onChange={handleChange(index, "period")}
              >
                <option value="monthly">Monthly</option>
                <option value="quarterly">Quarterly</option>
                <option value="semester">Semester</option>
                <option value="yearly">Yearly</option>
              </select>

              {/* Month */}
              {item.period === "monthly" && (
                <select
                  className="border p-2 mt-2 w-full rounded"
                  value={item.month}
                  onChange={handleChange(index, "month")}
                >
                  <option value="">-- Select Month --</option>
                  {[...Array(12)].map((_, i) => (
                    <option key={i + 1} value={i + 1}>
                      {new Date(0, i).toLocaleString("en-US", {
                        month: "long",
                      })}
                    </option>
                  ))}
                </select>
              )}

              {/* Quarter */}
              {item.period === "quarterly" && (
                <select
                  className="border p-2 mt-2 w-full rounded"
                  value={item.quarter}
                  onChange={handleChange(index, "quarter")}
                >
                  <option value="">-- Select Quarter --</option>
                  <option value="Q1">Quarter 1</option>
                  <option value="Q2">Quarter 2</option>
                  <option value="Q3">Quarter 3</option>
                  <option value="Q4">Quarter 4</option>
                </select>
              )}
            </div>
          ))}

          <button
            type="button"
            onClick={addRow}
            className="bg-green-600 text-white px-3 py-2 rounded"
          >
            + Add KPI
          </button>
        </div>

        <button
          type="submit"
          className="bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700"
        >
          Save All KPIs
        </button>
      </form>
    </div>
  );
}
