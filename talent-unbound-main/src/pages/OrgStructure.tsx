// src/pages/OrgStructure.tsx
"use client";


import { useEffect, useState } from "react";
import api_laravel from "@/lib/utils";

interface EmployeeNode {
  uuid: string;
  name: string;
  position_name: string;
  department_description: string;
  supervisorUuid: string | null;
  children?: EmployeeNode[];
}

export default function OrgStructurePage() {
  const [employees, setEmployees] = useState<EmployeeNode[]>([]);
  const [orgStructure, setOrgStructure] = useState<EmployeeNode[]>([]);

  useEffect(() => {
    api_laravel.get("/api/employees")
      .then(res => {
        const data: EmployeeNode[] = res.data.data.map((e: any) => ({
          uuid: e.uuid ?? e.id.toString(),
          name: e.name,
          position: e.position_name,
          department: e.department_description ?? "",
          supervisorUuid: e.immediate_supervisor ?? null,
        }));
        setEmployees(data);
        setOrgStructure(buildOrgRecursive(data));
      })
      .catch(err => console.error(err));
  }, []);

  function buildOrgRecursive(employees: EmployeeNode[], supervisorUuid: string | null = null): EmployeeNode[] {
    return employees
      .filter(emp => emp.supervisorUuid === supervisorUuid)
      .map(emp => ({
        ...emp,
        children: buildOrgRecursive(employees, emp.uuid)
      }));
  }

  return (
    <div className="p-4">
      <h1 className="text-xl font-bold mb-4">Organizational Structure</h1>
      <pre>{JSON.stringify(orgStructure, null, 2)}</pre>
    </div>
  );
}
