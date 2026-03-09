import React, { useEffect,useState } from "react";
import api_laravel from "@/lib/utils";
import Swal from "sweetalert2";
import { useNavigate } from "react-router-dom";

interface KPIItem {
  goal_name: string;
  target_value: string;
  weight: string;
  category: string;
}

export default function KpiMasterCreate() {
  const navigate = useNavigate();

  const [departments, setDepartments] = useState<any[]>([]);

  const loadDepartments = async () => {
  try {
    const res = await api_laravel.get("/api/departments");
    setDepartments(res.data || []);
  } catch (error) {
    Swal.fire("Error", "Gagal load department", "error");
  }
};

useEffect(() => {
  loadDepartments();
}, []);

  const [formData, setFormData] = useState({
    department_id: "",
    year: new Date().getFullYear(),
    period: "monthly",
    month: "",
    quarter: "",
    semester: "",
    items: [
      { goal_name: "", target_value: "", weight: "", category: "" }
    ] as KPIItem[],
  });

  const addRow = () => {
    setFormData((prev) => ({
      ...prev,
      items: [
        ...prev.items,
        { goal_name: "", target_value: "", weight: "", category: "" },
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
    (index: number, field: keyof KPIItem) =>
    (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => {
      const value = e.target.value;
      const updated = [...formData.items];
      updated[index][field] = value;

      setFormData({ ...formData, items: updated });
    };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    const payload = {
      department_id: formData.department_id,
      year: formData.year,
      period: formData.period,
      month: formData.month,
      quarter: formData.quarter,
      semester: formData.semester,
      details: formData.items,
    };

    try {
      await api_laravel.post("/api/kpi/master-kpi", payload);

      Swal.fire("Success!", "Master KPI berhasil disimpan", "success").then(
        () => navigate("/kpi/kpi-list")
      );
    } catch (error: any) {
      Swal.fire("Error", error.response?.data?.message || "Gagal menyimpan KPI", "error");
    }
  };

  return (
    <div className="p-5 bg-white rounded shadow">
      <h2 className="text-xl font-semibold mb-4">Create Master KPI</h2>

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

    {departments.map((dept) => (
      <option key={dept.id} value={dept.id}>
        {dept.name}
      </option>
    ))}
  </select>
</div>

        {/* Period Header */}
        <div>
          <label className="font-medium">Period</label>
          <select
            className="border p-2 w-full rounded"
            value={formData.period}
            onChange={(e) =>
              setFormData({ ...formData, period: e.target.value })
            }
          >
            <option value="monthly">Monthly</option>
            <option value="quarterly">Quarterly</option>
            <option value="semester">Semester</option>
            <option value="yearly">Yearly</option>
          </select>
        </div>

        {/* Conditional header fields */}
        {formData.period === "monthly" && (
          <div>
            <label>Month</label>
            <select
              className="border p-2 w-full rounded"
              value={formData.month}
              onChange={(e) =>
                setFormData({ ...formData, month: e.target.value })
              }
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
          </div>
        )}

        {formData.period === "quarterly" && (
          <div>
            <label>Quarter</label>
            <select
              className="border p-2 w-full rounded"
              value={formData.quarter}
              onChange={(e) =>
                setFormData({ ...formData, quarter: e.target.value })
              }
            >
              <option value="">-- Select Quarter --</option>
              <option value="Q1">Q1</option>
              <option value="Q2">Q2</option>
              <option value="Q3">Q3</option>
              <option value="Q4">Q4</option>
            </select>
          </div>
        )}

        {formData.period === "semester" && (
          <div>
            <label>Semester</label>
            <select
              className="border p-2 w-full rounded"
              value={formData.semester}
              onChange={(e) =>
                setFormData({ ...formData, semester: e.target.value })
              }
            >
              <option value="">-- Select Semester --</option>
              <option value="S1">Semester 1</option>
              <option value="S2">Semester 2</option>
            </select>
          </div>
        )}

        {/* KPI ITEM ROWS */}
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

              <select
                className="border p-2 mt-2 w-full rounded"
                value={item.category}
                onChange={handleChange(index, "category")}
              >
                <option value="">-- Select Category --</option>
                <option value="Quality">Quality</option>
                <option value="Productivity">Productivity</option>
                <option value="Discipline">Discipline</option>
              </select>

              <input
                className="border p-2 mt-2 w-full rounded"
                placeholder="Goal name"
                value={item.goal_name}
                onChange={handleChange(index, "goal_name")}
              />

              <input
                className="border p-2 mt-2 w-full rounded"
                placeholder="Target value"
                value={item.target_value}
                onChange={handleChange(index, "target_value")}
              />

              <input
                type="number"
                className="border p-2 mt-2 w-full rounded"
                placeholder="Weight (%)"
                value={item.weight}
                onChange={handleChange(index, "weight")}
              />
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

