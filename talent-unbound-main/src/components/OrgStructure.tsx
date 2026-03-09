"use client";

import { useEffect, useState } from "react";
import api_laravel from "@/lib/utils";
import { Tree, TreeNode } from "react-organizational-chart";
import { Card } from "@/components/ui/card";

interface EmployeeNode {
  uuid: string;
  name: string;
  position_name: string;
  department: string;
  position: string;
  department_description: string;
  supervisorUuid: string | null;
  children?: EmployeeNode[];
}

export default function OrgStructurePage() {
  const [orgStructure, setOrgStructure] = useState<EmployeeNode[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchEmployees = async () => {
      try {
        setLoading(true);
        const res = await api_laravel.get("/api/employees/list");
        
        console.log("API Response:", res.data); // Debug log
        
        // ✅ FIX: Handle nested data structure
        let employeesData = [];
        
        if (res.data.data && Array.isArray(res.data.data.data)) {
          // Structure: { success: true, data: { data: [...], meta: {...} } }
          employeesData = res.data.data.data;
        } else if (Array.isArray(res.data.data)) {
          // Structure: { success: true, data: [...] } 
          employeesData = res.data.data;
        } else if (Array.isArray(res.data)) {
          // Fallback: direct array response
          employeesData = res.data;
        }

        console.log("Processed Employees:", employeesData); // Debug log

        if (!Array.isArray(employeesData)) {
          throw new Error("Data employees tidak valid");
        }

        const data: EmployeeNode[] = employeesData.map((e: any) => ({
          uuid: e.uuid || e.id.toString(),
          name: e.name || "Unknown",
          position_name: e.position_name || e.position || "No Position",
          department: e.department || "",
          position: e.position_name || e.position || "No Position",
          department_description: e.department_description || e.department || "No Department",
          supervisorUuid: e.immediate_supervisor || null,
        }));

        console.log("Mapped Data:", data); // Debug log
        setOrgStructure(buildOrgRecursive(data));
        
      } catch (err: any) {
        console.error("Error fetching employees:", err);
        setError(err.response?.data?.message || err.message || "Gagal memuat data");
      } finally {
        setLoading(false);
      }
    };

    fetchEmployees();
  }, []);

  // Build tree structure
  function buildOrgRecursive(
    employees: EmployeeNode[],
    supervisorUuid: string | null = null
  ): EmployeeNode[] {
    const filtered = employees.filter((emp) => {
      // Handle null/undefined supervisorUuid for root nodes
      if (supervisorUuid === null) {
        return emp.supervisorUuid === null || emp.supervisorUuid === "";
      }
      return emp.supervisorUuid === supervisorUuid;
    });

    console.log(`Building for supervisor ${supervisorUuid}:`, filtered); // Debug log

    return filtered.map((emp) => ({
      ...emp,
      children: buildOrgRecursive(employees, emp.uuid),
    }));
  }

  // Render recursive TreeNode
  const renderTreeNode = (node: EmployeeNode) => (
    <TreeNode
      key={node.uuid}
      label={
        <Card className="p-3 shadow-md bg-white min-w-[160px] text-center border border-blue-500 hover:shadow-lg transition-shadow">
          <p className="font-bold text-blue-700 truncate">{node.name}</p>
          <p className="text-sm text-gray-600 truncate">{node.position}</p>
          {node.department_description && (
            <p className="text-xs text-gray-400 truncate">{node.department_description}</p>
          )}
        </Card>
      }
    >
      {node.children && node.children.map((child) => renderTreeNode(child))}
    </TreeNode>
  );

  if (loading) {
    return (
      <div className="p-6 min-h-screen flex items-center justify-center">
        <p className="text-lg">Loading organizational structure...</p>
      </div>
    );
  }

  if (error) {
    return (
      <div className="p-6 min-h-screen flex items-center justify-center">
        <div className="text-center">
          <p className="text-red-500 text-lg mb-2">Error: {error}</p>
          <button 
            onClick={() => window.location.reload()}
            className="bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-600"
          >
            Retry
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="p-6 overflow-auto bg-gray-50 min-h-screen">
      <h1 className="text-2xl font-bold mb-6 text-center text-blue-700">
        Organizational Structure
      </h1>

      {orgStructure.length > 0 ? (
        <div className="overflow-x-auto">
          <Tree
            lineWidth={"2px"}
            lineColor={"#2563eb"}
            lineBorderRadius={"10px"}
            label={
              <div className="text-center mb-4">
                <Card className="p-4 bg-blue-600 text-white inline-block">
                  <p className="font-bold">Organization</p>
                  <p className="text-sm">Root Level</p>
                </Card>
              </div>
            }
          >
            {orgStructure.map((root) => renderTreeNode(root))}
          </Tree>
        </div>
      ) : (
        <div className="text-center py-8">
          <p className="text-gray-500">No organizational data available</p>
          <p className="text-sm text-gray-400 mt-2">
            Make sure employees have supervisor relationships defined
          </p>
        </div>
      )}

      {/* Debug Info */}
    
    </div>
  );
}