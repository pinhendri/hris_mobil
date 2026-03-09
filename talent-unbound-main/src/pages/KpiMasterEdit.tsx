import React, { useEffect, useState } from "react";
import api_laravel from "@/lib/utils";
import { useParams, useNavigate } from "react-router-dom";
import Swal from "sweetalert2";

export default function KpiMasterEdit() {
  const { id } = useParams();
  const navigate = useNavigate();
  const [formData, setFormData] = useState<any>({
    department_id: "",
    year: "",
    period: "monthly",
    details: []
  });
  const [loading, setLoading] = useState(true);

  const loadData = async () => {
    try {
      const res = await api_laravel.get(`/api/kpi/master-kpi/${id}`);
      const apiData = res.data.data;
      
      // Transform data dari API ke format yang sesuai dengan form
      setFormData({
        id: apiData.id,
        department_id: apiData.department_id?.toString() || "",
        year: apiData.year?.toString() || "",
        period: apiData.period || "monthly",
        details: apiData.details?.map((detail: any) => ({
          id: detail.id,
          goal_name: detail.goal_name || "",
          target_value: detail.target_value || "",
          weight: detail.weight?.toString() || "",
          category: detail.category || "Quality",
          period: detail.period || "monthly",
          month: detail.month?.toString() || "",
          quarter: detail.quarter?.toString() || "",
          semester: detail.semester?.toString() || ""
        })) || []
      });
    } catch (err) {
      console.error("Error loading data:", err);
      Swal.fire("Error", "Gagal load data", "error");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadData();
  }, [id]);

  const handleChangeDetails =
    (index: number, field: string) =>
    (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => {
      const value = e.target.value;

      setFormData((prev: any) => {
        const updated = [...prev.details];
        updated[index] = {
          ...updated[index],
          [field]: field === "weight" || field === "month" || field === "quarter" || field === "semester" 
            ? (value === "" ? "" : Number(value)) 
            : value,
        };
        return { ...prev, details: updated };
      });
    };

  const addRow = () => {
    setFormData((prev: any) => ({
      ...prev,
      details: [
        ...prev.details,
        {
          goal_name: "",
          target_value: "",
          weight: "",
          category: "Quality",
          period: "monthly",
          month: "",
          quarter: "",
          semester: "",
        },
      ],
    }));
  };

  const updateKpi = async () => {
    try {
      // Transform data sebelum dikirim ke API
      const dataToSend = {
        department_id: parseInt(formData.department_id) || null,
        year: parseInt(formData.year) || null,
        period: formData.period,
        details: formData.details.map((detail: any) => ({
          id: detail.id,
          goal_name: detail.goal_name,
          target_value: detail.target_value,
          weight: parseFloat(detail.weight) || 0,
          category: detail.category,
          period: detail.period,
          month: detail.month ? parseInt(detail.month) : null,
          quarter: detail.quarter ? parseInt(detail.quarter) : null,
          semester: detail.semester ? parseInt(detail.semester) : null
        }))
      };

      await api_laravel.put(`/api/kpi/master-kpi/${id}`, dataToSend);
      Swal.fire("Success", "KPI berhasil diupdate", "success").then(() =>
        navigate("/kpi/kpi-list")
      );
    } catch (error: any) {
      console.error("Update error:", error);
      Swal.fire(
        "Error", 
        error.response?.data?.message || "Gagal update KPI", 
        "error"
      );
    }
  };

  if (loading) return <p className="p-5">Loading...</p>;
  if (!formData) return <p className="p-5">Data tidak ditemukan</p>;

  return (
    <div className="p-5 bg-white shadow rounded">
      <h2 className="text-xl font-semibold mb-4">Edit Master KPI</h2>

      {/* Department */}
      <div className="mb-3">
        <label className="block mb-1 font-medium">Department</label>
        <select
          className="border p-2 w-full rounded"
          value={formData.department_id}
          onChange={(e) =>
            setFormData({ ...formData, department_id: e.target.value })
          }
        >
          <option value="">Pilih Department</option>
          <option value="1">IT</option>
          <option value="2">HR</option>
          <option value="3">Finance</option>
          <option value="4">Sales</option>
          <option value="5">Operational</option>
          <option value="15">Information Technology</option>
        </select>
      </div>

      {/* Year */}
      <div className="mb-3">
        <label className="block mb-1 font-medium">Year</label>
        <input
          type="number"
          className="border p-2 w-full rounded"
          value={formData.year}
          onChange={(e) =>
            setFormData({ ...formData, year: e.target.value })
          }
          placeholder="e.g., 2025"
        />
      </div>

      {/* Period */}
      <div className="mb-3">
        <label className="block mb-1 font-medium">Period</label>
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

      {/* Editable KPI Details */}
      <div className="border rounded p-3 space-y-4 bg-gray-50">
        {formData.details.map((item: any, index: number) => (
          <div key={index} className="border p-3 rounded bg-white">
            <h3 className="font-semibold">KPI #{index + 1}</h3>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-3 mt-2">
              <div>
                <label className="block mb-1 text-sm">Category</label>
                <select
                  className="border p-2 w-full rounded"
                  value={item.category}
                  onChange={handleChangeDetails(index, "category")}
                >
                  <option value="Quality">Quality</option>
                  <option value="Productivity">Productivity</option>
                  <option value="Discipline">Discipline</option>
                </select>
              </div>

              <div>
                <label className="block mb-1 text-sm">Goal Name</label>
                <input
                  className="border p-2 w-full rounded"
                  value={item.goal_name}
                  onChange={handleChangeDetails(index, "goal_name")}
                  placeholder="Goal name"
                />
              </div>

              <div>
                <label className="block mb-1 text-sm">Target Value</label>
                <input
                  className="border p-2 w-full rounded"
                  value={item.target_value}
                  onChange={handleChangeDetails(index, "target_value")}
                  placeholder="Target value"
                />
              </div>

              <div>
                <label className="block mb-1 text-sm">Weight (%)</label>
                <input
                  type="number"
                  className="border p-2 w-full rounded"
                  value={item.weight}
                  onChange={handleChangeDetails(index, "weight")}
                  placeholder="Weight"
                  min="0"
                  max="100"
                />
              </div>

              <div>
                <label className="block mb-1 text-sm">Detail Period</label>
                <select
                  className="border p-2 w-full rounded"
                  value={item.period}
                  onChange={handleChangeDetails(index, "period")}
                >
                  <option value="monthly">Monthly</option>
                  <option value="quarterly">Quarterly</option>
                  <option value="semester">Semester</option>
                  <option value="yearly">Yearly</option>
                </select>
              </div>

              {item.period === "monthly" && (
                <div>
                  <label className="block mb-1 text-sm">Month</label>
                  <input
                    type="number"
                    className="border p-2 w-full rounded"
                    value={item.month}
                    onChange={handleChangeDetails(index, "month")}
                    placeholder="Month (1-12)"
                    min="1"
                    max="12"
                  />
                </div>
              )}

              {item.period === "quarterly" && (
                <div>
                  <label className="block mb-1 text-sm">Quarter</label>
                  <input
                    type="number"
                    className="border p-2 w-full rounded"
                    value={item.quarter}
                    onChange={handleChangeDetails(index, "quarter")}
                    placeholder="Quarter (1-4)"
                    min="1"
                    max="4"
                  />
                </div>
              )}

              {item.period === "semester" && (
                <div>
                  <label className="block mb-1 text-sm">Semester</label>
                  <input
                    type="number"
                    className="border p-2 w-full rounded"
                    value={item.semester}
                    onChange={handleChangeDetails(index, "semester")}
                    placeholder="Semester (1-2)"
                    min="1"
                    max="2"
                  />
                </div>
              )}
            </div>
          </div>
        ))}

        <button
          type="button"
          onClick={addRow}
          className="bg-green-600 hover:bg-green-700 text-white px-3 py-2 rounded"
        >
          + Add KPI Detail
        </button>
      </div>

      <div className="flex gap-2 mt-4">
        <button
          onClick={updateKpi}
          className="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded"
        >
          Update KPI
        </button>
        <button
          onClick={() => navigate("/kpi/kpi-list")}
          className="bg-gray-500 hover:bg-gray-600 text-white px-4 py-2 rounded"
        >
          Cancel
        </button>
      </div>
    </div>
  );
}