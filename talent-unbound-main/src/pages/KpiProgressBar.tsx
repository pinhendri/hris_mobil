import React, { useEffect, useState } from "react";
import api_laravel from "@/lib/utils";

export default function KpiProgressBar({ employeeId, period }: any) {
  const [progress, setProgress] = useState(0);

  const loadProgress = async () => {
    const res = await api_laravel.get(`/api/kpi/progress/${employeeId}/${period}`);
    setProgress(res.data.progress);
  };

  useEffect(() => {
    if (employeeId && period) loadProgress();
  }, [employeeId, period]);

  return (
    <div className="p-3 border rounded bg-gray-50">
      <h3 className="font-semibold mb-2">KPI Progress</h3>

      <div className="w-full bg-gray-300 rounded-full h-4">
        <div
          className="bg-green-600 h-4 rounded-full"
          style={{ width: `${progress}%` }}
        ></div>
      </div>

      <p className="mt-2 font-medium">{progress}%</p>
    </div>
  );
}
